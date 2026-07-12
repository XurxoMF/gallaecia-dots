#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.0.3"
DOTFILES_DIR="$HOME/.dotfiles"
MODULES_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules"
SPOTDL_OUTPUT='Música/SpotDL/{album-artist}/{album}/{track-number}. {title}.{output-ext}'
SPOTDL_LYRICS_PROVIDERS='["genius", "azlyrics", "musixmatch"]'

if [ ! -r "$MODULES_DIR/ui.sh" ] ||
  [ ! -r "$MODULES_DIR/commands.sh" ] ||
  [ ! -r "$MODULES_DIR/files.sh" ] ||
  [ ! -r "$MODULES_DIR/versions.sh" ] ||
  [ ! -r "$MODULES_DIR/apps.sh" ]; then
  echo "Non se atoparon os módulos de Gallaecia Dots en $MODULES_DIR." >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$MODULES_DIR/ui.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/commands.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/files.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/versions.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/apps.sh"

show_changelog() {
  echo
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Engadido o comando interactivo spotdl-musica (se SpotDL está instalado)."
  info "· Actualizada a ruta output e os lyrics_providers do config de SpotDL."
  echo
}

update_spotdl_config() {
  local config_file="$HOME/.config/spotdl/config.json"

  if ! file_exists "$config_file"; then
    return 0
  fi

  sed -i \
    -e "s#^\([[:space:]]*\"output\"[[:space:]]*:[[:space:]]*\)\"[^\"]*\"\(,\?\)#\1\"$SPOTDL_OUTPUT\"\2#" \
    -e "s#^\([[:space:]]*\"lyrics_providers\"[[:space:]]*:[[:space:]]*\)\[\][[:space:]]*\(,\?\)#\1$SPOTDL_LYRICS_PROVIDERS\2#" \
    "$config_file"
}

apply_update() {
  update_spotdl_config || return 1

  if has_command spotdl; then
    mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" &&
    replace_file \
      "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/202-spotdl" \
      "$HOME/.local/share/gallaecia-dots/bashrc/202-spotdl"
  fi
}

main() {
  show_changelog

  if ! gum_confirm "Instalar update $VERSION?"; then
    warning "Update $VERSION cancelada."
    exit 1
  fi

  if apply_update; then
    success "Update $VERSION instalada con éxito!"
  else
    fail "Algo fallou ao instalar a update $VERSION."
  fi
}

main "$@"
