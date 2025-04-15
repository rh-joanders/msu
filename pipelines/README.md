# OpenShift Pipelines (Tekton)

This directory contains the Tekton pipeline definitions for CI/CD automation of the LAMP stack application.

## Contents

- `pipeline.yaml`: Main pipeline definition
- `tasks/`: Directory containing custom Tekton tasks
  - `build-image.yaml`: Task for updating deployment manifests

## Pipeline Overview

The pipeline performs the following steps:

1. Fetches the application code from Git
2. Builds the container image using Buildah
3. Updates the manifests with the new image reference
4. Triggers ArgoCD to sync the application

## Prerequisites

- OpenShift Pipelines operator installed
- The following Tekton tasks must be installed (they come pre-installed with OpenShift Pipelines):
  - `git-clone` ClusterTask
  - `buildah` ClusterTask
  - `argocd-task-sync-and-wait` Task (requires manual installation, see below)

### Installing ArgoCD Task

```bash
oc apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/argocd-task-sync-and-wait/0.2/argocd-task-sync-and-wait.yaml
```

## Running the Pipeline

1. Create a workspace PVC:
   ```bash
   oc create -f - <<EOF
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
   ```

2. Create a PipelineRun:
   ```bash
   oc create -f - <<EOF
   apiVersion: tekton.dev/v1beta1
   kind: PipelineRun
   metadata:
     generateName: lamp-pipeline-run-
     namespace: lamp-dev
   spec:
     pipelineRef:
       name: lamp-pipeline
     workspaces:
     - name: shared-workspace
       persistentVolumeClaim:
         claimName: pipeline-workspace-pvc
     params:
     - name: git-url
       value: https://github.com/YOUR_USERNAME/openshift-lamp-gitops.git
     - name: git-revision
       value: main
     - name: image-name
       value: image-registry.openshift-image-registry.svc:5000/lamp-dev/lamp-app
     - name: image-tag
       value: latest
     - name: deployment-namespace
       value: lamp-dev
   EOF
   ```

## Custom Parameters

The pipeline accepts the following parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| git-url | URL of the git repository | N/A |
| git-revision | Git revision to build | main |
| image-name | Name of the image to build | N/A |
| image-tag | Tag of the image to build | latest |
| deployment-namespace | Namespace to deploy to | lamp-dev |
