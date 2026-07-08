#!/usr/bin/env bash

set -u
set -o pipefail

GREEN="#2baf03"
RED="#cc2508"
BLUE="#90CDFF"
YELLOW="#D6C104"

gum_style() {
  gum style \
	--background="" \
	--border-background="" \
	--border-foreground="$BLUE" \
	--margin="0 0" \
	--padding="0 0" \
	"$@"
}

success() {
  echo
  gum_style \
	--foreground="$GREEN" \
	--bold \
	"$1"
  echo
}

fail() {
  echo
  gum_style \
	--foreground="$RED" \
	--bold \
	"$1"
  exit 1
}

warning() {
  gum_style \
	--foreground="$YELLOW" \
	--bold \
	"$1"
}

title() {
  gum_style \
	--foreground="$BLUE" \
	--bold \
	"$1"
  echo
}

gum_confirm() {
  gum confirm \
	--affirmative="Si" \
	--negative="No" \
	--prompt.foreground="#90cdff" \
	--prompt.background="" \
	--selected.foreground="#003350" \
	--selected.background="#90cdff" \
	--unselected.foreground="#cce6ff" \
	--unselected.background="#004b72" \
	--padding="0 0" \
	"$@"
}

has_command_or_skip() {
  local command_name="$1"
  local error_message="$2"

  if ! command -v "$command_name" &> /dev/null; then
    warning "$error_message"
    return 1
  fi
}

run_step() {
  local success_message="$1"
  local error_message="$2"
  local step="$3"

  if "$step"; then
    success "$success_message"
  else
    fail "$error_message"
  fi
}

confirm_step() {
  local question="$1"
  local success_message="$2"
  local error_message="$3"
  local step="$4"

  if gum_confirm "$question"; then
    run_step \
		"$success_message" \
		"$error_message" \
		"$step"
  fi
}

show_logo() {
  local logo_script="$HOME/.config/gallaecia-dots/scripts/gallaecia.sh"

  if [ -x "$logo_script" ]; then
    "$logo_script"
  fi
}

update_rust() {
  if ! has_command_or_skip rustup "Rustup non está instalado. Saltando actualización de Rust."; then
    return 0
  fi

  title "Actualizando Rust..."
  rustup update
}

update_arch() {
  if ! has_command_or_skip yay "YAY non está instalado. Saltando actualización de pacman e AUR."; then
    return 0
  fi

  title "Actualizando pacman e AUR..."
  yay -Syu --devel
}

update_flatpak() {
  if ! has_command_or_skip flatpak "Flatpak non está instalado. Saltando actualización de Flatpak."; then
    return 0
  fi

  title "Actualizando Flatpak..."
  flatpak update
}

main() {
  show_logo

  confirm_step \
	"Actualizar Rust?" \
	"Rust actualizado con éxito!" \
	"Algo fallou ao actualizar Rust!" \
	update_rust

  confirm_step \
	"Actualizar pacman e AUR?" \
	"Pacman e AUR actualizados con éxito!" \
	"Algo fallou ao actualizar pacman e AUR!" \
	update_arch

  confirm_step \
	"Actualizar Flatpak?" \
	"Flatpak actualizado con éxito!" \
	"Algo fallou ao actualizar Flatpak!" \
	update_flatpak

  if gum_confirm "Reiniciar sistema? (Recomendado se se actualizaron paquetes)"; then
    systemctl reboot
  fi
}

main "$@"
