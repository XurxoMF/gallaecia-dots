# Benvid@ ao changelog de Gallaecia Dots

Aquí atoparás todos os cambios feitos entre versións cos comandos a executar para actualizar os dotfiles.

Revisa cada ficheiro e cambio para ver que non modifiquen nada que non desexes.

> [!NOTE]  
> Recorda que poder ver a versión actual e a data na que instalaches ou actualizaches os dotfiles con este comando:
>
> ```bash
> cat ~/.local/share/gallaecia-dots/version
> ```

## 2.0.0-04-07-2026

Dotfiles inciales.

## 2.1.0-04-07-2026

Nesta updates engadíronse un par de paquetes usados por varias apps de Gallaecia Dots como SpotDL ou yt-dlp así como por un montón de aplicacións moi usadas e tamén se engadiu como dependencia opcional SpotDL o cal descagará música en formato `opus` en `~/Música/Descargadas/Artista/Album/1. Título.opus` (config modificable).

Tamén se modificou o install.sh para gardar a data da versión e a data da instalación para saber cando actualizar.

### Engadido comentario no .bashrc

```bash
cat >> ~/.bashrc <<'EOF'

##########################################################
#### TODO O QUE ESTÉ DEBAIXO DISTO DEBERÍASE DE MOVER ####
####     A UN ARQUIVO EN ~/.config/bashrc/123-xxx     ####
##########################################################
EOF
```

### Engadidos python, pip, pipx e ffmpeg

```bash
yay -Syu python pip pipx ffmpeg
```

```bash
cat >> ~/.config/bashrc/000-autostart <<'EOF'

# PATH para apps de pipx
export PATH="$PATH:$HOME/.local/bin"

# Suxerencias de apps instaladas con pipx
eval "$(register-python-argcomplete pipx)"
EOF
```

### Engadido SpotDL como dependencia opcional

```bash
git clone https://github.com/XurxoMF/gallaecia-dots.git "$HOME/.dotfiles"
```

```bash
pipx install spotdl
```

```bash
rm -rf "$HOME/.config/spotdl" && cp -r "$HOME/.dotfiles/optional/.config/spotdl" "$HOME/.config/spotdl"
```

> [!TIP]  
> Actualiza a versión e data de actualización dos dotfiles con este comando:
>
> ```bash
> echo "2.1.0-04-07-2026 | Actualizado o $(date +%d-%m-%Y)" > "$HOME/.local/share/gallaecia-dots/version"
> ```

## 2.1.1-05-07-2026

Pequeno arreglo dun bug cun keybind de hyprland.

### Modificado ~/.config/hypr/hyprland.lua

```bash
hl.bind("SHIFT + Print",  hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen allw"))
                                                                                 |
                                                                          Eliminada esta w
```

> [!TIP]  
> Actualiza a versión e data de actualización dos dotfiles con este comando:
>
> ```bash
> echo "2.1.1-05-07-2026 | Actualizado o $(date +%d-%m-%Y)" > "$HOME/.local/share/gallaecia-dots/version"
> ```

## 2.2.0-06-07-2026

Nesta update mellórase a integración visual entre GTK, QT e KDE usando Papirus Dark, Breeze e o esquema de cores de Noctalia tamén para aplicacións KDE.

Tamén se move a configuración de VS Code a dependencias opcionais, xa que só é necesaria se se instala VS Code, e engádese configuración opcional para Dolphin.

### Engadidos Papirus, Breeze e Breeze Icons

```bash
yay -Syu papirus-icon-theme breeze breeze-icons kservice archlinux-xdg-menu
```

### Eliminado ~/.config/gallaecia-dots/scripts/mime-merge.sh

### Modificado ~/.config/gallaecia-dots/scripts/system-update.sh

```bash
git clone https://github.com/XurxoMF/gallaecia-dots.git "$HOME/.dotfiles"
```

```bash
rm -rf ~/.config/gallaecia-dots/scripts/system-update.sh
cp ~/.dotfiles/.config/gallaecia-dots/scripts/system-update.sh ~/.config/gallaecia-dots/scripts/system-update.sh
```

### Modificado ~/.config/hypr/hyprland.lua

```lua
-- Set D-Bus and systemd ENVs
hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_MENU_PREFIX=arch- XDG_CURRENT_DESKTOP=hyprland")
                                                                                  ^
                                                                               Engadido

-- código existente --

-- Set GTK themes
hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'")
                                                             V       V
                                                            modificados
                                                             V       V
hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'")

-- código existente --

-- KDE
hl.env("XDG_MENU_PREFIX", "arch-")
```

### Modificado ~/.config/noctalia/noctalia-config.toml

```toml
[theme.templates]
builtin_ids = [ "gtk3", "gtk4", "hyprland", "kcolorscheme", "qt" ]
                                                 ^
                                             Engadido
```

### Modificados ~/.config/qt5ct/qt5ct.conf e ~/.config/qt5ct/qt6ct.conf

```ini
[Appearance]
icon_theme=Papirus-Dark
style=Breeze
```

```ini
[Appearance]
icon_theme=Papirus-Dark
style=Breeze
```

### Engadida configuración de GTK3 e GTK4

```bash
git clone https://github.com/XurxoMF/gallaecia-dots.git "$HOME/.dotfiles"
```

```bash
rm -rf "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
cp -r "$HOME/.dotfiles/.config/gtk-3.0" "$HOME/.config/gtk-3.0"
cp -r "$HOME/.dotfiles/.config/gtk-4.0" "$HOME/.config/gtk-4.0"
```

### Engadida configuración global de KDE

```bash
git clone https://github.com/XurxoMF/gallaecia-dots.git "$HOME/.dotfiles"
```

```bash
rm -f "$HOME/.config/kdeglobals"
cp "$HOME/.dotfiles/.config/kdeglobals" "$HOME/.config/kdeglobals"
```

### Engadida configuración opcional de Dolphin

> [!NOTE]  
> Só é necesario copiar estes ficheiros se instalas Dolphin.

```bash
git clone https://github.com/XurxoMF/gallaecia-dots.git "$HOME/.dotfiles"
```

```bash
rm -f "$HOME/.config/dolphinrc" "$HOME/.config/baloofileinformationrc" "$HOME/.config/kservicemenurc"
rm -rf "$HOME/.local/share/kxmlgui5/dolphin"
cp "$HOME/.dotfiles/optional/.config/dolphinrc" "$HOME/.config/dolphinrc"
cp "$HOME/.dotfiles/optional/.config/baloofileinformationrc" "$HOME/.config/baloofileinformationrc"
cp "$HOME/.dotfiles/optional/.config/kservicemenurc" "$HOME/.config/kservicemenurc"
mkdir -p "$HOME/.local/share/kxmlgui5"
cp -r "$HOME/.dotfiles/optional/.local/share/kxmlgui5/dolphin" "$HOME/.local/share/kxmlgui5/dolphin"
```

> [!TIP]  
> Actualiza a versión e data de actualización dos dotfiles con este comando:
>
> ```bash
> echo "2.2.0-06-07-2026 | Actualizado o $(date +%d-%m-%Y)" > "$HOME/.local/share/gallaecia-dots/version"
> ```
