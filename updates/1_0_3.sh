#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.0.3"
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

# Se SpotDL xa está instalado, copia o wrapper Bash e substitúe a súa configuración.
# Se non existe, omite o paso para respectar a selección previa do usuario.
update_spotdl_config() {
  if ! has_command spotdl; then
    return 0
  fi

  if ! mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc"; then
    return 1
  fi
  if ! replace_file \
    "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/202-spotdl" \
    "$HOME/.local/share/gallaecia-dots/bashrc/202-spotdl"; then
    return 1
  fi
  if ! replace_file \
    "$DOTFILES_DIR/optional/.config/spotdl/config.json" \
    "$HOME/.config/spotdl/config.json"; then
    return 1
  fi
}

# Imprime os cambios específicos de SpotDL que se ofrecen nesta versión.
# Non instala nin modifica nada antes da confirmación.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Engadido o comando interactivo spotdl-musica (se SpotDL está instalado)."
  info "· Actualizada a config de SpotDL."
}

# Delega no único paso opcional e propaga o seu código.
# O éxito tamén inclúe o caso no que SpotDL non estaba instalado.
apply_update() {
  if ! update_spotdl_config; then
    return 1
  fi
}

# Mostra, confirma e aplica a migración; unha cancelación devolve erro.
# Só un resultado completo permite que o instalador rexistre esta versión.
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
