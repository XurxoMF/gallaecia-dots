#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.4.0"
DOTFILES_DIR="$HOME/.dotfiles"
MODULES_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules"
INTERNAL_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/internal"

# Desde 1.4.0 os updates cargan tamén o modo persistente da instalación.
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

# As instalacións anteriores a 1.4.0 eran sempre escritorios. Conserva un modo
# válido se xa existe e crea `desktop` unicamente cando falta o novo estado.
initialize_install_mode() {
  if [ -e "$GALLAECIA_MODE_FILE" ]; then
    get_install_mode > /dev/null
    return
  fi

  set_install_mode desktop
}

# Instala nas rutas controladas as librarías e scripts conscientes do modo.
update_mode_aware_scripts() {
  local module internal_library

  if ! ensure_directory \
    "$HOME/.local/share/gallaecia-dots/scripts/modules" \
    "$HOME/.local/share/gallaecia-dots/scripts/internal"; then
    return 1
  fi

  for module in commands gallaecia; do
    if ! replace_file \
      "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/$module.sh" \
      "$HOME/.local/share/gallaecia-dots/scripts/modules/$module.sh"; then
      return 1
    fi
  done

  for internal_library in apps mode; do
    if ! replace_file \
      "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/internal/$internal_library.sh" \
      "$HOME/.local/share/gallaecia-dots/scripts/internal/$internal_library.sh"; then
      return 1
    fi
  done

  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/system-update.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/system-update.sh"
}

# Ofrece nftables ás instalacións existentes sen retirar nin modificar outros
# firewalls. Aceptar instala o paquete e habilítao só para o seguinte arranque;
# `/etc/nftables.conf` consérvase tal e como estea no sistema.
offer_nftables() {
  if ! confirm "Instalar e habilitar nftables para o seguinte arranque?"; then
    info "nftables non se modificou."
    return 0
  fi

  if ! yay -S --needed nftables; then
    return 1
  fi
  sudo systemctl enable nftables.service
}

# Resume a incorporación dos modos e a opción de firewall antes de actuar.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Engadidos os modos persistentes de escritorio e servidor."
  info "· As instalacións existentes quedan rexistradas como escritorio."
  info "· Engadidas categorías e fluxos específicos para servidores."
  info "· O actualizador ofrece só os xestores e ferramentas que detecta instalados."
  info "· Poderás instalar e habilitar nftables opcionalmente."
}

# Inicializa o modo antes de instalar os consumidores e deixa nftables como
# decisión independente do usuario.
apply_update() {
  if ! initialize_install_mode; then
    return 1
  fi
  if ! update_mode_aware_scripts; then
    return 1
  fi
  if ! offer_nftables; then
    return 1
  fi
}

# Presenta o changelog, confirma e executa o orquestrador completo.
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
