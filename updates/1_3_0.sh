#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.3.0"
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

# Substitúe o módulo público que incorpora `run-terminal-as`. As shells xa
# abertas recibirán a función ao volver cargar o Bashrc ou abrir unha nova.
update_commands_module() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/commands.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/modules/commands.sh"
}

# Instala o punto de entrada usado por procesos gráficos que non cargan as
# funcións do Bashrc e conserva o permiso executable do ficheiro controlado.
install_terminal_runner() {
  if ! replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/run-terminal-as.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/run-terminal-as.sh"; then
    return 1
  fi

  chmod +x "$HOME/.local/share/gallaecia-dots/scripts/run-terminal-as.sh"
}

# Actualiza unicamente a base compartida e controlada de Hyprland. O wrapper
# persoal de ~/.config/hypr permanece intacto.
update_hyprland_base() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/hypr/gallaecia.lua" \
    "$HOME/.local/share/gallaecia-dots/hypr/gallaecia.lua"
}

# Substitúe a configuración base de Noctalia para que o botón chame directamente
# o lanzador, sen crear antes unha terminal intermedia. Non toca custom.toml.
update_noctalia_config() {
  replace_file \
    "$DOTFILES_DIR/.config/noctalia/gallaecia.toml" \
    "$HOME/.config/noctalia/gallaecia.toml"
}

# Resume os cambios antes de modificar as instalacións existentes.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Engadido run-terminal-as para abrir comandos cun app_id estable."
  info "· O actualizador ábrese nunha única terminal flotante e centrada."
  info "· Kitty, Alacritty, Foot, Ghostty e WezTerm usan o mesmo identificador."
}

# Instala primeiro a API e o seu entrypoint e activa despois os consumidores.
apply_update() {
  if ! update_commands_module; then
    return 1
  fi
  if ! install_terminal_runner; then
    return 1
  fi
  if ! update_hyprland_base; then
    return 1
  fi
  if ! update_noctalia_config; then
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
