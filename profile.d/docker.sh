#!/usr/bin/env bash

# Docker helper aliases and environment variables.
export DOCKER_CLI_EXPERIMENTAL=enabled

alias d='docker'
alias dps='docker ps'
alias dpa='docker ps -a'
alias dim='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dbuild='docker build . -t'

if command -v docker-compose >/dev/null 2>&1; then
    alias dc='docker-compose'
fi
