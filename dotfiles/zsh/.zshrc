# ~/.zshrc

# Historico
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY INC_APPEND_HISTORY

# Completions
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Prompt + ferramentas
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
source <(fzf --zsh)

# Node via fnm (troca automatica ao entrar em pastas com .nvmrc/.node-version)
eval "$(fnm env --use-on-cd)"

# Python via pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# Aliases
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --git'
alias la='eza -a --icons'
alias lt='eza --tree --icons --level=2'
alias cat='bat'
alias lg='lazygit'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias update='paru -Syu'
