#!/bin/bash

RELEASE_NAME="argo"
NAMESPACE="admin"
ARGO_VALUES="argo-cd/values.yaml"
REPO_FILE="argo-cd/repo.yaml"
APP_OF_APPS_FILE="argo-cd/app-of-apps.yaml"

kubectl create namespace $NAMESPACE

helm install $RELEASE_NAME oci://registry-1.docker.io/bitnamicharts/argo-cd \
  -n $NAMESPACE \
  -f $ARGO_VALUES

kubectl rollout status deployment/${RELEASE_NAME}-argo-cd-server -n $NAMESPACE

PASSWORD=$(kubectl get secret argocd-secret -n $NAMESPACE -o jsonpath="{.data['clearPassword']}" | base64 --decode)

if [ -z "$PASSWORD" ]; then
  echo "Failed to retrieve the password. Please check if the installation completed successfully."
else
  echo "Admin password: $PASSWORD"
fi

echo "Applying $REPO_FILE to add the repository..."
kubectl apply -f $REPO_FILE -n $NAMESPACE

echo "Applying $APP_OF_APPS_FILE to add the repository..."
kubectl apply -f $APP_OF_APPS_FILE -n $NAMESPACE

echo "Setting up port forwarding (localhost:8080 -> service:80)..."
kubectl port-forward svc/${RELEASE_NAME}-argo-cd-server 8080:80 -n $NAMESPACE &
FORWARD_PID=$!

echo "Port forwarding is active. You can access the Argo CD UI at http://localhost:8080"
echo "Press Ctrl+C to stop port forwarding."

# Wait for the user to terminate the script
wait $FORWARD_PID