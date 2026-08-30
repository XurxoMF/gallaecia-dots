#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.4.1"
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

# Copia un ficheiro temático só cando a ruta de destino non existe. Deste xeito
# cada paso conserva tanto temas persoais como ficheiros xerados por Noctalia.
copy_default_theme_file() {
  local source="$1"
  local target="$2"

  if path_exists -- "$target"; then
    return 0
  fi

  copy_file "$source" "$target"
}

# Actualiza a biblioteca de categorías para que futuras seleccións incorporen
# automaticamente os temas distribuídos nesta versión.
update_theming_app_library() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/internal/apps.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/internal/apps.sh"
}

# Instala unha paleta estática inicial para Gum nos dous modos. Se Noctalia xa
# xerou outra ou o usuario a personalizou, a migración non a substitúe.
install_default_ui_colors() {
  copy_default_theme_file \
    "$DOTFILES_DIR/.config/gallaecia-dots/ui-colors.sh" \
    "$HOME/.config/gallaecia-dots/ui-colors.sh"
}

# Actualiza no escritorio a lista de templates dinámicos ofrecidos por
# Noctalia. O ficheiro `gallaecia.toml` está controlado polo proxecto.
update_noctalia_templates() {
  replace_file \
    "$DOTFILES_DIR/.config/noctalia/gallaecia.toml" \
    "$HOME/.config/noctalia/gallaecia.toml"
}

# Instala o tema inicial de Kitty sen sobrescribir un tema ou configuración xa
# existente.
install_kitty_theme() {
  if ! has_package kitty; then
    return 0
  fi
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/kitty/themes/noctalia.conf" \
    "$HOME/.config/kitty/themes/noctalia.conf" || return 1
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/kitty/kitty.conf" \
    "$HOME/.config/kitty/kitty.conf"
}

# Instala o tema inicial de Alacritty só cando faltan os destinos.
install_alacritty_theme() {
  if ! has_package alacritty; then
    return 0
  fi
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/alacritty/themes/noctalia.toml" \
    "$HOME/.config/alacritty/themes/noctalia.toml" || return 1
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/alacritty/alacritty.toml" \
    "$HOME/.config/alacritty/alacritty.toml"
}

# Instala o tema inicial de Foot só cando faltan os destinos.
install_foot_theme() {
  if ! has_package foot; then
    return 0
  fi
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/foot/themes/noctalia" \
    "$HOME/.config/foot/themes/noctalia" || return 1
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/foot/foot.ini" \
    "$HOME/.config/foot/foot.ini"
}

# Instala o tema inicial de Ghostty só cando faltan os destinos.
install_ghostty_theme() {
  if ! has_package ghostty; then
    return 0
  fi
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/ghostty/themes/noctalia" \
    "$HOME/.config/ghostty/themes/noctalia" || return 1
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/ghostty/config" \
    "$HOME/.config/ghostty/config"
}

# Instala o tema inicial de WezTerm só cando faltan os destinos.
install_wezterm_theme() {
  if ! has_package wezterm; then
    return 0
  fi
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/wezterm/colors/Noctalia.toml" \
    "$HOME/.config/wezterm/colors/Noctalia.toml" || return 1
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/wezterm/wezterm.lua" \
    "$HOME/.config/wezterm/wezterm.lua"
}

# Instala o tema inicial de Helix sen modificar configuracións xa existentes.
install_helix_theme() {
  if ! has_package helix; then
    return 0
  fi
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/helix/themes/noctalia.toml" \
    "$HOME/.config/helix/themes/noctalia.toml" || return 1
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/helix/config.toml" \
    "$HOME/.config/helix/config.toml"
}

# Instala o módulo de cores de Neovim e só crea o init mínimo cando falta.
install_neovim_theme() {
  if ! has_package neovim; then
    return 0
  fi
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/nvim/lua/matugen.lua" \
    "$HOME/.config/nvim/lua/matugen.lua" || return 1
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/nvim/init.lua" \
    "$HOME/.config/nvim/init.lua"
}

# Instala o esquema de Micro e só crea a selección mínima cando falta.
install_micro_theme() {
  if ! has_package micro; then
    return 0
  fi
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/micro/colorschemes/noctalia.micro" \
    "$HOME/.config/micro/colorschemes/noctalia.micro" || return 1
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/micro/settings.json" \
    "$HOME/.config/micro/settings.json"
}

# Instala o tema de tmux e só crea o ficheiro que o carga cando falta.
install_tmux_theme() {
  if ! has_package tmux; then
    return 0
  fi
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/tmux/themes/noctalia.conf" \
    "$HOME/.config/tmux/themes/noctalia.conf" || return 1
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/tmux/tmux.conf" \
    "$HOME/.config/tmux/tmux.conf"
}

# Instala o tema de btop e só crea a selección mínima cando falta.
install_btop_theme() {
  if ! has_package btop; then
    return 0
  fi
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/btop/themes/noctalia.theme" \
    "$HOME/.config/btop/themes/noctalia.theme" || return 1
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/btop/btop.conf" \
    "$HOME/.config/btop/btop.conf"
}

# Instala os dous ficheiros do flavor de Yazi sen sobrescribir o flavor actual.
install_yazi_theme() {
  if ! has_package yazi; then
    return 0
  fi
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/yazi/flavors/noctalia.yazi/flavor.toml" \
    "$HOME/.config/yazi/flavors/noctalia.yazi/flavor.toml" || return 1
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/yazi/flavors/noctalia.yazi/tmtheme.xml" \
    "$HOME/.config/yazi/flavors/noctalia.yazi/tmtheme.xml" || return 1
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/yazi/theme.toml" \
    "$HOME/.config/yazi/theme.toml"
}

# Instala o tema xerado de OpenCode se a aplicación está presente.
install_opencode_theme() {
  if ! has_package opencode; then
    return 0
  fi
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/opencode/themes/matugen.json" \
    "$HOME/.config/opencode/themes/matugen.json" || return 1
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/opencode/tui.json" \
    "$HOME/.config/opencode/tui.json"
}

# Instala o tema xerado de OBS Studio se a aplicación está presente.
install_obs_theme() {
  if ! has_package obs-studio; then
    return 0
  fi
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/obs-studio/themes/matugen.obt" \
    "$HOME/.config/obs-studio/themes/matugen.obt"
}

# Instala o tema importable de Telegram se a aplicación está presente.
install_telegram_theme() {
  if ! has_package telegram-desktop; then
    return 0
  fi
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/telegram-desktop/themes/noctalia.tdesktop-theme" \
    "$HOME/.config/telegram-desktop/themes/noctalia.tdesktop-theme"
}

# Instala o tema de Zathura e só crea o include mínimo cando falta.
install_zathura_theme() {
  if ! has_package zathura; then
    return 0
  fi
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/zathura/noctaliarc" \
    "$HOME/.config/zathura/noctaliarc" || return 1
  copy_default_theme_file \
    "$DOTFILES_DIR/optional/.config/zathura/zathurarc" \
    "$HOME/.config/zathura/zathurarc"
}

# Resume a incorporación dos temas antes de pedir confirmación.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Engadida unha paleta galega inicial para Gum nos dous modos."
  info "· As aplicacións instaladas reciben o seu tema só cando non existe."
  info "· Helix, Neovim, Micro, Yazi, tmux e btop quedan tematizados tamén no servidor."
  if is_desktop; then
    info "· Noctalia activa tamén os templates de btop, Micro, tmux, Blender, GIMP e Inkscape."
  fi
}

# Orquestra cada copia de maneira explícita para non marcar a versión cando
# algunha aplicación instalada queda cun tema incompleto.
apply_update() {
  if ! update_theming_app_library; then
    return 1
  fi
  if ! install_default_ui_colors; then
    return 1
  fi

  if is_desktop; then
    if ! update_noctalia_templates; then
      return 1
    fi
  elif ! is_server; then
    return 1
  fi

  if ! install_kitty_theme; then
    return 1
  fi
  if ! install_alacritty_theme; then
    return 1
  fi
  if ! install_foot_theme; then
    return 1
  fi
  if ! install_ghostty_theme; then
    return 1
  fi
  if ! install_wezterm_theme; then
    return 1
  fi
  if ! install_helix_theme; then
    return 1
  fi
  if ! install_neovim_theme; then
    return 1
  fi
  if ! install_micro_theme; then
    return 1
  fi
  if ! install_tmux_theme; then
    return 1
  fi
  if ! install_btop_theme; then
    return 1
  fi
  if ! install_yazi_theme; then
    return 1
  fi
  if ! install_opencode_theme; then
    return 1
  fi
  if ! install_obs_theme; then
    return 1
  fi
  if ! install_telegram_theme; then
    return 1
  fi
  if ! install_zathura_theme; then
    return 1
  fi
}

# Presenta o changelog, confirma e executa o orquestrador completo.
main() {
  if ! get_install_mode > /dev/null; then
    fail "Non se puido determinar o modo da instalación."
  fi

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
