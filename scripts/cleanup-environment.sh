#!/bin/bash
# cleanup-environment.sh - Script to remove all resources associated with an environment
# Usage: ./scripts/cleanup-environment.sh <app-name> [--force]

# Enable exit on error
set -e

# Function to show usage information
show_usage() {
  echo "Usage: $0 <app-name> [--force]"
  echo ""
  echo "  app-name:   Name of the application/namespace to clean up"
  echo "  --force:    Skip confirmation prompts (use with caution)"
  echo ""
  echo "Example: $0 lamp-dev"
  echo "Example: $0 lamp-feature-xyz --force"
  exit 1
}

# Check for minimum required arguments
if [ $# -lt 1 ]; then
  show_usage
fi

# Process arguments
APP_NAME=$1
FORCE=false
if [ "$2" = "--force" ]; then
  FORCE=true
fi

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
  echo "No deployment.env file found, using command line arguments and defaults"
fi

# Set default values for variables not already defined
export ARGOCD_NAMESPACE=${ARGOCD_NAMESPACE:-"openshift-gitops"}

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

# Function to delete a resource if it exists
delete_resource() {
  local resource_type=$1
  local resource_name=$2
  local namespace=$3
  local description=$4
  
  echo -n "Checking for $description ($resource_type/$resource_name)... "
  
  if resource_exists "$resource_type" "$resource_name" "$namespace"; then
    echo "Found."
    echo -n "Deleting $description... "
    
    if [ -z "$namespace" ]; then
      oc delete $resource_type $resource_name --wait=false
    else
      oc delete $resource_type $resource_name -n $namespace --wait=false
    fi
    
    echo "Delete initiated."
  else
    echo "Not found. Skipping."
  fi
}

# Confirmation prompt if not using --force
if [ "$FORCE" != "true" ]; then
  echo "WARNING: This will remove all resources associated with the environment: $APP_NAME"
  echo "The following resources will be deleted:"
  echo "- ArgoCD application in namespace: $ARGOCD_NAMESPACE"
  echo "- All resources in namespace: $APP_NAME"
  echo "- Overlay directory: manifests/overlays/$APP_NAME (if exists)"
  echo ""
  read -p "Are you sure you want to proceed? (y/n): " confirm
  if [[ $confirm != [yY] ]]; then
    echo "Operation canceled."
    exit 0
  fi
fi

echo "=== Starting cleanup of environment: $APP_NAME ==="

# Step 1: Delete the ArgoCD application
echo "Removing ArgoCD application..."
delete_resource "application" "$APP_NAME" "$ARGOCD_NAMESPACE" "ArgoCD application"

# Step 2: Delete the namespace (this will delete all resources in the namespace)
echo "Removing namespace and all resources within it..."
delete_resource "namespace" "$APP_NAME" "" "namespace"

# Step 3: Delete overlay directory if it exists
OVERLAY_DIR="manifests/overlays/$APP_NAME"
if [ -d "$OVERLAY_DIR" ]; then
  echo -n "Removing overlay directory: $OVERLAY_DIR... "
  rm -rf "$OVERLAY_DIR"
  echo "Done."
else
  echo "Overlay directory not found. Skipping."
fi

# Wait for resource deletion to complete
echo "Waiting for resources to be deleted..."
echo -n "Checking if namespace still exists... "
attempts=0
max_attempts=30
deleted=false

while [ $attempts -lt $max_attempts ]; do
  if ! resource_exists "namespace" "$APP_NAME" ""; then
    deleted=true
    break
  fi
  echo -n "."
  sleep 2
  attempts=$((attempts + 1))
done

if [ "$deleted" = "true" ]; then
  echo " Namespace successfully deleted."
else
  echo " Namespace deletion in progress. It might take some time to complete."
  echo "You can check the status later using: oc get namespace $APP_NAME"
fi

echo ""
echo "=== Cleanup completed for environment: $APP_NAME ==="
echo "Note: Some resources might still be in the process of deletion."
echo "To verify complete removal, run: oc get all -n $APP_NAME"
echo ""
echo "The following resources have been removed:"
echo "- ArgoCD application: $APP_NAME (from namespace: $ARGOCD_NAMESPACE)"
echo "- Namespace: $APP_NAME and all resources within it"
echo "- Overlay directory: $OVERLAY_DIR (if it existed)"