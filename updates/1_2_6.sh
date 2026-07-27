#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.2.6"
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

# Reinicia unha única vez o daemon da sesión para que volva crear o chaveiro
# `login.keyring`. Non habilita o servizo: o arranque habitual segue dependendo
# do socket global do paquete e do desbloqueo realizado por PAM.
restart_gnome_keyring_daemon() {
  systemctl --user restart gnome-keyring-daemon.service
}

# Fixa `Login` como chaveiro predeterminado para Secret Service sen substituír
# os demais chaveiros que poida ter o usuario.
install_default_keyring() {
  replace_file \
    "$DOTFILES_DIR/.local/share/keyrings/default" \
    "$HOME/.local/share/keyrings/default"
}

# Actualiza os comandos de Git só cando a ferramenta xa está instalada.
update_git_commands() {
  if ! has_command git; then
    return 0
  fi

  replace_file \
    "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/203-git" \
    "$HOME/.local/share/gallaecia-dots/bashrc/203-git"
}

# Actualiza os comandos de yt-dlp só cando a ferramenta xa está instalada.
update_yt_dlp_commands() {
  if ! has_command yt-dlp; then
    return 0
  fi

  replace_file \
    "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/201-yt-dlp" \
    "$HOME/.local/share/gallaecia-dots/bashrc/201-yt-dlp"
}

# Actualiza os comandos de SpotDL só cando a ferramenta xa está instalada.
update_spotdl_commands() {
  if ! has_command spotdl; then
    return 0
  fi

  replace_file \
    "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/202-spotdl" \
    "$HOME/.local/share/gallaecia-dots/bashrc/202-spotdl"
}

# Resume os cambios antes de modificar as instalacións existentes.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· GNOME Keyring reiníciase para rexenerar o chaveiro Login."
  info "· Login queda configurado como chaveiro predeterminado."
  info "· Os comandos opcionais de Git, yt-dlp e SpotDL usan nomes en inglés."
}

# Rexenera primeiro o chaveiro e configura despois a selección predeterminada.
apply_update() {
  if ! restart_gnome_keyring_daemon; then
    return 1
  fi
  if ! install_default_keyring; then
    return 1
  fi
  if ! update_git_commands; then
    return 1
  fi
  if ! update_yt_dlp_commands; then
    return 1
  fi
  if ! update_spotdl_commands; then
    return 1
  fi
}

# Presenta o changelog, confirma e executa o orquestrador.
# Só un éxito completo permite ao instalador marcar a versión como aplicada.
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
