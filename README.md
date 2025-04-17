# OpenShift LAMP Stack GitOps Demo

A complete example of a LAMP (Linux, Apache, MySQL, PHP) stack application deployed on OpenShift using GitOps principles and CI/CD automation.

## Overview

This repository demonstrates:

1. A simple PHP web application connected to a MySQL database
2. Deployment on OpenShift using Kubernetes-native resources
3. GitOps-based deployment using OpenShift GitOps (ArgoCD)
4. CI/CD automation using OpenShift Pipelines (Tekton)
5. Environment-specific configuration using Kustomize overlays
6. Feature branch support for easy testing and development

## Prerequisites

- OpenShift 4.x cluster with admin access
- OpenShift CLI (`oc`) installed and configured
- OpenShift GitOps Operator installed
- OpenShift Pipelines Operator installed

## Repository Structure

- `application/`: PHP application source code and Dockerfile
- `manifests/`: Kubernetes/OpenShift manifests organized with Kustomize
  - `base/`: Base resources used by all environments
  - `overlays/`: Environment-specific configurations
- `pipelines/`: Tekton pipeline definitions for CI/CD automation
- `gitops/`: ArgoCD configuration for GitOps deployment
- `scripts/`: Utility scripts to deploy and manage environments

## Quick Start

1. Fork this repository to your GitHub account

2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/openshift-lamp-gitops.git
   cd openshift-lamp-gitops
   ```

3. Update the deployment.env file with your repository URL and other settings:
   ```bash
   # Edit deployment.env with your settings
   APP_NAME=lamp-dev
   GIT_REPOSITORY_URL=https://github.com/YOUR_USERNAME/openshift-lamp-gitops.git
   GIT_BRANCH=main
   ```

4. Create the environment overlay:
   ```bash
   ./scripts/create-environment-overlay.sh lamp-dev main
   ```

5. Deploy the environment:
   ```bash
   ./scripts/deployment-script.sh
   ```

6. Access the application:
   ```bash
   # Get the application URL
   oc get route lamp-app -n lamp-dev
   ```

## Working with Multiple Environments

This repository supports multiple environment deployments:

### Development Environment

```bash
# Configure development environment
./scripts/create-environment-overlay.sh lamp-dev dev
APP_NAME=lamp-dev GIT_BRANCH=dev ./scripts/deployment-script.sh
```

### Production Environment

```bash
# Configure production environment
./scripts/create-environment-overlay.sh lamp-prod main
APP_NAME=lamp-prod GIT_BRANCH=main ./scripts/deployment-script.sh
```

### Feature Branches

```bash
# For a feature branch named "feature/new-login"
./scripts/create-environment-overlay.sh lamp-feature-new-login feature/new-login
APP_NAME=lamp-feature-new-login GIT_BRANCH=feature/new-login ./scripts/deployment-script.sh
```

## CI/CD Pipeline

The CI/CD pipeline is automatically triggered when you push changes to your repository:

1. Code changes are pushed to your Git repository
2. Webhook triggers the Tekton pipeline
3. Pipeline builds a new container image
4. Pipeline updates the deployment configuration
5. ArgoCD detects changes and synchronizes the application

## Customization

### Environment Variables

The `deployment.env` file provides various configuration options:

- `APP_NAME`: Name of the application/namespace
- `GIT_REPOSITORY_URL`: URL of your Git repository
- `GIT_BRANCH`: Branch to deploy
- `TRIGGER_PIPELINE`: Whether to trigger the pipeline immediately
- `IMAGE_TAG_LATEST`: Whether to tag images as 'latest'
- Various resource limits and database settings

See the comments in `deployment.env` for more details.

### Application Code

The PHP application code is in the `application/` directory. You can:

- Modify the application code
- Update the Dockerfile
- Adjust the PHP version or extensions

### Kubernetes Resources

Kubernetes/OpenShift resources are defined in `manifests/`:

- Base resources are in `manifests/base/`
- Environment-specific overlays are in `manifests/overlays/<env>/`

## Cleanup

To remove an environment:

```bash
./scripts/cleanup-environment.sh lamp-dev
```

## Troubleshooting

See the [Troubleshooting.md](application/Troubleshooting.md) and [runbook.md](runbook.md) files for detailed troubleshooting instructions.

## Contributing

Contributions are welcome! Please submit issues and pull requests for any improvements.

## License

This project is licensed under the MIT License - see the LICENSE file for details.