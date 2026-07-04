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
gum style --foreground="#90CDFF" --bold "Habilitar [multilib] e cores en pacman" && echo
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
gum style "Os programas obligatorios inclúen, entre outros, yay, Rust, Flatpak, Kitty, Hyprland..."
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

  # Instalar paquetes obligatorios
  if yay -Syu --needed noto-fonts-cjk noto-fonts-emoji noto-fonts \
     flatpak util-linux pipewire gnome-keyring libsecret greetd cage wlr-randr dbus polkit libnewt playerctl \
     hyprland uwsm \
     noctalia-git noctalia-greeter-git \
     qt5-base qt6-base qt5ct qt6ct qt5-wayland qt6-wayland xsettingsd hyprland-qt-support \
     xdg-utils xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-user-dirs \
     xorg-xrandr \
     adw-gtk-theme \
     kitty seahorse && \
     flatpak install org.gtk.Gtk3theme.adw-gtk3-dark org.gtk.Gtk3theme.adw-gtk3 && \
     systemctl --user enable gnome-keyring-daemon.service && \
     systemctl --user start gnome-keyring-daemon.service
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
gum style --foreground="#D6C104" --bold "· Sobreescríbense os ficheiros ~/.wallpapers/Gallaecia - XXXXXX.jpg"
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

gum style "Xa temos os dotfiles instalados e configurados! Agora solo faltan as partes opcionales!" && echo

# Instalar navegador
gum style --foreground="#90CDFF" --bold "Instalar navegador web e configuralo" && echo
gum style "É complicado hoxe en día usar un ordenador sin un navegador web. Instala o que elixas (ou ningún) de forma rápida dende aquí." && echo

navegador=$(gum choose --header "Selecciona un navegador web ou preme Esc para non instalar ningún:" \
  "Tor Browser" \
  "Firefox" \
  "Vivaldi" \
  "Brave" \
  "Opera" \
  "LibreWolf" \
  "Zen Browser"
)

case "$navegador" in
  "Tor Browser")
    yay -Syu --needed tor-browser-bin && \
    sed -i 's|-- {{navegador}}|hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("tor-browser"))|g' \
      "$HOME/.config/hypr/hyprland-custom.lua"
    ;;
  "Firefox")
    yay -Syu --needed firefox && \
    sed -i 's|-- {{navegador}}|hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("firefox"))|g' \
      "$HOME/.config/hypr/hyprland-custom.lua"
    ;;
  "Vivaldi")
    yay -Syu --needed vivaldi && \
    sed -i 's|-- {{navegador}}|hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("vivaldi-stable"))|g' \
      "$HOME/.config/hypr/hyprland-custom.lua"
    ;;
  "Brave")
    yay -Syu --needed brave-bin && \
    sed -i 's|-- {{navegador}}|hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("brave"))|g' \
      "$HOME/.config/hypr/hyprland-custom.lua"
    ;;
  "Opera")
    yay -Syu --needed opera && \
    sed -i 's|-- {{navegador}}|hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("opera"))|g' \
      "$HOME/.config/hypr/hyprland-custom.lua"
    ;;
  "LibreWolf")
    yay -Syu --needed librewolf-bin && \
    sed -i 's|-- {{navegador}}|hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("librewolf"))|g' \
      "$HOME/.config/hypr/hyprland-custom.lua"
    ;;
  "Zen Browser")
    yay -Syu --needed zen-browser-bin && \
    sed -i 's|-- {{navegador}}|hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("zen-browser"))|g' \
      "$HOME/.config/hypr/hyprland-custom.lua"
    ;;
esac

# Instalar explorador de arquivos
gum style --foreground="#90CDFF" --bold "Instalar explorador de arquivos e configuralo" && echo
gum style "Igual que sin navegador é complicado traballar, sin explorador de arquivos inda máis. Instala o que elixas (ou ningún) de forma rápida dende aquí." && echo

explorador=$(gum choose --header "Selecciona un explorador de arquivos ou preme Esc para non instalar ningún:" \
  "Nemo" \
  "Dolphin" \
  "Nautilus" \
  "Thunar" \
  "Yazi"
)

case "$explorador" in
  "Nemo")
    yay -Syu --needed nemo && \
    sed -i 's|-- {{explorador}}|hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nemo"))|g' \
      "$HOME/.config/hypr/hyprland-custom.lua"
    ;;
  "Dolphin")
    yay -Syu --needed dolphin && \
    sed -i 's|-- {{explorador}}|hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("dolphin"))|g' \
      "$HOME/.config/hypr/hyprland-custom.lua"
    ;;
  "Nautilus")
    yay -Syu --needed nautilus && \
    sed -i 's|-- {{explorador}}|hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus"))|g' \
      "$HOME/.config/hypr/hyprland-custom.lua"
    ;;
  "Thunar")
    yay -Syu --needed thunar && \
    sed -i 's|-- {{explorador}}|hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("thunar"))|g' \
      "$HOME/.config/hypr/hyprland-custom.lua"
    ;;
  "Yazi")
    yay -Syu --needed yazi && \
    sed -i 's|-- {{explorador}}|hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("kitty -e yazi"))|g' \
      "$HOME/.config/hypr/hyprland-custom.lua"
    ;;
esac

# Instalar editor de texto
gum style --foreground="#90CDFF" --bold "Instalar editor de texto/código e configuralo" && echo
gum style "Un editor de texto/código é casi imprescindible nun equipo. Instala o que elixas (ou ningún) de forma rápida dende aquí." && echo

editor_texto=$(gum choose --header "Selecciona un editor de texto/código ou preme Esc para non instalar ningún:" \
  "VS Code" \
  "VSCodium" \
  "Neovim" \
  "Vim" \
  "Zed" \
  "Kate" \
  "Sublime Text"
)

case "$editor_texto" in
  "VS Code")
    yay -Syu --needed visual-studio-code-bin && \
    sed -i 's|-- {{editor_texto}}|hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("code"))|g' \
      "$HOME/.config/hypr/hyprland-custom.lua"
    ;;
  "VSCodium")
    yay -Syu --needed vscodium-bin && \
    sed -i 's|-- {{editor_texto}}|hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("codium"))|g' \
      "$HOME/.config/hypr/hyprland-custom.lua"
    ;;
  "Neovim")
    yay -Syu --needed neovim && \
    sed -i 's|-- {{editor_texto}}|hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("kitty -e nvim"))|g' \
      "$HOME/.config/hypr/hyprland-custom.lua"
    ;;
  "Vim")
    yay -Syu --needed vim && \
    sed -i 's|-- {{editor_texto}}|hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("kitty -e vim"))|g' \
      "$HOME/.config/hypr/hyprland-custom.lua"
    ;;
  "Zed")
    yay -Syu --needed zed && \
    sed -i 's|-- {{editor_texto}}|hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("zed"))|g' \
      "$HOME/.config/hypr/hyprland-custom.lua"
    ;;
  "Kate")
    yay -Syu --needed kate && \
    sed -i 's|-- {{editor_texto}}|hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("kate"))|g' \
      "$HOME/.config/hypr/hyprland-custom.lua"
    ;;
  "Sublime Text")
    yay -Syu --needed sublime-text-4 && \
    sed -i 's|-- {{editor_texto}}|hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("subl"))|g' \
      "$HOME/.config/hypr/hyprland-custom.lua"
    ;;
esac

# Instalar visualizador de imaxes
gum style --foreground="#90CDFF" --bold "Instalar visualizador de imaxes e configuralo" && echo
gum style "Un visualizador de imaxes permite abrir e consultar imaxes de forma rápida e cómoda. Instala o que elixas (ou ningún) de forma rápida dende aquí." && echo

visualizador_imaxes=$(gum choose --header "Selecciona un visualizador de imaxes ou preme Esc para non instalar ningún:" \
  "Gwenview" \
  "Loupe" \
  "imv" \
  "qimgv" \
  "Ristretto"
)

case "$visualizador_imaxes" in
  "Gwenview")
    yay -Syu --needed gwenview
    ;;
  "Loupe")
    yay -Syu --needed loupe
    ;;
  "imv")
    yay -Syu --needed imv
    ;;
  "qimgv")
    yay -Syu --needed qimgv
    ;;
  "Ristretto")
    yay -Syu --needed ristretto
    ;;
esac

# Instalar reprodutor de vídeo
gum style --foreground="#90CDFF" --bold "Instalar reprodutor de vídeo e configuralo" && echo
gum style "Un reprodutor de vídeo permite reproducir contido multimedia de forma rápida e cómoda. Instala o que elixas (ou ningún) de forma rápida dende aquí." && echo

reprodutor_video=$(gum choose --header "Selecciona un reprodutor de vídeo ou preme Esc para non instalar ningún:" \
  "VLC" \
  "MPV" \
  "Haruna" \
  "Celluloid" \
  "SMPlayer"
)

case "$reprodutor_video" in
  "VLC")
    yay -Syu --needed vlc
    ;;
  "MPV")
    yay -Syu --needed mpv
    ;;
  "Haruna")
    yay -Syu --needed haruna
    ;;
  "Celluloid")
    yay -Syu --needed celluloid
    ;;
  "SMPlayer")
    yay -Syu --needed smplayer
    ;;
esac

# Instalar visor de PDF
gum style --foreground="#90CDFF" --bold "Instalar visor de PDF" && echo
gum style "Un visor de PDF permite abrir e consultar documentos PDF de forma rápida e cómoda. Instala o que elixas (ou ningún) de forma rápida dende aquí." && echo

visor_pdf=$(gum choose --header "Selecciona un visor de PDF ou preme Esc para non instalar ningún:" \
  "Okular" \
  "Papers" \
  "Zathura" \
  "MuPDF" \
  "Xreader"
)

case "$visor_pdf" in
  "Okular")
    yay -Syu --needed okular
    ;;
  "Papers")
    yay -Syu --needed papers
    ;;
  "Zathura")
    yay -Syu --needed zathura zathura-pdf-mupdf
    ;;
  "MuPDF")
    yay -Syu --needed mupdf
    ;;
  "Xreader")
    yay -Syu --needed xreader
    ;;
esac

# Instalar xestor de arquivos comprimidos
gum style --foreground="#90CDFF" --bold "Instalar xestor de arquivos comprimidos" && echo
gum style "Un xestor de arquivos comprimidos permite crear, abrir e extraer arquivos comprimidos mediante unha interface gráfica. Instala o que elixas (ou ningún) de forma rápida dende aquí." && echo

xestor_comprimidos=$(gum choose --header "Selecciona un xestor de arquivos comprimidos ou preme Esc para non instalar ningún:" \
  "File Roller" \
  "Ark" \
  "Xarchiver" \
  "Engrampa" \
  "PeaZip"
)

case "$xestor_comprimidos" in
  "File Roller")
    yay -Syu --needed file-roller
    ;;
  "Ark")
    yay -Syu --needed ark
    ;;
  "Xarchiver")
    yay -Syu --needed xarchiver
    ;;
  "Engrampa")
    yay -Syu --needed engrampa
    ;;
  "PeaZip")
    yay -Syu --needed peazip-qt-bin
    ;;
esac

# Instalar xestor de discos e particións
gum style --foreground="#90CDFF" --bold "Instalar xestor de discos e particións" && echo
gum style "Un xestor de discos e particións permite administrar unidades, particións e sistemas de arquivos mediante unha interface gráfica. Instala o que elixas (ou ningún) de forma rápida dende aquí." && echo

xestor_discos=$(gum choose --header "Selecciona un xestor de discos e particións ou preme Esc para non instalar ningún:" \
  "GNOME Disks" \
  "GParted" \
  "KDE Partition Manager"
)

case "$xestor_discos" in
  "GNOME Disks")
    yay -Syu --needed gnome-disk-utility
    ;;
  "GParted")
    yay -Syu --needed gparted
    ;;
  "KDE Partition Manager")
    yay -Syu --needed partitionmanager
    ;;
esac

# Instalar calculadora
gum style --foreground="#90CDFF" --bold "Instalar calculadora" && echo
gum style "Unha calculadora permite realizar cálculos básicos, científicos e avanzados directamente dende o escritorio. Instala a que elixas (ou ningunha) de forma rápida dende aquí." && echo

calculadora=$(gum choose --header "Selecciona unha calculadora ou preme Esc para non instalar ningunha:" \
  "GNOME Calculator" \
  "KCalc" \
  "Qalculate!" \
  "SpeedCrunch" \
  "Galculator"
)

case "$calculadora" in
  "GNOME Calculator")
    yay -Syu --needed gnome-calculator
    ;;
  "KCalc")
    yay -Syu --needed kcalc
    ;;
  "Qalculate!")
    yay -Syu --needed qalculate-gtk
    ;;
  "SpeedCrunch")
    yay -Syu --needed speedcrunch
    ;;
  "Galculator")
    yay -Syu --needed galculator
    ;;
esac

# Instalar cliente de correo
gum style --foreground="#90CDFF" --bold "Instalar cliente de correo" && echo
gum style "Un cliente de correo permite xestionar as túas contas e mensaxes directamente dende o escritorio. Instala o que elixas (ou ningún) de forma rápida dende aquí." && echo

cliente_correo=$(gum choose --header "Selecciona un cliente de correo ou preme Esc para non instalar ningún:" \
  "Thunderbird" \
  "Betterbird" \
  "Geary" \
  "Evolution"
)

case "$cliente_correo" in
  "Thunderbird")
    yay -Syu --needed thunderbird
    ;;
  "Betterbird")
    yay -Syu --needed betterbird-bin
    ;;
  "Geary")
    yay -Syu --needed geary
    ;;
  "Evolution")
    yay -Syu --needed evolution
    ;;
esac

# Instalar suite ofimática
gum style --foreground="#90CDFF" --bold "Instalar suite ofimática" && echo
gum style "Unha suite ofimática permite crear e editar documentos, follas de cálculo e presentacións. Instala a que elixas (ou ningunha) de forma rápida dende aquí." && echo

suite_ofimatica=$(gum choose --header "Selecciona unha suite ofimática ou preme Esc para non instalar ningunha:" \
  "LibreOffice" \
  "ONLYOFFICE" \
  "Calligra"
)

case "$suite_ofimatica" in
  "LibreOffice")
    yay -Syu --needed libreoffice-fresh
    ;;
  "ONLYOFFICE")
    yay -Syu --needed onlyoffice-bin
    ;;
  "Calligra")
    yay -Syu --needed calligra
    ;;
esac

# Instalar aplicación de notas
gum style --foreground="#90CDFF" --bold "Instalar aplicación de notas" && echo
gum style "Unha aplicación de notas permite organizar ideas, apuntes e documentación persoal. Instala a que elixas (ou ningunha) de forma rápida dende aquí." && echo

app_notas=$(gum choose --header "Selecciona unha aplicación de notas ou preme Esc para non instalar ningunha:" \
  "Obsidian" \
  "Joplin" \
  "MarkText" \
  "Apostrophe"
)

case "$app_notas" in
  "Obsidian")
    yay -Syu --needed obsidian
    ;;
  "Joplin")
    yay -Syu --needed joplin-desktop
    ;;
  "MarkText")
    yay -Syu --needed marktext-bin
    ;;
  "Apostrophe")
    yay -Syu --needed apostrophe
    ;;
esac

# Instalar xestor de contrasinais
gum style --foreground="#90CDFF" --bold "Instalar xestor de contrasinais" && echo
gum style "Un xestor de contrasinais permite gardar e organizar credenciais de forma segura. Instala o que elixas (ou ningún) de forma rápida dende aquí." && echo

xestor_contrasinais=$(gum choose --header "Selecciona un xestor de contrasinais ou preme Esc para non instalar ningún:" \
  "KeePassXC" \
  "Bitwarden" \
  "1Password"
)

case "$xestor_contrasinais" in
  "KeePassXC")
    yay -Syu --needed keepassxc
    ;;
  "Bitwarden")
    yay -Syu --needed bitwarden
    ;;
  "1Password")
    yay -Syu --needed 1password
    ;;
esac

# Instalar cliente Torrent
gum style --foreground="#90CDFF" --bold "Instalar cliente Torrent" && echo
gum style "Un cliente Torrent permite descargar e compartir arquivos mediante o protocolo BitTorrent. Instala o que elixas (ou ningún) de forma rápida dende aquí." && echo

cliente_torrent=$(gum choose --header "Selecciona un cliente Torrent ou preme Esc para non instalar ningún:" \
  "qBittorrent" \
  "Transmission" \
  "Deluge" \
  "Fragments"
)

case "$cliente_torrent" in
  "qBittorrent")
    yay -Syu --needed qbittorrent
    ;;
  "Transmission")
    yay -Syu --needed transmission-gtk
    ;;
  "Deluge")
    yay -Syu --needed deluge
    ;;
  "Fragments")
    yay -Syu --needed fragments
    ;;
esac

# Instalar aplicacións populares
gum style --foreground="#90CDFF" --bold "Instalar outras aplicacións populares" && echo
gum style "Selecciona outras aplicacións populares que queiras instalar no teu equipo. Podes seleccionar varias opcións ou non instalar ningunha." && echo

apps_populares=$(gum choose --no-limit --header "Selecciona as aplicacións que queiras instalar ou preme Esc para non instalar ningunha:" \
  "Discord" \
  "Vesktop" \
  "OBS Studio" \
  "Krita" \
  "GIMP" \
  "Inkscape" \
  "Blender" \
  "Kdenlive" \
  "Steam (Pacman)" \
  "Steam (Flatpak)" \
  "Spotify"
)

pkgs_apps_populares=()
flatpaks_apps_populares=()

while IFS= read -r app; do
  case "$app" in
    "Discord")
      pkgs_apps_populares+=("discord")
      ;;
    "Vesktop")
      pkgs_apps_populares+=("vesktop")
      ;;
    "OBS Studio")
      pkgs_apps_populares+=("obs-studio")
      ;;
    "Krita")
      pkgs_apps_populares+=("krita")
      ;;
    "GIMP")
      pkgs_apps_populares+=("gimp")
      ;;
    "Inkscape")
      pkgs_apps_populares+=("inkscape")
      ;;
    "Blender")
      pkgs_apps_populares+=("blender")
      ;;
    "Kdenlive")
      pkgs_apps_populares+=("kdenlive")
      ;;
    "Steam (Pacman)")
      pkgs_apps_populares+=("steam")
      ;;
    "Steam (Flatpak)")
      flatpaks_apps_populares+=("com.valvesoftware.Steam")
      ;;
    "Spotify")
      pkgs_apps_populares+=("spotify")
      ;;
  esac
done <<< "$apps_populares"

if [ ${#pkgs_apps_populares[@]} -gt 0 ]; then
  yay -Syu --needed "${pkgs_apps_populares[@]}"
fi

if [ ${#flatpaks_apps_populares[@]} -gt 0 ]; then
  flatpak install -y flathub "${flatpaks_apps_populares[@]}"
fi

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

# Xerar MIME types
gum style --foreground="#90CDFF" --bold "Xerar os MIME types rexistrados" && echo
gum style "Os MIME types son os que lle indican ao sistema que aplicación por defecto usa cada arquivo, por exemplo, que aplicación abre os .mp4." && echo
gum style "Isto engadirá os mimes que necesitan as aplcacións que instalaches en ~/.config/mimeapps.list para que logo poidas editala manualmente e asociar as apps que queiras a cada un." && echo

if "$HOME/.config/gallaecia-dots/scripts/mime-merge.sh"; then
  echo && gum style --foreground="#2baf03" --bold "MIME types agregados con éxito!" && echo
else
  echo && gum style --foreground="#cc2508" --bold "Algo fallou ao xerar os novos MIME types!" && echo
fi