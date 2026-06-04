#!/usr/bin/env bash

# Kubernetes helpers — tuned for daily use and CKA/CKS exam speed.
if [ -f "$HOME/.kube/config" ]; then
    export KUBECONFIG="$HOME/.kube/config"
fi

alias k='kubectl'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods -A'
alias kgpw='kubectl get pods -o wide'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kdn='kubectl describe node'
alias kdp='kubectl describe pod'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'
alias kn='kubectl config set-context --current --namespace'
alias kctx='kubectl config use-context'

# Exam time-savers: append to imperative commands.
#   k run nginx --image=nginx $do      -> prints manifest instead of creating
#   k delete pod nginx $now            -> instant delete, no grace period
export do='--dry-run=client -o yaml'
export now='--force --grace-period=0'

# Shell completion (and make the `k` alias complete like kubectl).
if command -v kubectl >/dev/null 2>&1; then
    if [ -n "${ZSH_VERSION:-}" ]; then
        source <(kubectl completion zsh)
        compdef k=kubectl 2>/dev/null || true
    elif [ -n "${BASH_VERSION:-}" ]; then
        source <(kubectl completion bash)
        complete -o default -F __start_kubectl k
    fi
fi
