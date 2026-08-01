# ~/.zshrc
# macOS defaults to zsh. We reuse the same shared helpers as bash so the
# terminal behaves identically across the Mac, the multipass VM, and WSL.

# --- powerlevel10k instant prompt -------------------------------------------
# Must stay near the top of ~/.zshrc. Anything that prints to the console before
# this line (or before oh-my-zsh loads) will disable instant prompt.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- oh-my-zsh --------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# DevOps stack: kube/helm/flux/terraform/azure completions + aliases.
# NOTE: zsh-syntax-highlighting must remain the LAST entry in this list.
plugins=(
  git
  kubectl
  kubectx
  helm
  docker
  docker-compose
  terraform
  azure
  fluxcd
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# This file is shared with the multipass VM and WSL, where oh-my-zsh may not be
# installed. Guard the load so those hosts still get a working shell: oh-my-zsh
# runs compinit itself, so only run it ourselves in the fallback path.
if [ -r "$ZSH/oh-my-zsh.sh" ]; then
    source "$ZSH/oh-my-zsh.sh"
else
    autoload -Uz compinit && compinit
    PS1='%n@%m:%~$ '
fi

# --- user environment and shared helpers (POSIX-clean, safe under zsh) ------
# Sourced after oh-my-zsh so completion (compinit) is already initialised;
# e.g. profile.d/kubernetes.sh calls `kubectl completion zsh`.
[ -f "$HOME/.bash_exports" ]   && source "$HOME/.bash_exports"
[ -f "$HOME/.bash_aliases" ]   && source "$HOME/.bash_aliases"
[ -f "$HOME/.bash_functions" ] && source "$HOME/.bash_functions"

# load shared shell helpers (kubernetes/docker/helm/tools)
for f in "$HOME/.dotfiles/profile.d/"*.sh; do
    [ -r "$f" ] && source "$f"
done

# --- history ----------------------------------------------------------------
setopt append_history share_history hist_ignore_all_dups
HISTSIZE=10000
SAVEHIST=20000
HISTFILE="$HOME/.zsh_history"

# --- powerlevel10k prompt config --------------------------------------------
# To reconfigure the look/segments interactively, run: p10k configure
[[ ! -f "$HOME/.p10k.zsh" ]] || source "$HOME/.p10k.zsh"
