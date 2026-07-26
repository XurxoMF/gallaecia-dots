#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.0.1"
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
source "$MODULES_DIR/commands.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/files.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/versions.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/apps.sh"

# Move o Bashrc antigo de yt-dlp á localización controlada por Gallaecia.
migrate_yt_dlp_bash_module() {
  if ! is_pkg_installed yt-dlp ||
    ! file_exists "$HOME/.config/bashrc/201-yt-dlp"; then
    return 0
  fi

  if ! rm -f "$HOME/.config/bashrc/201-yt-dlp"; then
    return 1
  fi
  if ! mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc"; then
    return 1
  fi
  if ! replace_file \
    "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/201-yt-dlp" \
    "$HOME/.local/share/gallaecia-dots/bashrc/201-yt-dlp"; then
    return 1
  fi
}

# Actualiza os helpers compartidos de ficheiros e aplicacións.
update_helpers_modules() {
  if ! mkdir -p "$HOME/.local/share/gallaecia-dots/scripts/modules"; then
    return 1
  fi
  if ! replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/files.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/modules/files.sh"; then
    return 1
  fi
  if ! replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/apps.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/modules/apps.sh"; then
    return 1
  fi
}

# Actualiza o Bashrc principal controlado polo proxecto.
update_main_bashrc() {
  replace_file "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
}

# Mostra o resumo visible dos cambios incluídos na migración.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Mellorados os comandos de yt-dlp."
}

# Executa cada cambio da migración e detense no primeiro erro.
apply_update() {
  if ! migrate_yt_dlp_bash_module; then
    return 1
  fi
  if ! update_helpers_modules; then
    return 1
  fi
  if ! update_main_bashrc; then
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
