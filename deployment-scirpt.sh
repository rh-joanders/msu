#!/bin/bash
# Comprehensive deployment script for OpenShift LAMP GitOps demo

set -e  # Exit on any error

# Configuration
REPO_URL="https://github.com/rh-joanders/msu.git"  # Update this!
BRANCH="main"

echo "=== Setting up OpenShift LAMP GitOps Demo ==="
echo "Git Repository: $REPO_URL"
echo "Branch: $BRANCH"

# Step 1: Create the necessary namespaces
echo "Creating namespaces..."
oc new-project lamp-dev 2>/dev/null || true
oc new-project lamp-prod 2>/dev/null || true

# Step 2: Check if OpenShift GitOps and Pipelines are installed
echo "Checking for required operators..."
if ! oc get crd applications.argoproj.io >/dev/null 2>&1; then
  echo "Error: OpenShift GitOps operator is not installed. Please install it first."
  exit 1
fi

if ! oc get crd pipelineruns.tekton.dev >/dev/null 2>&1; then
  echo "Error: OpenShift Pipelines operator is not installed. Please install it first."
  exit 1
fi

# Step 3: Apply Tekton task for ArgoCD sync if it doesn't exist
echo "Setting up Tekton tasks..."
if ! oc get task argocd-task-sync-and-wait -n lamp-dev >/dev/null 2>&1; then
  echo "Installing ArgoCD sync task..."
  oc apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/argocd-task-sync-and-wait/0.2/argocd-task-sync-and-wait.yaml -n lamp-dev
fi

# Step 4: Create pipeline workspace PVC
echo "Creating pipeline workspace PVC..."
cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pipeline-workspace-pvc
  namespace: lamp-dev
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

# Step 5: Apply pipeline definition and tasks
echo "Applying pipeline definition and tasks..."
oc apply -f pipelines/pipeline.yaml -n lamp-dev
oc apply -f pipelines/tasks/build-image.yaml -n lamp-dev

# Step 6: Apply ArgoCD application (with the correct server URL)
echo "Setting up ArgoCD applications..."
# Update the repository URL in the application yaml
sed "s|https://github.com/rh-joanders/msu.git|$REPO_URL|g" gitops/application.yaml | \
sed "s|targetRevision: main|targetRevision: $BRANCH|g" | \
oc apply -f -

echo "Waiting for ArgoCD controller to process the applications (10s)..."
sleep 10

# Step 7: Give the pipeline service account permissions
echo "Setting up permissions..."
oc policy add-role-to-user edit system:serviceaccount:lamp-dev:pipeline -n lamp-dev
oc policy add-role-to-user system:image-builder system:serviceaccount:lamp-dev:pipeline -n lamp-dev
oc policy add-role-to-user system:image-puller system:serviceaccount:lamp-dev:default -n lamp-dev
oc policy add-role-to-user system:image-puller system:serviceaccount:lamp-prod:default -n lamp-dev

# Step 8: Trigger a pipeline run
echo "Triggering pipeline run..."
cat <<EOF | oc create -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: lamp-pipeline-run-
  namespace: lamp-dev
spec:
  pipelineRef:
    name: lamp-pipeline
  workspaces:
  - name: shared-workspace
    persistentVolumeClaim:
      claimName: pipeline-workspace-pvc
  params:
  - name: git-url
    value: $REPO_URL
  - name: git-revision
    value: $BRANCH
  - name: image-name
    value: image-registry.openshift-image-registry.svc:5000/lamp-dev/lamp-app
  - name: image-tag
    value: latest
  - name: deployment-namespace
    value: lamp-dev
EOF

# Step 9: Print information for accessing the application
echo "=== Deployment Started ==="
echo "The pipeline is now running. You can check its status with:"
echo "  oc get pipelineruns -n lamp-dev"
echo ""
echo "Once completed, check the ArgoCD sync status:"
echo "  oc get applications -n openshift-gitops"
echo ""
echo "The application will be available at:"
echo "  https://$(oc get route lamp-app -n lamp-dev --template='{{.spec.host}}' 2>/dev/null || echo "<pending>")"
echo ""
echo "ArgoCD console is available at:"
echo "  https://$(oc get route openshift-gitops-server -n openshift-gitops --template='{{.spec.host}}' 2>/dev/null || echo "<pending>")"