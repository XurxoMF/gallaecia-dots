#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.0.1"
DOTFILES_DIR="$HOME/.dotfiles"
MODULES_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules"

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
  info "· Mellorados os comandos de yt-dlp."
  echo
}

apply_update() {
  if is_pkg_installed yt-dlp && file_exists "$HOME/.config/bashrc/201-yt-dlp"; then
    rm -f "$HOME/.config/bashrc/201-yt-dlp" &&
    mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" &&
    replace_file \
      "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/201-yt-dlp" \
      "$HOME/.local/share/gallaecia-dots/bashrc/201-yt-dlp"
  fi

  mkdir -p "$HOME/.local/share/gallaecia-dots/scripts/modules" &&
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/files.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/modules/files.sh" &&
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/apps.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/modules/apps.sh" &&
  replace_file "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
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
