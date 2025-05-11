#!/bin/bash
K3S_TOKEN=${cluster_token} 
{% if first_master == false }
K3S_URL=https://${api_server_ip}:${api_server_port} 
{% else %}

echo "Installing K3s"
curl -sfL https://get.k3s.io | sh -s - server \
    --flannel-backend=none \
    --disable-kube-proxy \
    --disable servicelb \
    --disable-network-policy \
    --disable traefik \
    --cluster-init \
    --secrets-encryption 


{ % if first_master == true }
echo "Installing Helm & Cilium"
export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"

sudo dnf install helm

echo "Installing Cilium"
helm repo add cilium https://helm.cilium.io/
helm repo update

# helm install cilium cilium/cilium
helm install cilium cilium/cilium \
    --namespace kube-system \
    --set k8sServiceHost=${api_server_ip} \
    --set k8sServicePort=${api_server_port}\
    --set operator.replicas=3 \
    --set operator.prometheus.enabled=true \
    --set operator.prometheus.serviceMonitor.enabled=true \
    --set operator.prometheus.serviceMonitor.interval=30s \
    --set operator.prometheus.serviceMonitor.honorLabels=true
{% endif }