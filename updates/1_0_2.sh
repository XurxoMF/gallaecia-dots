#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.0.2"
DOTFILES_DIR="$HOME/.dotfiles"
MODULES_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules"

if [ ! -r "$MODULES_DIR/ui.sh" ] ||
  [ ! -r "$MODULES_DIR/files.sh" ] ||
  [ ! -r "$MODULES_DIR/apps.sh" ]; then
  echo "Non se atoparon os módulos de Gallaecia Dots en $MODULES_DIR." >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$MODULES_DIR/ui.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/files.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/apps.sh"

# Actualiza o wrapper visual compartido.
update_ui_module() {
  if ! mkdir -p "$HOME/.local/share/gallaecia-dots/scripts/modules"; then
    return 1
  fi
  if ! replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/ui.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/modules/ui.sh"; then
    return 1
  fi
}

# Actualiza o template que Noctalia usa para xerar as cores da interface.
update_ui_colors_template() {
  if ! mkdir -p "$HOME/.local/share/gallaecia-dots/noctalia"; then
    return 1
  fi
  if ! replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/noctalia/ui-colors.sh.template" \
    "$HOME/.local/share/gallaecia-dots/noctalia/ui-colors.sh.template"; then
    return 1
  fi
}

# Actualiza o Bashrc de yt-dlp se xa estaba instalado por Gallaecia.
update_yt_dlp_bash_module() {
  if ! is_pkg_installed yt-dlp ||
    ! file_exists "$HOME/.local/share/gallaecia-dots/bashrc/201-yt-dlp"; then
    return 0
  fi

  if ! rm -f "$HOME/.local/share/gallaecia-dots/bashrc/201-yt-dlp"; then
    return 1
  fi
  if ! replace_file \
    "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/201-yt-dlp" \
    "$HOME/.local/share/gallaecia-dots/bashrc/201-yt-dlp"; then
    return 1
  fi
}

# Mostra o resumo visible dos cambios incluídos na migración.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Corrixido gum_input para usar só opcións soportadas por gum."
  info "· Actualizado o template de cores de Noctalia para gum input."
  info "· Actualizados os comandos interactivos de yt-dlp."
}

# Executa cada cambio da migración e detense no primeiro erro.
apply_update() {
  if ! update_ui_module; then
    return 1
  fi
  if ! update_ui_colors_template; then
    return 1
  fi
  if ! update_yt_dlp_bash_module; then
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
