#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.0.4"
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

# Instala Ark para integrar a compresión en Dolphin cando este está dispoñible.
install_ark_for_dolphin() {
  if ! has_command dolphin; then
    return 0
  fi

  if ! yay -Sy --needed ark; then
    return 1
  fi
}

# Actualiza a configuración compartida de Hyprland.
update_hyprland_config() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/hypr/gallaecia.lua" \
    "$HOME/.local/share/gallaecia-dots/hypr/gallaecia.lua"
}

# Mostra o resumo visible dos cambios incluídos na migración.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Engadido ark para engadir compresión de arquivos a dolphin (solo se tes dolphin)."
  info "· Actualizadas animacións de Hyprland rotas dende a 0.56.0."
}

# Executa cada cambio da migración e detense no primeiro erro.
apply_update() {
  if ! install_ark_for_dolphin; then
    return 1
  fi
  if ! update_hyprland_config; then
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
