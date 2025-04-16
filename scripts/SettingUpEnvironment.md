# Setting Up with Environment Variables

This document explains how to use environment variables to configure your OpenShift LAMP GitOps deployment.

## Available Environment Variables

|
 Variable Name 
|
 Description 
|
 Default Value 
|
|
---------------
|
-------------
|
---------------
|
|
`GIT_REPOSITORY_URL`
|
 URL of the Git repository 
|
 https://github.com/rh-joanders/msu.git 
|
|
`GIT_BRANCH`
|
 Branch to use for initial deployment 
|
 main 
|

## Usage Examples

### Basic Usage

```bash
# Deploy with default values
./deploy-script.sh
```

### Custom Repository

```bash
# Deploy with a different Git repository
export GIT_REPOSITORY_URL="https://github.com/myuser/my-lamp-app.git"
./deploy-script.sh
```

### Custom Branch

```bash
# Deploy from a specific branch
export GIT_REPOSITORY_URL="https://github.com/myuser/my-lamp-app.git"
export GIT_BRANCH="development"
./deploy-script.sh
```

### One-time Usage

```bash
# Specify variables directly in the command
GIT_REPOSITORY_URL="https://github.com/myuser/my-lamp-app.git" GIT_BRANCH="feature/new-feature" ./deploy-script.sh
```

## Environment Configuration

The deployment script creates a ConfigMap that stores the Git repository URL, which is used by the ArgoCD applications. This allows you to change the repository URL without manually editing each application definition.

### Checking the Current Configuration

```bash
# View the current Git repository configuration
oc get configmap git-repo-config -n lamp-dev -o jsonpath='{.data.GIT_REPOSITORY_URL}'
```

### Updating the Configuration

If you need to change the Git repository URL after the initial deployment:

```bash
# Update the ConfigMap
oc patch configmap git-repo-config -n lamp-dev --type merge -p '{"data": {"GIT_REPOSITORY_URL": "https://github.com/newuser/new-repo.git"}}'

# Refresh the ArgoCD applications
oc patch application lamp-dev -n openshift-gitops --type merge -p '{"spec": {"source": {"repoURL": "https://github.com/newuser/new-repo.git"}}}'
oc patch application lamp-prod -n openshift-gitops --type merge -p '{"spec": {"source": {"repoURL": "https://github.com/newuser/new-repo.git"}}}'
```

## Troubleshooting

If you encounter issues with environment variables not being recognized:

1. Ensure you're exporting the variables properly in your current shell session
2. Check for typos in variable names (they are case-sensitive)
3. Verify that the script has execution permissions (`chmod +x deploy-script.sh`)