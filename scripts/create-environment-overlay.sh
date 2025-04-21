#!/bin/bash
# Script to create a new environment overlay based on the template

# Enable exit on error
set -e

# Usage information
show_usage() {
  echo "Usage: $0 <app-name> [<git-branch>]"
  echo "  app-name:   Name of the application/namespace (e.g. lamp-dev, lamp-prod, feature-123)"
  echo "  git-branch: Git branch to deploy (defaults to main)"
  echo ""
  echo "Example: $0 lamp-dev dev"
  exit 1
}

# Check for minimum required arguments
if [ $# -lt 1 ]; then
  show_usage
fi

# Get parameters
APP_NAME=$1
GIT_BRANCH=${2:-main}

# Ensure APP_NAME doesn't start with a hyphen
if [[ $APP_NAME == -* ]]; then
  echo "Error: app-name cannot start with a hyphen"
  exit 1
fi

# Set paths
TEMPLATE_DIR="manifests/overlays/template"
OVERLAY_DIR="manifests/overlays/$APP_NAME"

echo "Creating environment overlay for $APP_NAME (branch: $GIT_BRANCH)"

# Check if template directory exists
if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Error: Template directory $TEMPLATE_DIR not found"
  exit 1
fi

# Check if overlay directory already exists
if [ -d "$OVERLAY_DIR" ]; then
  echo "Warning: Overlay directory $OVERLAY_DIR already exists"
  read -p "Do you want to overwrite it? (y/n): " confirm
  if [[ $confirm != [yY] ]]; then
    echo "Operation canceled"
    exit 0
  fi
  echo "Overwriting existing overlay..."
else
  # Create overlay directory
  mkdir -p "$OVERLAY_DIR"
  echo "Created directory: $OVERLAY_DIR"
fi

# Copy template files to the new overlay directory
cp -r "$TEMPLATE_DIR"/* "$OVERLAY_DIR"/
echo "Copied template files to overlay directory"

# Load environment variables from deployment.env if it exists
if [ -f "deployment.env" ]; then
  echo "Loading environment variables from deployment.env..."
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
      var_value=$(echo "$var_value" | xargs)
      
      # Export the variable
      export "$var_name"="$var_value"
    fi
  done < "deployment.env"
else
  echo "Warning: deployment.env file not found. Using defaults."
fi

# Set default values for variables not defined in deployment.env
export ARGOCD_NAMESPACE=${ARGOCD_NAMESPACE:-"openshift-gitops"}
export IMAGE_TAG_LATEST=${IMAGE_TAG_LATEST:-"yes"}
export TRIGGER_PIPELINE=${TRIGGER_PIPELINE:-"no"}
export MYSQL_MEMORY_LIMIT=${MYSQL_MEMORY_LIMIT:-"512Mi"}
export MYSQL_CPU_LIMIT=${MYSQL_CPU_LIMIT:-"500m"}
export PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-"256Mi"}
export PHP_CPU_LIMIT=${PHP_CPU_LIMIT:-"200m"}
export MYSQL_DATABASE=${MYSQL_DATABASE:-"lamp_db"}
export MYSQL_USER=${MYSQL_USER:-"lamp_user"}
export MYSQL_PASSWORD=${MYSQL_PASSWORD:-"lamp_password"}
export MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-"root_password"}
export INIT_DATABASE=${INIT_DATABASE:-"yes"}
export PHP_REPLICAS=${PHP_REPLICAS:-"1"}
export MYSQL_REPLICAS=${MYSQL_REPLICAS:-"1"}
export GIT_REPOSITORY_URL=${GIT_REPOSITORY_URL:-"https://github.com/YOUR_USERNAME/openshift-lamp-gitops.git"}

# Function to perform sed replacements based on OS
perform_sed() {
  local file=$1
  local pattern=$2
  local replacement=$3
  
  if [[ $(uname) == "Darwin" ]]; then
    # macOS requires -i '' for in-place editing
    sed -i '' "s#${pattern}#${replacement}#g" "$file"
  else
    # Linux version
    sed -i "s#${pattern}#${replacement}#g" "$file"
  fi
}

# Replace placeholder variables in all files in the overlay
find "$OVERLAY_DIR" -type f | while read -r file; do
  # Core variables
  perform_sed "$file" '\${APP_NAME}' "$APP_NAME"
  perform_sed "$file" '\${GIT_BRANCH}' "$GIT_BRANCH"
  perform_sed "$file" '\${GIT_REPOSITORY_URL}' "$GIT_REPOSITORY_URL"
  
  # ArgoCD configuration
  perform_sed "$file" '\${ARGOCD_NAMESPACE}' "$ARGOCD_NAMESPACE"
  
  # Image configuration
  perform_sed "$file" '\${IMAGE_TAG_LATEST}' "$IMAGE_TAG_LATEST"
  
  # Pipeline configuration
  perform_sed "$file" '\${TRIGGER_PIPELINE}' "$TRIGGER_PIPELINE"
  
  # MySQL resource limits
  perform_sed "$file" '\${MYSQL_MEMORY_LIMIT}' "$MYSQL_MEMORY_LIMIT"
  perform_sed "$file" '\${MYSQL_CPU_LIMIT}' "$MYSQL_CPU_LIMIT"
  
  # PHP resource limits
  perform_sed "$file" '\${PHP_MEMORY_LIMIT}' "$PHP_MEMORY_LIMIT"
  perform_sed "$file" '\${PHP_CPU_LIMIT}' "$PHP_CPU_LIMIT"
  
  # Database configuration
  perform_sed "$file" '\${MYSQL_DATABASE}' "$MYSQL_DATABASE"
  perform_sed "$file" '\${MYSQL_USER}' "$MYSQL_USER"
  perform_sed "$file" '\${MYSQL_PASSWORD}' "$MYSQL_PASSWORD"
  perform_sed "$file" '\${MYSQL_ROOT_PASSWORD}' "$MYSQL_ROOT_PASSWORD"
  
  # Application configuration
  perform_sed "$file" '\${INIT_DATABASE}' "$INIT_DATABASE"
  perform_sed "$file" '\${PHP_REPLICAS}' "$PHP_REPLICAS"
  perform_sed "$file" '\${MYSQL_REPLICAS}' "$MYSQL_REPLICAS"
done

echo "Updated placeholder variables in overlay files"
echo ""
echo "Environment overlay created successfully"
echo "Overlay path: $OVERLAY_DIR"
echo ""
echo "To deploy this environment, run the deployment script with:"
echo "APP_NAME=$APP_NAME GIT_BRANCH=$GIT_BRANCH ./scripts/single-env-deployment.sh"