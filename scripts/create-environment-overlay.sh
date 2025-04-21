#!/bin/bash
# Script to create a new environment overlay based on the template

# Enable exit on error
set -e

# Usage information
show_usage() {
  echo "Usage: $0 [<app-name>] [<git-branch>]"
  echo "  app-name:   Name of the application/namespace (defaults to APP_NAME from deployment.env)"
  echo "  git-branch: Git branch to deploy (defaults to GIT_BRANCH from deployment.env)"
  echo ""
  echo "Example: $0 lamp-dev dev"
  echo "Example: $0  # Uses values from deployment.env"
  exit 1
}

# Load environment variables from deployment.env file
load_env_file() {
  local env_file="deployment.env"
  
  if [ -f "$env_file" ]; then
    echo "Loading environment variables from $env_file..."
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
    done < "$env_file"
    echo "Environment variables loaded successfully"
  else
    echo "Warning: No deployment.env file found"
  fi
}

# Load environment variables first
load_env_file

# Get parameters - use command line arguments if provided, otherwise use deployment.env values
APP_NAME=${1:-$APP_NAME}
GIT_BRANCH=${2:-$GIT_BRANCH}

# Validate required parameters
if [ -z "$APP_NAME" ]; then
  echo "Error: APP_NAME is required (either as argument or in deployment.env)"
  show_usage
fi

if [ -z "$GIT_BRANCH" ]; then
  echo "Error: GIT_BRANCH is required (either as argument or in deployment.env)"
  show_usage
fi

# Ensure APP_NAME doesn't start with a hyphen
if [[ $APP_NAME == -* ]]; then
  echo "Error: app-name cannot start with a hyphen"
  exit 1
fi

# Set paths
TEMPLATE_DIR="manifests/overlays/template"
OVERLAY_DIR="manifests/overlays/$APP_NAME"

echo "Creating environment overlay for $APP_NAME (branch: $GIT_BRANCH)"
echo "Using Git repository: ${GIT_REPOSITORY_URL}"

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

# Replace placeholder variables in the overlay
# Use additional variables from deployment.env if available
if [[ $(uname) == "Darwin" ]]; then
  # macOS requires -i '' for in-place editing
  find "$OVERLAY_DIR" -type f -exec sed -i '' "s/\${APP_NAME}/$APP_NAME/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i '' "s/\${GIT_BRANCH}/$GIT_BRANCH/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i '' "s/\${GIT_REPOSITORY_URL}/$GIT_REPOSITORY_URL/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i '' "s/\${MYSQL_DATABASE}/$MYSQL_DATABASE/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i '' "s/\${MYSQL_USER}/$MYSQL_USER/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i '' "s/\${MYSQL_PASSWORD}/$MYSQL_PASSWORD/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i '' "s/\${MYSQL_ROOT_PASSWORD}/$MYSQL_ROOT_PASSWORD/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i '' "s/\${MYSQL_STORAGE_CLASS}/$MYSQL_STORAGE_CLASS/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i '' "s/\${MYSQL_MEMORY_LIMIT}/$MYSQL_MEMORY_LIMIT/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i '' "s/\${MYSQL_CPU_LIMIT}/$MYSQL_CPU_LIMIT/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i '' "s/\${PHP_MEMORY_LIMIT}/$PHP_MEMORY_LIMIT/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i '' "s/\${PHP_CPU_LIMIT}/$PHP_CPU_LIMIT/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i '' "s/\${PHP_REPLICAS}/$PHP_REPLICAS/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i '' "s/\${MYSQL_REPLICAS}/$MYSQL_REPLICAS/g" {} \;
else
  # Linux version
  find "$OVERLAY_DIR" -type f -exec sed -i "s/\${APP_NAME}/$APP_NAME/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i "s/\${GIT_BRANCH}/$GIT_BRANCH/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i "s/\${GIT_REPOSITORY_URL}/$GIT_REPOSITORY_URL/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i "s/\${MYSQL_DATABASE}/$MYSQL_DATABASE/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i "s/\${MYSQL_USER}/$MYSQL_USER/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i "s/\${MYSQL_PASSWORD}/$MYSQL_PASSWORD/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i "s/\${MYSQL_ROOT_PASSWORD}/$MYSQL_ROOT_PASSWORD/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i "s/\${MYSQL_STORAGE_CLASS}/$MYSQL_STORAGE_CLASS/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i "s/\${MYSQL_MEMORY_LIMIT}/$MYSQL_MEMORY_LIMIT/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i "s/\${MYSQL_CPU_LIMIT}/$MYSQL_CPU_LIMIT/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i "s/\${PHP_MEMORY_LIMIT}/$PHP_MEMORY_LIMIT/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i "s/\${PHP_CPU_LIMIT}/$PHP_CPU_LIMIT/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i "s/\${PHP_REPLICAS}/$PHP_REPLICAS/g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i "s/\${MYSQL_REPLICAS}/$MYSQL_REPLICAS/g" {} \;
fi

echo "Updated placeholder variables in overlay files"
echo ""
echo "Environment overlay created successfully"
echo "Overlay path: $OVERLAY_DIR"
echo ""
echo "Current configuration:"
echo "  APP_NAME: $APP_NAME"
echo "  GIT_BRANCH: $GIT_BRANCH"
echo "  GIT_REPOSITORY_URL: $GIT_REPOSITORY_URL"
echo "  MySQL Database: $MYSQL_DATABASE"
echo "  PHP Replicas: $PHP_REPLICAS"
echo ""
echo "To deploy this environment, run the deployment script:"
echo "./scripts/deployment-script.sh"
echo ""
echo "Or customize the deployment with environment variables:"
echo "TRIGGER_PIPELINE=yes ./scripts/deployment-script.sh"