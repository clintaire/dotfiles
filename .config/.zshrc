# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Performance optimization
skip_global_compinit=1

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# Disabled because we're using starship
ZSH_THEME=""

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  command-not-found
  sudo
)

source $ZSH/oh-my-zsh.sh

# User configuration

# ================================
# Plugin configurations
# ================================

# zsh-autosuggestions settings
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# Performance: faster completion loading
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# ================================
# Custom configuration to match bash/starship setup
# ================================

# File system aliases (using eza like in bash)
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias cd="zd"
zd() {
  if [ $# -eq 0 ]; then
    builtin cd ~ && return
  elif [ -d "$1" ]; then
    builtin cd "$1"
  else
    z "$@" && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
  fi
}
open() {
  xdg-open "$@" >/dev/null 2>&1 &
}

# Quick navigation
# alias mdd='cd /home/$USER/Documents/'
# alias dvv='cd /home/$USER/Documents/'
# alias txx='cd /home/$USER/Documents/'
alias dtt='cd /home/$USER/Work/dotfiles/'

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# File search and grep
alias ff='find . -type f -name' fd='find . -type d -name'
alias grep='grep --color=auto' egrep='egrep --color=auto' fgrep='fgrep --color=auto'

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

alias gh='ghsearch' so='sosearch' mdn='mdnsearch' npm='npmsearch' pypi='pypisearch'

# Lazy load nvm
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    export NVM_DIR="$HOME/.nvm"
    nvm() { unset -f nvm; [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"; nvm "$@"; }
fi

# Auto-suggestions configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Tools
alias d='docker'
alias r='rails'
n() { if [ "$#" -eq 0 ]; then nvim .; else nvim "$@"; fi; }

# Git
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

# Initialize modern shell tools
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

if command -v fzf &> /dev/null; then
  if [[ -f /usr/share/fzf/completion.zsh ]]; then
    source /usr/share/fzf/completion.zsh
  fi
  if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
    source /usr/share/fzf/key-bindings.zsh
  fi
fi

export PATH=~/.npm-global/bin:$PATH
export PATH=/usr/local/texlive/2025/bin/x86_64-linux:$PATH

export GPG_TTY=$(tty)
