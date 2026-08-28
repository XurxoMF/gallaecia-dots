#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.2.4"
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

# Actualiza os helpers de paquetes coa detección correcta da primeira columna
# devolta por `pipx list --short`.
update_apps_module() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/apps.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/modules/apps.sh"
}

# Actualiza a categoría de IDE para instalar a configuración controlada de VS
# Code tanto nas instalacións novas como ao volver executar a categoría.
update_category_installer() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/internal/apps.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/internal/apps.sh"
}

# Actualiza o dispatcher para que `install-category` use a versión instalada
# das categorías sen sincronizar antes o repositorio.
update_gallaecia_module() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/gallaecia.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/modules/gallaecia.sh"
}

# Se VS Code xa está instalado, restaura a súa configuración controlada e
# obrígao a empregar GNOME Keyring mediante o backend estándar de libsecret.
update_vscode_password_store() {
  if ! has_package --manager yay visual-studio-code-bin; then
    return 0
  fi

  replace_file \
    "$DOTFILES_DIR/optional/.config/code-flags.conf" \
    "$HOME/.config/code-flags.conf"
}

# Resume os cambios antes de modificar as instalacións existentes.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Corrixida a detección das aplicacións instaladas con Pipx."
  info "· VS Code usa GNOME Keyring mediante libsecret para gardar credenciais."
  info "· install-category usa as apps da versión instalada sen sincronizar o repositorio."
}

# Aplica cada substitución por separado e detense ante o primeiro erro.
apply_update() {
  if ! update_apps_module; then
    return 1
  fi
  if ! update_category_installer; then
    return 1
  fi
  if ! update_gallaecia_module; then
    return 1
  fi
  if ! update_vscode_password_store; then
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
