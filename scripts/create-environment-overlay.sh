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

# Export variables for envsubst
export APP_NAME
export GIT_BRANCH

# Replace placeholder variables in the overlay using envsubst
echo "Substituting variables in overlay files..."
find "$OVERLAY_DIR" -type f | while read -r file; do
  # Create a temporary file for the substitution
  temp_file=$(mktemp)
  
  # Use envsubst to substitute variables
  envsubst < "$file" > "$temp_file"
  
  # Move the temporary file back to replace the original
  mv "$temp_file" "$file"
done

echo "Updated placeholder variables in overlay files"
echo ""
echo "Environment overlay created successfully"
echo "Overlay path: $OVERLAY_DIR"
echo ""
echo "To deploy this environment, run the deployment script with:"
echo "APP_NAME=$APP_NAME GIT_BRANCH=$GIT_BRANCH ./scripts/single-env-deployment.sh"