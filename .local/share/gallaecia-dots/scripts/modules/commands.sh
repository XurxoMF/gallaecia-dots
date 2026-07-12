# shellcheck shell=bash

# Comproba se un comando está dispoñible no PATH.
has_command() {
  local command_name="$1"

  command -v "$command_name" &> /dev/null
}

# Instala un paquete de pacman só se o comando asociado aínda non existe.
# Úsase para prerequisitos básicos como gum/git.
ensure_command() {
  local command_name="$1"
  local package_name="$2"

  if ! has_command "$command_name"; then
    sudo pacman -Sy --needed "$package_name"
  fi
}
