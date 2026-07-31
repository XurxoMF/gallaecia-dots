#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.2.2"
DOTFILES_DIR="$HOME/.dotfiles"
MODULES_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules"
INTERNAL_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/internal"

# Todos os updates cargan sempre a API pública e as librarías internas completas.
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

# Substitúe o módulo de interface controlado por Gallaecia para que o estilo das
# coincidencias de `gum filter` non interrompa o fondo da fila que ten o cursor.
update_ui_module() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/ui.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/modules/ui.sh"
}

# Explica a corrección visual antes de substituír o módulo público de interface.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Corrixido o fondo da fila activa nos filtros cando a busca resalta coincidencias."
}

# Aplica a substitución nun paso explícito para non rexistrar unha copia fallida.
apply_update() {
  if ! update_ui_module; then
    return 1
  fi
}

# Presenta o changelog, confirma e executa o orquestrador.
# Só un éxito completo permite ao instalador marcar a versión como aplicada.
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
