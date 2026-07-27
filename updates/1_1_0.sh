#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.1.0"
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

# Habilita o servizo global de Docker e engade o usuario actual ao grupo.
# O acceso sen sudo faise efectivo normalmente no seguinte inicio de sesión.
install_docker() {
  if ! sudo systemctl enable docker.service; then
    return 1
  fi
  if ! sudo usermod -aG docker "$USER"; then
    return 1
  fi
}

# Garante a área Bash opcional e instala nela o módulo de comandos Git.
# Non configura identidade, credenciais nin repositorios por si mesmo.
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

# Garante a área Bash opcional e instala o módulo de Docker/Compose.
# A preparación do daemon e do grupo realízase por separado en `install_docker`.
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

# Percorre a lista pechada de módulos introducidos nesta versión e substitúe cada
# ficheiro controlado. Detense se algunha copia falla para non mesturar APIs.
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

# Garante a área opcional e actualiza cada wrapper só se a aplicación existe.
# Así non activa comandos dunha app que o usuario non instalara previamente.
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

# Substitúe o actualizador do sistema pola versión compatible cos novos módulos.
# Non executa ningunha actualización durante esta copia.
update_system_update() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/system-update.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/system-update.sh"
}

# Instala Git/GitHub CLI, comproba o estado local dos dous paquetes e só entón
# engade o módulo Bash. Unha verificación fallida propágase como erro.
install_git_tools() {
  if ! yay -Syu --needed git github-cli; then
    return 1
  fi
  if ! has_package --manager yay git ||
    ! has_package --manager yay github-cli; then
    warning "Git ou GitHub CLI non quedaron instalados correctamente."
    return 1
  fi
  if ! configure_git; then
    return 1
  fi
}

# Instala Docker, Compose e Buildx; verifica cada paquete e configura servizo,
# grupo e módulo Bash. Cada fase depende do éxito da anterior.
install_docker_tools() {
  if ! yay -Syu --needed docker docker-compose docker-buildx; then
    return 1
  fi
  if ! has_package --manager yay docker ||
    ! has_package --manager yay docker-compose ||
    ! has_package --manager yay docker-buildx; then
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

# Presenta todas as capacidades novas antes da confirmación principal.
# As preguntas opcionais de Git e Docker aparecen máis tarde en `apply_update`.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Engadidos Git e GitHub CLI con funcións interactivas."
  info "· Engadidos Docker, Docker Compose e Docker Buildx con funcións interactivas."
  info "· Engadida axuda e parámetros avanzados aos helpers reutilizables."
  info "· Engadida axuda e parámetros avanzados aos módulos Bash (yt-dlp, SpotDL...)."
  info "· Arreglado un bug no script de actualización do sistema."
}

# Actualiza primeiro a infraestrutura común e pregunta despois polas ferramentas
# opcionais. Rexeitar Git ou Docker é válido; aceptar e fallar detén a migración.
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

# Mostra o changelog, confirma o conxunto e executa o orquestrador.
# Cancelar ou fallar evita que o instalador marque esta versión.
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
