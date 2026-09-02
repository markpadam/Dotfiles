# ~/.zshrc
# macOS defaults to zsh. We reuse the same shared helpers as bash so the
# terminal behaves identically across the Mac, the multipass VM, and WSL.

# --- oh-my-zsh --------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
# The prompt comes from Starship (see the Omachy-managed block at the end of
# this file), so oh-my-zsh loads no theme of its own. Leaving this empty also
# means nothing here prints to the console before oh-my-zsh, which is why the
# old powerlevel10k instant-prompt preamble is gone.
ZSH_THEME=""

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

# --- mise (Node/Python/Go/Rust toolchain manager) ----------------------------
command -v mise >/dev/null && eval "$(mise activate zsh)"

# --- history ----------------------------------------------------------------
setopt append_history share_history hist_ignore_all_dups
HISTSIZE=10000
SAVEHIST=20000
HISTFILE="$HOME/.zsh_history"

# ── Omachy managed (do not edit between these markers) ──
# zsh-syntax-highlighting and zsh-autosuggestions are already loaded by the
# oh-my-zsh plugin list above, so they are not re-sourced here.
eval "$(starship init zsh)"
eval "$(fzf --zsh)"
eval "$(atuin init zsh)"
eval "$(zoxide init zsh --cmd cd)"
set -o vi
# modern CLI replacements: eza→ls, bat→cat, zoxide→cd (above)
alias ls='eza --group-directories-first --icons=auto'
alias ll='eza -la --git --group-directories-first --icons=auto'
alias la='eza -a --group-directories-first --icons=auto'
alias lt='eza --tree --level=2 --group-directories-first --icons=auto'
alias cat='bat --paging=never'
fastfetch
dev() { sh ~/.config/omachy/dev-session.sh "$@"; }
# ── End Omachy managed ──
