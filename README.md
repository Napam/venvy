
# Venvy
*Python virtual environment orchestration done simply and reusably*

## Features
- Defines a set of handy terminal commands to orchestrate different Python virtual environments
- The venvy-wrapped virtual environments are made in a dotfile-repo friendly manner
- Only uses native Python (no external dependencies)
- Handling for different Python executables (for example different Python versions) for each virtual environment

## Background and reasoning behind Venvy
A way to store and synchronize configuration files such as `.vimrc`, `.zshrc`, `.bashrc` across different computers / OS installations is to have a "[dotfiles](https://en.wikipedia.org/wiki/Hidden_file_and_hidden_directory#Unix_and_Unix-like_environments)" repository. It is basically a repostory with such configaration files that often are prefixed a dot, hence the name, and then one typically symlinks the dotfiles to their appropriate locations from the repository.

I simply wanted to have my Python virtual environments in my dotfiles repository. Thus I created Venvy, a tool which orchestrates Python's integrated `venv` module such that the virtual environments are stored in a "dotfile-repo-friendly" manner.

I will assume users are familiar with the `requirements.txt` convention of Python. A venvy virtual environment is essentially a `requirements.txt` file along with data about which Python executable is to be used. The python venv files themselves are considered as cache and are git ignored.

## Installation
Venvy is entirely written in bash. As long as you have a working bash environment it should work. Zsh will also work as it can run bash code.

The simplest way to install `venvy` is to clone this repo to `$HOME/.local/src/venvy` (has to be at that location), then just make sure that the `venvy.sh` file gets sources when you start your terminal. Here are some specific instructions for different shells:

### bash
1. Run `git clone git@github.com:Napam/venvy.git $HOME/.local/src/venvy`
1. Append the following to your `$HOME/.bashrc` file:
    ```bash
    export VENVY_SRC_DIR="$HOME/.local/src/venvy"
    [[ -s $VENVY_SRC_DIR ]] && source "$VENVY_SRC_DIR/venvy.sh"
    ```
1. Run `. $HOME/.bashrc`
1. You should now see venvy's help screen

### zsh
1. Run `git clone git@github.com:Napam/venvy.git $HOME/.local/src/venvy`
1. Append the following to your `$HOME/.zshrc` file:
    ```bash
    export VENVY_SRC_DIR="$HOME/.local/src/venvy"
    [[ -s $VENVY_SRC_DIR ]] && source "$VENVY_SRC_DIR/venvy.sh"
    ```
1. Run `. $HOME/.zshrc`
1. You should now see venvy's help screen

## Adding the configuration to your dotfiles repository
Add the following directory: `$HOME/.config/venvy`.

## Quickstart
1. Add a virtual environment: `venvy add test`
1. Edit its underlying `requirements.txt` file: `venvy edit`. For example add `numpy`.
    1. It will by default open `vim` or `nano` or whatever you have set `EDITOR` to be.
    1. When you save and close the editor, venvy will basically do a `pip install -r requirements.txt` for you.
    1. You can still just do `pip install`, but then the change won't be reflected in the internal registry of venvy, meaning the changes won't end up in your dotfiles repository.
1. Do `pip list` to see that `numpy` is one of the dependencies.
1. Deactivate the virtual environment with: `deactivate`

## Tab completion
As of this date `venvy` only has tab compoletion (bash is WIP). Try write `venvy` followed with a tab, you should get tab completion.

## How it works
Assuming you have ran `venvy` once, venvy should have initialized some files in your environment. The venvy configuration files are stored at `$HOME/.config/venvy`. The directory is "git friendly". It is the one meant to be added to your dotfiles repository. It contains a `.gitignore` that ignores the cache files of the virtual environments, such that the only things that git tracks are the requirements the their names, and which executable they use. The configuration files are meant to editable, so feel free to mess around there directly. The commands only read / and write to those configuration files.

Venvy will use whatever python exisists in your environment, but it has to be new enough to have the `venv` module built in, that is you need Python 3.3 or higher. If you want to have virtual environments that are tied to something other than your default `python`/`python3` executables, you just specify something else. See the section below.

### Quick overview of possible commands
Here is what you get from `venvy --help` or just `venvy`. It is shows everything you can do with `venvy`.
```
venvy add <name> [executable]
  Create, build and activate venv configuration. Optionally specify python executable.
  For example: venvy add test python3.8

venvy use <name>
  Activate venv.

venvy deactivate
  Deactivates current running venv. You can also just type 'deactivate' to use the
  native python venv deactivation function.

venvy clean <name>
  Clean venv cache, venv will be rebuilt on next usage. If you are currently using the
  venv, it will be deactivated for you automatically.

venvy edit [name]
  Edit requirements.txt for a venv. It will use your current activated venv, or you
  can specify which venv you want to edit. Will also run a 'pip install -r
  requirements.txt' afterwards. This means that added packages will get installed
  automatically, but removal of packages will not remove them from the actual
  installed packages in the venv. You will have to remove using 'pip uninstall
  <package>' manually if that is desired.

venvy setexec <name> <executable>
  Set Python executable to another path for a venv. This will in turn do a clean of
  the venv cache of the specified venv, which will in turn rebuild the virtual
  environment using the specified executable on the next run.

venvy rm <name>
  Remove venv.

venvy ls
  List configured venvs.

venvy purge
  Remove all venvs. Will require an interactive confirmation.

venvy help
  Show this text
```

## Similar tools

### [virtualenvwrapper](https://github.com/python-virtualenvwrapper/virtualenvwrapper)
It is very similar to this venvy. However, it is not based on Python built in venv module, but rather Ian Bicking’s virtualenv tool, and it does not have as dot-file friendly config structure like this one. It is however way more feature rich. Venvy aims to be minimal and simple without too many bells and whistles.
