#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.1.3"
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

# Substitúe o módulo UI controlado polo proxecto pola versión que centraliza
# cores, axuda de controis e padding interno de Gum.
update_ui_module() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/ui.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/modules/ui.sh"
}

# Substitúe o template de Noctalia para que as seguintes xeracións de paleta
# conserven os fondos transparentes definidos polo módulo UI.
update_ui_colors_template() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/noctalia/ui-colors.sh.template" \
    "$HOME/.local/share/gallaecia-dots/noctalia/ui-colors.sh.template"
}

# Detalla os cambios visuais e de controis antes de pedir permiso.
# Non rexenera a paleta nin modifica ficheiros nesta fase.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Retirado o fondo dos elementos non seleccionados en choose e filter."
  info "· Engadida unha guía visible para navegar e marcar seleccións."
  info "· Substituídos os saltos permanentes polo padding interno de Gum."
  info "· Documentados os controis dos selectores interactivos."
}

# Actualiza primeiro o consumidor das cores e despois o template xerador.
# Propaga o primeiro fallo para non aceptar unha parella incoherente.
apply_update() {
  if ! update_ui_module; then
    return 1
  fi
  if ! update_ui_colors_template; then
    return 1
  fi
}

# Presenta, confirma e aplica os dous ficheiros controlados.
# A cancelación ou un erro evita rexistrar a versión.
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
