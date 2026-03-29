#!/usr/bin/env bash

# Recarga Hyprland
hyprctl reload

# Recarga Kitty
pkill -SIGUSR1 kitty

# Recarga Waybar
pkill waybar
hyprctl dispatch exec waybar

# Recarga estilos de SwayNC
swaync-client -rs

# Recarga Elephant
pkill elephant
hyprctl dispatch exec elephant