_venvy_completion_debug () {
  if [[ $VENVY_COMPLETION_DEBUG_LOG ]]; then
    mkdir -p $VENVY_CACHE_DIR
    echo $1 >> $VENVY_CACHE_DIR/completion_debug.txt
  fi
}

_venvy_completion () {
  local index=$(($CURRENT - 1))
  local current_word=${words[index]}

  _venvy_completion_debug "index: $index"
  _venvy_completion_debug "current_word: $current_word"

  if [[ $index == 1 ]]; then
    compadd -- $(venvy -h | awk '/^[[:space:]]+venvy/ {print $2}')
    return 0
  fi 

  case $current_word in
    use | edit | rm | clean | setexec)
      _venvy_completion_debug "in handler for use | edit | rm | clean | setexec"
      compadd -- $(find $VENVY_CONFIG_DIR/ -type d -mindepth 1 -maxdepth 1 -exec basename {} \;)
      ;;
    *) 
      _venvy_completion_debug "no match"
      ;;
  esac
}

_venvy_completion_wrapper () {
  _venvy_completion_debug "--- Start completion ---"
  _venvy_completion
  _venvy_completion_debug "--- End completion ---"
}

compdef _venvy_completion_wrapper venvy
