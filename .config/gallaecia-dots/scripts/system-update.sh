#!/usr/bin/env bash

# Mostramos logo
"$HOME/.config/gallaecia-dots/scripts/gallaecia.sh"

# Actualizar Rust?
if gum confirm --affirmative="Si" --negative="No" "Actualizar Rust?"; then
  printf ":: Actualizando Rust...\n\n"
  rustup update
  printf "\n:: Actualizado Rust!\n\n"
fi

# Actualizar pacman e AUR?
if gum confirm --affirmative="Si" --negative="No" "Actualizar pacman e AUR?"; then
  printf ":: Actualizando pacman e AUR...\n\n"
  yay -Syu --devel
  printf "\n:: Actualizado pacman e AUR!\n\n"
fi

# Actualizar Flatpak?
if gum confirm --affirmative="Si" --negative="No" "Actualizar Flatpak?"; then
  printf ":: Actualizando Flatpak...\n\n"
  flatpak update
  printf "\n:: Actualizado Flatpak!\n\n"
fi

kbuildsycoca6 --noincremental

# Reiniciar
if gum confirm --affirmative="Si" --negative="No" "Reinciar sistema? (Recomendado si se actualizaron paquetes)"; then
  systemctl reboot
fi