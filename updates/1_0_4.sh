#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.0.4"
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

# Comproba se Dolphin está instalado e, só nese caso, instala Ark mediante Yay.
# A ausencia de Dolphin é un éxito porque a integración é opcional.
install_ark_for_dolphin() {
  if ! has_command dolphin; then
    return 0
  fi

  if ! yay -Sy --needed ark; then
    return 1
  fi
}

# Substitúe a base Lua de Hyprland controlada por Gallaecia.
# Non toca o wrapper persoal gardado en `~/.config/hypr`.
update_hyprland_config() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/hypr/gallaecia.lua" \
    "$HOME/.local/share/gallaecia-dots/hypr/gallaecia.lua"
}

# Informa da integración de Ark e da corrección de animacións.
# Non realiza os cambios antes da confirmación do usuario.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Engadido ark para engadir compresión de arquivos a dolphin (solo se tes dolphin)."
  info "· Actualizadas animacións de Hyprland rotas dende a 0.56.0."
}

# Instala primeiro a dependencia opcional e despois actualiza Hyprland.
# Detense no primeiro erro para non ocultar unha migración parcial.
apply_update() {
  if ! install_ark_for_dolphin; then
    return 1
  fi
  if ! update_hyprland_config; then
    return 1
  fi
}

# Presenta o resumo, pide confirmación e aplica todos os pasos.
# Cancelar ou fallar impide que o instalador marque a versión.
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
