export VENVY_CACHE_DIR=$HOME/.cache/venvy
export VENVY_CONFIG_DIR=$HOME/.config/venvy
export VENVY_SRC_DIR=$HOME/.local/src/venvy

_venvy_usage() {
  local self='venvy'

  cat << EOF
Usage:
  $self add <name> [executable]
      Create, build and activate venv configuration. Optionally specify python executable.
      For example: $self add test python3.8

  $self use <name>
      Activate venv.

  $self deactivate
      Deactivates current running venv. You can also just type 'deactivate' to use the
      native python venv deactivation function.

  $self clean <name>
      Clean venv cache, venv will be rebuilt on next usage. If you are currently using the
      venv, it will be deactivated for you automatically.

  $self edit [name]
      Edit requirements.txt for a venv. It will use your current activated venv, or you
      can specify which venv you want to edit. Will also run a 'pip install -r
      requirements.txt' afterwards. This means that added packages will get installed
      automatically, but removal of packages will not remove them from the actual
      installed packages in the venv. You will have to remove using 'pip uninstall
      <package>' manually if that is desired.

  $self setexec <name> <executable>
      Set Python executable to another path for a venv. This will in turn do a clean of
      the venv cache of the specified venv, which will in turn rebuild the virtual
      environment using the specified executable on the next run.

  $self rm <name>
      Remove specified venv.

  $self ls
      List configured all venvs.

  $self mv <old> <new>
      Move a venv to a new name. 

  $self purge
      Remove all venvs. Will require an interactive confirmation.

  $self help
      Show this text.
EOF
}

_venvy_ls() {
  find $VENVY_CONFIG_DIR/ -mindepth 1 -maxdepth 1 -type d -not -name '.*' -exec basename {} \; | sort
}

_venvy_could_not_find_venv_error() {
  echo "Could not find the venv called '$1'. The available ones are:"
  _venvy_ls
}

_venvy_invalid_executable_error() {
  echo "Could not find the Python executable '$1', please specify a valid executable"
}

_venvy_missing_venv_name_error() {
  echo "A name for the virtual environment must be specified. The available ones are:"
  _venvy_ls
}

_venvy_add() {
  local venv_name=$1
  local executable=$2
  local venv_dir=$VENVY_CONFIG_DIR/$venv_name

  if [[ -z $venv_name ]]; then
    echo "You must specify a name. For example 'venvy add test'. You can also specify an executable as well, like 'venvy add legacy python3.8'"
    return 1
  fi

  if [[ -d $venv_dir ]]; then
    echo "A venv called '$venv_name' already exists. Run 'venvy use $1' to activate it."
    return 1
  fi

  if [[ ! $executable ]]; then
    if command -v python > /dev/null; then
      local executable=python
    fi

    if command -v python3 > /dev/null; then
      local executable=python3
    fi
  fi

  if [[ ! $executable ]]; then
    echo "Could not infer a python executable. If you have a non-standard Python installation, please explicitly specify the path to the executable"
    return 1
  fi

  if ! command -v $executable > /dev/null; then
    _venvy_invalid_executable_error $executable
    return 1
  fi

  cp -r $VENVY_SRC_DIR/templates/venv $VENVY_CONFIG_DIR/$venv_name

  # This is basically gnu sed -i, but it also works on MacOS
  perl -i -pe "s/{executable}/$executable/g" $VENVY_CONFIG_DIR/$venv_name/metadata.txt

  echo "Created venv '$venv_name'"

  _venvy_use $venv_name
}

_venvy_build() {
  local venv_dir=$1
  local req_name=${2:-requirements.txt}

  local venv_path=$venv_dir/venv
  local req_file=${venv_dir}/${req_name}
  local prompt_name=$(basename $venv_dir)
  local executable=$(awk -F= '$1 == "executable" {print $2; exit}' $venv_dir/metadata.txt)

  echo "Building virtual environment: $prompt_name"
  echo "Using Python executable: $executable"
  $executable -m venv --prompt $prompt_name $venv_path

  echo "Installing requirements from $req_file"
  $venv_path/bin/python -m pip install -r $req_file
}

_venvy_build_and_activate() {
  local venv_dir=$1

  _venvy_build $venv_dir

  echo "Activating virtual environment"
  source $venv_dir/venv/bin/activate
}

_venvy_use() {
  local venv_name=$1
  if [[ -z "${venv_name// /}" ]]; then
    _venvy_missing_venv_name_error
    return 1
  fi

  local venv_dir=$VENVY_CONFIG_DIR/$venv_name
  if [[ ! -e $venv_dir ]]; then
    _venvy_could_not_find_venv_error $venv_name
    return 1
  fi

  local activate=$venv_dir/venv/bin/activate

  if [[ ! -f $activate ]]; then
    _venvy_build_and_activate $venv_dir
  fi

  source $activate
}

_venvy_clean() {
  local venv_name=$1
  if [[ -z "${venv_name// /}" ]]; then
    _venvy_missing_venv_name_error
    return 1
  fi

  local venv_dir=$VENVY_CONFIG_DIR/$venv_name
  if [[ ! -e $venv_dir ]]; then
    _venvy_could_not_find_venv_error $venv_dir
    return 1
  fi

  # If currenty using the venv that is to be cleaned, deactivate it first
  if [[ $VIRTUAL_ENV == $venv_dir/venv ]]; then
    deactivate
  fi

  rm -rf $venv_dir/venv
  echo "Cleaned venv '$venv_name'"
}

_venvy_edit() {
  local venv_name=$1

  if [[ $venv_name ]]; then
    local venv_dir=$VENVY_CONFIG_DIR/$venv_name
    if [[ ! -e $venv_dir ]]; then
      _venvy_could_not_find_venv_error $venv_dir
      return 1
    fi
  else
    if [[ $VIRTUAL_ENV ]]; then
      local venv_dir=$(dirname $VIRTUAL_ENV)
    else
      _venvy_missing_venv_name_error
      return 1
    fi
  fi

  if command -v nano > /dev/null; then
    local editor=nano
  fi

  if command -v vi > /dev/null; then
    local editor=vi
  fi

  if command -v vim > /dev/null; then
    local editor=vim
  fi

  if command -v nvim > /dev/null; then
    local editor=nvim
  fi

  # One could think that just using command -v $VAR would be enough.
  # But in ZSH command -v $EMPTY_VAR returns 1, but in bash it returns 0.
  # Therefore check if $VARIABLE exist and then command

  if [[ $EDITOR && $(command -v $EDITOR) ]]; then
    local editor=$EDITOR
  fi

  if [[ $VENVY_EDITOR && $(command -v $VENVY_EDITOR) ]]; then
    local editor=$VENVY_EDITOR
  fi

  if [[ ! $editor ]]; then
    echo "Cannot open editor since could not find nano, vim, nor the EDITOR or the VENVY_EDITOR environment variables"
    echo "You can still find all the venv configuration files at $VENVY_CONFIG_DIR"
    return 1
  fi

  local curr_req_file=$venv_dir/requirements.txt
  local staging_req_name=requirements.staging.txt
  local staging_req_file=$venv_dir/$staging_req_name
  cp $curr_req_file $staging_req_file
  $editor $staging_req_file

  local changes=$(git diff --no-index $curr_req_file $staging_req_file | grep -E '^[-+][^-+#]')

  if [[ $changes ]]; then
    local to_remove=$(echo $changes | grep -E '^-')
    if [[ $to_remove ]]; then
      awk -F^- '{print $2}' <<< $to_remove | pip uninstall -y -r /dev/stdin
    fi

    _venvy_build $venv_dir $staging_req_name

    # Handle git+https:// urls
    local git_install_packages=$(pip freeze | perl -nle 'print "$1 $2" if /(.+) @ (git\+https:\/\/.+)@/')
    if [[ $git_install_packages ]]; then
      local temp_file="./.temp"
      echo $git_install_packages | while read line; do
        read -r name url <<< $line
        awk -v name="$name" -v url="$url" '{print (index($0, url) != 0 ? $0 "#egg="name : $0)}' $staging_req_file > "$temp_file" && mv "$temp_file" $staging_req_file
      done
    fi

    cat $staging_req_file | grep -E '^[^\#]' | pip freeze -r /dev/stdin | awk '/##.+pip freeze:/ {exit} {print}' > $curr_req_file
    rm $staging_req_file
  else
    # In case one wrote some comments or something
    mv $staging_req_file $curr_req_file
  fi
}

_venvy_setexec() {
  local venv_name=$1
  local venv_dir=$VENVY_CONFIG_DIR/$venv_name
  if [[ ! -e $venv_dir || ! $venv_name ]]; then
    _venvy_could_not_find_venv_error $venv_name
    return 1
  fi
  local new_executable=$2

  if ! command -v $new_executable > /dev/null; then
    _venvy_invalid_executable_error $new_executable
    return 1
  fi

  local metadata_file=$VENVY_CONFIG_DIR/$1/metadata.txt

  # This is basically gnu sed -i, but it also works on MacOS
  perl -i -pe "s/(executable=).+/\1$new_executable/g" $metadata_file

  echo "Executable for '$venv_name' is now set to '$(awk -F= '$1 == "executable" {print $2; exit}' $metadata_file)'"

  if [[ $VIRTUAL_ENV == $venv_dir/venv ]]; then
    local reactivate=1
  fi

  _venvy_clean $venv_name
  _venvy_build $venv_dir

  if [[ $reactivate ]]; then
    _venvy_use $venv_name
  fi
}

_venvy_rm() {
  local venv_name=$1
  if [[ -z "${venv_name// /}" ]]; then
    _venvy_missing_venv_name_error
    return 1
  fi

  local venv_dir=$VENVY_CONFIG_DIR/$venv_name
  if [[ ! -e $venv_dir ]]; then
    _venvy_could_not_find_venv_error $venv_name
    return 1
  fi

  # If currenty using the venv that is to be deleted, deactivate it first
  if [[ $VIRTUAL_ENV == $venv_dir/venv ]]; then
    deactivate
  fi

  rm -rf $venv_dir
  echo "Removed venv '$venv_name'"
}

_venvy_mv() {
  local old_name=$1
  local new_name=$2
  if [[ -z "${old_name// /}" ]]; then
    _venvy_missing_venv_name_error
    return 1
  fi

  local old_venv_dir=$VENVY_CONFIG_DIR/$old_name
  if [[ ! -e $old_venv_dir ]]; then
    _venvy_could_not_find_venv_error $old_name
    return 1
  fi

  # If currenty using the venv that is to be moved, deactivate it first
  if [[ $VIRTUAL_ENV == $old_venv_dir/venv ]]; then
    local reactivate=1
    deactivate
  fi

  local new_venv_dir=$VENVY_CONFIG_DIR/$new_name
  if [[ -e $new_venv_dir ]]; then
    echo "A venv called '$new_name' already exists. Do you want to overwrite it? (y/n): "
    read response
    if [[ ! $response =~ ^[Yy]$ ]]; then
      echo "Aborted mv"
      return 0
    fi
    rm -rf $old_venv_dir
  fi

  mv $old_venv_dir $new_venv_dir
  echo "Moved venv '$venv_name' to '$new_name', will rebuild"

  _venvy_clean $new_name
  _venvy_build $new_venv_dir

  if [[ $reactivate ]]; then
    _venvy_use $new_name
  fi
}

_venvy_purge() {
  local response
  printf "Are you sure you want to delete all configured virtual environments? (y/n): "
  read response
  if [[ ! $response =~ ^[Yy]$ ]]; then
    echo "Aborted purge"
    return 0
  fi

  if [[ $VIRTUAL_ENV ]]; then
    deactivate
  fi

  find $VENVY_CONFIG_DIR/ -mindepth 1 -maxdepth 1 -type d -not -name ".*" -exec rm -rf {} +
  echo "Successfully removed all venvs"
}

_venvy_ensure_home_files() {
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

venvy() {
  if [[ $# -lt 1 ]]; then
    echo 'Insufficient arguments\n'
    _venvy_usage
    return 1
  fi

  _venvy_ensure_home_files

  local subcommand=$1
  local venv_name=$2

  if [[ $subcommand == 'add' ]]; then
    local executable=$3
    _venvy_add $venv_name $executable
  elif [[ $subcommand == 'use' ]]; then
    _venvy_use $venv_name
  elif [[ $subcommand == 'deactivate' ]]; then
    command -v deactivate > /dev/null && deactivate
  elif [[ $subcommand == 'clean' ]]; then
    _venvy_clean $venv_name
  elif [[ $subcommand == 'edit' ]]; then
    _venvy_edit $venv_name
  elif [[ $subcommand == 'setexec' ]]; then
    local executable=$3
    _venvy_setexec $venv_name $executable
  elif [[ $subcommand == 'rm' ]]; then
    _venvy_rm $venv_name
  elif [[ $subcommand == 'ls' ]]; then
    _venvy_ls
  elif [[ $subcommand == 'mv' ]]; then
    local old=$venv_name
    local new=$3
    _venvy_mv $old $new
  elif [[ $subcommand == 'purge' ]]; then
    _venvy_purge
  elif [[ $subcommand == '-h' || $subcommand == '--help' || $subcommand == 'help' ]]; then
    _venvy_usage
  else
    echo "Unknown subcommand: $subcommand"
    _venvy_usage
    return 1
  fi
}
