#!/usr/bin/env bash
set -euo pipefail

echo "Installing metrics-server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# kind/minikube use self-signed kubelet certs — metrics-server needs this flag
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

echo "Waiting for metrics-server to be ready..."
kubectl rollout status deployment/metrics-server -n kube-system --timeout=120s

sleep 20
echo "Node metrics:"
kubectl top nodes || true
echo "Pod metrics:"
kubectl top pods -n demo || true
