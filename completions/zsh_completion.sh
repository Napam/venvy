_venvy_completion_debug() {
  if [[ $VENVY_COMPLETION_DEBUG_LOG ]]; then
    mkdir -p $VENVY_CACHE_DIR
    echo $1 >> $VENVY_CACHE_DIR/completion_debug.txt
  fi
}

_venvy_completion() {
  local index=$(($CURRENT - 1))
  local prev_word=${words[index - 1]}
  local current_word=${words[index]}

  _venvy_completion_debug "index: $index"
  _venvy_completion_debug "prev_word: $prev_word"
  _venvy_completion_debug "current_word: $current_word"

  if [[ $index == 1 ]]; then
    compadd -- $(venvy -h | awk '/^[[:space:]]+venvy/ {print $2}')
    return 0
  fi

  case $current_word in
    use | edit | rm | clean | setexec | mv)
      _venvy_completion_debug "in current_word handler for use | edit | rm | clean | setexec | mv"
      compadd -- $(find $VENVY_CONFIG_DIR/ -type d -mindepth 1 -maxdepth 1 -exec basename {} \;)
      ;;
    *)
      _venvy_completion_debug "no match for current word"
      ;;
  esac

  case $prev_word in
    mv)
      _venvy_completion_debug "in prev_word handler mv"
      compadd -- $(find $VENVY_CONFIG_DIR/ -type d -mindepth 1 -maxdepth 1 -exec basename {} \;)
      ;;
    *)
      _venvy_completion_debug "no match for prev word"
      ;;
  esac
}

_venvy_completion_wrapper() {
  _venvy_completion_debug "--- Start completion ---"
  _venvy_completion
  _venvy_completion_debug "--- End completion ---"
}

compdef _venvy_completion_wrapper venvy
