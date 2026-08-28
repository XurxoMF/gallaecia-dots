#!/usr/bin/env bash

set -u
set -o pipefail

###############################################################################
# ACTUALIZADOR INTERACTIVO DO SISTEMA
#
# É o fluxo que abre o botón de Noctalia no escritorio ou `gallaecia update` en
# calquera modo. Cada xestor ou ferramenta instalada ofrece o seu bloque:
#
#   Rust -> Yay/Pacman -> Flatpak -> Yazi -> pipx -> dotfiles -> reinicio
#
# A parte de dotfiles reutiliza `gallaecia _sync-repo`. Despois executa
# install.sh en modo update para aplicar só as migracións pendentes.
###############################################################################

# shellcheck source=/dev/null
source "$HOME/.local/share/gallaecia-dots/scripts/modules/ui.sh"
# shellcheck source=/dev/null
source "$HOME/.local/share/gallaecia-dots/scripts/modules/commands.sh"
# shellcheck source=/dev/null
source "$HOME/.local/share/gallaecia-dots/scripts/modules/gallaecia.sh"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
INSTALLER="$DOTFILES_DIR/install.sh"

# Comproba se o helper visual instalado existe e, nese caso, execútao.
# A ausencia do logo non bloquea a actualización nin produce un erro.
show_logo() {
  local logo_script="$HOME/.local/share/gallaecia-dots/scripts/gallaecia.sh"

  if [ -x "$logo_script" ]; then
    "$logo_script"
  fi
}

# Clona ou actualiza o repo e comproba sempre as migracións pendentes.
# O código 2 de `_sync-repo` significa cancelación do usuario: non é un erro e
# tampouco se lanza o instalador. Outros erros deteñen este bloque.
update_dotfiles() {
  local sync_status

  title "Actualizar dotfiles"

  gallaecia _sync-repo --confirm
  sync_status=$?

  if [ "$sync_status" -eq 2 ]; then
    return 0
  fi
  if [ "$sync_status" -ne 0 ]; then
    warning "Non se puideron sincronizar os dotfiles."
    return 1
  fi

  if [ ! -r "$INSTALLER" ]; then
    warning "Non se atopou o instalador en $INSTALLER."
    return 1
  fi

  info "Comprobando actualizacións pendentes..."
  if ! SKIP_CLONE=1 INSTALL_MODE="update" bash "$INSTALLER"; then
    warning "Non se completaron todas as actualizacións dos dotfiles."
    return 1
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

# Se Yay existe, actualiza nunha soa operación paquetes oficiais, AUR e paquetes
# de desenvolvemento. Se falta, informa e devolve éxito para continuar co resto.
update_arch() {
  if has_command yay; then
    title "Actualizando pacman e AUR..."
    yay -Syu --devel
  else
    warning "YAY non está instalado. Saltando actualización de pacman e AUR."
  fi
}

# Se Flatpak está dispoñible, solicita ao xestor actualizar todas as instalacións.
# A ausencia de Flatpak só mostra un aviso porque este ecosistema é opcional.
update_flatpak() {
  if has_command flatpak; then
    title "Actualizando Flatpak..."
    flatpak update
  else
    warning "Flatpak non está instalado. Saltando actualización de Flatpak."
  fi
}

# Actualiza os plugins de Yazi. O fluxo principal só ofrece este bloque cando
# están dispoñibles tanto Yazi como o seu xestor `ya`.
update_yazi_plugins() {
  title "Actualizando plugins de Yazi..."
  ya pkg upgrade
}

# Se pipx está dispoñible, actualiza todos os contornos xestionados por el.
# A ausencia de pipx só mostra un aviso porque este ecosistema é opcional.
update_pipx() {
  if has_command pipx; then
    title "Actualizando paquetes de pipx..."
    pipx upgrade-all
  else
    warning "pipx non está instalado. Saltando actualización de paquetes de pipx."
  fi
}

# Pregunta por cada bloque na orde visible. Rexeitalo continúa co seguinte;
# aceptalo e obter un erro detén o fluxo para non ocultar unha actualización
# incompleta.
main() {
  show_logo

  if has_command rustup; then
    if confirm "Actualizar Rust?"; then
      if update_rust; then
        success "Rust actualizado con éxito!"
      else
        fail "Algo fallou ao actualizar Rust!"
      fi
    fi
  fi

  if has_command yay; then
    if confirm "Actualizar pacman e AUR?"; then
      if update_arch; then
        success "Pacman e AUR actualizados con éxito!"
      else
        fail "Algo fallou ao actualizar pacman e AUR!"
      fi
    fi
  fi

  if has_command flatpak; then
    if confirm "Actualizar Flatpak?"; then
      if update_flatpak; then
        success "Flatpak actualizado con éxito!"
      else
        fail "Algo fallou ao actualizar Flatpak!"
      fi
    fi
  fi

  if has_command yazi && has_command ya; then
    if confirm "Actualizar plugins de Yazi?"; then
      if update_yazi_plugins; then
        success "Plugins de Yazi actualizados con éxito!"
      else
        fail "Algo fallou ao actualizar os plugins de Yazi!"
      fi
    fi
  fi

  if has_command pipx; then
    if confirm "Actualizar paquetes de pipx?"; then
      if update_pipx; then
        success "Paquetes de pipx actualizados con éxito!"
      else
        fail "Algo fallou ao actualizar os paquetes de pipx!"
      fi
    fi
  fi

  if ! update_dotfiles; then
    fail "Algo fallou ao actualizar os dotfiles."
    return 1
  fi

  if confirm "Reiniciar sistema? (Recomendado se se actualizaron paquetes)"; then
    systemctl reboot
  fi
}

main "$@"
