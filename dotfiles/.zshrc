# ~/.zshrc
# macOS defaults to zsh. We reuse the same shared helpers as bash so the
# terminal behaves identically across the Mac, the multipass VM, and WSL.

# load user environment and helpers (POSIX-clean, safe under zsh)
[ -f "$HOME/.bash_exports" ]   && source "$HOME/.bash_exports"
[ -f "$HOME/.bash_aliases" ]   && source "$HOME/.bash_aliases"
[ -f "$HOME/.bash_functions" ] && source "$HOME/.bash_functions"

# zsh completion system — required before kubectl/helm completion in profile.d
autoload -Uz compinit && compinit

# load shared shell helpers (kubernetes/docker/helm/tools)
for f in "$HOME/.dotfiles/profile.d/"*.sh; do
    [ -r "$f" ] && source "$f"
done

# interactive prompt + history
export PS1='%n@%m:%~$ '
setopt append_history share_history hist_ignore_all_dups
HISTSIZE=10000
SAVEHIST=20000
HISTFILE="$HOME/.zsh_history"
