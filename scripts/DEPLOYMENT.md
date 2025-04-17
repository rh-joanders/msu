# OpenShift LAMP Stack GitOps Deployment Guide

This guide provides comprehensive instructions for deploying the LAMP (Linux, Apache, MySQL, PHP) stack to OpenShift using GitOps principles and CI/CD automation.

## Architecture Overview

This deployment uses:
- **OpenShift GitOps** (ArgoCD) for continuous deployment
- **OpenShift Pipelines** (Tekton) for CI/CD automation
- **Single environment per deployment** approach for clarity and flexibility

## Prerequisites

- OpenShift 4.18+ cluster with admin access
- OpenShift CLI (`oc`) installed and configured
- OpenShift GitOps Operator installed
- OpenShift Pipelines Operator installed
- Git repository with appropriate permissions

## Deployment Process

### Step 1: Configure Environment Variables

Create a `deployment.env` file in the project root:

```
# Application and namespace configuration
APP_NAME=lamp-dev

# Git repository configuration
GIT_REPOSITORY_URL=https://github.com/your-username/your-repo.git
GIT_BRANCH=main

# ArgoCD configuration
ARGOCD_NAMESPACE=openshift-gitops

# Deployment settings
IMAGE_TAG_LATEST=yes

# Pipeline settings
TRIGGER_PIPELINE=no
```

### Step 2: Create Environment Overlay

Run the environment overlay creation script:

```bash
./scripts/create-environment-overlay.sh lamp-dev dev
```

This creates a Kustomize overlay in `manifests/overlays/lamp-dev` configured for your environment.

### Step 3: Deploy the Environment

Run the deployment script:

```bash
./scripts/single-env-deployment.sh
```

This script will:
1. Load variables from `deployment.env`
2. Create the required namespace
3. Set up Tekton pipelines and tasks
4. Create the ArgoCD application
5. Configure webhooks for CI/CD automation

### Step 4: Verify Deployment

1. Check that the ArgoCD application is synced:
   ```bash
   oc get application lamp-dev -n openshift-gitops
   ```

2. Verify that all pods are running:
   ```bash
   oc get pods -n lamp-dev
   ```

3. Access the application using the route:
   ```bash
   oc get route lamp-app -n lamp-dev
   ```

## Multiple Environment Deployment

To deploy multiple environments (e.g., dev, test, prod), run the process separately for each environment:

```bash
# Create overlays for each environment
./scripts/create-environment-overlay.sh lamp-dev dev
./scripts/create-environment-overlay.sh lamp-test test
./scripts/create-environment-overlay.sh lamp-prod main

# Deploy each environment
APP_NAME=lamp-dev GIT_BRANCH=dev ./scripts/single-env-deployment.sh
APP_NAME=lamp-test GIT_BRANCH=test ./scripts/single-env-deployment.sh
APP_NAME=lamp-prod GIT_BRANCH=main ./scripts/single-env-deployment.sh
```

## CI/CD Pipeline

The CI/CD pipeline automatically:
1. Clones the repository
2. Builds the container image
3. Tags the image with the branch name
4. Optionally tags the image as 'latest'
5. Updates the deployment manifests
6. Triggers ArgoCD to sync the application

## Customization Options

### Image Tagging

- Images are tagged with the branch name by default
- Set `IMAGE_TAG_LATEST=yes` to also tag images as 'latest'

### Git Branch

- Each environment is tied to a specific Git branch
- The pipeline watches for changes to that branch

### Resource Limits

Customize resource limits in the overlay kustomization file:
- Edit `manifests/overlays/<APP_NAME>/kustomization.yaml`

## Updating an Environment

To update an existing environment:

1. Update your code and push to the appropriate Git branch
2. The webhook will trigger a pipeline run automatically

Alternatively, trigger a pipeline run manually:

```bash
APP_NAME=lamp-dev GIT_BRANCH=dev TRIGGER_PIPELINE=yes ./scripts/single-env-deployment.sh
```

## Troubleshooting

### Deployment Issues

- Check ArgoCD application status:
  ```bash
  oc get application lamp-dev -n openshift-gitops
  oc describe application lamp-dev -n openshift-gitops
  ```

- Verify pipeline runs:
  ```bash
  oc get pipelineruns -n lamp-dev
  oc describe pipelinerun <pipelinerun-name> -n lamp-dev
  ```

### Common Errors

1. **Image pull failures**: Ensure image registry permissions are correct
2. **ArgoCD sync errors**: Check if the Git repository is accessible
3. **Pipeline failures**: Examine pipeline task logs for specific errors

## Clean Up

To remove an environment:

1. Delete the ArgoCD application:
   ```bash
   oc delete application lamp-dev -n openshift-gitops
   ```

2. Delete the namespace:
   ```bash
   oc delete namespace lamp-dev
   ```