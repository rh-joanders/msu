#!/bin/bash
# Script to create a new environment overlay based on the template

# Enable exit on error
set -e

# Function to show usage information
show_usage() {
  echo "Usage: $0 [<app-name>] [<git-branch>]"
  echo "  app-name:   Name of the application/namespace (e.g. lamp-dev, lamp-prod, feature-123)"
  echo "  git-branch: Git branch to deploy (defaults to main)"
  echo ""
  echo "If arguments are not provided, values from deployment.env or environment variables will be used."
  echo ""
  echo "Example: $0 lamp-dev dev"
  echo "Example: $0  # Uses values from deployment.env"
  exit 1
}

# Check if envsubst is available
if ! command -v envsubst &> /dev/null; then
  echo "Error: envsubst command not found. Please install gettext-base or gettext package."
  exit 1
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
  echo "No deployment.env file found, using command line arguments or existing environment variables"
fi

# Get parameters - use command line arguments if provided, otherwise use environment variables
APP_NAME=${1:-${APP_NAME}}
GIT_BRANCH=${2:-${GIT_BRANCH:-main}}

# Validate that APP_NAME is set
if [ -z "$APP_NAME" ]; then
  echo "Error: APP_NAME is not set. Please provide an app-name argument or set APP_NAME in deployment.env"
  show_usage
fi

# Ensure APP_NAME doesn't start with a hyphen
if [[ $APP_NAME == -* ]]; then
  echo "Error: app-name cannot start with a hyphen"
  exit 1
fi

# Set all required environment variables with defaults if not already set
# Resource limits
export PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-"256Mi"}
export PHP_CPU_LIMIT=${PHP_CPU_LIMIT:-"200m"}
export MYSQL_MEMORY_LIMIT=${MYSQL_MEMORY_LIMIT:-"512Mi"}
export MYSQL_CPU_LIMIT=${MYSQL_CPU_LIMIT:-"500m"}

# Database configuration
export MYSQL_DATABASE=${MYSQL_DATABASE:-"lamp_db"}
export MYSQL_USER=${MYSQL_USER:-"lamp_user"}
export MYSQL_PASSWORD=${MYSQL_PASSWORD:-"lamp_password"}
export MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-"root_password"}

# Additional configurations
export MYSQL_STORAGE_CLASS=${MYSQL_STORAGE_CLASS:-""}
export PHP_REPLICAS=${PHP_REPLICAS:-1}
export MYSQL_REPLICAS=${MYSQL_REPLICAS:-1}
export INIT_DATABASE=${INIT_DATABASE:-"yes"}
export GIT_REPOSITORY_URL=${GIT_REPOSITORY_URL:-"https://github.com/rh-joanders/msu.git"}
export ARGOCD_NAMESPACE=${ARGOCD_NAMESPACE:-"openshift-gitops"}

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

# Create a trap to cleanup temporary files on exit
cleanup() {
  local exit_code=$?
  # Find and remove any temporary files created by mktemp
  find "$OVERLAY_DIR" -name "tmp.*" -type f -delete 2>/dev/null || true
  exit $exit_code
}
trap cleanup EXIT

# Copy template files to the new overlay directory
cp -r "$TEMPLATE_DIR"/* "$OVERLAY_DIR"/
echo "Copied template files to overlay directory"

# Export variables for envsubst
export APP_NAME
export GIT_BRANCH
export GIT_REPOSITORY_URL
export ARGOCD_NAMESPACE
export PHP_MEMORY_LIMIT
export PHP_CPU_LIMIT  
export MYSQL_MEMORY_LIMIT
export MYSQL_CPU_LIMIT
export MYSQL_DATABASE
export MYSQL_USER
export MYSQL_PASSWORD
export MYSQL_ROOT_PASSWORD
export MYSQL_STORAGE_CLASS
export PHP_REPLICAS
export MYSQL_REPLICAS
export INIT_DATABASE

# Define the list of variables to substitute
ENVSUBST_VARS='${APP_NAME} ${GIT_BRANCH} ${GIT_REPOSITORY_URL} ${ARGOCD_NAMESPACE} ${PHP_MEMORY_LIMIT} ${PHP_CPU_LIMIT} ${MYSQL_MEMORY_LIMIT} ${MYSQL_CPU_LIMIT} ${MYSQL_DATABASE} ${MYSQL_USER} ${MYSQL_PASSWORD} ${MYSQL_ROOT_PASSWORD} ${MYSQL_STORAGE_CLASS} ${PHP_REPLICAS} ${MYSQL_REPLICAS} ${INIT_DATABASE}'

# Replace placeholder variables in the overlay using envsubst
echo "Substituting variables in overlay files..."
find "$OVERLAY_DIR" -type f | while read -r file; do
  # Create a temporary file for the substitution
  temp_file=$(mktemp)
  
  # Validate that the file exists and is readable
  if [ ! -r "$file" ]; then
    echo "Error: Cannot read file $file"
    continue
  fi
  
  # Use envsubst to substitute variables
  if ! envsubst "$ENVSUBST_VARS" < "$file" > "$temp_file"; then
    echo "Error: Failed to substitute variables in $file"
    rm -f "$temp_file"
    continue
  fi
  
  # Replace the original file with the substituted version
  if ! mv "$temp_file" "$file"; then
    echo "Error: Failed to update $file"
    rm -f "$temp_file"
    continue
  fi
done

echo "Updated placeholder variables in overlay files"
echo ""
echo "Environment overlay created successfully"
echo "Overlay path: $OVERLAY_DIR"
echo ""
echo "Resource Configuration:"
echo "  PHP Memory Limit: $PHP_MEMORY_LIMIT"
echo "  PHP CPU Limit: $PHP_CPU_LIMIT"
echo "  MySQL Memory Limit: $MYSQL_MEMORY_LIMIT"
echo "  MySQL CPU Limit: $MYSQL_CPU_LIMIT"
echo "  MySQL Storage Class: ${MYSQL_STORAGE_CLASS:-'cluster default'}"
echo ""
echo "To deploy this environment, run the deployment script with:"
echo "APP_NAME=$APP_NAME GIT_BRANCH=$GIT_BRANCH ./scripts/single-env-deployment.sh"
echo "Or if these values are in deployment.env, simply run:"
echo "./scripts/single-env-deployment.sh"