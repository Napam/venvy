#!/usr/bin/env bash

run () {
  local executable={executable}
  local dir_path=$(realpath $(dirname $BASH_SOURCE))
  local venv_path=$dir_path/venv
  local prompt_name=$(basename $dir_path)
  local req_file=${dir_path}/requirements.txt

  echo "Building virtual environment: $prompt_name"
  echo "Using Python executable: $executable"
  $executable -m venv --prompt $prompt_name $venv_path

  echo "Activating virtual environment"
  source ${venv_path}/bin/activate 
  
  printf "Installing requirements from $req_file"
  pip install -r $req_file 
}

run

