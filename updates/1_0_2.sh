#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.0.2"
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

# Garante a área de módulos e substitúe `ui.sh` pola versión corrixida.
# O ficheiro é controlado polo proxecto e pode actualizarse con seguridade.
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

# Garante a área de Noctalia e substitúe o template que produce as variables de
# cor consumidas polo módulo UI; non modifica a paleta persoal directamente.
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

# Só cando yt-dlp e o módulo opcional existen, substitúe ese módulo pola versión
# compatible coa nova interface. Non instala yt-dlp nin activa unha app non elixida.
update_yt_dlp_bash_module() {
  if ! has_package --manager yay yt-dlp ||
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

# Imprime a versión e os cambios de UI/yt-dlp antes de pedir confirmación.
# É unha operación unicamente informativa.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Corrixido gum_input para usar só opcións soportadas por gum."
  info "· Actualizado o template de cores de Noctalia para gum input."
  info "· Actualizados os comandos interactivos de yt-dlp."
}

# Actualiza módulo, template e integración opcional en orde.
# Calquera fallo devolve 1 e evita rexistrar unha actualización incompleta.
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

# Presenta o changelog, require confirmación e executa o orquestrador.
# A cancelación e os erros rematan o script sen marcar a versión.
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
