#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.1.0"
DOTFILES_DIR="$HOME/.dotfiles"
MODULES_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules"

if [ ! -r "$MODULES_DIR/ui.sh" ] ||
  [ ! -r "$MODULES_DIR/commands.sh" ] ||
  [ ! -r "$MODULES_DIR/files.sh" ] ||
  [ ! -r "$MODULES_DIR/versions.sh" ] ||
  [ ! -r "$MODULES_DIR/apps.sh" ]; then
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

# Deixa Docker preparado para arrancar e para usalo sen sudo tras reiniciar.
install_docker() {
  sudo systemctl enable docker.service &&
  sudo usermod -aG docker "$USER"
}

# Instala os helpers interactivos de Git no directorio controlado por Gallaecia.
configure_git() {
  mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" &&
  replace_file \
    "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/203-git" \
    "$HOME/.local/share/gallaecia-dots/bashrc/203-git"
}

# Instala os helpers interactivos de Docker no directorio controlado por Gallaecia.
configure_docker() {
  mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" &&
  replace_file \
    "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/204-docker" \
    "$HOME/.local/share/gallaecia-dots/bashrc/204-docker"
}

# Actualiza os módulos internos e reutilizables empregados polos scripts.
update_helpers_modules() {
  local module_name

  mkdir -p "$HOME/.local/share/gallaecia-dots/scripts/modules" &&
  for module_name in ui files commands apps versions; do
    replace_file \
      "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/$module_name.sh" \
      "$HOME/.local/share/gallaecia-dots/scripts/modules/$module_name.sh" || return 1
  done
}

# Actualiza yt-dlp e SpotDL só cando o comando correspondente está instalado.
update_bash_modules() {
  mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" || return 1

  if has_command yt-dlp; then
    replace_file \
      "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/201-yt-dlp" \
      "$HOME/.local/share/gallaecia-dots/bashrc/201-yt-dlp" || return 1
  fi

  if has_command spotdl; then
    replace_file \
      "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/202-spotdl" \
      "$HOME/.local/share/gallaecia-dots/bashrc/202-spotdl" || return 1
  fi
}

# Instala a versión máis recente do actualizador interactivo do sistema.
update_system_update() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/system-update.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/system-update.sh"
}

# Mostra o resumo visible dos cambios incluídos na migración.
show_changelog() {
  echo
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Engadidos Git e GitHub CLI con funcións interactivas."
  info "· Engadidos Docker, Docker Compose e Docker Buildx con funcións interactivas."
  info "· Engadida axuda e parámetros avanzados aos helpers reutilizables."
  info "· Engadida axuda e parámetros avanzados aos módulos Bash (yt-dlp, SpotDL...)."
  info "· Arreglado un bug no script de actualización do sistema."
  echo
}

# Actualiza os ficheiros comúns e ofrece as novas integracións opcionais.
apply_update() {
  update_helpers_modules &&
  update_bash_modules &&
  update_system_update || return 1

  if gum_confirm "Queres instalar e configurar Git + GitHub CLI?"; then
    if ! yay -Syu --needed git github-cli; then
      return 1
    fi
    if ! is_pkg_installed git || ! is_pkg_installed github-cli; then
      warning "Git ou GitHub CLI non quedaron instalados correctamente."
      return 1
    fi
    configure_git || return 1
  fi

  echo

  if gum_confirm "Queres instalar e configurar Docker, Docker Compose e Docker Buildx? (Non elimina contedores existentes)"; then
    if ! yay -Syu --needed docker docker-compose docker-buildx; then
      return 1
    fi
    if ! is_pkg_installed docker ||
      ! is_pkg_installed docker-compose ||
      ! is_pkg_installed docker-buildx; then
      warning "Docker, Compose ou Buildx non quedaron instalados correctamente."
      return 1
    fi
    install_docker || return 1
    configure_docker || return 1
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
