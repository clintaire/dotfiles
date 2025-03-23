#
# ▓ ▓ ▓ ▓ ▓▓▓▓ ▓ ▓
#     ▓ ▓ zshrc ▓ ▓ ▓ ▓
#

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set the theme for Zsh (Powerlevel10k).
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins for Oh My Zsh.
plugins=(
    git
    npm
    node
    pip
    zsh-syntax-highlighting
    zsh-autosuggestions
)

# Source Oh My Zsh.
source $ZSH/oh-my-zsh.sh

# User configuration
export LANG=en_US.UTF-8
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# CUDA
export PATH=/opt/cuda/bin:$PATH
export LD_LIBRARY_PATH=/opt/cuda/lib64:$LD_LIBRARY_PATH

# Set GPG_TTY for GPG key management.
export GPG_TTY=$(tty)

# SSH Agent setup
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval $(ssh-agent -s) &>/dev/null
  ssh-add ~/.ssh/id_ed25519 &>/dev/null
fi

# Uncomment to enable Powerlevel10k prompt customization.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Editor
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# alias zshconfig="nvim ~/.zshrc"
# alias ohmyzsh="nvim ~/.oh-my-zsh"

# Npm Global
export PATH=~/.npm-global/bin:$PATH
