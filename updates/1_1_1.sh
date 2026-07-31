#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.1.1"
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

# Substitúe `system-update.sh` pola versión que sempre chama o instalador en modo
# update, mesmo cando Git non descargou commits novos.
update_system_update() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/system-update.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/system-update.sh"
}

# Explica as correccións de entrada e detección de migracións pendentes.
# Non altera o actualizador ata que o usuario confirme.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Corrixida a entrada interactiva das migracións para evitar EOF."
  info "· O actualizador comproba versións pendentes aínda co repo ao día."
}

# Executa o único paso e propaga o resultado de `replace_file`.
# Un fallo deixa a versión sen rexistrar para poder reintentala.
apply_update() {
  if ! update_system_update; then
    return 1
  fi
}

# Mostra o changelog, confirma e comunica se a substitución rematou.
# Cancelar considérase un erro deliberado para deter a cadea de migracións.
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
