#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.1.2"
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

# Actualiza os módulos compartidos co novo formato de axuda e interface.
update_shared_modules() {
  local module

  for module in apps commands files ui versions; do
    if ! replace_file \
      "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/$module.sh" \
      "$HOME/.local/share/gallaecia-dots/scripts/modules/$module.sh"; then
      return 1
    fi
  done
}

# Actualiza o fluxo do sistema para aproveitar o novo espazado común.
update_system_update() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/system-update.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/system-update.sh"
}

# Actualiza os Bashrc opcionais nos que se retiraron saltos redundantes.
update_optional_bash_modules() {
  if ! mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc"; then
    return 1
  fi

  if has_command yt-dlp; then
    if ! replace_file \
      "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/201-yt-dlp" \
      "$HOME/.local/share/gallaecia-dots/bashrc/201-yt-dlp"; then
      return 1
    fi
  fi

  if has_command spotdl; then
    if ! replace_file \
      "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/202-spotdl" \
      "$HOME/.local/share/gallaecia-dots/bashrc/202-spotdl"; then
      return 1
    fi
  fi

  if has_command git; then
    if ! replace_file \
      "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/203-git" \
      "$HOME/.local/share/gallaecia-dots/bashrc/203-git"; then
      return 1
    fi
  fi

  if has_command docker; then
    if ! replace_file \
      "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/204-docker" \
      "$HOME/.local/share/gallaecia-dots/bashrc/204-docker"; then
      return 1
    fi
  fi
}

# Mostra o resumo visible dos cambios incluídos na migración.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Centralizado o espazado visual nos helpers de gum."
  info "· Eliminados saltos redundantes nos instaladores e comandos opcionais."
  info "· As seleccións e inputs seguen devolvendo stdout sen liñas adicionais."
  info "· Ampliadas e unificadas as axudas dos comandos e helpers."
  info "· Estandarizado o formato de todas as migracións."
}

# Executa cada cambio da migración e detense no primeiro erro.
apply_update() {
  if ! update_shared_modules; then
    return 1
  fi
  if ! update_system_update; then
    return 1
  fi
  if ! update_optional_bash_modules; then
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
