#!/bin/bash
# Idempotent deployment script for OpenShift LAMP GitOps demo

# Enable exit on error and command tracing for better debugging
set -e
# Uncomment the following line when debugging
# set -x

# Default configuration (can be overridden by environment variables)
export GIT_REPOSITORY_URL=${GIT_REPOSITORY_URL:-"https://github.com/rh-joanders/msu.git"}
export GIT_BRANCH=${GIT_BRANCH:-"main"}
export DEPLOYMENT_NAMESPACE=${DEPLOYMENT_NAMESPACE:-"lamp-dev"}
export IMAGE_TAG=${IMAGE_TAG:-"latest"}

echo "=== Setting up OpenShift LAMP GitOps Demo ==="
echo "Git Repository: $GIT_REPOSITORY_URL"
echo "Branch: $GIT_BRANCH"
echo "Deployment Namespace: $DEPLOYMENT_NAMESPACE"

# Function to check if a resource exists
resource_exists() {
  local resource_type=$1
  local resource_name=$2
  local namespace=$3
  
  if [ -z "$namespace" ]; then
    oc get $resource_type $resource_name &>/dev/null
  else
    oc get $resource_type $resource_name -n $namespace &>/dev/null
  fi
  
  return $?
}

# Function to create namespace if it doesn't exist
create_namespace() {
  local namespace=$1
  
  if ! resource_exists "namespace" "$namespace"; then
    echo "Creating namespace: $namespace"
    oc create namespace $namespace
  else
    echo "Namespace $namespace already exists, skipping creation"
  fi
}

# Function to process template files (environment variable substitution)
process_template() {
  local template_file=$1
  local output_file=$2
  
  if [ -f "$template_file" ]; then
    echo "Processing template: $template_file -> $output_file"
    envsubst < "$template_file" > "$output_file"
  else
    echo "Warning: Template file $template_file not found"
    return 1
  fi
}

# Step 1: Create the necessary namespaces
create_namespace "lamp-dev"
create_namespace "lamp-prod"

# Step 2: Check if OpenShift GitOps and Pipelines are installed
echo "Checking for required operators..."
if ! resource_exists "crd" "applications.argoproj.io"; then
  echo "Error: OpenShift GitOps operator is not installed. Please install it first."
  exit 1
fi

if ! resource_exists "crd" "pipelineruns.tekton.dev"; then
  echo "Error: OpenShift Pipelines operator is not installed. Please install it first."
  exit 1
fi

# Step 3: Update Git repository ConfigMap file
echo "Updating Git repository ConfigMap file..."
GIT_REPO_CONFIG_PATH="manifests/base/git-repo-config.yaml"
if [ -f "$GIT_REPO_CONFIG_PATH" ]; then
  # Replace the placeholder with the actual Git repository URL
  sed -i "s|GIT_REPOSITORY_URL: .*|GIT_REPOSITORY_URL: \"$GIT_REPOSITORY_URL\"|" "$GIT_REPO_CONFIG_PATH"
  echo "Updated $GIT_REPO_CONFIG_PATH with repository URL: $GIT_REPOSITORY_URL"
else
  echo "Warning: Git repository ConfigMap file not found at $GIT_REPO_CONFIG_PATH"
fi

# Step 4: Apply Tekton task for ArgoCD sync if it doesn't exist
echo "Setting up Tekton tasks..."
if ! resource_exists "task" "argocd-task-sync-and-wait" "lamp-dev"; then
  echo "Installing ArgoCD sync task..."
  oc apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/argocd-task-sync-and-wait/0.2/argocd-task-sync-and-wait.yaml -n lamp-dev
else
  echo "ArgoCD sync task already exists, skipping installation"
fi

# Step 5: Create or update pipeline workspace PVC
echo "Creating/updating pipeline workspace PVC..."
oc apply -f "pipelines/resources/pipeline-workspace-pvc.yaml" -n lamp-dev

# Step 6: Apply pipeline definition and tasks
echo "Applying pipeline definition and tasks..."
# Define the files to apply
TASK_FILES=(
  "pipelines/tasks/build-image.yaml"
)
PIPELINE_FILES=(
  "pipelines/pipeline.yaml"
)

# Apply the task files
for file in "${TASK_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "Applying task: $file"
    oc apply -f "$file" -n lamp-dev
  else
    echo "Warning: Task file $file not found, skipping"
  fi
done

# Apply the pipeline files
for file in "${PIPELINE_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "Applying pipeline: $file"
    oc apply -f "$file" -n lamp-dev
  else
    echo "Warning: Pipeline file $file not found, skipping"
  fi
done

# Step 7: Apply ArgoCD application definitions
echo "Setting up ArgoCD applications..."
TEMP_ARGOCD_APP=$(mktemp)
process_template "gitops/application-template.yaml" "$TEMP_ARGOCD_APP"
oc apply -f "$TEMP_ARGOCD_APP"
rm -f "$TEMP_ARGOCD_APP"

echo "Waiting for ArgoCD controller to process the applications (10s)..."
sleep 10

# Step 8: Set up permissions (idempotent by default)
echo "Setting up permissions..."
# Set up permissions for pipeline service account
oc policy add-role-to-user edit system:serviceaccount:lamp-dev:pipeline -n lamp-dev
oc policy add-role-to-user edit system:serviceaccount:lamp-dev:pipeline -n lamp-prod
oc policy add-role-to-user system:image-builder system:serviceaccount:lamp-dev:pipeline -n lamp-dev
oc policy add-role-to-user system:image-puller system:serviceaccount:lamp-dev:default -n lamp-dev
oc policy add-role-to-user system:image-puller system:serviceaccount:lamp-prod:default -n lamp-dev

# Step 9: Trigger a pipeline run only if requested
if [ "${TRIGGER_PIPELINE:-no}" = "yes" ]; then
  echo "Triggering pipeline run..."
  TEMP_PIPELINE_RUN=$(mktemp)
  process_template "pipelines/templates/pipeline-run-template.yaml" "$TEMP_PIPELINE_RUN"
  oc create -f "$TEMP_PIPELINE_RUN"
  rm -f "$TEMP_PIPELINE_RUN"
else
  echo "Skipping pipeline trigger. Set TRIGGER_PIPELINE=yes to trigger a pipeline run."
fi

# Step 10: Apply the Tekton triggers for automatic pipeline runs
echo "Setting up Tekton triggers..."
TRIGGER_FILES=(
  "pipelines/triggers/git-trigger-template.yaml"
  "pipelines/triggers/git-trigger-binding.yaml" 
  "pipelines/triggers/git-eventlistener.yaml"
  "pipelines/routes/git-eventlistener.yaml"
)

# Apply the trigger files
for file in "${TRIGGER_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "Applying Tekton trigger: $file"
    oc apply -f "$file" -n lamp-dev
  else
    echo "Warning: Trigger file $file not found, skipping"
  fi
done

# Step 11: Print information and verify setup
echo "=== Deployment Completed ==="
echo "Verifying setup..."

# Function to check resource status
check_resource() {
  local resource_type=$1
  local resource_name=$2
  local namespace=$3
  local message=$4
  
  if resource_exists "$resource_type" "$resource_name" "$namespace"; then
    echo "✅ $message"
  else
    echo "❌ $message - Not found!"
  fi
}

# Check key resources
check_resource "pipeline" "lamp-pipeline" "lamp-dev" "Tekton Pipeline"
check_resource "task" "argocd-task-sync-and-wait" "lamp-dev" "ArgoCD Sync Task"
check_resource "application" "lamp-dev" "openshift-gitops" "ArgoCD Dev Application"
check_resource "application" "lamp-prod" "openshift-gitops" "ArgoCD Prod Application"
check_resource "pvc" "pipeline-workspace-pvc" "lamp-dev" "Pipeline Workspace PVC"

echo ""
echo "Application will be available at:"
APP_ROUTE=$(oc get route lamp-app -n lamp-dev --template='{{.spec.host}}' 2>/dev/null || echo "<pending>")
echo "  https://${APP_ROUTE}"
echo ""
echo "ArgoCD console is available at:"
ARGOCD_ROUTE=$(oc get route openshift-gitops-server -n openshift-gitops --template='{{.spec.host}}' 2>/dev/null || echo "<pending>")
echo "  https://${ARGOCD_ROUTE}"
echo ""
echo "Webhook URL for Git repository:"
WEBHOOK_ROUTE=$(oc get route lamp-webhook-route -n lamp-dev --template='{{.spec.host}}' 2>/dev/null || echo "<pending>")
echo "  https://${WEBHOOK_ROUTE}"