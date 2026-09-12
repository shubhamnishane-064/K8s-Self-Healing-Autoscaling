#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-demo-cluster}"

# Create cluster if it doesn't exist
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "Creating kind cluster '${CLUSTER_NAME}'..."
  kind create cluster --name "${CLUSTER_NAME}"
else
  echo "Cluster '${CLUSTER_NAME}' already exists."
fi

echo "Building demo-app:v1..."
docker build -t demo-app:v1 ./app

echo "Loading image into kind..."
kind load docker-image demo-app:v1 --name "${CLUSTER_NAME}"

echo "Applying manifests..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/

echo "Waiting for rollout..."
kubectl rollout status deployment/demo-app -n demo --timeout=120s
kubectl get pods -n demo
