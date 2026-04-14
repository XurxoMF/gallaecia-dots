# 0.1.1

Elimina Rust con `rustup self uninstall` e instalao desde pacman con `sudo pacman -Syu --needed rustup && rustup default stable`.

Elimina este código de `~/.coinfig/bashrc/000-autostart`:

```
# Carga rustup
source "$HOME/.cargo/env"
```

Edita este código de `~/.config/hypr/config/hyprland/look-and-feel.conf`:

```
decoration {
    rounding = 12
    rounding_power = 2
}
```

Engade este código de `~.config/sxettingsd/xsettingsd.conf`:

```
Gtk/ColorScheme "prefer-dark"
```
