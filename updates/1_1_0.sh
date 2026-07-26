#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.1.0"
DOTFILES_DIR="$HOME/.dotfiles"
MODULES_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules"

if [ ! -r "$MODULES_DIR/ui.sh" ] ||
  [ ! -r "$MODULES_DIR/commands.sh" ] ||
  [ ! -r "$MODULES_DIR/files.sh" ] ||
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
  if ! sudo systemctl enable docker.service; then
    return 1
  fi
  if ! sudo usermod -aG docker "$USER"; then
    return 1
  fi
}

# Instala os helpers interactivos de Git no directorio controlado por Gallaecia.
configure_git() {
  if ! mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc"; then
    return 1
  fi
  if ! replace_file \
    "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/203-git" \
    "$HOME/.local/share/gallaecia-dots/bashrc/203-git"; then
    return 1
  fi
}

# Instala os helpers interactivos de Docker no directorio controlado por Gallaecia.
configure_docker() {
  if ! mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc"; then
    return 1
  fi
  if ! replace_file \
    "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/204-docker" \
    "$HOME/.local/share/gallaecia-dots/bashrc/204-docker"; then
    return 1
  fi
}

# Actualiza os módulos internos e reutilizables empregados polos scripts.
update_helpers_modules() {
  local module_name

  if ! mkdir -p "$HOME/.local/share/gallaecia-dots/scripts/modules"; then
    return 1
  fi

  for module_name in ui files commands apps versions; do
    if ! replace_file \
      "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/$module_name.sh" \
      "$HOME/.local/share/gallaecia-dots/scripts/modules/$module_name.sh"; then
      return 1
    fi
  done
}

# Actualiza yt-dlp e SpotDL só cando o comando correspondente está instalado.
update_bash_modules() {
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
}

# Instala a versión máis recente do actualizador interactivo do sistema.
update_system_update() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/system-update.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/system-update.sh"
}

# Instala Git e GitHub CLI, verifica os paquetes e engade os seus helpers.
install_git_tools() {
  if ! yay -Syu --needed git github-cli; then
    return 1
  fi
  if ! is_pkg_installed git || ! is_pkg_installed github-cli; then
    warning "Git ou GitHub CLI non quedaron instalados correctamente."
    return 1
  fi
  if ! configure_git; then
    return 1
  fi
}

# Instala Docker, verifica os paquetes e prepara o servizo e os helpers.
install_docker_tools() {
  if ! yay -Syu --needed docker docker-compose docker-buildx; then
    return 1
  fi
  if ! is_pkg_installed docker ||
    ! is_pkg_installed docker-compose ||
    ! is_pkg_installed docker-buildx; then
    warning "Docker, Compose ou Buildx non quedaron instalados correctamente."
    return 1
  fi
  if ! install_docker; then
    return 1
  fi
  if ! configure_docker; then
    return 1
  fi
}

# Mostra o resumo visible dos cambios incluídos na migración.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Engadidos Git e GitHub CLI con funcións interactivas."
  info "· Engadidos Docker, Docker Compose e Docker Buildx con funcións interactivas."
  info "· Engadida axuda e parámetros avanzados aos helpers reutilizables."
  info "· Engadida axuda e parámetros avanzados aos módulos Bash (yt-dlp, SpotDL...)."
  info "· Arreglado un bug no script de actualización do sistema."
}

# Executa cada cambio da migración e detense no primeiro erro.
apply_update() {
  if ! update_helpers_modules; then
    return 1
  fi
  if ! update_bash_modules; then
    return 1
  fi
  if ! update_system_update; then
    return 1
  fi

  if gum_confirm "Queres instalar e configurar Git + GitHub CLI?"; then
    if ! install_git_tools; then
      return 1
    fi
  fi

  if gum_confirm "Queres instalar e configurar Docker, Docker Compose e Docker Buildx? (Non elimina contedores existentes)"; then
    if ! install_docker_tools; then
      return 1
    fi
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
