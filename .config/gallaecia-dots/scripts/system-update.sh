#!/usr/bin/env bash

# Mostramos logo
"$HOME/.config/gallaecia-dots/scripts/gallaecia.sh"

# Actualizar pacman e AUR?
if gum confirm --affirmative="Si" --negative="No" "Actualizar pacman e AUR?"; then
  printf ":: Actualizando pacman e AUR...\n\n"
  yay -Syu
  printf "\n:: Actualizado pacman e AUR!\n\n"
fi

# Actualizar Flatpak?
if gum confirm --affirmative="Si" --negative="No" "Actualizar Flatpak?"; then
  printf ":: Actualizando Flatpak...\n\n"
  flatpak update
  printf "\n:: Actualizado Flatpak!\n\n"
fi

# Actualizar Rust?
if gum confirm --affirmative="Si" --negative="No" "Actualizar Rust?"; then
  printf ":: Actualizando Rust...\n\n"
  rustup update
  printf "\n:: Actualizado Rust!\n\n"
fi

# Actualizar plugins de Yazi?
if gum confirm --affirmative="Si" --negative="No" "Actualizar plugins de Yazi?"; then
  printf ":: Actualizando plugins de Yazi...\n\n"
  ya pkg upgrade
  printf "\n:: Actualizados plugins de Yazi!\n\n"
fi

# Actualizar MIME types?
if gum confirm --affirmative="Si" --negative="No" "Actualizar MIME types?"; then
  printf ":: Actualizando MIME types...\n"
  "$HOME/.config/gallaecia-dots/scripts/mime-merge.sh"
  printf "\n:: Actualizados os MIME types!\n\n"
fi

read -rsn 1 -p ":: Actualización completada! Presiona [ENTER] para cerrar..."