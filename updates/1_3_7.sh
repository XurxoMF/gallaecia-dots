#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.3.7"
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

# Instala Hyprpicker, que proporciona o selector empregado polo novo plugin de
# cor de Noctalia. `--needed` evita reinstalalo se xa está presente.
install_color_picker_dependency() {
  yay -S --needed hyprpicker
}

# Substitúe a libraría interna controlada para ofrecer ONLYOFFICE desde
# `gallaecia install-category office` nas instalacións xa existentes.
update_internal_apps_library() {
  if ! ensure_directory "$HOME/.local/share/gallaecia-dots/scripts/internal"; then
    return 1
  fi

  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/internal/apps.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/internal/apps.sh"
}

# Substitúe a configuración base de Noctalia, controlada por Gallaecia, para
# activar o plugin do selector de cor. `custom.toml` permanece intacto.
update_noctalia_config() {
  if ! ensure_directory "$HOME/.config/noctalia"; then
    return 1
  fi

  replace_file \
    "$DOTFILES_DIR/.config/noctalia/gallaecia.toml" \
    "$HOME/.config/noctalia/gallaecia.toml"
}

# Resume os cambios antes de modificar as instalacións existentes.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Engadido ONLYOFFICE como opción na categoría de oficina e notas."
  info "· Engadido OpenCode como opción na categoría de desenvolvemento."
  info "· Configuradas as asociacións de documentos, follas de cálculo e presentacións."
  info "· Engadido á barra de Noctalia o plugin do selector de cor."
  info "· Hyprpicker instálase como dependencia obrigatoria do novo plugin."
}

# Instala a dependencia e actualiza os ficheiros controlados que expoñen as
# novas opcións de aplicacións e Noctalia.
apply_update() {
  if ! install_color_picker_dependency; then
    return 1
  fi
  if ! update_internal_apps_library; then
    return 1
  fi
  if ! update_noctalia_config; then
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
