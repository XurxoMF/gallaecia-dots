#!/usr/bin/env bash

# Mostramos logo
"$HOME/.config/gallaecia-dots/scripts/gallaecia.sh"

# Seleccionamos o tema claro/escuro
modo=${2:-$(gum choose --header "Selecciona o tema:" "Claro" "Oscuro")}

if [ "$modo" == "Claro" ]; then
  # Seleccionamos e aplicamos o tema claro en base a imaxe
  matugen image --mode light --type scheme-vibrant --verbose --show-colors ${3:+--source-color-index "$3"} "$1"
  
  # Cambiamos o tema a claro en gsettings
  gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
else
  # Seleccionamos e aplicamos o tema escuro en base a imaxe
  matugen image --mode dark --type scheme-vibrant --verbose --show-colors ${3:+--source-color-index "$3"} "$1"

  # Cambiamos o tema a escuro en gsettings
  gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
fi

# Reiniciamos todos os servizos para aplicar o novo tema
"$HOME/.config/gallaecia-dots/scripts/reload-all.sh"