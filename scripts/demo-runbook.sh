#!/usr/bin/env bash
# Interactive demo script — run each section separately when presenting.

set -uo pipefail

banner() { echo; echo "============================================================"; echo "$1"; echo "============================================================"; }

banner "DEMO 1: ReplicaSet self-healing (delete a pod)"
kubectl get pods -n demo
POD=$(kubectl get pods -n demo -l app=demo-app -o jsonpath='{.items[0].metadata.name}')
echo "Deleting pod: ${POD}"
kubectl delete pod "${POD}" -n demo
echo "Watching recovery for 20 seconds..."
kubectl get pods -n demo -w &
WATCH_PID=$!
sleep 20
kill "${WATCH_PID}" 2>/dev/null || true

banner "DEMO 2: Liveness probe recovery (crash the process)"
POD=$(kubectl get pods -n demo -l app=demo-app -o jsonpath='{.items[0].metadata.name}')
echo "Hitting /crash on pod: ${POD}"
kubectl exec -n demo "${POD}" -- \
  python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/crash')" || true

echo "Watching RESTARTS counter for 60 seconds..."
kubectl get pods -n demo -w &
WATCH_PID=$!
sleep 60
kill "${WATCH_PID}" 2>/dev/null || true

banner "DEMO 3: HPA scale-up under load"
kubectl get hpa -n demo
echo "Starting stress pod..."
kubectl apply -f k8s/stress-pod.yaml
echo "Watching HPA for 3 minutes..."
kubectl get hpa -n demo -w &
WATCH_PID=$!
sleep 180
kill "${WATCH_PID}" 2>/dev/null || true

banner "DEMO 4: HPA scale-down after load stops"
kubectl delete pod cpu-stressor -n demo --ignore-not-found
echo "Watching HPA for 3 minutes as load subsides..."
kubectl get hpa -n demo -w &
WATCH_PID=$!
sleep 180
kill "${WATCH_PID}" 2>/dev/null || true

banner "DEMO COMPLETE"
kubectl get pods -n demo
kubectl get hpa -n demo
