_venvy_completion_debug() {
  if [[ $VENVY_COMPLETION_DEBUG_LOG ]]; then
    mkdir -p $VENVY_CACHE_DIR
    echo $1 >> $VENVY_CACHE_DIR/completion_debug.txt
  fi
}

_venvy_completion() {
  local index=$(($COMP_CWORD))
  local prev_prev_word=${COMP_WORDS[$(($index - 2))]}
  local prev_word=${COMP_WORDS[$(($index - 1))]}
  local current_word=${COMP_WORDS[$index]}

  _venvy_completion_debug "COMP_WORDS: ${COMP_WORDS[*]}"
  _venvy_completion_debug "index: $index"
  _venvy_completion_debug "prev_prev_word: $prev_word"
  _venvy_completion_debug "prev_word: $prev_word"
  _venvy_completion_debug "current_word: $current_word"

  if [[ $index == 1 ]]; then
    COMPREPLY=($(compgen -W "$(venvy -h | awk '/^[[:space:]]+venvy/ {print $2}')" -- $current_word))
    return 0
  fi

  case $prev_word in
    use | edit | rm | clean | setexec | mv)
      _venvy_completion_debug "in prev_word handler for use | edit | rm | clean | setexec | mv"
      COMPREPLY=($(compgen -W "$(find $VENVY_CONFIG_DIR/ -type d -mindepth 1 -maxdepth 1 -exec basename {} \;)" -- $current_word))
      ;;
    *)
      _venvy_completion_debug "no match in prev_word handler"
      ;;
  esac

  case $prev_prev_word in
    use | edit | rm | clean | setexec | mv)
      _venvy_completion_debug "in prev_prev_word handler for mv"
      COMPREPLY=($(compgen -W "$(find $VENVY_CONFIG_DIR/ -type d -mindepth 1 -maxdepth 1 -exec basename {} \;)" -- $current_word))
      ;;
    *)
      _venvy_completion_debug "no match in prev_prev_word handler"
      ;;
  esac
}

_venvy_completion_wrapper() {
  _venvy_completion_debug "--- Start completion ---"
  _venvy_completion
  _venvy_completion_debug "--- End completion ---"
}

complete -F _venvy_completion_wrapper venvy
