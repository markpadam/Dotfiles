#!/usr/bin/env bash

# Kubernetes helpers
if [ -f "$HOME/.kube/config" ]; then
    export KUBECONFIG="$HOME/.kube/config"
fi

alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kdn='kubectl describe node'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'
