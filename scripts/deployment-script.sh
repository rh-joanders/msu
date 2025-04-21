# Enable exit on error and command tracing for better debugging
set -e
# Uncomment the following line when debugging
#set -x

# Load environment variables from deployment.env file if it exists
ENV_FILE="deployment.env"
if [ -f "$ENV_FILE" ]; then
  echo "Loading environment variables from $ENV_FILE..."
  # Read the deployment.env file line by line
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    if [[ -z "$line" || "$line" =~ ^# ]]; then
      continue
    fi
    
    # Extract variable name and value
    if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
      var_name="${BASH_REMATCH[1]}"
      var_value="${BASH_REMATCH[2]}"
      
      # Remove leading/trailing whitespace
      var_name=$(echo "$var_name" | xargs)
      
      # Export the variable if not already set
      if [ -z "${!var_name}" ]; then
        export "$var_name"="$var_value"
      fi
    fi
  done < "$ENV_FILE"
  echo "Environment variables loaded successfully"
else
  echo "No deployment.env file found, using default or existing environment variables"
fi

# Default configuration (can be overridden by environment variables)
export APP_NAME=${APP_NAME:-"lamp-dev"}
export GIT_REPOSITORY_URL=${GIT_REPOSITORY_URL:-"https://github.com/rh-joanders/msu.git"}
export GIT_BRANCH=${GIT_BRANCH:-"main"}
export ARGOCD_NAMESPACE=${ARGOCD_NAMESPACE:-"openshift-gitops"}
export IMAGE_TAG_LATEST=${IMAGE_TAG_LATEST:-"yes"}

# Set the namespace variable to match APP_NAME for simplicity
export NAMESPACE=$APP_NAME

# Set the image tag to match the branch name
# Strip any "/" from the branch name for the image tag
export IMAGE_TAG=$(echo $GIT_BRANCH | sed 's/\//-/g')

echo "=== Setting up OpenShift LAMP GitOps Demo ==="
echo "Git Repository: $GIT_REPOSITORY_URL"
echo "Git Branch: $GIT_BRANCH"
echo "Application Name/Namespace: $APP_NAME"
echo "ArgoCD Namespace: $ARGOCD_NAMESPACE"

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

# Step 1: Create the namespace
create_namespace "$NAMESPACE"

# Grant image-builder role to the pipeline service account in the application namespace
oc policy add-role-to-user system:image-builder system:serviceaccount:$APP_NAME:pipeline -n $APP_NAME

# Grant image-pusher role to ensure push access
oc policy add-role-to-user system:image-pusher system:serviceaccount:$APP_NAME:pipeline -n $APP_NAME

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

# Step 3: Apply Git repository ConfigMap from file
echo "Applying Git repository ConfigMap..."
envsubst < manifests/base/git-repo-config.yaml | oc apply -n $NAMESPACE -f -

# Step 4: Apply Tekton task for ArgoCD sync if it doesn't exist
echo "Setting up Tekton tasks..."
if ! resource_exists "task" "argocd-task-sync-and-wait" "$NAMESPACE"; then
  echo "Installing ArgoCD sync task..."
  oc apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/argocd-task-sync-and-wait/0.2/argocd-task-sync-and-wait.yaml -n "$NAMESPACE"
else
  echo "ArgoCD sync task already exists, skipping installation"
fi

# Step 5: Apply pipeline workspace PVC from file
echo "Applying pipeline workspace PVC..."
oc apply -f pipelines/resources/pipeline-workspace-pvc.yaml -n "$NAMESPACE"

# Step 6: Apply the update-deployment task from file
echo "Applying update-deployment task..."
oc apply -f pipelines/tasks/update-deployment.yaml -n "$NAMESPACE"

# Step 7: Apply pipeline definition from file
echo "Applying pipeline definition..."
oc apply -f pipelines/pipeline.yaml -n "$NAMESPACE"

# Step 8: Apply ArgoCD application definition from file
echo "Setting up ArgoCD application..."
envsubst < gitops/application-template.yaml | oc apply -f -

echo "Waiting for ArgoCD controller to process the application (10s)..."
sleep 10

# Step 9: Set up permissions
echo "Setting up permissions..."
# Apply pipeline service account, role, and role binding
oc apply -f pipelines/rbac/pipeline-serviceaccount.yaml -n "$NAMESPACE"
oc apply -f pipelines/rbac/pipeline-role.yaml -n "$NAMESPACE"
oc apply -f pipelines/rbac/pipeline-rolebinding.yaml -n "$NAMESPACE"

# Create and apply cross-namespace role and rolebinding
envsubst < pipelines/rbac/cross-namespace-role.yaml | oc apply -f -
envsubst < pipelines/rbac/cross-namespace-rolebinding.yaml | oc apply -f -

# Step 10: Trigger a pipeline run only if requested
if [ "${TRIGGER_PIPELINE:-no}" = "yes" ]; then
  echo "Triggering pipeline run..."
  envsubst < pipelines/templates/pipeline-run-template.yaml | oc create -f -
else
  echo "Skipping pipeline trigger. Set TRIGGER_PIPELINE=yes to trigger a pipeline run."
fi

# Create ArgoCD Configuration for Pipeline
echo "Setting up ArgoCD configuration for pipeline..."

# Get ArgoCD server URL from route
echo "Getting ArgoCD server URL..."
ARGOCD_ROUTE=$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
if [ -z "$ARGOCD_ROUTE" ]; then
  ARGOCD_ROUTE=$(oc get route argocd-server -n openshift-gitops -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
fi

if [ -z "$ARGOCD_ROUTE" ]; then
  echo "Warning: Could not find ArgoCD route. Using internal service URL."
  ARGOCD_SERVER="argocd-server.openshift-gitops.svc.cluster.local:443"
else
  ARGOCD_SERVER="${ARGOCD_ROUTE}:443"
fi

# Get ArgoCD admin password from cluster secret
echo "Retrieving ArgoCD admin password..."
ARGOCD_PASSWORD=$(oc get secret openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' 2>/dev/null | base64 -d)
if [ -z "$ARGOCD_PASSWORD" ]; then
  ARGOCD_PASSWORD=$(oc get secret argocd-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' 2>/dev/null | base64 -d)
fi

if [ -z "$ARGOCD_PASSWORD" ]; then
  echo "Error: Could not retrieve ArgoCD admin password"
  exit 1
fi

# Create ArgoCD configuration files
export ARGOCD_SERVER
export ARGOCD_PASSWORD
envsubst < pipelines/rbac/argocd-configmap.yaml | oc apply -f -
envsubst < pipelines/rbac/argocd-secret.yaml | oc apply -f -

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
check_resource "pipeline" "lamp-pipeline" "$NAMESPACE" "Tekton Pipeline"
check_resource "task" "argocd-task-sync-and-wait" "$NAMESPACE" "ArgoCD Sync Task"
check_resource "task" "update-deployment" "$NAMESPACE" "Update Deployment Task"
check_resource "application" "$APP_NAME" "$ARGOCD_NAMESPACE" "ArgoCD Application"
check_resource "pvc" "pipeline-workspace-pvc" "$NAMESPACE" "Pipeline Workspace PVC"

echo ""
echo "Application will be available at:"
APP_ROUTE=$(oc get route lamp-app -n "$NAMESPACE" --template='{{.spec.host}}' 2>/dev/null || echo "<pending>")
echo "  https://${APP_ROUTE}"
echo ""
echo "ArgoCD console is available at:"
ARGOCD_ROUTE=$(oc get route openshift-gitops-server -n "$ARGOCD_NAMESPACE" --template='{{.spec.host}}' 2>/dev/null || echo "<pending>")
echo "  https://${ARGOCD_ROUTE}"