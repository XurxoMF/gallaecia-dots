#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.1.2"
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

# Substitúe comandos, ficheiros e UI como unha unidade para manter compatible a
# súa nova convención de axuda, passthrough e espazado.
update_shared_modules() {
  local module

  for module in commands files ui; do
    if ! replace_file \
      "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/$module.sh" \
      "$HOME/.local/share/gallaecia-dots/scripts/modules/$module.sh"; then
      return 1
    fi
  done
}

# Substitúe o actualizador que deixa a separación visual nos wrappers de UI.
# Non executa tarefas de mantemento durante a migración.
update_system_update() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/system-update.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/system-update.sh"
}

# Actualiza cada módulo opcional só cando o seu executable está dispoñible.
# Mantén así as eleccións do usuario e evita instalar integracións non solicitadas.
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

# Explica a unificación de interface, axudas e formato dos scripts.
# Non modifica ficheiros ata recibir confirmación.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Centralizado o espazado visual nos helpers de gum."
  info "· Eliminados saltos redundantes nos instaladores e comandos opcionais."
  info "· As seleccións e inputs seguen devolvendo stdout sen liñas adicionais."
  info "· Ampliadas e unificadas as axudas dos comandos e helpers."
  info "· Estandarizado o formato de todas as migracións."
}

# Actualiza en orde API pública, consumidor do sistema e módulos opcionais.
# Calquera erro detén a cadea e deixa a versión pendente.
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

# Presenta, confirma e aplica a migración completa.
# A cancelación e os fallos devólvense ao instalador como erro.
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
