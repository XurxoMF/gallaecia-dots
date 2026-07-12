# shellcheck shell=bash

has_command() {
  local command_name="$1"

  command -v "$command_name" &> /dev/null
}

ensure_command() {
  local command_name="$1"
  local package_name="$2"

  if ! has_command "$command_name"; then
    sudo pacman -Sy --needed "$package_name"
  fi
}
