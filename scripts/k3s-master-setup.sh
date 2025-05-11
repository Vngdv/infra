#!/bin/bash

## Set auto K3S config
sudo chmod 600 /etc/rancher/k3s/k3s.yaml
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> $HOME/.bashrc
source $HOME/.bashrc