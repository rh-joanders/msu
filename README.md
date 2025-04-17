# OpenShift LAMP Stack GitOps Demo

A complete example of a LAMP (Linux, Apache, MySQL, PHP) stack application deployed on OpenShift using GitOps principles and CI/CD automation.

## Overview

This repository demonstrates:

1. A simple PHP web application connected to a MySQL database
2. Deployment on OpenShift using Kubernetes-native resources
3. GitOps-based deployment using OpenShift GitOps (ArgoCD)
4. CI/CD automation using OpenShift Pipelines (Tekton)

## Prerequisites

- OpenShift 4.18+ cluster with admin access
- OpenShift CLI (`oc`) installed and configured
- OpenShift GitOps Operator installed
- OpenShift Pipelines Operator installed

## Repository Structure

- `application/`: PHP application source code and Dockerfile
- `manifests/`: Kubernetes/OpenShift manifests organized with Kustomize
- `pipelines/`: Tekton pipeline definitions for CI/CD automation
- `gitops/`: ArgoCD configuration for GitOps deployment
- `scripts/`: Utility scripts to deploy and manage environments

## Quick Start

1. Fork this repository to your GitHub account

2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/openshift-lamp-gitops.git
   cd openshift-lamp-gitops

3. Update the deployment.env file with your repository URL and other settings:
# Edit deployment.env
APP_NAME=lamp-dev
GIT_REPOSITORY_URL=https://github.com/YOUR_USERNAME/openshift-lamp-gitops.git
GIT_BRANCH=main

4. Create the environment overlay:
bash./scripts/create-environment-overlay.sh lamp-dev main

5. Deploy the environment:
bash./scripts/single-env-deployment.sh

# The script will output the URL at the end of deployment
# Or you can find it with:
oc get route lamp-app -n lamp-dev