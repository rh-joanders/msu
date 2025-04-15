# GitOps Configuration with ArgoCD

This directory contains the ArgoCD application definitions for deploying the LAMP stack using GitOps principles.

## Overview

ArgoCD is used to continuously synchronize the Kubernetes/OpenShift resources from this Git repository to the cluster. It monitors changes to the manifests and automatically applies them, ensuring the cluster state matches the desired state defined in Git.

## Applications

- `lamp-dev`: Deploys the development environment
- `lamp-prod`: Deploys the production environment

## Deployment Process

1. ArgoCD monitors the Git repository for changes
2. When changes are detected or a sync is manually triggered, ArgoCD applies the Kubernetes manifests
3. ArgoCD reports the sync status and any errors

## Usage

Apply the ArgoCD application definitions:

```bash
# Make sure to update the repoURL in the applications first
oc apply -f gitops/application.yaml
```

### Monitoring Deployments

1. Access the ArgoCD UI:
   ```bash
   oc get route openshift-gitops-server -n openshift-gitops
   ```

2. Log in with your OpenShift credentials

3. View the application sync status and details

## Configuration Details

The ArgoCD applications are configured with:

- Automatic sync enabled for development environment
- Manual approval required for production environment
- Automatic creation of namespaces if they don't exist
- Pruning of resources that are no longer defined in Git (for development only)