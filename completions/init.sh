if [[ $ZSH_VERSION ]]; then
  source $VENVY_SRC_DIR/completions/zsh_completion.sh
elif [[ $BASH_VERSION ]]; then
  source $VENVY_SRC_DIR/completions/bash_completion.sh
fi
