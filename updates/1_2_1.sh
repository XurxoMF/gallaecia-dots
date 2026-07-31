#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.2.1"
DOTFILES_DIR="$HOME/.dotfiles"
MODULES_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules"
INTERNAL_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/internal"

# Todos os updates cargan sempre a API pública e as librarías internas completas.
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

# Retira o arranque directo do servizo creado por versións anteriores de
# Gallaecia. O paquete de Arch mantén habilitado globalmente o socket, mentres
# que PAM recibe o contrasinal de greetd e coordina a creación e o desbloqueo
# de `Login`. A deshabilitación non detén o daemon da sesión actual.
configure_keyring_startup() {
  if ! systemctl --user disable gnome-keyring-daemon.service; then
    return 1
  fi
}

# Explica o único cambio desta corrección antes de modificar os symlinks do
# servizo de usuario. Non detén procesos nin altera os chaveiros persoais.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Corrixida a inicialización do chaveiro Login no primeiro acceso con greetd."
}

# Aplica a corrección nun paso explícito para non marcar a versión se systemd
# non puidese retirar o arranque directo configurado anteriormente.
apply_update() {
  if ! configure_keyring_startup; then
    return 1
  fi
}

# Presenta o changelog, confirma e executa o orquestrador.
# Só un éxito completo permite ao instalador marcar a versión como aplicada.
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
