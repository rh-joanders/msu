#!/bin/bash
# Script to create a new environment overlay based on the template

# Enable exit on error
set -e

# Determine the script's location and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="${SCRIPT_DIR}/.."

# Load environment variables from deployment.env file if it exists
# Try multiple locations for the deployment.env file
ENV_FILE_LOCATIONS=(
  "${SCRIPT_DIR}/deployment.env"     # In scripts directory
  "${PROJECT_ROOT}/deployment.env"   # In project root
  "./deployment.env"                 # Current directory
)

# Find the deployment.env file
ENV_FILE=""
for location in "${ENV_FILE_LOCATIONS[@]}"; do
  if [ -f "$location" ]; then
    ENV_FILE="$location"
    break
  fi
done

if [ -n "$ENV_FILE" ]; then
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
  echo "No deployment.env file found in the following locations:"
  for location in "${ENV_FILE_LOCATIONS[@]}"; do
    echo "  - $location"
  done
  echo "Using command line arguments and defaults"
fi

# Get parameters - use command line arguments if provided, otherwise use env variables
APP_NAME=${1:-$APP_NAME}
GIT_BRANCH=${2:-$GIT_BRANCH}

# Show current configuration
echo "Current configuration:"
echo "  APP_NAME: $APP_NAME"
echo "  GIT_BRANCH: $GIT_BRANCH"
echo "  GIT_REPOSITORY_URL: $GIT_REPOSITORY_URL"
echo ""

# Check if required variables are set
if [ -z "$APP_NAME" ]; then
  echo "Error: APP_NAME is not set."
  echo "Please provide app-name as a command line argument or set it in deployment.env file."
  echo "Usage: $0 [<app-name>] [<git-branch>]"
  exit 1
fi

if [ -z "$GIT_BRANCH" ]; then
  echo "Warning: GIT_BRANCH is not set. Using default value: main"
  GIT_BRANCH="main"
fi

if [ -z "$GIT_REPOSITORY_URL" ]; then
  echo "Error: GIT_REPOSITORY_URL is not set. Please set it in deployment.env or as an environment variable."
  exit 1
fi

# Ensure APP_NAME doesn't start with a hyphen
if [[ $APP_NAME == -* ]]; then
  echo "Error: app-name cannot start with a hyphen"
  exit 1
fi

# Change to project root after loading env file
cd "$PROJECT_ROOT"

# Set paths (now relative to project root)
TEMPLATE_DIR="manifests/overlays/template"
OVERLAY_DIR="manifests/overlays/$APP_NAME"

echo "Creating environment overlay for $APP_NAME (branch: $GIT_BRANCH)"
echo "Using Git repository: $GIT_REPOSITORY_URL"

# Check if template directory exists
if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Error: Template directory $TEMPLATE_DIR not found"
  echo "Current directory: $(pwd)"
  echo "Listing directory structure:"
  ls -la manifests/overlays/ || echo "Manifests directory not found"
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
if [[ $(uname) == "Darwin" ]]; then
  # macOS requires -i '' for in-place editing
  find "$OVERLAY_DIR" -type f -exec sed -i '' "s|\${APP_NAME}|$APP_NAME|g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i '' "s|\${GIT_BRANCH}|$GIT_BRANCH|g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i '' "s|\${GIT_REPOSITORY_URL}|$GIT_REPOSITORY_URL|g" {} \;
else
  # Linux version
  find "$OVERLAY_DIR" -type f -exec sed -i "s|\${APP_NAME}|$APP_NAME|g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i "s|\${GIT_BRANCH}|$GIT_BRANCH|g" {} \;
  find "$OVERLAY_DIR" -type f -exec sed -i "s|\${GIT_REPOSITORY_URL}|$GIT_REPOSITORY_URL|g" {} \;
fi

echo "Updated placeholder variables in overlay files"
echo ""
echo "Environment overlay created successfully"
echo "Overlay path: $OVERLAY_DIR"
echo ""
echo "To deploy this environment, run the deployment script with:"
echo "APP_NAME=$APP_NAME GIT_BRANCH=$GIT_BRANCH ./scripts/deployment-script.sh"