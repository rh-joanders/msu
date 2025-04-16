#!/bin/bash
# Comprehensive deployment script for OpenShift LAMP GitOps demo with repo variable

set -e  # Exit on any error

# Default configuration (can be overridden by environment variables)
GIT_REPOSITORY_URL=${GIT_REPOSITORY_URL:-"https://github.com/rh-joanders/msu.git"}
GIT_BRANCH=${GIT_BRANCH:-"main"}

echo "=== Setting up OpenShift LAMP GitOps Demo ==="
echo "Git Repository: $GIT_REPOSITORY_URL"
echo "Branch: $GIT_BRANCH"

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

# Step 3: Create ConfigMap with Git repository URL
echo "Creating Git repository ConfigMap..."
cat <<EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: git-repo-config
  namespace: lamp-dev
data:
  GIT_REPOSITORY_URL: "$GIT_REPOSITORY_URL"
EOF

# Step 4: Apply Tekton task for ArgoCD sync if it doesn't exist
echo "Setting up Tekton tasks..."
if ! oc get task argocd-task-sync-and-wait -n lamp-dev >/dev/null 2>&1; then
  echo "Installing ArgoCD sync task..."
  oc apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/argocd-task-sync-and-wait/0.2/argocd-task-sync-and-wait.yaml -n lamp-dev
fi

# Step 5: Create pipeline workspace PVC
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

# Step 6: Apply pipeline definition and tasks
echo "Applying pipeline definition and tasks..."
# First, substitute the repository URL in the pipeline files
PIPELINE_FILE="pipelines/pipeline.yaml"
SETUP_ENV_FILE="pipelines/tasks/setup-environment.yaml"
UPDATE_DEPLOY_FILE="pipelines/tasks/update-deployment.yaml"

# Apply the pipeline files
oc apply -f $SETUP_ENV_FILE -n lamp-dev
oc apply -f $UPDATE_DEPLOY_FILE -n lamp-dev
oc apply -f $PIPELINE_FILE -n lamp-dev

# Step 7: Apply ArgoCD application (with the correct repository URL)
echo "Setting up ArgoCD applications..."
# Apply the templated application with the repository URL
envsubst < argocd-app-template.yaml | oc apply -f -

echo "Waiting for ArgoCD controller to process the applications (10s)..."
sleep 10

# Step 8: Give the pipeline service account permissions
echo "Setting up permissions..."
oc policy add-role-to-user edit system:serviceaccount:lamp-dev:pipeline -n lamp-dev
oc policy add-role-to-user edit system:serviceaccount:lamp-dev:pipeline -n lamp-prod
oc policy add-role-to-user system:image-builder system:serviceaccount:lamp-dev:pipeline -n lamp-dev
oc policy add-role-to-user system:image-puller system:serviceaccount:lamp-dev:default -n lamp-dev
oc policy add-role-to-user system:image-puller system:serviceaccount:lamp-prod:default -n lamp-dev

# Step 9: Trigger a pipeline run
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
    value: $GIT_REPOSITORY_URL
  - name: git-revision
    value: $GIT_BRANCH
  - name: target-environment
    value: dev
  - name: image-tag
    value: latest
  - name: feature-branch-name
    value: ""
EOF

# Step 10: Apply the Tekton triggers for automatic pipeline runs
echo "Setting up Tekton triggers..."
# First, substitute the repository URL in the trigger files
TRIGGER_TEMPLATE_FILE="trigger-template.yaml"
TRIGGER_BINDING_FILE="trigger-binding.yaml"
EVENT_LISTENER_FILE="event-listener.yaml"
EVENT_LISTENER_ROUTE_FILE="event-listener-route.yaml"

# Apply the trigger files
oc apply -f $TRIGGER_TEMPLATE_FILE -n lamp-dev
oc apply -f $TRIGGER_BINDING_FILE -n lamp-dev
oc apply -f $EVENT_LISTENER_FILE -n lamp-dev
oc apply -f $EVENT_LISTENER_ROUTE_FILE -n lamp-dev

# Step 11: Print information for accessing the application
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
echo ""
echo "Webhook URL for Git repository:"
echo "  https://$(oc get route lamp-webhook-route -n lamp-dev --template='{{.spec.host}}' 2>/dev/null || echo "<pending>")"