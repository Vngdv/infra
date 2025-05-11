#!/bin/bash

# Set variable for k3s ip
K3S_IP=10.1.1.100
K3S_PORT=6443

# Setup Cilium
helm repo add cilium https://helm.cilium.io/

# TODO update Service host with variable or smt
helm install cilium cilium/cilium --version 1.17.3 \
   --namespace kube-system \
   --set operator.replicas=2 \
   --set k8sServiceHost=$K3S_IP \
   --set k8sServicePort=$K3S_PORT \
   --set kubeProxyReplacement=true

