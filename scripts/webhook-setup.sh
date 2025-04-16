#!/bin/bash
# Setup script for configuring Git webhooks

set -e  # Exit on any error

# Configuration
GITHUB_REPO_OWNER="rh-joanders"  # Change to your GitHub username or organization
GITHUB_REPO_NAME="msu"           # Change to your repository name
GITHUB_TOKEN=""                  # Your GitHub personal access token

# Install the required Tekton components
echo "=== Installing Tekton Triggers ==="
oc apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml

# Apply Tekton Trigger resources
echo "=== Applying Tekton Trigger resources ==="
oc apply -f trigger-template.yaml
oc apply -f trigger-binding.yaml
oc apply -f event-listener.yaml
oc apply -f event-listener-route.yaml

# Ensure the pipeline service account can create resources
echo "=== Setting up pipeline permissions ==="
oc policy add-role-to-user edit system:serviceaccount:lamp-dev:pipeline -n lamp-dev
oc policy add-role-to-user edit system:serviceaccount:lamp-dev:pipeline -n lamp-prod

# Ensure the pipeline workspace PVC exists
if ! oc get pvc pipeline-workspace-pvc -n lamp-dev >/dev/null 2>&1; then
  echo "Creating pipeline workspace PVC..."
  cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pipeline-workspace-pvc
  namespace: lamp-dev
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
fi

# Get the webhook URL
WEBHOOK_URL="https://$(oc get route lamp-webhook-route -n lamp-dev --template='{{.spec.host}}')"
echo "Webhook URL: $WEBHOOK_URL"

# Create GitHub webhook (if GitHub token is provided)
if [ -n "$GITHUB_TOKEN" ]; then
  echo "=== Creating GitHub webhook ==="
  curl -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME/hooks \
    -d '{
      "name": "web",
      "active": true,
      "events": ["push"],
      "config": {
        "url": "'"$WEBHOOK_URL"'",
        "content_type": "json",
        "insecure_ssl": "0"
      }
    }'
  echo "GitHub webhook created successfully"
else
  echo "=== GitHub webhook configuration ==="
  echo "To manually set up a webhook in your GitHub repository:"
  echo "1. Go to https://github.com/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME/settings/hooks/new"
  echo "2. Set Payload URL to: $WEBHOOK_URL"
  echo "3. Content type: application/json"
  echo "4. Select 'Just the push event'"
  echo "5. Click 'Add webhook'"
fi

echo "=== Setup complete ==="
echo "Your pipeline will now automatically run when you push to any branch in your repository."
echo "To test it, you can create and push a new branch:"
echo ""
echo "  # Create a new feature branch"
echo "  git checkout -b feature/my-feature"
echo "  # Make changes, commit them"
echo "  git commit -am 'New feature'"
echo "  # Push the branch"
echo "  git push origin feature/my-feature"
echo ""
echo "The pipeline will automatically build and deploy to a new environment."
echo ""
echo "When you're ready for production, merge to the prod branch:"
echo ""
echo "  git checkout -b prod"
echo "  git merge feature/my-feature"
echo "  git push origin prod"
echo ""
echo "The pipeline will deploy to the production environment."