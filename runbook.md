Runbook: Deploying LAMP Stack on OpenShift with GitOps and Pipelines
This runbook provides step-by-step instructions for deploying the LAMP stack application on an OpenShift 4.18 cluster that already has OpenShift Pipelines and OpenShift GitOps installed.
Prerequisites

Access to an OpenShift 4.18 cluster with cluster-admin privileges
OpenShift CLI (oc) installed and configured to access your cluster
OpenShift Pipelines Operator already installed
OpenShift GitOps Operator already installed
Git repository containing the LAMP stack code (as provided in the previous artifacts)

Step 1: Clone Your Repository
Ensure your repository with all the code is accessible. If you need to clone it:
bashgit clone https://github.com/YOUR_USERNAME/openshift-lamp-gitops.git
cd openshift-lamp-gitops
Step 2: Create Required Namespaces
bash# Create development namespace
oc new-project lamp-dev

# Create production namespace
oc new-project lamp-prod
Step 3: Create Required Secrets and ConfigMaps
bash# Apply the MySQL secrets to both namespaces
oc apply -f manifests/base/mysql-secret.yaml -n lamp-dev
oc apply -f manifests/base/mysql-secret.yaml -n lamp-prod

# Optional: Update secrets with secure values (recommended for production)
oc create secret generic mysql-secret \
  --from-literal=username=lamp_user \
  --from-literal=password=$(openssl rand -base64 12) \
  --from-literal=database=lamp_db \
  --from-literal=root-password=$(openssl rand -base64 16) \
  --dry-run=client -o yaml | oc apply -f - -n lamp-prod
Step 4: Set Up Pipeline Infrastructure
bash# Create pipeline workspace PVC
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

# Apply pipeline definition
oc apply -f pipelines/pipeline.yaml -n lamp-dev

# Apply custom pipeline tasks
oc apply -f pipelines/tasks/build-image.yaml -n lamp-dev

# Install the ArgoCD sync task from Tekton catalog if not present
if ! oc get task argocd-task-sync-and-wait -n lamp-dev &>/dev/null; then
  echo "Installing ArgoCD sync task..."
  oc apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/argocd-task-sync-and-wait/0.2/argocd-task-sync-and-wait.yaml -n lamp-dev
fi
Step 5: Set Up ArgoCD Applications
bash# Update the repository URL in the ArgoCD application manifests
# Replace the placeholder with your actual Git repository URL
REPO_URL="https://github.com/YOUR_USERNAME/openshift-lamp-gitops.git"
sed -i "s|https://github.com/example/openshift-lamp-gitops.git|$REPO_URL|g" gitops/application.yaml

# Apply the ArgoCD application definitions
oc apply -f gitops/application.yaml
Step 6: Verify ArgoCD Setup
bash# Get the ArgoCD route
ARGOCD_ROUTE=$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')
echo "ArgoCD UI available at: https://$ARGOCD_ROUTE"

# Check application status
oc get applications -n openshift-gitops
Step 7: Trigger Initial Pipeline Run
bash# Create a pipeline run to build and deploy the application
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
    value: main
  - name: image-name
    value: image-registry.openshift-image-registry.svc:5000/lamp-dev/lamp-app
  - name: image-tag
    value: latest
  - name: deployment-namespace
    value: lamp-dev
EOF
Step 8: Monitor Pipeline Execution
bash# Get the pipeline run name
PIPELINE_RUN=$(oc get pipelineruns -n lamp-dev --sort-by=.metadata.creationTimestamp -o name | tail -1)

# Watch pipeline progress
oc logs $PIPELINE_RUN --all-containers=true -f -n lamp-dev

# Or monitor in OpenShift console
echo "Check Pipeline status in OpenShift console: Pipelines → Pipeline Runs"
Step 9: Verify Application Deployment
bash# Wait for ArgoCD to sync (this happens automatically for dev, manually for prod)
oc wait --for=condition=Synced applications lamp-dev -n openshift-gitops --timeout=2m

# Check if pods are running
oc get pods -n lamp-dev

# Get the application route
APP_ROUTE=$(oc get route lamp-app -n lamp-dev -o jsonpath='{.spec.host}')
echo "LAMP application available at: https://$APP_ROUTE"

# Test the application
curl -k https://$APP_ROUTE
Step 10: Deploy to Production (Optional)
bash# Manually sync the production application in ArgoCD
oc patch application lamp-prod -n openshift-gitops --type=merge -p '{"spec":{"syncPolicy":{"automated":{"prune":false,"selfHeal":true}}}}'

# Or manually trigger a sync
oc argo app sync lamp-prod -n openshift-gitops

# Create a pipeline run for production
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
    value: main
  - name: image-name
    value: image-registry.openshift-image-registry.svc:5000/lamp-prod/lamp-app
  - name: image-tag
    value: stable
  - name: deployment-namespace
    value: lamp-prod
EOF
Troubleshooting

Pipeline Fails at Build Stage:

Check if the namespace has appropriate image pull/push permissions:

bashoc policy add-role-to-user system:image-puller system:serviceaccount:lamp-prod:default -n lamp-dev
oc policy add-role-to-user edit system:serviceaccount:lamp-dev:pipeline -n lamp-dev

ArgoCD Application Not Syncing:

Check ArgoCD application status:

bashoc describe application lamp-dev -n openshift-gitops

Force a sync if needed:

bashoc patch application lamp-dev -n openshift-gitops --type=merge -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'

Database Connection Issues:

Verify the MySQL pod is running:

bashoc get pods -l app=mysql -n lamp-dev

Check MySQL logs:

bashoc logs $(oc get pods -l app=mysql -n lamp-dev -o name) -n lamp-dev

Verify the secrets are correctly mounted:

bashoc describe pod $(oc get pods -l app=lamp-app -n lamp-dev -o name | head -1) -n lamp-dev


Cleanup
If you need to remove the deployment:
bash# Delete ArgoCD applications
oc delete -f gitops/application.yaml

# Delete namespaces (this will delete all resources within them)
oc delete project lamp-dev
oc delete project lamp-prod
