#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.0.1"
DOTFILES_DIR="$HOME/.dotfiles"
MODULES_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules"
INTERNAL_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/internal"

if [ ! -r "$MODULES_DIR/apps.sh" ] ||
  [ ! -r "$MODULES_DIR/commands.sh" ] ||
  [ ! -r "$MODULES_DIR/files.sh" ] ||
  [ ! -r "$MODULES_DIR/gallaecia.sh" ] ||
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
source "$MODULES_DIR/ui.sh"
# shellcheck source=/dev/null
source "$INTERNAL_DIR/apps.sh"
# shellcheck source=/dev/null
source "$INTERNAL_DIR/versions.sh"

# Se yt-dlp e o módulo antigo existen, retírao de `~/.config/bashrc` e instala a
# versión nova na área opcional controlada por Gallaecia; noutro caso non actúa.
migrate_yt_dlp_bash_module() {
  if ! has_package --manager yay yt-dlp ||
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

# Crea as dúas áreas de scripts e substitúe o módulo público de ficheiros e a
# libraría interna de aplicacións necesaria para os seguintes fluxos.
update_helpers_modules() {
  if ! mkdir -p \
    "$HOME/.local/share/gallaecia-dots/scripts/modules" \
    "$HOME/.local/share/gallaecia-dots/scripts/internal"; then
    return 1
  fi
  if ! replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/files.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/modules/files.sh"; then
    return 1
  fi
  if ! replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/internal/apps.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/internal/apps.sh"; then
    return 1
  fi
}

# Substitúe o `.bashrc` principal pola versión que carga a nova área opcional.
# Non modifica os módulos personalizados dentro de `~/.config/bashrc`.
update_main_bashrc() {
  replace_file "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
}

# Imprime a versión e o resumo que o usuario revisa antes de confirmar.
# Non modifica ficheiros nin marca a migración como instalada.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Mellorados os comandos de yt-dlp."
}

# Executa os tres pasos en orde e devolve 1 no primeiro fallo.
# O instalador só rexistrará a versión cando este orquestrador devolva 0.
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

# Mostra o changelog, pide confirmación e comunica o resultado final.
# Cancelar ou fallar termina con erro para impedir que se marque a versión.
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
