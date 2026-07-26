#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.2.5"
DOTFILES_DIR="$HOME/.dotfiles"
MODULES_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules"

if [ ! -r "$MODULES_DIR/ui.sh" ] ||
  [ ! -r "$MODULES_DIR/files.sh" ]; then
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

# Instala os reprodutores requiridos polo plugin de fondos animados.
install_animated_wallpaper_dependencies() {
  yay -S --needed mpv mpvpaper
}

# Actualiza a configuración de Noctalia controlada polo proxecto.
update_noctalia_config() {
  replace_file \
    "$DOTFILES_DIR/.config/noctalia/gallaecia.toml" \
    "$HOME/.config/noctalia/gallaecia.toml"
}

# Crea o directorio persoal no que se gardan os fondos animados.
create_wallpaper_videos_dir() {
  mkdir -p "$HOME/.wallpaper-videos"
}

# Mostra o resumo visible dos cambios incluídos na migración.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Reparado o botón de actualización do sistema na barra."
  info "· Engadido un tradutor ao launcher."
  info "· Engadido un sistema de fondos animados."
}

# Executa cada cambio da migración e detense no primeiro erro.
apply_update() {
  if ! install_animated_wallpaper_dependencies; then
    return 1
  fi
  if ! update_noctalia_config; then
    return 1
  fi
  if ! create_wallpaper_videos_dir; then
    return 1
  fi
}

# Confirma e executa a migración, propagando calquera erro ao instalador.
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
