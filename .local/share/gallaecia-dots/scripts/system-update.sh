#!/usr/bin/env bash

set -u
set -o pipefail

# shellcheck source=/dev/null
source "$HOME/.local/share/gallaecia-dots/scripts/modules/ui.sh"
# shellcheck source=/dev/null
source "$HOME/.local/share/gallaecia-dots/scripts/modules/commands.sh"

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
INSTALLER="$DOTFILES_DIR/install.sh"
REPO_BRANCH="${1:-${REPO_BRANCH:-release}}"

# Mostra o logo se o script visual existe e é executable.
show_logo() {
  local logo_script="$HOME/.local/share/gallaecia-dots/scripts/gallaecia.sh"

  if [ -x "$logo_script" ]; then
    "$logo_script"
  fi
}

# Comproba se o repo local existe e é un clon git válido.
has_dotfiles_repo() {
  git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree &> /dev/null &&
    [ -r "$INSTALLER" ]
}

dotfiles_repo_problem() {
  if [ ! -d "$DOTFILES_DIR" ]; then
    printf 'Non existe %s.' "$DOTFILES_DIR"
    return
  fi

  if ! git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree &> /dev/null; then
    printf '%s existe, pero Git non o recoñece como repo.' "$DOTFILES_DIR"
    return
  fi

  if [ ! -r "$INSTALLER" ]; then
    printf 'O repo existe, pero non se pode ler %s.' "$INSTALLER"
    return
  fi

  printf 'Non se puido validar %s.' "$DOTFILES_DIR"
}

# Trae a info remota antes de comprobar se hai actualizacións.
fetch_dotfiles_updates() {
  git -C "$DOTFILES_DIR" fetch --quiet origin "$REPO_BRANCH"
}

# Asegura que a actualización se aplica sobre a rama esperada.
checkout_dotfiles_branch() {
  if git -C "$DOTFILES_DIR" show-ref --verify --quiet "refs/heads/$REPO_BRANCH"; then
    git -C "$DOTFILES_DIR" switch "$REPO_BRANCH"
    return
  fi

  git -C "$DOTFILES_DIR" switch --track -c "$REPO_BRANCH" "origin/$REPO_BRANCH"
}

# Devolve éxito se o repo local está por detrás da rama remota.
dotfiles_need_update() {
  local local_head remote_head

  local_head="$(git -C "$DOTFILES_DIR" rev-parse HEAD)"
  remote_head="$(git -C "$DOTFILES_DIR" rev-parse "origin/$REPO_BRANCH")"

  [ "$local_head" != "$remote_head" ]
}

# Avisa se hai cambios locais que Git gardará temporalmente durante o pull.
warn_dirty_repo() {
  if [ -n "$(git -C "$DOTFILES_DIR" status --porcelain)" ]; then
    warning "Hai cambios locais en $DOTFILES_DIR. Git tentará conservalos mediante autostash."
    return 0
  fi

  return 1
}

# Actualiza o repo cando fai falta e comproba sempre as migracións pendentes.
update_dotfiles() {
  title "Actualizar dotfiles"

  if ! has_dotfiles_repo; then
    local repo_problem

    repo_problem="$(dotfiles_repo_problem)"
    warning "$repo_problem Saltando actualización dos dotfiles."
    return 0
  fi

  if ! fetch_dotfiles_updates; then
    fail "Non se puido comprobar se hai updates nos dotfiles."
    return 1
  fi

  if dotfiles_need_update; then
    if warn_dirty_repo; then
      echo
    fi

    if ! gum_confirm "Hai updates novos nos dotfiles. Queres actualizalos e relanzar o instalador?"; then
      info "Actualización dos dotfiles cancelada."
      return 0
    fi

    title "Actualizando repo de dotfiles"

    if ! checkout_dotfiles_branch ||
      ! git -C "$DOTFILES_DIR" pull --ff-only --autostash origin "$REPO_BRANCH"; then
      fail "Non se puido actualizar o repo de dotfiles."
      return 1
    fi
  else
    info "Os dotfiles xa están actualizados."
  fi

  info "Comprobando actualizacións pendentes..."
  if ! SKIP_CLONE=1 REPO_BRANCH="$REPO_BRANCH" INSTALL_MODE="update" bash "$INSTALLER"; then
    warning "Non se completaron todas as actualizacións dos dotfiles."
    return 1
  fi

  echo
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

  if ! update_dotfiles; then
    fail "Algo fallou ao actualizar os dotfiles."
    return 1
  fi

  echo

  if gum_confirm "Reiniciar sistema? (Recomendado se se actualizaron paquetes)"; then
    systemctl reboot
  fi
}

main "$@"
