#!/bin/bash
# Idempotent webhook setup script for OpenShift LAMP GitOps demo

# Enable exit on error
set -e

# Default configuration (can be overridden by environment variables)
export GITHUB_REPO_OWNER=${GITHUB_REPO_OWNER:-"rh-joanders"}
export GITHUB_REPO_NAME=${GITHUB_REPO_NAME:-"msu"}
export GITHUB_TOKEN=${GITHUB_TOKEN:-""}

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

echo "=== Setting up Git webhooks for OpenShift LAMP GitOps Demo ==="
echo "Repository: $GITHUB_REPO_OWNER/$GITHUB_REPO_NAME"

# Step 1: Check if Tekton Triggers components are installed
echo "Checking for Tekton Triggers components..."
if ! resource_exists "crd" "eventlisteners.triggers.tekton.dev"; then
  echo "Installing Tekton Triggers components..."
  oc apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
  
  # Wait for CRDs to be ready
  echo "Waiting for Tekton Triggers CRDs to be ready..."
  for i in {1..30}; do
    if resource_exists "crd" "eventlisteners.triggers.tekton.dev"; then
      echo "Tekton Triggers CRDs are ready."
      break
    fi
    echo "Waiting for Tekton Triggers CRDs to be ready... (${i}/30)"
    sleep 2
  done
  
  if ! resource_exists "crd" "eventlisteners.triggers.tekton.dev"; then
    echo "Error: Tekton Triggers CRDs failed to install within the timeout."
    exit 1
  fi
else
  echo "Tekton Triggers components already installed."
fi

# Step 2: Ensure lamp-dev namespace exists
echo "Ensuring lamp-dev namespace exists..."
if ! resource_exists "namespace" "lamp-dev"; then
  echo "Creating lamp-dev namespace..."
  oc create namespace lamp-dev
else
  echo "lamp-dev namespace already exists."
fi

# Step 3: Apply Tekton Trigger resources
echo "Applying Tekton Trigger resources..."
TRIGGER_FILES=(
  "pipelines/triggers/git-trigger-template.yaml"
  "pipelines/triggers/git-trigger-binding.yaml" 
  "pipelines/triggers/git-eventlistener.yaml"
  "pipelines/routes/git-eventlistener.yaml"
)

# Apply the trigger files
for file in "${TRIGGER_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "Applying: $file"
    oc apply -f "$file" -n lamp-dev
  else
    echo "Warning: File $file not found, skipping"
  fi
done

# Step 4: Ensure the pipeline service account has correct permissions
echo "Setting up pipeline permissions..."
oc policy add-role-to-user edit system:serviceaccount:lamp-dev:pipeline -n lamp-dev
oc policy add-role-to-user edit system:serviceaccount:lamp-dev:pipeline -n lamp-prod

# Step 5: Ensure the pipeline workspace PVC exists
echo "Checking pipeline workspace PVC..."
if ! resource_exists "pvc" "pipeline-workspace-pvc" "lamp-dev"; then
  echo "Creating pipeline workspace PVC..."
  oc apply -f "pipelines/resources/pipeline-workspace-pvc.yaml" -n lamp-dev
else
  echo "Pipeline workspace PVC already exists."
fi

# Step 6: Get the webhook URL and check if the EventListener is ready
echo "Waiting for EventListener deployment to be ready..."
for i in {1..30}; do
  if oc get deployment el-lamp-git-webhook -n lamp-dev -o jsonpath='{.status.readyReplicas}' 2>/dev/null | grep -q '1'; then
    echo "EventListener is ready."
    break
  fi
  echo "Waiting for EventListener to be ready... (${i}/30)"
  sleep 2
done

# Get the webhook URL
if resource_exists "route" "lamp-webhook-route" "lamp-dev"; then
  WEBHOOK_URL="https://$(oc get route lamp-webhook-route -n lamp-dev --template='{{.spec.host}}')"
  echo "Webhook URL: $WEBHOOK_URL"
else
  echo "Error: lamp-webhook-route not found. Check the EventListener deployment."
  exit 1
fi

# Step 7: Create GitHub webhook (if GitHub token is provided)
if [ -n "$GITHUB_TOKEN" ]; then
  echo "=== Creating GitHub webhook ==="
  
  # Check if webhook already exists
  WEBHOOKS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME/hooks")
  
  if echo "$WEBHOOKS" | grep -q "$WEBHOOK_URL"; then
    echo "Webhook already exists for this URL."
  else
    # Create new webhook
    RESPONSE=$(curl -s -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME/hooks" \
      -d '{
        "name": "web",
        "active": true,
        "events": ["push"],
        "config": {
          "url": "'"$WEBHOOK_URL"'",
          "content_type": "json",
          "insecure_ssl": "0"
        }
      }')
    
    if echo "$RESPONSE" | grep -q '"id":'; then
      echo "GitHub webhook created successfully."
    else
      echo "Error creating GitHub webhook: $RESPONSE"
    fi
  fi
else
  echo "=== GitHub webhook configuration ==="
  echo "To manually set up a webhook in your GitHub repository:"
  echo "1. Go to https://github.com/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME/settings/hooks/new"
  echo "2. Set Payload URL to: $WEBHOOK_URL"
  echo "3. Content type: application/json"
  echo "4. Select 'Just the push event'"
  echo "5. Click 'Add webhook'"
fi

# Step 8: Verify the setup
echo "=== Verifying setup ==="
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

check_resource "triggertemplate" "lamp-trigger-template" "lamp-dev" "Trigger Template"
check_resource "triggerbinding" "lamp-git-push-binding" "lamp-dev" "Trigger Binding"
check_resource "eventlistener" "lamp-git-webhook" "lamp-dev" "Event Listener"
check_resource "route" "lamp-webhook-route" "lamp-dev" "Webhook Route"
check_resource "pvc" "pipeline-workspace-pvc" "lamp-dev" "Pipeline Workspace PVC"

echo ""
echo "=== Setup complete ==="
echo "Your pipeline will automatically run when you push to any branch in your repository."