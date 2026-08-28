#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.1.5"
DOTFILES_DIR="$HOME/.dotfiles"
MODULES_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules"
INTERNAL_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/internal"

if [ ! -r "$MODULES_DIR/apps.sh" ] ||
  [ ! -r "$MODULES_DIR/commands.sh" ] ||
  [ ! -r "$MODULES_DIR/files.sh" ] ||
  [ ! -r "$MODULES_DIR/gallaecia.sh" ] ||
  [ ! -r "$MODULES_DIR/network.sh" ] ||
  [ ! -r "$MODULES_DIR/ui.sh" ] ||
  [ ! -r "$INTERNAL_DIR/apps.sh" ] ||
  [ ! -r "$INTERNAL_DIR/mode.sh" ] ||
  [ ! -r "$INTERNAL_DIR/versions.sh" ]; then
  echo "Non se atoparon os módulos ou librarías internas en $DOTFILES_DIR." >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$MODULES_DIR/apps.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/commands.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/files.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/gallaecia.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/network.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/ui.sh"
# shellcheck source=/dev/null
source "$INTERNAL_DIR/apps.sh"
# shellcheck source=/dev/null
source "$INTERNAL_DIR/mode.sh"
# shellcheck source=/dev/null
source "$INTERNAL_DIR/versions.sh"

# Instala obrigatoriamente MPV e mpvpaper mediante Yay.
# Ambos son necesarios para que o plugin de fondos animados poida reproducir vídeo.
install_animated_wallpaper_dependencies() {
  yay -S --needed mpv mpvpaper
}

# Substitúe `gallaecia.toml` para activar as correccións da barra, o tradutor e
# o soporte de fondos animados, preservando `custom.toml`.
update_noctalia_config() {
  replace_file \
    "$DOTFILES_DIR/.config/noctalia/gallaecia.toml" \
    "$HOME/.config/noctalia/gallaecia.toml"
}

# Garante `~/.wallpaper-videos` sen borrar vídeos que xa existan.
# O directorio queda como almacén persoal consumido por Noctalia.
create_wallpaper_videos_dir() {
  mkdir -p "$HOME/.wallpaper-videos"
}

# Presenta as tres capacidades visibles que engade esta versión.
# Non instala paquetes nin copia configuración antes da confirmación.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Reparado o botón de actualización do sistema na barra."
  info "· Engadido un tradutor ao launcher."
  info "· Engadido un sistema de fondos animados."
}

# Instala dependencias, actualiza Noctalia e crea o directorio nesta orde.
# Detense no primeiro erro para que a versión non quede marcada a medias.
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

# Mostra o resumo, require confirmación e aplica os tres pasos.
# Calquera cancelación ou fallo deixa a migración pendente para o futuro.
main() {
  show_changelog

  if ! confirm "Instalar update $VERSION?"; then
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
