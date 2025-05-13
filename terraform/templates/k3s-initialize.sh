#!/bin/bash
# Info: Run this script as root

# Variables
K3S_IP=10.1.1.100
K3S_PORT=6443
GITOPS_REPO_URL="https://github.com/Vngdv/infra.git"
GITOPS_REPO_PATH="cluster"

### Script starts here ###

# Set Kubeconfig & alias kubectl
export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
alias kubectl="k3s kubectl"


# Setup Cilium
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.17.3 \
   --namespace kube-system \
   --set operator.replicas=2 \
   --set k8sServiceHost=$K3S_IP \
   --set k8sServicePort=$K3S_PORT \
   --set kubeProxyReplacement=true


# Setup ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Login to ArgoCD
ARGOCD_POD_NAME=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath="{.items[0].metadata.name}")
ARGOCD_ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo)
kubectl exec $ARGOCD_POD_NAME -n argocd \
    -- argocd login localhost:8080 \
    --insecure --username admin --password $ARGOCD_ADMIN_PASSWORD


kubectl exec $ARGOCD_POD_NAME  -n argocd \
    -- argocd app create apps \
    --repo $GITOPS_REPO_URL \
    --dest-namespace argocd \
    --path $GITOPS_REPO_PATH \
    --dest-server https://kubernetes.default.svc \
    --sync-policy automated

unset ARGOCD_POD_NAME
unset ARGOCD_ADMIN_PASSWORD