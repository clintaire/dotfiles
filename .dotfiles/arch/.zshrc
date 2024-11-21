# Prevent recursion by checking if the variable is already set
if [[ -z "$ZSHRC_LOADED" ]]; then
  export ZSHRC_LOADED=1  # Mark the file as loaded

  # Check if running on Mac or Arch
  if [[ "$(uname)" == "Darwin" ]]; then
    source ~/.dotfiles/mac/.zshrc  # Use Mac-specific settings
  elif [[ "$(uname)" == "Linux" ]]; then
    source ~/.dotfiles/arch/.zshrc  # Use Arch-specific settings
  fi

  # Other common setup
  HISTFILE=~/.histfile
  HISTSIZE=5000
  SAVEHIST=1000
  bindkey -e

  # Init other things, without recursion
  eval "$(oh-my-posh --init --shell zsh --config ~/.poshthemes/peru.omp.json)"

  # If needed, enable or disable plugins below
  # source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
  # source /home/ciao/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

