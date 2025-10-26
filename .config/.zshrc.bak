# Enhanced .zshrc for Professional Development

# GPG configuration
export GPG_TTY=$(tty)

# Performance optimization
skip_global_compinit=1

# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# Faster completion
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS HIST_SAVE_NO_DUPS HIST_REDUCE_BLANKS
setopt HIST_VERIFY INC_APPEND_HISTORY SHARE_HISTORY

# Plugins (minimal for speed)
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    extract
    jsontools
    history-substring-search
    colored-man-pages
)

source $ZSH/oh-my-zsh.sh

# Environment variables
export EDITOR='code' VISUAL='code' PAGER='less' LANG=en_US.UTF-8
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Quick navigation
alias ..='cd ..' ...='cd ../..' ....='cd ../../..' ~='cd ~' -- -='cd -'
alias qf='cd /home/cli/Documents/Portfolio/clintaire/projects/blogs/quickfix'
alias cap='cd /home/cli/Documents/Portfolio/clintaire/projects'
alias ca='cd /home/cli/Documents/Portfolio/clintaire/'
alias dot='cd /home/cli/git/dotfiles'

# NvChad aliases (Mousepad-style editor)
alias nv='nvim'
alias edit='nvim'
alias e='nvim'

# Quick execution and testing
alias run='python'
alias py='python'
alias js='node'
alias go='go run'
alias rs='cargo run'
alias test='npm test'
alias serve='python -m http.server'
alias pytest='python -m pytest'
alias jupyter='jupyter notebook'
alias lab='jupyter lab'
alias cl='clear'

# Enhanced ls
alias ll='ls -alF' la='ls -A' l='ls -CF' ls='ls --color=auto' lt='ls -ltr' lh='ls -lh'

# Git aliases
alias g='git' ga='git add' gaa='git add --all' gb='git branch' gba='git branch -a'
alias gbd='git branch -d' gc='git commit -v' gcm='git commit -m' gco='git checkout'
alias gcb='git checkout -b' gd='git diff' gdc='git diff --cached' gl='git pull'
alias gp='git push' gst='git status' gss='git status -s' gsta='git stash' gstp='git stash pop'
alias glog='git log --oneline --decorate --graph' gloga='git log --oneline --decorate --graph --all'

# Directory and file operations
alias md='mkdir -p' rd='rmdir' tree='tree -C'
alias rm='rm -i' cp='cp -i' mv='mv -i'

# System
alias ps='ps auxf' top='htop' myps='ps -f -u $USER'
alias ping='ping -c 5' ports='netstat -tulanp' myip='curl -s ipinfo.io/ip'
alias df='df -h' du='du -h' free='free -h' path='echo -e ${PATH//:/\\n}'

# Development
alias c='code .' reload='source ~/.zshrc' zshconfig='code ~/.zshrc'
alias py='python3' pip='pip3' venv='python3 -m venv' activate='source venv/bin/activate'

# Node.js
alias ni='npm install' nid='npm install --save-dev' nig='npm install -g'
alias nis='npm install --save' nr='npm run' ns='npm start' nt='npm test'
alias nb='npm run build' nf='npm run format' nl='npm run lint'

# File search and grep
alias ff='find . -type f -name' fd='find . -type d -name'
alias grep='grep --color=auto' egrep='egrep --color=auto' fgrep='fgrep --color=auto'

# Docker (conditional)
if command -v docker &> /dev/null; then
    alias dk='docker' dc='docker-compose' dps='docker ps' dpa='docker ps -a'
    alias di='docker images' drm='docker rm' drmi='docker rmi' dstop='docker stop $(docker ps -q)'
fi

# Kubernetes (conditional)
if command -v kubectl &> /dev/null; then
    alias kub='kubectl' kg='kubectl get' kd='kubectl describe' ka='kubectl apply' kubd='kubectl delete'
fi

# Functions
mkcd() { mkdir -p "$1" && cd "$1"; }

extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

gitignore() { curl -sL "https://www.gitignore.io/api/$1"; }
killp() { ps aux | grep "$1" | grep -v grep | awk '{print $2}' | xargs kill -9; }

# Web search functions
unalias ddg google 2>/dev/null

duckduckgo() {
    [[ $# -eq 0 ]] && { echo "Usage: duckduckgo <search terms>"; return 1; }
    xdg-open "https://duckduckgo.com/?q=$(echo "$*" | sed 's/ /+/g')" 2>/dev/null &
}

googlesearch() {
    [[ $# -eq 0 ]] && { echo "Usage: googlesearch <search terms>"; return 1; }
    xdg-open "https://www.google.com/search?q=$(echo "$*" | sed 's/ /+/g')" 2>/dev/null &
}

ghsearch() {
    [[ $# -eq 0 ]] && { echo "Usage: ghsearch <search terms>"; return 1; }
    xdg-open "https://github.com/search?q=$(echo "$*" | sed 's/ /+/g')" 2>/dev/null &
}

sosearch() {
    [[ $# -eq 0 ]] && { echo "Usage: sosearch <search terms>"; return 1; }
    xdg-open "https://stackoverflow.com/search?q=$(echo "$*" | sed 's/ /+/g')" 2>/dev/null &
}

mdnsearch() {
    [[ $# -eq 0 ]] && { echo "Usage: mdnsearch <search terms>"; return 1; }
    xdg-open "https://developer.mozilla.org/en-US/search?q=$(echo "$*" | sed 's/ /+/g')" 2>/dev/null &
}

npmsearch() {
    [[ $# -eq 0 ]] && { echo "Usage: npmsearch <package name>"; return 1; }
    xdg-open "https://www.npmjs.com/search?q=$(echo "$*" | sed 's/ /+/g')" 2>/dev/null &
}

pypisearch() {
    [[ $# -eq 0 ]] && { echo "Usage: pypisearch <package name>"; return 1; }
    xdg-open "https://pypi.org/search/?q=$(echo "$*" | sed 's/ /+/g')" 2>/dev/null &
}

# Search aliases
alias ddg='duckduckgo' google='googlesearch' websearch='duckduckgo' search='duckduckgo'

# Auto-suggestions configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Load external tools (conditional)
[[ -f /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
command -v direnv &> /dev/null && eval "$(direnv hook zsh)"
command -v pyenv &> /dev/null && eval "$(pyenv init -)"

# Lazy load nvm
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    export NVM_DIR="$HOME/.nvm"
    nvm() { unset -f nvm; [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"; nvm "$@"; }
fi

# Keybindings
bindkey '^R' history-incremental-search-backward '^S' history-incremental-search-forward
bindkey '^P' history-search-backward '^N' history-search-forward
bindkey '^[[1;5C' forward-word '^[[1;5D' backward-word
bindkey '^A' beginning-of-line '^E' end-of-line '^K' kill-line '^U' kill-whole-line

alias dockermgr="~/automations/docker-manager.sh"
alias dockerpro="~/automations/docker-project-manager.sh"
export PATH=~/.npm-global/bin:$PATH
# export QT_STYLE_OVERRIDE=Adwaita-Dark
export QT_QPA_PLATFORMTHEME=qt5ct

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/cli/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/cli/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/cli/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/cli/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PATH="$HOME/.local/bin:$PATH"

# export _JAVA_OPTIONS="-Dswt.autoScale=200"
# export GDK_SCALE=2
# export _JAVA_OPTIONS="-Dawt.toolkit.name=WLToolkit"
export PATH="$HOME/.config/emacs/bin:$PATH"
