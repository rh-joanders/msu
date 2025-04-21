#!/bin/bash
# OpenShift LAMP GitOps deployment script

# Enable exit on error
set -e

# Determine script and project directories
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

# Load environment variables from deployment.env file if it exists
ENV_FILE="$SCRIPT_DIR/deployment.env"
if [ -f "$ENV_FILE" ]; then
  echo "Loading environment variables from $ENV_FILE..."
  . "$ENV_FILE"
  echo "Environment variables loaded successfully"
else
  echo "No deployment.env file found at $ENV_FILE, using default values"
fi

# Default configuration - make sure to export these variables
export APP_NAME="${APP_NAME:-lamp-dev}"
export GIT_REPOSITORY_URL="${GIT_REPOSITORY_URL:-https://github.com/YOUR_USERNAME/openshift-lamp-gitops.git}"
export GIT_BRANCH="${GIT_BRANCH:-main}"
export ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-openshift-gitops}"
export IMAGE_TAG_LATEST="${IMAGE_TAG_LATEST:-yes}"
export NAMESPACE="$APP_NAME"
export IMAGE_TAG="$(echo "$GIT_BRANCH" | sed 's/\//-/g')"

# Check if critical variables are set properly
if [[ "$GIT_REPOSITORY_URL" == "https://github.com/YOUR_USERNAME/openshift-lamp-gitops.git" ]]; then
    echo "WARNING: Using default GIT_REPOSITORY_URL. Please update the repository URL in deployment.env"
fi

echo "=== OpenShift LAMP GitOps Deployment ==="
echo "Git Repository: $GIT_REPOSITORY_URL"
echo "Git Branch: $GIT_BRANCH"
echo "Application Name/Namespace: $APP_NAME"
echo "ArgoCD Namespace: $ARGOCD_NAMESPACE"

# Check if oc command is available
if ! command -v oc > /dev/null 2>&1; then
    echo "Error: 'oc' command not found. Please install the OpenShift CLI."
    exit 1
fi

# Check if we're logged in to OpenShift
if ! oc whoami > /dev/null 2>&1; then
    echo "Error: Not logged in to OpenShift. Please run 'oc login' first."
    exit 1
fi

# Function to check if a resource exists
resource_exists() {
  local resource_type="$1"
  local resource_name="$2"
  local namespace="$3"
  
  if [ -z "$namespace" ]; then
    oc get "$resource_type" "$resource_name" > /dev/null 2>&1
  else
    oc get "$resource_type" "$resource_name" -n "$namespace" > /dev/null 2>&1
  fi
  
  return $?
}

# Function to create namespace if it doesn't exist
create_namespace() {
  local namespace="$1"
  
  if ! resource_exists "namespace" "$namespace"; then
    echo "Creating namespace: $namespace"
    oc create namespace "$namespace"
  else
    echo "Namespace $namespace already exists"
  fi
}

# Main deployment steps
echo "Starting deployment..."
cd "$PROJECT_ROOT"

# Step 1: Create namespace
create_namespace "$NAMESPACE"

# Step 2: Create pipeline service account
if ! resource_exists "serviceaccount" "pipeline" "$NAMESPACE"; then
  echo "Creating pipeline service account..."
  oc create serviceaccount pipeline -n "$NAMESPACE"
fi

# Step 3: Set up permissions
echo "Setting up permissions..."
oc policy add-role-to-user system:image-builder "system:serviceaccount:$NAMESPACE:pipeline" -n "$NAMESPACE"
oc policy add-role-to-user system:image-pusher "system:serviceaccount:$NAMESPACE:pipeline" -n "$NAMESPACE"
oc policy add-role-to-user edit "system:serviceaccount:$NAMESPACE:pipeline" -n "$NAMESPACE"

# Step 4: Apply Kubernetes resources
echo "Applying Kubernetes resources..."

# Apply resources that belong in the application namespace
namespace_files=(
  "pipelines/resources/pipeline-workspace-pvc.yaml"
  "pipelines/tasks/build-image.yaml"
  "pipelines/pipeline.yaml"
)

# Only attempt to apply files that actually exist
for file in "${namespace_files[@]}"; do
  if [ -f "$file" ]; then
    echo "Found: $file"
    envsubst < "$file" | oc apply -f - -n "$NAMESPACE"
  else
    echo "Skipping: $file (not found)"
  fi
done

# Step 5: Apply ArgoCD application
if [ -f "gitops/application-template.yaml" ]; then
  echo "Applying ArgoCD application to namespace: $ARGOCD_NAMESPACE"
  # Apply the template with environment variable substitution
  envsubst < "gitops/application-template.yaml" | oc apply -f - -n "$ARGOCD_NAMESPACE"
else
  echo "Creating ArgoCD application directly..."
  cat <<EOF | oc apply -f - -n "$ARGOCD_NAMESPACE"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${APP_NAME}
  namespace: ${ARGOCD_NAMESPACE}
spec:
  project: default
  source:
    repoURL: ${GIT_REPOSITORY_URL}
    targetRevision: ${GIT_BRANCH}
    path: manifests/overlays/${APP_NAME}
    kustomize:
      images:
        - "image-registry.openshift-image-registry.svc:5000/${APP_NAME}/lamp-app:${GIT_BRANCH}"
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${APP_NAME}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
fi

# Step 6: Verify deployment
echo ""
echo "=== Deployment Summary ==="
echo "Namespace: $NAMESPACE"
echo "Application: $APP_NAME"
echo ""
echo "Checking resources..."
resource_exists "pipeline" "lamp-pipeline" "$NAMESPACE" && echo "✅ Pipeline found" || echo "❌ Pipeline not found"
resource_exists "application" "$APP_NAME" "$ARGOCD_NAMESPACE" && echo "✅ ArgoCD application found" || echo "❌ ArgoCD application not found"

echo ""
echo "Deployment completed!"