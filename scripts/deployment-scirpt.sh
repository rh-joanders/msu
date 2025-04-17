#!/bin/bash
# Simplified deployment script for OpenShift LAMP GitOps demo
# This script deploys a single environment based on environment variables

# Enable exit on error and command tracing for better debugging
set -e
# Uncomment the following line when debugging
# set -x

# Load environment variables from deployment.env file if it exists
ENV_FILE="deployment.env"
if [ -f "$ENV_FILE" ]; then
  echo "Loading environment variables from $ENV_FILE..."
  # Read the deployment.env file line by line
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    if [[ -z "$line" || "$line" =~ ^# ]]; then
      continue
    fi
    
    # Extract variable name and value
    if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
      var_name="${BASH_REMATCH[1]}"
      var_value="${BASH_REMATCH[2]}"
      
      # Remove leading/trailing whitespace
      var_name=$(echo "$var_name" | xargs)
      
      # Export the variable if not already set
      if [ -z "${!var_name}" ]; then
        export "$var_name"="$var_value"
      fi
    fi
  done < "$ENV_FILE"
  echo "Environment variables loaded successfully"
else
  echo "No deployment.env file found, using default or existing environment variables"
fi

# Default configuration (can be overridden by environment variables)
export APP_NAME=${APP_NAME:-"lamp-dev"}
export GIT_REPOSITORY_URL=${GIT_REPOSITORY_URL:-"https://github.com/rh-joanders/msu.git"}
export GIT_BRANCH=${GIT_BRANCH:-"main"}
export ARGOCD_NAMESPACE=${ARGOCD_NAMESPACE:-"openshift-gitops"}
export IMAGE_TAG_LATEST=${IMAGE_TAG_LATEST:-"yes"}

# Set the namespace variable to match APP_NAME for simplicity
export NAMESPACE=$APP_NAME

# Set the image tag to match the branch name
# Strip any "/" from the branch name for the image tag
export IMAGE_TAG=$(echo $GIT_BRANCH | sed 's/\//-/g')

echo "=== Setting up OpenShift LAMP GitOps Demo ==="
echo "Git Repository: $GIT_REPOSITORY_URL"
echo "Git Branch: $GIT_BRANCH"
echo "Application Name/Namespace: $APP_NAME"
echo "ArgoCD Namespace: $ARGOCD_NAMESPACE"

# Function to check if a resource exists
resource_exists() {
  local resource_type=$1
  local resource_name=$2
  local namespace=$3
  
  if [ -z "$namespace" ]; then
    oc get $resource_type $resource_name &>/dev/null
  else
    oc get $resource_type $resource_name -n $namespace &>/dev/null
  fi
  
  return $?
}

# Function to create namespace if it doesn't exist
create_namespace() {
  local namespace=$1
  
  if ! resource_exists "namespace" "$namespace"; then
    echo "Creating namespace: $namespace"
    oc create namespace $namespace
  else
    echo "Namespace $namespace already exists, skipping creation"
  fi
}

# Step 1: Create the namespace
create_namespace "$NAMESPACE"

# Step 2: Check if OpenShift GitOps and Pipelines are installed
echo "Checking for required operators..."
if ! resource_exists "crd" "applications.argoproj.io"; then
  echo "Error: OpenShift GitOps operator is not installed. Please install it first."
  exit 1
fi

if ! resource_exists "crd" "pipelineruns.tekton.dev"; then
  echo "Error: OpenShift Pipelines operator is not installed. Please install it first."
  exit 1
fi

# Step 3: Create/Update Git repository ConfigMap
echo "Creating/Updating Git repository ConfigMap..."
TEMP_CONFIGMAP=$(mktemp)
cat << EOF > "$TEMP_CONFIGMAP"
apiVersion: v1
kind: ConfigMap
metadata:
  name: git-repo-config
  namespace: $NAMESPACE
data:
  GIT_REPOSITORY_URL: "$GIT_REPOSITORY_URL"
  APP_NAME: "$APP_NAME"
EOF
oc apply -f "$TEMP_CONFIGMAP"
rm -f "$TEMP_CONFIGMAP"

# Step 4: Apply Tekton task for ArgoCD sync if it doesn't exist
echo "Setting up Tekton tasks..."
if ! resource_exists "task" "argocd-task-sync-and-wait" "$NAMESPACE"; then
  echo "Installing ArgoCD sync task..."
  oc apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/argocd-task-sync-and-wait/0.2/argocd-task-sync-and-wait.yaml -n "$NAMESPACE"
else
  echo "ArgoCD sync task already exists, skipping installation"
fi

# Step 5: Create or update pipeline workspace PVC
echo "Creating/updating pipeline workspace PVC..."
TEMP_PVC=$(mktemp)
cat << EOF > "$TEMP_PVC"
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pipeline-workspace-pvc
  namespace: $NAMESPACE
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
oc apply -f "$TEMP_PVC"
rm -f "$TEMP_PVC"

# Step 6: Update and apply custom build-image task
echo "Creating/updating build-image task..."
TEMP_BUILD_TASK=$(mktemp)
cat << EOF > "$TEMP_BUILD_TASK"
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: update-deployment
  namespace: $NAMESPACE
spec:
  description: |
    This task updates the Kustomize overlay to reference the newly built image.
    It's used to change the image reference in the manifest without requiring
    a git commit or push, as this is a demo application.
  workspaces:
  - name: source  # Workspace containing the manifests
  params:
  - name: image-name
    type: string
    description: The name of the container image
  - name: image-tag
    type: string
    description: The tag of the container image
  - name: deployment-path
    type: string
    description: Path to the kustomization.yaml file to update
  steps:
  - name: update-yaml
    image: quay.io/openshift/origin-cli:latest  # OpenShift CLI image with yaml editing tools
    script: |
      #!/bin/sh
      set -e
      echo "Updating image in \${DEPLOYMENT_PATH} to \${IMAGE_NAME}:\${IMAGE_TAG}"
      cd \$(workspaces.source.path)
      
      # Add or update image references in kustomization.yaml
      if ! grep -q "images:" \${DEPLOYMENT_PATH}; then
        # If no images section exists, add it
        echo "images:" >> \${DEPLOYMENT_PATH}
        echo "- name: lamp-app" >> \${DEPLOYMENT_PATH}
        echo "  newName: \${IMAGE_NAME}" >> \${DEPLOYMENT_PATH}
        echo "  newTag: \${IMAGE_TAG}" >> \${DEPLOYMENT_PATH}
      else
        # If images section exists, update it
        sed -i "s|newName: .*|newName: \${IMAGE_NAME}|g" \${DEPLOYMENT_PATH}
        sed -i "s|newTag: .*|newTag: \${IMAGE_TAG}|g" \${DEPLOYMENT_PATH}
      fi
      
      # In a real-world scenario, we would commit and push these changes to git
      # For this demo, we're just modifying the files locally since ArgoCD is configured
      # to detect changes
      
      echo "Deployment manifest updated successfully"
    env:
    - name: IMAGE_NAME
      value: $(params.image-name)
    - name: IMAGE_TAG
      value: $(params.image-tag)
    - name: DEPLOYMENT_PATH
      value: $(params.deployment-path)
EOF
oc apply -f "$TEMP_BUILD_TASK"
rm -f "$TEMP_BUILD_TASK"

# Step 7: Update and apply pipeline definition
echo "Creating/updating pipeline definition..."
TEMP_PIPELINE=$(mktemp)
cat << EOF > "$TEMP_PIPELINE"
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: lamp-pipeline
  namespace: $NAMESPACE
spec:
  description: |
    This pipeline clones the LAMP application repository, builds the container image,
    updates the Kubernetes manifests, and triggers ArgoCD to sync the application.
  workspaces:
  - name: shared-workspace  # Workspace for sharing data between tasks
  params:
  - name: git-url
    type: string
    description: URL of the git repo
  - name: git-revision
    type: string
    description: Git revision to build
    default: main
  - name: image-name
    type: string
    description: Name of the image to build
  - name: image-tag
    type: string
    description: Tag of the image to build
    default: $IMAGE_TAG
  - name: add-latest-tag
    type: string
    description: Whether to also tag the image as 'latest'
    default: ""
  - name: deployment-path
    type: string
    description: Path to kustomization.yaml
    default: manifests/overlays/$NAMESPACE/kustomization.yaml
  tasks:
  # Task 1: Clone the git repository
  - name: fetch-repository
    taskRef:
      name: git-clone  # Using the standard git-clone ClusterTask
      kind: Task
    workspaces:
    - name: output
      workspace: shared-workspace
    params:
    - name: url
      value: \$(params.git-url)
    - name: revision
      value: \$(params.git-revision)
    - name: subdirectory
      value: ""
    - name: deleteExisting
      value: "true"

  # Task 2: Build and push the container image
  - name: build-image
    taskRef:
      name: buildah  # Using the standard buildah ClusterTask
      kind: Task
    runAfter:
    - fetch-repository  # Must run after git clone
    workspaces:
    - name: source
      workspace: shared-workspace
    params:
    - name: IMAGE
      value: \$(params.image-name):\$(params.image-tag)
    - name: CONTEXT
      value: application  # Directory containing Dockerfile
    - name: DOCKERFILE
      value: Dockerfile
    - name: ADDITIONAL_TAGS
      value: \$(params.add-latest-tag)  # Add latest tag if requested

  # Task 3: Update the deployment manifests with the new image
  - name: update-manifests
    taskRef:
      name: update-deployment  # Custom task defined above
      kind: Task
    runAfter:
    - build-image  # Must run after image build
    workspaces:
    - name: source
      workspace: shared-workspace
    params:
    - name: image-name
      value: \$(params.image-name)
    - name: image-tag
      value: \$(params.image-tag)
    - name: deployment-path
      value: \$(params.deployment-path)

  # Task 4: Trigger ArgoCD to sync the application
  - name: sync-application
    taskRef:
      name: argocd-task-sync-and-wait  # From Tekton catalog
      kind: Task
    runAfter:
    - update-manifests  # Must run after manifest update
    params:
    - name: application-name
      value: $APP_NAME
    - name: flags
      value: --insecure  # Use if ArgoCD is not using TLS certificates
EOF
oc apply -f "$TEMP_PIPELINE"
rm -f "$TEMP_PIPELINE"

# Step 8: Apply ArgoCD application definition
echo "Setting up ArgoCD application..."
TEMP_ARGOCD_APP=$(mktemp)
cat << EOF > "$TEMP_ARGOCD_APP"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${APP_NAME}
  namespace: ${ARGOCD_NAMESPACE}
spec:
  project: default
  source:
    repoURL: ${GIT_REPOSITORY_URL}
    targetRevision: ${GIT_BRANCH}
    path: manifests/overlays/${APP_NAME}
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: ${NAMESPACE}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

oc apply -f "$TEMP_ARGOCD_APP"
rm -f "$TEMP_ARGOCD_APP"

echo "Waiting for ArgoCD controller to process the application (10s)..."
sleep 10

# Step 9: Set up permissions (idempotent by default)
echo "Setting up permissions..."
# Set up permissions for pipeline service account
oc policy add-role-to-user edit system:serviceaccount:${NAMESPACE}:pipeline -n ${NAMESPACE}
oc policy add-role-to-user system:image-builder system:serviceaccount:${NAMESPACE}:pipeline -n ${NAMESPACE}
oc policy add-role-to-user system:image-puller system:serviceaccount:${NAMESPACE}:default -n ${NAMESPACE}

# Step 10: Trigger a pipeline run only if requested
if [ "${TRIGGER_PIPELINE:-no}" = "yes" ]; then
  echo "Triggering pipeline run..."
  TEMP_PIPELINE_RUN=$(mktemp)
  
  # Determine if we should tag as latest
  ADDITIONAL_TAGS=""
  if [ "${IMAGE_TAG_LATEST}" = "yes" ]; then
    ADDITIONAL_TAGS="image-registry.openshift-image-registry.svc:5000/${NAMESPACE}/lamp-app:latest"
  fi
  
  cat << EOF > "$TEMP_PIPELINE_RUN"
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: lamp-pipeline-run-
  namespace: ${NAMESPACE}
spec:
  pipelineRef:
    name: lamp-pipeline
  workspaces:
  - name: shared-workspace
    persistentVolumeClaim:
      claimName: pipeline-workspace-pvc
  params:
  - name: git-url
    value: ${GIT_REPOSITORY_URL}
  - name: git-revision
    value: ${GIT_BRANCH}
  - name: image-name
    value: image-registry.openshift-image-registry.svc:5000/${NAMESPACE}/lamp-app
  - name: image-tag
    value: ${IMAGE_TAG}
  - name: add-latest-tag
    value: "${ADDITIONAL_TAGS}"
  - name: deployment-path
    value: manifests/overlays/${NAMESPACE}/kustomization.yaml
EOF
  oc create -f "$TEMP_PIPELINE_RUN"
  rm -f "$TEMP_PIPELINE_RUN"
else
  echo "Skipping pipeline trigger. Set TRIGGER_PIPELINE=yes to trigger a pipeline run."
fi

# Step 11: Apply the Tekton triggers for automatic pipeline runs
echo "Setting up Tekton triggers..."
TEMP_TRIGGER_TEMPLATE=$(mktemp)

# Determine if we should tag as latest
ADDITIONAL_TAGS=""
if [ "${IMAGE_TAG_LATEST}" = "yes" ]; then
  ADDITIONAL_TAGS="image-registry.openshift-image-registry.svc:5000/${NAMESPACE}/lamp-app:latest"
fi

cat << EOF > "$TEMP_TRIGGER_TEMPLATE"
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerTemplate
metadata:
  name: lamp-trigger-template
  namespace: $NAMESPACE
spec:
  params:
  - name: git-repo-url
    description: The git repository url
  - name: git-revision
    description: The git revision (branch, tag, or commit SHA)
  - name: git-repo-name
    description: The name of the git repository
  - name: branch-name
    description: The name of the branch that was pushed to
  resourcetemplates:
  - apiVersion: tekton.dev/v1beta1
    kind: PipelineRun
    metadata:
      generateName: lamp-pipeline-run-
      namespace: $NAMESPACE
    spec:
      serviceAccountName: pipeline
      pipelineRef:
        name: lamp-pipeline
      workspaces:
      - name: shared-workspace
        persistentVolumeClaim:
          claimName: pipeline-workspace-pvc
      params:
      - name: git-url
        value: \$(tt.params.git-repo-url)
      - name: git-revision
        value: \$(tt.params.git-revision)
      - name: image-name
        value: image-registry.openshift-image-registry.svc:5000/${NAMESPACE}/lamp-app
      - name: image-tag
        value: \$(tt.params.branch-name)
      - name: add-latest-tag
        value: "${ADDITIONAL_TAGS}"
      - name: deployment-path
        value: manifests/overlays/${NAMESPACE}/kustomization.yaml
EOF
oc apply -f "$TEMP_TRIGGER_TEMPLATE"
rm -f "$TEMP_TRIGGER_TEMPLATE"

TEMP_TRIGGER_BINDING=$(mktemp)
cat << EOF > "$TEMP_TRIGGER_BINDING"
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerBinding
metadata:
  name: lamp-git-push-binding
  namespace: $NAMESPACE
spec:
  params:
  - name: git-repo-url
    value: \$(body.repository.url)
  - name: git-revision
    value: \$(body.after)
  - name: git-repo-name
    value: \$(body.repository.name)
EOF
oc apply -f "$TEMP_TRIGGER_BINDING"
rm -f "$TEMP_TRIGGER_BINDING"

TEMP_EVENT_LISTENER=$(mktemp)
cat << EOF > "$TEMP_EVENT_LISTENER"
apiVersion: triggers.tekton.dev/v1beta1
kind: EventListener
metadata:
  name: lamp-git-webhook
  namespace: $NAMESPACE
spec:
  serviceAccountName: pipeline
  triggers:
  - name: git-push-trigger
    bindings:
    - ref: lamp-git-push-binding
    template:
      ref: lamp-trigger-template
    interceptors:
    - name: filter-by-event-type
      ref:
        name: "cel"
      params:
      - name: "filter"
        value: "body.ref.startsWith('refs/heads/${GIT_BRANCH}')"
  resources:
    kubernetesResource:
      spec:
        template:
          spec:
            serviceAccountName: pipeline
            containers:
            - resources:
                limits:
                  memory: 256Mi
                  cpu: 100m
                requests:
                  memory: 128Mi
                  cpu: 50m
EOF
oc apply -f "$TEMP_EVENT_LISTENER"
rm -f "$TEMP_EVENT_LISTENER"

TEMP_WEBHOOK_ROUTE=$(mktemp)
cat << EOF > "$TEMP_WEBHOOK_ROUTE"
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: lamp-webhook-route
  namespace: $NAMESPACE
spec:
  port:
    targetPort: 8080
  to:
    kind: Service
    name: el-lamp-git-webhook
    weight: 100
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
EOF
oc apply -f "$TEMP_WEBHOOK_ROUTE"
rm -f "$TEMP_WEBHOOK_ROUTE"

# Step 12: Print information and verify setup
echo "=== Deployment Completed ==="
echo "Verifying setup..."

# Function to check resource status
check_resource() {
  local resource_type=$1
  local resource_name=$2
  local namespace=$3
  local message=$4
  
  if resource_exists "$resource_type" "$resource_name" "$namespace"; then
    echo "✅ $message"
  else
    echo "❌ $message - Not found!"
  fi
}

# Check key resources
check_resource "pipeline" "lamp-pipeline" "$NAMESPACE" "Tekton Pipeline"
check_resource "task" "argocd-task-sync-and-wait" "$NAMESPACE" "ArgoCD Sync Task"
check_resource "application" "$APP_NAME" "$ARGOCD_NAMESPACE" "ArgoCD Application"
check_resource "pvc" "pipeline-workspace-pvc" "$NAMESPACE" "Pipeline Workspace PVC"

echo ""
echo "Application will be available at:"
APP_ROUTE=$(oc get route lamp-app -n "$NAMESPACE" --template='{{.spec.host}}' 2>/dev/null || echo "<pending>")
echo "  https://${APP_ROUTE}"
echo ""
echo "ArgoCD console is available at:"
ARGOCD_ROUTE=$(oc get route openshift-gitops-server -n "$ARGOCD_NAMESPACE" --template='{{.spec.host}}' 2>/dev/null || echo "<pending>")
echo "  https://${ARGOCD_ROUTE}"
echo ""
echo "Webhook URL for Git repository:"
WEBHOOK_ROUTE=$(oc get route lamp-webhook-route -n "$NAMESPACE" --template='{{.spec.host}}' 2>/dev/null || echo "<pending>")
echo "  https://${WEBHOOK_ROUTE}"