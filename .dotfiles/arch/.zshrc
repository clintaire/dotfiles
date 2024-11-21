# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=5000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/ciao/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

# Oh My Posh
eval "$(oh-my-posh --init --shell zsh --config ~/.poshthemes/peru.omp.json)"

# Autosuggestions
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# Syntax Highlighting
echo "source ${(q-)PWD}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc
source /home/ciao/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /home/ciao/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /home/ciao/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /home/ciao/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /home/ciao/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /home/ciao/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
