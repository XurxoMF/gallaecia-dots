#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.2.3"
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
# shellcheck source=/dev/null
source "$MODULES_DIR/versions.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/apps.sh"

# Actualiza os wrappers de Gum co novo estilo e espazado interno.
update_ui_module() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/ui.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/modules/ui.sh"
}

# Evita que Noctalia rexenere fondos nos elementos normais dos selectores.
update_ui_colors_template() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/noctalia/ui-colors.sh.template" \
    "$HOME/.local/share/gallaecia-dots/noctalia/ui-colors.sh.template"
}

# Mostra o resumo visible dos cambios incluídos na migración.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Retirado o fondo dos elementos non seleccionados en choose e filter."
  info "· Engadida unha guía visible para navegar e marcar seleccións."
  info "· Substituídos os saltos permanentes polo padding interno de Gum."
  info "· Documentados os controis dos selectores interactivos."
}

# Executa cada cambio da migración e detense no primeiro erro.
apply_update() {
  if ! update_ui_module; then
    return 1
  fi
  if ! update_ui_colors_template; then
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
