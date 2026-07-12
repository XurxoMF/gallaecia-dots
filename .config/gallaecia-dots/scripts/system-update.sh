#!/usr/bin/env bash

set -u
set -o pipefail

# shellcheck source=/dev/null
source "$HOME/.config/gallaecia-dots/scripts/modules/ui.sh"
# shellcheck source=/dev/null
source "$HOME/.config/gallaecia-dots/scripts/modules/commands.sh"

show_logo() {
  local logo_script="$HOME/.config/gallaecia-dots/scripts/gallaecia.sh"

  if [ -x "$logo_script" ]; then
    "$logo_script"
  fi
}

update_rust() {
  if has_command rustup; then
    title "Actualizando Rust..."
    rustup update
  else
    warning "Rustup non está instalado. Saltando actualización de Rust."
  fi
}

update_arch() {
  if has_command yay; then
    title "Actualizando pacman e AUR..."
    yay -Syu --devel
  else
    warning "YAY non está instalado. Saltando actualización de pacman e AUR."
  fi
}

update_flatpak() {
  if has_command flatpak; then
    title "Actualizando Flatpak..."
    flatpak update
  else
    warning "Flatpak non está instalado. Saltando actualización de Flatpak."
  fi
}

update_yazi_plugins() {
  if has_command yazi && has_command ya; then
    title "Actualizando plugins de Yazi..."
    ya pkg upgrade
  else
    warning "Yazi non está instalado. Saltando actualización de plugins de Yazi."
  fi
}

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
