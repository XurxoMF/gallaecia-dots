#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.3.6"
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
  [ ! -r "$INTERNAL_DIR/mode.sh" ] ||
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
source "$INTERNAL_DIR/mode.sh"
# shellcheck source=/dev/null
source "$INTERNAL_DIR/versions.sh"

# Substitúe a libraría interna controlada para que `gallaecia install-category`
# deixe de instalar boydaihungst/restore nas instalacións xa existentes.
update_internal_apps_library() {
  if ! ensure_directory "$HOME/.local/share/gallaecia-dots/scripts/internal"; then
    return 1
  fi

  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/internal/apps.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/internal/apps.sh"
}

# Actualiza a configuración xeral de Yazi só cando conserva exactamente a
# versión distribuída por Gallaecia. Un ficheiro personalizado queda intacto.
update_yazi_config() {
  local source_file="$DOTFILES_DIR/optional/.config/yazi/yazi.toml"
  local target_file="$HOME/.config/yazi/yazi.toml"
  local old_checksum="1adca0ddd8433fe8a314cae1d6bd64ecfc9d8b30da6aac251e083600c2a705e3"
  local current_checksum

  if ! has_command yazi; then
    return 0
  fi
  if ! ensure_directory "$HOME/.config/yazi"; then
    return 1
  fi
  if [ ! -f "$target_file" ]; then
    if ! replace_file "$source_file" "$target_file"; then
      return 1
    fi
    return 0
  fi
  if files_equal "$source_file" "$target_file"; then
    return 0
  fi

  current_checksum="$(sha256sum "$target_file" | cut -d ' ' -f1)" || return 1
  if [ "$current_checksum" = "$old_checksum" ]; then
    if ! replace_file "$source_file" "$target_file"; then
      return 1
    fi
    return 0
  fi

  warning "Conservouse o yazi.toml personalizado; revisa manualmente as novidades de Yazi 26.8.15."
  return 0
}

# Actualiza o mapa de teclas só cando segue sendo o distribuído na versión
# anterior. Así non se pisan atallos persoais dunha instalación existente.
update_yazi_keymap() {
  local source_file="$DOTFILES_DIR/optional/.config/yazi/keymap.toml"
  local target_file="$HOME/.config/yazi/keymap.toml"
  local old_checksum="adcfdb693128cac11a766e1161b642fc3891bd373ebb9b26323e5c7a17219cfb"
  local current_checksum

  if ! has_command yazi; then
    return 0
  fi
  if ! ensure_directory "$HOME/.config/yazi"; then
    return 1
  fi
  if [ ! -f "$target_file" ]; then
    if ! replace_file "$source_file" "$target_file"; then
      return 1
    fi
    return 0
  fi
  if files_equal "$source_file" "$target_file"; then
    return 0
  fi

  current_checksum="$(sha256sum "$target_file" | cut -d ' ' -f1)" || return 1
  if [ "$current_checksum" = "$old_checksum" ]; then
    if ! replace_file "$source_file" "$target_file"; then
      return 1
    fi
    return 0
  fi

  warning "Conservouse o keymap.toml personalizado; revisa manualmente as novidades de Yazi 26.8.15."
  return 0
}

# Retira o antigo plugin de restauración, substituído polo lixo integrado de
# Yazi 26.8.15. Consulta primeiro o manifesto para que a ausencia sexa válida.
remove_legacy_yazi_restore_plugin() {
  local package_file="$HOME/.config/yazi/package.toml"

  if ! has_command yazi || ! has_command ya; then
    return 0
  fi
  if [ ! -f "$package_file" ]; then
    return 0
  fi
  if ! grep -Fq 'use = "boydaihungst/restore"' "$package_file"; then
    return 0
  fi

  ya pkg delete boydaihungst/restore
}

# Resume os cambios antes de modificar as instalacións existentes.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Configuración de Yazi actualizada para a versión 26.8.15."
  info "· Engadidos o lixo integrado, a creación múltiple e o historial das entradas."
  info "· Actualizados os atallos de copia, movemento e axuda."
  info "· Actualizada a libraría interna de aplicacións de Gallaecia."
  info "· Retirado o antigo plugin boydaihungst/restore."
  info "· As configuracións persoalizadas de Yazi consérvanse sen substituír."
}

# Actualiza os ficheiros distribuídos e retira despois o plugin xa obsoleto.
apply_update() {
  if ! update_internal_apps_library; then
    return 1
  fi
  if ! update_yazi_config; then
    return 1
  fi
  if ! update_yazi_keymap; then
    return 1
  fi
  if ! remove_legacy_yazi_restore_plugin; then
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
