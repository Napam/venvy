#!/usr/bin/env bash

export VENVY_CONFIG_DIR=$HOME/.config/venvy
export VENVY_SRC_DIR=$HOME/.local/src/venvy

_venvy_usage () {
   local self='venvy'

    cat <<EOF
Usage:
  $self add <name> [executable]  Create, build and activate venv configuration. Optionally specify python executable.
  $self use <name>               Activate venv
  $self clean <name>             Clean venv cache, venv will be rebuilt on next usage
  $self edit <name>              Edit requirements.txt for a venv
  $self rm <name>                Remove venv
  $self ls                       List configured venvs
  $self {help, --help, -h}       Show this text
EOF
}

_venvy_ls () {
  find $VENVY_CONFIG_DIR -mindepth 1 -maxdepth 1 -type d -not -name '.*' -exec basename {} \; | sort
}

_venvy_could_not_find_venv () {
  echo "Could not find the venv called '$1'. The available ones are:"
  _venvy_ls
}

_venvy_add () {
  local venv_dir=$VENVY_CONFIG_DIR/$1
  local executable=$2

  if [[ -d $venv_dir ]]; then
    echo "A venv called '$1' already exists. Run 'venvy use $1' to activate it."
    return 1;
  fi

  if command -v python >/dev/null; then
    local executable=python
  fi

  if command -v python3 >/dev/null; then
    local executable=python3
  fi

  if [[ ! $executable ]]; then
    echo "Could not infer a python executable. If you have a non-standard Python installation, please explicitly specify the path to the executable"
    return 1;
  fi

  if ! command -v $executable >/dev/null; then
    echo "Could find the Python executable '$executable', please specify a valid executable"
    return 1;
  fi

  cp -r $VENVY_SRC_DIR/templates/venv $VENVY_CONFIG_DIR/$1

  # This is basically gnu sed -i, but it also works on MacOS
  perl -i -pe "s/{executable}/$executable/g" $VENVY_CONFIG_DIR/$1/create.sh

  echo "Created venv '$1'"

  _venvy_use $1
}

_venvy_use () {
  local venv_dir=$VENVY_CONFIG_DIR/$1
  if [[ ! -e $venv_dir ]]; then
    _venvy_could_not_find_venv $venv_dir
    return 1;
  fi

  local activate=$venv_dir/venv/bin/activate

  if [[ ! -f $activate ]]; then
    local venv_create
    bash $venv_dir/create.sh
  fi

  source $activate
}

_venvy_clean () {
  local venv_dir=$VENVY_CONFIG_DIR/$1
  if [[ ! -e $venv_dir ]]; then
    _venvy_could_not_find_venv $venv_dir
    return 1;
  fi

  # If currenty using the venv that is to be cleaned, deactivate it first
  if [[ $VIRTUAL_ENV == $venv_dir/venv ]]; then 
    deactivate
  fi

  rm -rf $venv_dir/venv
  echo "Cleaned venv '$1'"
}

_venvy_edit () {
  local venv_dir=$VENVY_CONFIG_DIR/$1
  if [[ ! -e $venv_dir ]]; then
    _venvy_could_not_find_venv $venv_dir
    return 1;
  fi

  if command -v nano >/dev/null; then
    local executable=nano
  fi

  if command -v vim >/dev/null; then
    local editor=vim
  fi

  if command -v $EDITOR >/dev/null; then
    local editor=$EDITOR
  fi

  if command -v $VENVY_EDITOR >/dev/null; then
    local editor=$VENVY_EDITOR
  fi

  if [[ ! $editor ]]; then
    echo "Cannot open editor since could not find nano, vim, nor the EDITOR or the VENVY_EDITOR environment variables"
    echo "You can still find all the venv configuration files at $VENVY_CONFIG_DIR"
    return 1;
  fi

  $editor $venv_dir/requirements.txt

  _venvy_use $1
}

_venvy_remove () {
  local venv_dir=$VENVY_CONFIG_DIR/$1
  if [[ ! -e $venv_dir ]]; then
    _venvy_could_not_find_venv $1
    return 1;
  fi

  # If currenty using the venv that is to be deleted, deactivate it first
  if [[ $VIRTUAL_ENV == $venv_dir/venv ]]; then 
    deactivate
  fi

  rm -rf $venv_dir
  echo "Removed venv '$1'"
}

_venvy_initialize_files_in_home_if_needed () {
  if [[ ! -d $VENVY_CONFIG_DIR ]]; then
    mkdir -p $VENVY_CONFIG_DIR
  fi

  if [[ ! -f $VENVY_CONFIG_DIR/.gitignore ]]; then
    cp $VENVY_SRC_DIR/templates/home/gitignore $VENVY_CONFIG_DIR/.gitignore 
  fi

  if [[ ! -f $VENVY_CONFIG_DIR/README.md ]]; then
    cp $VENVY_SRC_DIR/templates/home/README.md $VENVY_CONFIG_DIR/
  fi
}

venvy () {
  if [[ $# -lt 1 ]]; then
    echo 'Insufficient arguments'
    _venvy_usage
    return 1
  fi

  _venvy_initialize_files_in_home_if_needed

  local subcommand=$1
  local venv_name=$2

  if [[ $subcommand == 'add' ]]; then
    local executable=$3
    _venvy_add $venv_name $executable
  elif [[ $subcommand == 'use' ]]; then
    _venvy_use $venv_name
  elif [[ $subcommand == 'clean' ]]; then
    _venvy_clean $venv_name
  elif [[ $subcommand == 'edit' ]]; then
    _venvy_edit $venv_name
  elif [[ $subcommand == 'rm' ]]; then
    _venvy_remove $venv_name
  elif [[ $subcommand == 'ls' ]]; then
    _venvy_ls
  elif [[ $subcommand == '-h' || $subcommand == '--help' || $subcommand == 'help' ]]; then
    _venvy_usage
  else
    echo "Unknown subcommand: $subcommand"
    _venvy_usage
    return 1
  fi 
}
