#!/usr/bin/env bash

set -u
set -o pipefail

# shellcheck source=/dev/null
source "$HOME/.local/share/gallaecia-dots/scripts/modules/ui.sh"
# shellcheck source=/dev/null
source "$HOME/.local/share/gallaecia-dots/scripts/modules/commands.sh"

# Mostra o logo se o script visual existe e é executable.
show_logo() {
  local logo_script="$HOME/.local/share/gallaecia-dots/scripts/gallaecia.sh"

  if [ -x "$logo_script" ]; then
    "$logo_script"
  fi
}

# Actualiza Rust só se rustup está instalado.
# Así o updater serve tamén para instalacións onde Rust non se escolleu/usou.
update_rust() {
  if has_command rustup; then
    title "Actualizando Rust..."
    rustup update
  else
    warning "Rustup non está instalado. Saltando actualización de Rust."
  fi
}

# Actualiza paquetes de pacman e AUR mediante yay.
update_arch() {
  if has_command yay; then
    title "Actualizando pacman e AUR..."
    yay -Syu --devel
  else
    warning "YAY non está instalado. Saltando actualización de pacman e AUR."
  fi
}

# Actualiza Flatpaks instalados.
update_flatpak() {
  if has_command flatpak; then
    title "Actualizando Flatpak..."
    flatpak update
  else
    warning "Flatpak non está instalado. Saltando actualización de Flatpak."
  fi
}

# Actualiza plugins de Yazi só se existen yazi e o comando ya.
update_yazi_plugins() {
  if has_command yazi && has_command ya; then
    title "Actualizando plugins de Yazi..."
    ya pkg upgrade
  else
    warning "Yazi non está instalado. Saltando actualización de plugins de Yazi."
  fi
}

# Pregunta por cada bloque de actualización e aborta se falla un bloque aceptado.
main() {
  show_logo

  if gum_confirm "Actualizar Rust?"; then
    if update_rust; then
      success "Rust actualizado con éxito!"
    else
      fail "Algo fallou ao actualizar Rust!"
    fi
  fi

  if gum_confirm "Actualizar pacman e AUR?"; then
    if update_arch; then
      success "Pacman e AUR actualizados con éxito!"
    else
      fail "Algo fallou ao actualizar pacman e AUR!"
    fi
  fi

  if gum_confirm "Actualizar Flatpak?"; then
    if update_flatpak; then
      success "Flatpak actualizado con éxito!"
    else
      fail "Algo fallou ao actualizar Flatpak!"
    fi
  fi

  if gum_confirm "Actualizar plugins de Yazi?"; then
    if update_yazi_plugins; then
      success "Plugins de Yazi actualizados con éxito!"
    else
      fail "Algo fallou ao actualizar os plugins de Yazi!"
    fi
  fi

  if gum_confirm "Reiniciar sistema? (Recomendado se se actualizaron paquetes)"; then
    systemctl reboot
  fi
}

main "$@"
