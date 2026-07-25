#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.1.1"
DOTFILES_DIR="$HOME/.dotfiles"
MODULES_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules"
UPDATE_1_1_0_SCRIPT="$DOTFILES_DIR/updates/1_1_0.sh"

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

# Reexecuta unha vez a 1.1.0 para reparar posibles instalacións incompletas.
repair_update_1_1_0() {
  if [ ! -r "$UPDATE_1_1_0_SCRIPT" ]; then
    warning "Non se atopou $UPDATE_1_1_0_SCRIPT para reparar a instalación."
    return 1
  fi

  info "Vaise reexecutar a update 1.1.0 para completar calquera paso pendente polo bug introducido anteriormente."

  if ! bash "$UPDATE_1_1_0_SCRIPT"; then
    warning "A reparación da update 1.1.0 non se completou."
    return 1
  fi
}

# Mostra os cambios e a reparación que aplicará esta migración.
show_changelog() {
  echo
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Corrixida a entrada interactiva das migracións para evitar EOF."
  info "· O actualizador comproba versións pendentes aínda co repo ao día."
  info "· Reexecútase a update 1.1.0 para reparar instalacións incompletas."
  echo
}

# Instala o actualizador corrixido e reexecuta a migración anterior.
apply_update() {
  update_system_update || return 1
  repair_update_1_1_0
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
