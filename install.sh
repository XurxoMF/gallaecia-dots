#!/usr/bin/env bash

# Limpiamos o terminal
clear

# Instalamos gum si non está instalado
if ! command -v gum &> /dev/null || ! command -v git &> /dev/null; then
  echo ":: Instalando programas requeridos para executar este script (gum e git)..." && echo
  sudo pacman -Sy --needed gum git
fi

# Limpiamos o terminal
clear

# Mostramos o banner
echo '  _____       _ _                 _       '
echo ' / ____|     | | |               (_)      '
echo '| |  __  __ _| | | __ _  ___  ___ _  __ _ '
echo '| | |_ |/ _` | | |/ _` |/ _ \/ __| |/ _` |'
echo '| |__| | (_| | | | (_| |  __/ (__| | (_| |'
echo ' \_____|\__,_|_|_|\__,_|\___|\___|_|\__,_|'
echo '                                          '

# Exportamos variables de estilo de gum
export GUM_CHOOSE_PADDING="0 0"
export GUM_CHOOSE_CURSOR_FOREGROUND="#90cdff"
export GUM_CHOOSE_CURSOR_BACKGROUND=""
export GUM_CHOOSE_HEADER_FOREGROUND="#dbe3ed"
export GUM_CHOOSE_HEADER_BACKGROUND=""
export GUM_CHOOSE_ITEM_FOREGROUND="#dbe3ed"
export GUM_CHOOSE_ITEM_BACKGROUND=""
export GUM_CHOOSE_SELECTED_FOREGROUND="#90cdff"
export GUM_CHOOSE_SELECTED_BACKGROUND=""
export GUM_CONFIRM_PROMPT_FOREGROUND="#90cdff"
export GUM_CONFIRM_PROMPT_BACKGROUND=""
export GUM_CONFIRM_SELECTED_FOREGROUND="#003350"
export GUM_CONFIRM_SELECTED_BACKGROUND="#90cdff"
export GUM_CONFIRM_UNSELECTED_FOREGROUND="#cce6ff"
export GUM_CONFIRM_UNSELECTED_BACKGROUND="#004b72"
export GUM_CONFIRM_PADDING="0 0"
export GUM_INPUT_PROMPT_FOREGROUND="#dbe3ed"
export GUM_INPUT_PROMPT_BACKGROUND=""
export GUM_INPUT_PLACEHOLDER_FOREGROUND="#dbe3ed"
export GUM_INPUT_PLACEHOLDER_BACKGROUND=""
export GUM_INPUT_CURSOR_FOREGROUND="#90cdff"
export GUM_INPUT_CURSOR_BACKGROUND=""
export GUM_INPUT_HEADER_FOREGROUND="#dbe3ed"
export GUM_INPUT_HEADER_BACKGROUND=""
export GUM_INPUT_PADDING="0 0"
export GUM_SPIN_SPINNER_FOREGROUND="#90cdff"
export GUM_SPIN_SPINNER_BACKGROUND=""
export GUM_SPIN_TITLE_FOREGROUND="#dbe3ed"
export GUM_SPIN_TITLE_BACKGROUND=""
export GUM_SPIN_PADDING="0 0"

# Mostramos benvida ao usuario
gum style --foreground="#90CDFF" --bold "BENVID@ AO INSTALADOR DE GALLAECIA DOTS!" && echo
gum style "Con este script poderás instalar os dotfiles paso por paso para que poidas personalizar algunhas cousas e gardar copias de seguridade antes de que se sobreescriban polos dotfiles."
gum style "Simplemente responde as preguntas que irán aparecendo en pantalla deixa que ocurra a maxia pagana." && echo

# Mostramos alerta de arquivos e carpetas que poden ser eliminados
gum style --foreground="#D6C104" --bold "IMPORTANTE"
gum style --foreground="#D6C104" --bold "Ten en conta que algunhas das opcións durante a instalación borrarán ou editarán certas carpetas e arquivos no sistema!"
gum style --foreground="#D6C104" --bold "Antes de borrar ou editar nada avisaráse de que arquivos se verán afectados e como." && echo

# Descargar Gallaecia Dots
gum style "Primeiro vamos a descargar Gallaecia Dots!" && echo

if gum confirm --affirmative="Si" --negative="No" "Descargar Gallaecia Dots?"; then
  if rm -rf "$HOME/.dotfiles" && \
     git clone https://github.com/XurxoMF/gallaecia-dots.git "$HOME/.dotfiles"
  then
    echo && gum style --foreground="#2baf03" --bold "Gallaecia Dots descargado con éxito!" && echo
  else
    echo && gum style --foreground="#cc2508" --bold "Algo fallou ao descargar Gallaecia Dots! Abortando instalación..." && exit 1
  fi
else
  gum style --foreground="#cc2508" --bold "Non se poden instalar os dotfiles sen descargalos primeiro! Abortando instalación..." && exit 1
fi

gum style "Agora que temos os dotfiles descargados, vamos a instalalos!" && echo

# Cambiar idioma a Galego con fallback a Español e logo a Inglés
gum style --foreground="#90CDFF" --bold "Cambiar idioma a Galego" && echo
gum style "Como bos dotfiles en Galego, temos que cambiar o idioma a Galego. Se engade un fallback a Español e logo a Inglés en caso de non haber nigún dos dous." && echo
gum style --foreground="#D6C104" --bold "Isto modificará o ficheiro /etc/locale.gen e sobreescribirá o ficheiro /etc/locale.conf!" && echo

if gum confirm --affirmative="Si" --negative="No" "Cambiar idioma a Galego > Español > Inglés?"; then
  if sudo sed -i 's/^#es_ES.UTF-8 UTF-8/es_ES.UTF-8 UTF-8/' /etc/locale.gen && \
     sudo sed -i 's/^#gl_ES.UTF-8 UTF-8/gl_ES.UTF-8 UTF-8/' /etc/locale.gen && \
     sudo sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
     sudo locale-gen && \
     echo "LANG=gl_ES.UTF-8" | sudo tee /etc/locale.conf && \
     echo "LANGUAGE=gl_ES:es_ES:en_US" | sudo tee -a /etc/locale.conf
  then
    echo && gum style --foreground="#2baf03" --bold "Idioma cambiado con éxito!" && echo
  else
    echo && gum style --foreground="#cc2508" --bold "Algo fallou ao cambiar o idioma! Abortando instalación..." && exit 1
  fi
fi

# Habilitar [multilib] en pacman
gum style --foreground="#90CDFF" --bold "Habilitar [multilib] en pacman" && echo
gum style "Algúns dos paquetes obligatorios están en multilib polo que temos que habilitala." && echo
gum style --foreground="#D6C104" --bold "Isto modificará o ficheiro /etc/pacman.conf!" && echo

if gum confirm --affirmative="Si" --negative="No" "Habilitar [multilib] e cores en pacman? (Obligatorio)"; then
  if sudo sed -i \
      -e 's/^#Color/Color/' \
      -e 's/^#ILoveCandy/ILoveCandy/' \
      -e '/^#Color/a ILoveCandy' \
      -e 's/^#\[multilib\]/[multilib]/' \
      -e '/^\[multilib\]/{n; s/^#Include/Include/}' \
      /etc/pacman.conf && \
     yay -Y --color always --save && \
     sudo pacman -Syy
  then
    echo && gum style --foreground="#2baf03" --bold "[multilib] habilitado con éxito e cores activadas!" && echo
  else
    echo && gum style --foreground="#cc2508" --bold "Algo fallou ao habilitar [multilib] ou activar cores! Abortando instalación..." && exit 1
  fi
else
  gum style --foreground="#cc2508" --bold "Sen [multilib] algúns paquetes obligatorios non poderán ser instalados! Abortando instalación..." && exit 1
fi

# Instalar obligatorios
gum style --foreground="#90CDFF" --bold "Instalar paquetes obligatorios? (Obligatorio)" && echo
gum style "Os programas obligatorios inclúen, entre outros, YAY, Rust, Flatpak, Kitty, Hyprland..."
gum style "Podes ver a lista de programas obligatorios en https://gallaecia-dots.xurxomf.xyz." && echo

if gum confirm --affirmative="Si" --negative="No" "Instalar YAY? (Obligatorio)"; then
  # Instalar YAY
  if sudo pacman -Syu --needed base-devel && \
     git clone https://aur.archlinux.org/yay.git ./yay && \
     cd yay && \
     makepkg -si && \
     cd .. && \
     sudo rm -rf yay
  then
    echo && gum style --foreground="#2baf03" --bold "YAY instalado con éxito!" && echo
  else
    echo && gum style --foreground="#cc2508" --bold "Algo fallou ao instalar YAY! Abortando instalación..." && exit 1
  fi

  # Instalar Rust
  if sudo pacman -Syu --needed rustup && \
     rustup default stable
  then
    echo && gum style --foreground="#2baf03" --bold "Rust instalado con éxito!" && echo
  else
    echo && gum style --foreground="#cc2508" --bold "Algo fallou durante a instalación de Rust! Abortando instalación..." && exit 1
  fi

  # Isntalar paquetes obligatorios
  if yay -Syu --needed noto-fonts-cjk noto-fonts-emoji noto-fonts \
     flatpak util-linux pipewire gnome-keyring libsecret greetd cage wlr-randr dbus polkit \
     hyprland \
     noctalia-git noctalia-greeter-git \
     qt5-base qt6-base qt5ct qt6ct qt5-wayland qt6-wayland xsettingsd hyprland-qt-support \
     xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-user-dirs \
     xorg-xrandr \
     adw-gtk-theme \
     kitty seahorse nautilus firefox && \
     flatpak install org.gtk.Gtk3theme.adw-gtk3-dark org.gtk.Gtk3theme.adw-gtk3
  then
    echo && gum style --foreground="#2baf03" --bold "Paquetes requeridos instalados con éxito!" && echo
  else
    echo && gum style --foreground="#cc2508" --bold "Algo fallou durante a instalación dos paquetes obligatorios! Abortando instalación..." && exit 1
  fi
else
  gum style --foreground="#cc2508" --bold "Sen os paquetes obligatorios os dotfiles non funcionarán! Abortando instalación..." && exit 1
fi

# Crear carpetas personales e configurar xdg-user-dirs
gum style --foreground="#90CDFF" --bold "Crear carpetas personales e configuralas" && echo
gum style "Os dotfiles necesitan multiples carpetas para certas cousas polo que é necesario crealas e configuralas."
gum style "Estas carpetas son Aplicacións, Desarrollo, Descargas, Documentos, Escritorio, Imaxes, Modelos, Música, Público, Vídeos, e Xogos."
gum style "Inda que como usuario non precises estas carpetas, certas funcionalidades incluídas nestes dotfiles e en certas aplicacións precisan que esas carpetas existan se non poden fallar ou non funcionar correctamente." && echo
gum style --foreground="#D6C104" --bold "Isto substituirá os ficheiros ~/.config/user-dirs.dirs e ~/.config/user-dirs.conf!" && echo

if gum confirm --affirmative="Si" --negative="No" "Crear carpetas? (Obligatorio)"; then
  if mkdir -p "$HOME/Aplicacións" "$HOME/Desarrollo" "$HOME/Descargas" "$HOME/Documentos" "$HOME/Escritorio" "$HOME/Imaxes" "$HOME/Modelos" "$HOME/Música" "$HOME/Público" "$HOME/Vídeos" "$HOME/Xogos" && \
     rm -rf "$HOME/.config/user-dirs.dirs" "$HOME/.config/user-dirs.conf" && \
     cp -r "$HOME/.dotfiles/.config/user-dirs.dirs" "$HOME/.config/user-dirs.dirs" && \
     cp -r "$HOME/.dotfiles/.config/user-dirs.conf" "$HOME/.config/user-dirs.conf"
  then
    echo && gum style --foreground="#2baf03" --bold "Carpetas creadas con éxito!" && echo
  else
    echo && gum style --foreground="#cc2508" --bold "Algo fallou durante a creación das carpetas! Abortando instalación..." && exit 1
  fi
else
  gum style --foreground="#cc2508" --bold "Sen estas carpetas algunhas aplicacións e programas non funcionrán correctamente! Abortando instalación..." && exit 1
fi

# Instalar dotfiles
gum style --foreground="#90CDFF" --bold "Instalar dotfiles" && echo
gum style "Todos os paquetes necesitan unha configuración tanto para o funcionamento como para os estilos. Iso mismo son os dotfiles." && echo
gum style --foreground="#D6C104" --bold "Isto eliminará e modificará multiples ficheiros en ~/.config/ e ~/. Lista de cambios:" && echo
gum style --foreground="#D6C104" --bold "· Sobreescríbese o ficheiro /etc/greetd/config.toml"
gum style --foreground="#D6C104" --bold "· Sobreescríbese o ficheiro ~/.bashrc"
gum style --foreground="#D6C104" --bold "· Sobreescríbese o ficheiro ~/.config/mimeapps.list"
gum style --foreground="#D6C104" --bold "· Sobreescríbese o ficheiro ~/.config/code-flags.conf"
gum style --foreground="#D6C104" --bold "· Sobreescríbese o ficheiro ~/.config/user-dirs.conf"
gum style --foreground="#D6C104" --bold "· Sobreescríbese o ficheiro ~/.config/user-dirs.dirs"
gum style --foreground="#D6C104" --bold "· Sobreescríbense os ficheiros ~/.wallpapers/Gallaecia XXXXXX.jpg"
gum style --foreground="#D6C104" --bold "· Sobreescríbese a carpeta ~/.config/bashrc/"
gum style --foreground="#D6C104" --bold "· Sobreescríbese a carpeta ~/.config/gallaecia-dots/"
gum style --foreground="#D6C104" --bold "· Sobreescríbese a carpeta ~/.config/xdg-desktop-portal/"
gum style --foreground="#D6C104" --bold "· Sobreescríbese a carpeta ~/.config/xsettingsd/"
gum style --foreground="#D6C104" --bold "· Sobreescríbese a carpeta ~/.config/gtk-3.0/"
gum style --foreground="#D6C104" --bold "· Sobreescríbese a carpeta ~/.config/gtk-4.0/"
gum style --foreground="#D6C104" --bold "· Sobreescríbese a carpeta ~/.config/qt5ct/"
gum style --foreground="#D6C104" --bold "· Sobreescríbese a carpeta ~/.config/qt6ct/"
gum style --foreground="#D6C104" --bold "· Sobreescríbese a carpeta ~/.config/hypr/"
gum style --foreground="#D6C104" --bold "· Sobreescríbese a carpeta ~/.config/kitty/" && echo

if gum confirm --affirmative="Si" --negative="No" "Instalar dotfiles? (Obligatorio)"; then
  # Instalar config de greetd
  if sudo -rf rm "/etc/greetd" && \
     sudo -r cp "$HOME/.dotfiles/others/greetd" "/etc/greetd" && \
     sudo useradd -r -s /usr/bin/nologin -d /var/lib/noctalia-greeter greeter 2>/dev/null || true && \
     sudo systemctl enable --now greetd && \
     sudo systemctl reload greetd
  then
    echo && gum style --foreground="#2baf03" --bold "Configuración de greetd instalada con éxito!" && echo
  else
    echo && gum style --foreground="#cc2508" --bold "Algo fallou ao instalar a configuración de greetd! Abortando instalación..." && exit 1
  fi

  # Instalar configs propias de Gallaecia Dots como scripts e wallpapers
  if rm -rf "$HOME/.config/gallaecia-dots" && \
     cp -r "$HOME/.dotfiles/.config/gallaecia-dots" "$HOME/.config/gallaecia-dots" && \
     sudo chmod +x -R "$HOME/.config/gallaecia-dots/scripts"
     mkdir -p "$HOME/.wallpapers"
     cp -rf "$HOME/.dotfiles/.wallpapers/." "$HOME/.wallpapers/"
  then
    echo && gum style --foreground="#2baf03" --bold "Configs propias de Gallaecia Dots instaladas con éxito!" && echo
  else
    echo && gum style --foreground="#cc2508" --bold "Algo fallou ao instalar as configs propias de Gallaecia Dots! Abortando instalación..." && exit 1
  fi

  # Instalar MIME types
  if rm -rf "$HOME/.config/mimeapps.list" && \
     cp -r "$HOME/.dotfiles/.config/mimeapps.list" "$HOME/.config/mimeapps.list"
  then
    echo && gum style --foreground="#2baf03" --bold "MIME types instalados con éxito!" && echo
  else
    echo && gum style --foreground="#cc2508" --bold "Algo fallou ao instalar os MIME types! Abortando instalación..." && exit 1
  fi

  # Instalar bashrc
  if rm -rf "$HOME/.bashrc" "$HOME/.config/bashrc" && \
     cp -r "$HOME/.dotfiles/.bashrc" "$HOME/.bashrc" && \
     cp -r "$HOME/.dotfiles/.config/bashrc" "$HOME/.config/bashrc" && \
     source "$HOME/.bashrc"
  then
    echo && gum style --foreground="#2baf03" --bold "Bashrc instalado con éxito!" && echo
  else
    echo && gum style --foreground="#cc2508" --bold "Algo fallou ao instalar o bashrc! Abortando instalación..." && exit 1
  fi

  # Configuración dos XDG Desktop Portals
  if rm -rf "$HOME/.config/xdg-desktop-portal" && \
     cp -r "$HOME/.dotfiles/.config/xdg-desktop-portal" "$HOME/.config/xdg-desktop-portal"
  then
    echo && gum style --foreground="#2baf03" --bold "XDG Desktop Portals configurados con éxito!" && echo
  else
    echo && gum style --foreground="#cc2508" --bold "Algo fallou ao configurar os XDG Desktop Portals! Abortando instalación..." && exit 1
  fi

  # Configuración de XSettingsd
  if rm -rf "$HOME/.config/xsettingsd" && \
     cp -r "$HOME/.dotfiles/.config/xsettingsd" "$HOME/.config/xsettingsd"
  then
    echo && gum style --foreground="#2baf03" --bold "XSettingsd configurado con éxito!" && echo
  else  
    echo && gum style --foreground="#cc2508" --bold "Algo fallou ao configurar o XSettingsd! Abortando instalación..." && exit 1
  fi

  # Configuración de GTK3 e GTK4
  if rm -rf "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"; then
    echo && gum style --foreground="#2baf03" --bold "GTK3 e GTK4 configurados con éxito!" && echo
  else
    echo && gum style --foreground="#cc2508" --bold "Algo fallou ao configurar GTK3 e GTK4! Abortando instalación..." && exit 1
  fi

  # Configuración de QT5 e QT6
  if rm -rf "$HOME/.config/qt6ct" "$HOME/.config/qt5ct" && \
     cp -r "$HOME/.dotfiles/.config/qt6ct" "$HOME/.config/qt6ct" && \
     cp -r "$HOME/.dotfiles/.config/qt5ct" "$HOME/.config/qt5ct"
  then
    echo && gum style --foreground="#2baf03" --bold "QT5 e QT6 configurados con éxito!" && echo
  else
    echo && gum style --foreground="#cc2508" --bold "Algo fallou ao configurar QT5 e QT6! Abortando instalación..." && exit 1
  fi

  # Configuiración de Kitty
  if rm -rf "$HOME/.config/kitty" && \
     cp -r "$HOME/.dotfiles/.config/kitty" "$HOME/.config/kitty"
  then
    echo && gum style --foreground="#2baf03" --bold "Kitty configurado con éxito!" && echo
  else
    echo && gum style --foreground="#cc2508" --bold "Algo fallou ao configurar Kitty! Abortando instalación..." && exit 1
  fi

  # Configuración de Hyprland
  if rm -rf "$HOME/.config/hypr" && \
     cp -r "$HOME/.dotfiles/.config/hypr" "$HOME/.config/hypr"
  then
    echo && gum style --foreground="#2baf03" --bold "Hyprland configurado con éxito!" && echo
  else
    echo && gum style --foreground="#cc2508" --bold "Algo fallou ao configurar Hyprland! Abortando instalación..." && exit 1
  fi
else
  gum style --foreground="#cc2508" --bold "Sen dotfiles... non hai dotfiles... curiosamente... Abortando instalación..." && exit 1
fi

systemctl --user enable gnome-keyring-daemon.service
systemctl --user start gnome-keyring-daemon.service

gum style "Xa temos os dotfiles instalados e configurados! Agora solo faltan as partes opcionales!" && echo

# Instalar yt-dlp?
gum style --foreground="#90CDFF" --bold "Instalar yt-dlp e configuralo" && echo
gum style "Se queres descargar vídeos e cancións de YouTube ou YouTube Music facilmente instala yt-dlp e terás varios comandos dispoñibles para usar." && echo
gum style --foreground="#D6C104" --bold "Isto substituirá a carpeta ~/.config/yt-dlp/ e o arquivo ~/.config/bachrc/201-yt-dlp!" && echo

if gum confirm --affirmative="Si" --negative="No" "Instalar yt-dlp?"; then
  if yay -Syu --needed yt-dlp && \
     rm -rf "$HOME/.config/yt-dlp" && \
     cp -r "$HOME/.dotfiles/optional/.config/yt-dlp" "$HOME/.config/yt-dlp" && \
     rm -rf "$HOME/.config/bashrc/201-yt-dlp" && \
     cp "$HOME/.dotfiles/optional/.config/bashrc/201-yt-dlp" "$HOME/.config/bashrc/201-yt-dlp" && \
     source "$HOME/.bashrc"
  then
    echo && gum style --foreground="#2baf03" --bold "yt-dlp instalado con éxito!" && echo
  else
    echo && gum style --foreground="#cc2508" --bold "Algo fallou ao instalar yt-dlp! Podes instalalo manualmente." && echo
  fi
fi


