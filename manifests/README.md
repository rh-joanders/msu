# manifests/README.md
# Kubernetes/OpenShift Manifests

This directory contains the Kubernetes/OpenShift manifests for deploying the LAMP stack application. The manifests are organized using Kustomize for better environment management.

## Structure

- `base/`: Contains the base resources common to all environments
- `overlays/`: Contains environment-specific overlays that customize the base resources
  - `dev/`: Development environment configuration
  - `prod/`: Production environment configuration

## Base Resources

The base directory includes:

- `deployment.yaml`: PHP/Apache application deployment
- `service.yaml`: Service for the PHP/Apache application
- `route.yaml`: OpenShift route for external access
- `configmap.yaml`: Application configuration
- `mysql-deployment.yaml`: MySQL database deployment
- `mysql-service.yaml`: Service for MySQL
- `mysql-pvc.yaml`: Persistent volume claim for MySQL data
- `mysql-secret.yaml`: Secret containing database credentials
- `kustomization.yaml`: Kustomize configuration

## Environment Overlays

Each environment overlay extends the base with specific customizations:

- **Development (dev)**: Single replica for both applications
- **Production (prod)**: Multiple replicas for high availability

## Usage

To apply the manifests directly:

```bash
# For development
oc apply -k manifests/overlays/dev

# For production
oc apply -k manifests/overlays/prod
```

However, in a GitOps setup, ArgoCD will apply these manifests automatically based on the defined applications.

## Customization

To customize for your environment:

1. Update environment-specific settings in the appropriate overlay
2. Modify resource requests/limits as needed
3. Update the secret values for your database
