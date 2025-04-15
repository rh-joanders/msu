# OpenShift LAMP Stack GitOps Demo

This repository contains a complete example of a LAMP (Linux, Apache, MySQL, PHP) stack application deployed on OpenShift 4.18 using GitOps principles and CI/CD automation.

## Overview

This demo showcases:

1. A simple PHP web application connected to a MySQL database
2. Deployment on OpenShift using Kubernetes-native resources
3. GitOps-based deployment using OpenShift GitOps (ArgoCD)
4. CI/CD automation using OpenShift Pipelines (Tekton)

## Repository Structure

- `application/`: Contains the PHP application source code and Dockerfile
- `manifests/`: Contains Kubernetes/OpenShift manifests organized with Kustomize
- `pipelines/`: Contains Tekton pipeline definitions for CI/CD
- `gitops/`: Contains ArgoCD configuration for GitOps deployment

## Prerequisites

- OpenShift 4.18 cluster with admin access
- OpenShift GitOps Operator installed (provides ArgoCD)
- OpenShift Pipelines Operator installed (provides Tekton)
- `oc` CLI tool configured to access your cluster

## Quick Start

1. Fork this repository to your own GitHub account

2. Create the necessary namespaces:
   ```
   oc new-project lamp-dev
   oc new-project lamp-prod
   ```

3. Apply the ArgoCD applications (update the repo URL first):
   ```
   oc apply -f gitops/application.yaml
   ```

4. Create a pipeline workspace PVC:
   ```
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

5. Create and run the pipeline:
   ```
   oc apply -f pipelines/pipeline.yaml
   oc apply -f pipelines/tasks/build-image.yaml
   ```

6. Trigger a pipeline run (update with your repo URL):
   ```
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

7. Access the application:
   ```
   oc get route lamp-app -n lamp-dev
   ```

## Detailed Documentation

See the README files in each directory for detailed explanations of each component.

# Application Documentation