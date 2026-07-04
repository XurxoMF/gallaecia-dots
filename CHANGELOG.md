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
