#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.1.4"
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
source "$INTERNAL_DIR/versions.sh"

# Substitúe o módulo UI pola variante que retira fondo e padding do filtro.
# O cambio afecta os seguintes selectores sen tocar os seus scripts consumidores.
update_ui_module() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/ui.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/modules/ui.sh"
}

# Describe os tres axustes de `gum filter` antes da confirmación.
# É unha función informativa sen efectos sobre a configuración.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Retirado o fondo do indicador desmarcado de gum filter."
  info "· Conservado o estilo anterior do indicador seleccionado."
  info "· Retirado o padding de gum filter porque ocupa a pantalla completa."
}

# Executa a única substitución e propaga o seu código.
# O instalador só marcará a versión se o ficheiro queda actualizado.
apply_update() {
  if ! update_ui_module; then
    return 1
  fi
}

# Mostra, confirma e aplica o cambio visual.
# Cancelar ou fallar termina con erro para permitir un reintento futuro.
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
