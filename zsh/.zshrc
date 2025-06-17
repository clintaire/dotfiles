# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Uncomment for case-sensitive or hyphen-insensitive completion
# CASE_SENSITIVE="true"
# HYPHEN_INSENSITIVE="true"

# Auto-update behavior
# zstyle ':omz:update' mode disabled
# zstyle ':omz:update' mode auto
# zstyle ':omz:update' mode reminder
# zstyle ':omz:update' frequency 13

# Terminal behavior
# DISABLE_MAGIC_FUNCTIONS="true"
# DISABLE_LS_COLORS="true"
# DISABLE_AUTO_TITLE="true"
# ENABLE_CORRECTION="true"
# COMPLETION_WAITING_DOTS="true"
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# History timestamp format
# HIST_STAMPS="mm/dd/yyyy"

# Custom folder for Oh My Zsh
# ZSH_CUSTOM=/path/to/new-custom-folder

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Powerlevel10k instant prompt configuration
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# Conda initialization
__conda_setup="$('/home/focus/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/focus/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/focus/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/focus/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup

# PATH additions
export PATH="/usr/local/share/npm/bin:$HOME/.cargo/bin:$PATH"

# nvm initialization (cleaned up)
export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.nvm}"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Homebrew environment
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"


# if [[ -t 1 ]] && command -v tmux &>/dev/null && [ -z "$TMUX" ]; then
#  jap_nums=(一 二 三 四 五 六 七 八 九 十 十一 十二 十三 十四 十五 十六 十七 十八 十九 二十)
#  SESSION_NAME="term-${jap_nums[$((RANDOM % 20))]}"
#  tmux attach-session -t "$SESSION_NAME" 2>/dev/null || tmux new-session -s "$SESSION_NAME"
# fi

autoload -Uz add-zsh-hook

tmux_autostart() {
  if [[ -o interactive && -z "$TMUX" && -n "$PS1" ]]; then
    if command -v tmux &>/dev/null; then
      jap_nums=(一 二 三 四 五 六 七 八 九 十 十一 十二 十三 十四 十五 十六 十七 十八 十九 二十)
      SESSION_NAME="term-${jap_nums[$((RANDOM % 20))]}"
      tmux has-session -t "$SESSION_NAME" 2>/dev/null \
        && tmux attach-session -t "$SESSION_NAME" \
        || tmux new-session -s "$SESSION_NAME"
    fi
  fi
}

add-zsh-hook -Uz precmd tmux_autostart
#

# Powerlevel10k config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# mise (toolchain manager)
eval "$(/home/focus/.local/bin/mise activate zsh)"

# Aliases (consider moving to $ZSH_CUSTOM/aliases.zsh)
# alias zshconfig="nvim ~/.zshrc"
# alias ohmyzsh="nvim ~/.oh-my-zsh"

