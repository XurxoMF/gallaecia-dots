#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.1.1"
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
source "$MODULES_DIR/files.sh"

# Instala o actualizador que comproba migracións aínda co repo ao día.
update_system_update() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/system-update.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/system-update.sh"
}

# Mostra os cambios e a reparación que aplicará esta migración.
show_changelog() {
  echo
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Corrixida a entrada interactiva das migracións para evitar EOF."
  info "· O actualizador comproba versións pendentes aínda co repo ao día."
  echo
}

# Instala o actualizador corrixido e reexecuta a migración anterior.
apply_update() {
  update_system_update || return 1
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
