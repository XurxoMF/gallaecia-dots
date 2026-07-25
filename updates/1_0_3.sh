#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.0.3"
DOTFILES_DIR="$HOME/.dotfiles"
MODULES_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules"

if [ ! -r "$MODULES_DIR/ui.sh" ] ||
  [ ! -r "$MODULES_DIR/commands.sh" ] ||
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

# Instala o Bashrc e a configuración nova de SpotDL cando está dispoñible.
update_spotdl_config() {
  if ! has_command spotdl; then
    return 0
  fi

  if ! mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc"; then
    return 1
  fi
  if ! replace_file \
    "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/202-spotdl" \
    "$HOME/.local/share/gallaecia-dots/bashrc/202-spotdl"; then
    return 1
  fi
  if ! replace_file \
    "$DOTFILES_DIR/optional/.config/spotdl/config.json" \
    "$HOME/.config/spotdl/config.json"; then
    return 1
  fi
}

# Mostra o resumo visible dos cambios incluídos na migración.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Engadido o comando interactivo spotdl-musica (se SpotDL está instalado)."
  info "· Actualizada a config de SpotDL."
}

# Executa cada cambio da migración e detense no primeiro erro.
apply_update() {
  if ! update_spotdl_config; then
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
