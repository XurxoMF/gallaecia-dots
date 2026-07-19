#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="base"

DOTFILES_DIR="$HOME/.dotfiles"
MODULES_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules"

if [ ! -r "$MODULES_DIR/ui.sh" ] ||
  [ ! -r "$MODULES_DIR/commands.sh" ] ||
  [ ! -r "$MODULES_DIR/files.sh" ] ||
  [ ! -r "$MODULES_DIR/versions.sh" ] ||
  [ ! -r "$MODULES_DIR/apps.sh" ]; then
  echo "Non se atoparon os módulos de Gallaecia Dots en $MODULES_DIR." >&2
  echo "Clona o repo en $DOTFILES_DIR e executa $DOTFILES_DIR/install.sh." >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$MODULES_DIR/ui.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/commands.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/files.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/versions.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/apps.sh"

REQUIRED_PACKAGES=(
  noto-fonts-cjk noto-fonts-emoji noto-fonts ttf-noto-nerd
  papirus-icon-theme breeze breeze-icons
  flatpak util-linux pipewire gnome-keyring libsecret greetd cage wlr-randr dbus polkit libnewt ddcutil power-profiles-daemon trash-cli
  python python-pip python-pipx ffmpeg udisks2 7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick mediainfo
  hyprland uwsm
  noctalia noctalia-greeter
  qt5-base qt6-base qt5ct qt6ct qt5-wayland qt6-wayland xsettingsd hyprland-qt-support kservice
  xdg-utils xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-user-dirs archlinux-xdg-menu
  xorg-xrandr xorg-xwayland
  adw-gtk-theme
)

PERSONAL_DIRS=(
  "$HOME/Aplicacións"
  "$HOME/Desarrollo"
  "$HOME/Descargas"
  "$HOME/Documentos"
  "$HOME/Escritorio"
  "$HOME/Imaxes"
  "$HOME/Modelos"
  "$HOME/Música"
  "$HOME/Público"
  "$HOME/Vídeos"
  "$HOME/Xogos"
)

terminal_command=""
editor_command=""
ide_command=""
browser_command=""
file_explorer_command=""

# Logo ASCII que se mostra ao comezo da instalación base.
banner() {
  echo '  _____       _ _                 _       '
  echo ' / ____|     | | |               (_)      '
  echo '| |  __  __ _| | | __ _  ___  ___ _  __ _ '
  echo '| | |_ |/ _` | | |/ _` |/ _ \/ __| |/ _` |'
  echo '| |__| | (_| | | | (_| |  __/ (__| | (_| |'
  echo ' \_____|\__,_|_|_|\__,_|\___|\___|_|\__,_|'
  echo '                                          '
}

# Mantense aquí por se a base se executa directamente desde o repo.
# O bootstrap xa instala gum/git, pero esta función fai a base máis autónoma.
install_prerequisites() {
  if ! command -v gum &> /dev/null || ! command -v git &> /dev/null; then
    echo ":: Instalando programas requeridos para executar este script (gum e git)..."
    echo
    ensure_command gum gum &&
    ensure_command git git
  fi
}

# Habilita locales galego, español e inglés e deixa galego como principal.
configure_locale() {
  sudo sed -i \
	-e 's/^#es_ES.UTF-8 UTF-8/es_ES.UTF-8 UTF-8/' \
	-e 's/^#gl_ES.UTF-8 UTF-8/gl_ES.UTF-8 UTF-8/' \
	-e 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' \
	/etc/locale.gen &&
  sudo locale-gen &&
  echo "LANG=gl_ES.UTF-8" | sudo tee /etc/locale.conf &&
  echo "LANGUAGE=gl_ES:es_ES:en_US" | sudo tee -a /etc/locale.conf
}

# Activa cores, ILoveCandy e [multilib] en pacman.
# Algúns paquetes necesarios dependen de multilib.
configure_pacman() {
  sudo sed -i \
	-e 's/^#Color/Color/' \
	-e 's/^#ILoveCandy/ILoveCandy/' \
	-e '/^#Color/a ILoveCandy' \
	-e 's/^#\[multilib\]/[multilib]/' \
	-e '/^\[multilib\]/{n; s/^#Include/Include/}' \
	/etc/pacman.conf &&
  sudo pacman -Syy
}

# Instala yay se aínda non existe.
# yay é necesario porque parte das apps/configs dependen de paquetes AUR.
install_yay() {
  if command -v yay &> /dev/null; then
    yay -Y --color always --save
    return 0
  fi

  sudo pacman -Syu --needed base-devel &&
  rm -rf ./yay &&
  git clone https://aur.archlinux.org/yay.git ./yay &&
  (
    cd yay &&
    makepkg -si
  ) &&
  sudo rm -rf yay &&
  yay -Y --color always --save
}

# Instala rustup e deixa a toolchain stable como default.
install_rust() {
  sudo pacman -Syu --needed rustup &&
  rustup default stable
}

# Instala só os paquetes obrigatorios do sistema base.
# As apps de usuario (terminal, navegador, editor...) escóllense máis abaixo.
install_required_packages() {
  yay -Syu --needed "${REQUIRED_PACKAGES[@]}" &&
  flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3-dark org.gtk.Gtk3theme.adw-gtk3
}

# Activa servizos de usuario necesarios para o escritorio.
configure_required_services() {
  systemctl --user enable gnome-keyring-daemon.service &&
  systemctl --user start gnome-keyring-daemon.service
}

# Crea as carpetas persoais esperadas e instala user-dirs.
create_personal_dirs() {
  mkdir -p "${PERSONAL_DIRS[@]}" "$HOME/.config" &&
  replace_file "$DOTFILES_DIR/.config/user-dirs.dirs" "$HOME/.config/user-dirs.dirs" &&
  replace_file "$DOTFILES_DIR/.config/user-dirs.conf" "$HOME/.config/user-dirs.conf"
}

# Instala greetd e a configuración do greeter.
install_greetd_config() {
  sudo rm -rf "/etc/greetd" "/var/lib/noctalia-greeter" &&
  sudo cp -r "$DOTFILES_DIR/others/greetd" "/etc/greetd" &&
  sudo cp -r "$DOTFILES_DIR/others/noctalia-greeter" "/var/lib/noctalia-greeter" &&
  { sudo useradd -r -s /usr/bin/nologin -d /var/lib/noctalia-greeter greeter 2> /dev/null || true; } &&
  sudo systemctl enable greetd
}

# Instala os ficheiros controlados por Gallaecia en ~/.local/share.
# Estes son actualizables porque non son configs directas do usuario.
install_gallaecia_config() {
  merge_path "$DOTFILES_DIR/.local/share/gallaecia-dots" "$HOME/.local/share/gallaecia-dots" &&
  replace_file "$DOTFILES_DIR/.config/mimeapps.list" "$HOME/.config/mimeapps.list" &&
  sudo chmod +x -R "$HOME/.local/share/gallaecia-dots/scripts" &&
  mkdir -p "$HOME/.wallpapers" &&
  cp -rf "$DOTFILES_DIR/.wallpapers/." "$HOME/.wallpapers/"
}

# Instala o .bashrc principal e os módulos de bashrc.
install_bashrc() {
  replace_file "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc" &&
  replace_path "$DOTFILES_DIR/.config/bashrc" "$HOME/.config/bashrc"
}

# Instala configuración GTK base.
install_gtk_config() {
  rm -rf "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" &&
  cp -r "$DOTFILES_DIR/.config/gtk-3.0" "$HOME/.config/gtk-3.0" &&
  cp -r "$DOTFILES_DIR/.config/gtk-4.0" "$HOME/.config/gtk-4.0"
}

# Instala configuración Qt/KDE base.
install_qt_config() {
  rm -rf "$HOME/.config/qt6ct" "$HOME/.config/qt5ct" "$HOME/.config/kdeglobals" &&
  cp -r "$DOTFILES_DIR/.config/qt6ct" "$HOME/.config/qt6ct" &&
  cp -r "$DOTFILES_DIR/.config/qt5ct" "$HOME/.config/qt5ct" &&
  cp "$DOTFILES_DIR/.config/kdeglobals" "$HOME/.config/kdeglobals"
}

# Instala configuración dos portais XDG.
install_xdg_portals() {
  replace_path "$DOTFILES_DIR/.config/xdg-desktop-portal" "$HOME/.config/xdg-desktop-portal"
}

# Instala configuración de xsettingsd.
install_xsettingsd() {
  replace_path "$DOTFILES_DIR/.config/xsettingsd" "$HOME/.config/xsettingsd"
}

# Config opcional de Kitty. Só se aplica se o usuario escolle Kitty.
install_kitty_config() {
  replace_path "$DOTFILES_DIR/optional/.config/kitty" "$HOME/.config/kitty"
}

# Config opcional de Alacritty. Iguala a fonte e o tamaño base de Kitty.
install_alacritty_config() {
  replace_path "$DOTFILES_DIR/optional/.config/alacritty" "$HOME/.config/alacritty"
}

# Config opcional de Foot. Iguala a fonte e o tamaño base de Kitty.
install_foot_config() {
  replace_path "$DOTFILES_DIR/optional/.config/foot" "$HOME/.config/foot"
}

# Config opcional de Ghostty. Iguala a fonte e o tamaño base de Kitty.
install_ghostty_config() {
  replace_path "$DOTFILES_DIR/optional/.config/ghostty" "$HOME/.config/ghostty"
}

# Config opcional de WezTerm. Iguala a fonte e o tamaño base de Kitty.
install_wezterm_config() {
  replace_path "$DOTFILES_DIR/optional/.config/wezterm" "$HOME/.config/wezterm"
}

# Config opcional de Dolphin. Só se aplica se o usuario escolle Dolphin.
install_dolphin_config() {
  replace_file "$DOTFILES_DIR/optional/.config/dolphinrc" "$HOME/.config/dolphinrc"
}

# Config opcional de Yazi e plugins recomendados.
# Só se aplica se o usuario escolle Yazi.
install_yazi_config() {
  replace_path "$DOTFILES_DIR/optional/.config/yazi" "$HOME/.config/yazi" &&
  ya pkg add yazi-rs/plugins:git &&
  ya pkg add yazi-rs/plugins:mount &&
  ya pkg add yazi-rs/plugins:chmod &&
  ya pkg add boydaihungst/restore &&
  ya pkg add boydaihungst/mediainfo
}

# Config opcional de VS Code. Só se aplica se o usuario escolle VS Code.
install_vscode_config() {
  replace_file "$DOTFILES_DIR/optional/.config/code-flags.conf" "$HOME/.config/code-flags.conf"
}

# Instala o wrapper de Hyprland en ~/.config.
# Ese ficheiro queda para o usuario; a base actualizable vive en ~/.local/share.
install_hyprland() {
  mkdir -p "$HOME/.config/hypr" &&
  replace_file "$DOTFILES_DIR/.config/hypr/hyprland.lua" "$HOME/.config/hypr/hyprland.lua"
}

# Instala Noctalia separando base e custom:
# gallaecia.toml pode actualizarse; custom.toml só se crea se non existe.
install_noctalia() {
  mkdir -p "$HOME/.config/noctalia" &&
  replace_file "$DOTFILES_DIR/.config/noctalia/gallaecia.toml" "$HOME/.config/noctalia/gallaecia.toml" &&
  if [ ! -f "$HOME/.config/noctalia/custom.toml" ]; then
    replace_file "$DOTFILES_DIR/.config/noctalia/custom.toml" "$HOME/.config/noctalia/custom.toml"
  fi
}

# Aplica todos os dotfiles base, sen apps opcionais.
# As configs de apps opcionais instálanse máis tarde segundo a selección.
install_dotfiles() {
  if install_greetd_config; then
    success "Configuración de greetd instalada con éxito!"
  else
    fail "Algo fallou ao instalar a configuración de greetd! Abortando instalación..."
  fi

  if install_gallaecia_config; then
    success "Configs propias de Gallaecia Dots instaladas con éxito!"
  else
    fail "Algo fallou ao instalar as configs propias de Gallaecia Dots! Abortando instalación..."
  fi

  if install_bashrc; then
    success "Bashrc instalado con éxito!"
  else
    fail "Algo fallou ao instalar o bashrc! Abortando instalación..."
  fi

  if install_xdg_portals; then
    success "XDG Desktop Portals configurados con éxito!"
  else
    fail "Algo fallou ao configurar os XDG Desktop Portals! Abortando instalación..."
  fi

  if install_xsettingsd; then
    success "XSettingsd configurado con éxito!"
  else
    fail "Algo fallou ao configurar o XSettingsd! Abortando instalación..."
  fi

  if install_gtk_config; then
    success "GTK3 e GTK4 configurados con éxito!"
  else
    fail "Algo fallou ao configurar GTK3 e GTK4! Abortando instalación..."
  fi

  if install_qt_config; then
    success "QT5 e QT6 configurados con éxito!"
  else
    fail "Algo fallou ao configurar QT5 e QT6! Abortando instalación..."
  fi

  if install_hyprland; then
    success "Hyprland configurado con éxito!"
  else
    fail "Algo fallou ao configurar Hyprland! Abortando instalación..."
  fi

  if install_noctalia; then
    success "Noctalia configurado con éxito!"
  else
    fail "Algo fallou ao configurar Noctalia! Abortando instalación..."
  fi
}

# Config opcional para yt-dlp e funcións de bash asociadas.
configure_yt_dlp() {
  mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" &&
  replace_path "$DOTFILES_DIR/optional/.config/yt-dlp" "$HOME/.config/yt-dlp" &&
  replace_file "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/201-yt-dlp" "$HOME/.local/share/gallaecia-dots/bashrc/201-yt-dlp"
}

# Config opcional para SpotDL.
configure_spotdl() {
  mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" &&
  replace_path "$DOTFILES_DIR/optional/.config/spotdl" "$HOME/.config/spotdl" &&
  replace_file "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/202-spotdl" "$HOME/.local/share/gallaecia-dots/bashrc/202-spotdl"
}

# Escribe ou substitúe unha asociación MIME en ~/.config/mimeapps.list.
set_default_app() {
  local mime_type="$1"
  local desktop_file="$2"
  local mimeapps="$HOME/.config/mimeapps.list"

  mkdir -p "$HOME/.config"
  touch "$mimeapps"

  if ! grep -qxF "[Default Applications]" "$mimeapps"; then
    printf '\n[Default Applications]\n' >> "$mimeapps"
  fi

  if grep -q "^${mime_type}=" "$mimeapps"; then
    sed -i "s#^${mime_type}=.*#${mime_type}=${desktop_file}#" "$mimeapps"
  else
    sed -i "/^\\[Default Applications\\]/a ${mime_type}=${desktop_file}" "$mimeapps"
  fi
}

# Aplica o mesmo .desktop a varios tipos MIME.
set_default_apps() {
  local desktop_file="$1"
  shift

  for mime_type in "$@"; do
    set_default_app "$mime_type" "$desktop_file"
  done
}

# Substitúe un placeholder {{nome}} no hyprland.lua do usuario.
# Escapamos & porque sed o interpreta como "texto atopado".
replace_hypr_placeholder() {
  local placeholder="$1"
  local value="$2"
  local hypr_config="$HOME/.config/hypr/hyprland.lua"

  value="${value//&/\\&}"
  sed -i "s#{{$placeholder}}#$value#g" "$hypr_config"
}

# Escolla das cinco categorías obrigatorias.
# Primeiro se escolle terminal porque Yazi usa "$terminal_command -e yazi"
# cando se configura como explorador de arquivos.
configure_required_apps() {
  # Cada entrada segue: "tipo|Nome|paquetes|comando|desktop".
  # A orde tamén importa: a primeira opción adoita ser a recomendada.

  # Seleccionar terminal

  local terminal_entries=(
    "pkg|Kitty|kitty|kitty|kitty.desktop"
    "pkg|Alacritty|alacritty|alacritty|Alacritty.desktop"
    "pkg|Foot|foot|foot|foot.desktop"
    "pkg|Ghostty|ghostty|ghostty|com.mitchellh.ghostty.desktop"
    "pkg|WezTerm|wezterm|wezterm|org.wezfurlong.wezterm.desktop"
  )

  choose_required_category \
    "Selecciona terminal ou terminais:" \
    "${terminal_entries[@]}"
  
  DEFAULT_ENTRY=$(choose_default_entry "Escolle terminal por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
  terminal_command="$(app_command "$DEFAULT_ENTRY")"

  replace_hypr_placeholder "terminal" "$terminal_command"

  if has_selected_app kitty; then
    install_kitty_config || return 1
  fi

  if has_selected_app alacritty; then
    install_alacritty_config || return 1
  fi

  if has_selected_app foot; then
    install_foot_config || return 1
  fi

  if has_selected_app ghostty; then
    install_ghostty_config || return 1
  fi

  if has_selected_app wezterm; then
    install_wezterm_config || return 1
  fi

  # Seleccionar editor

  local editor_entries=(
    "pkg|Neovim|neovim|nvim|nvim.desktop"
    "pkg|Helix|helix|hx|"
    "pkg|Vim|vim|vim|vim.desktop"
    "pkg|Nano|nano|nano|"
    "pkg|Micro|micro|micro|"
  )

  choose_required_category \
    "Selecciona editor ou editores de terminal:" \
    "${editor_entries[@]}"

  DEFAULT_ENTRY=$(choose_default_entry "Escolle editor de terminal por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
  editor_command="$(app_command "$DEFAULT_ENTRY")"

  replace_hypr_placeholder "editor" "$editor_command"

  # Seleccionar IDE

  local ide_entries=(
    "pkg|Visual Studio Code|visual-studio-code-bin|code|visual-studio-code.desktop"
    "pkg|Zed|zed|zed|dev.zed.Zed.desktop"
    "pkg|Obsidian|obsidian|obsidian|obsidian.desktop"
    "pkg|Geany|geany|geany|geany.desktop"
  )

  choose_required_category \
    "Selecciona IDE ou editores con interface gráfica:" \
    "${ide_entries[@]}"

  DEFAULT_ENTRY=$(choose_default_entry "Escolle IDE por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
  ide_command="$(app_command "$DEFAULT_ENTRY")"

  replace_hypr_placeholder "ide" "$ide_command"

  if [ -n "$(app_desktop "$DEFAULT_ENTRY")" ]; then
    set_default_apps "$(app_desktop "$DEFAULT_ENTRY")" text/plain
  fi

  if has_selected_app visual-studio-code-bin; then
    install_vscode_config || return 1
  fi

  # Seleccionar buscador

  local browser_entries=(
    "pkg|Firefox|firefox|firefox|firefox.desktop"
    "pkg|LibreWolf|librewolf-bin|librewolf|librewolf.desktop"
    "pkg|Zen Browser|zen-browser|zen-browser|zen.desktop"
    "pkg|Tor Browser|tor-browser-bin|tor-browser|torbrowser.desktop"
  )

  choose_required_category \
    "Selecciona navegador ou navegadores:" \
    "${browser_entries[@]}"

  DEFAULT_ENTRY=$(choose_default_entry "Escolle navegador por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
  browser_command="$(app_command "$DEFAULT_ENTRY")"

  replace_hypr_placeholder "navegador" "$browser_command"

  set_default_apps "$(app_desktop "$DEFAULT_ENTRY")" \
    text/html application/xhtml+xml x-scheme-handler/http x-scheme-handler/https

  # Seleccionar explorador de arquivos

  local file_explorer_entries=(
    "pkg|Dolphin|dolphin|dolphin|org.kde.dolphin.desktop"
    "pkg|Nautilus|nautilus|nautilus|org.gnome.Nautilus.desktop"
    "pkg|Nemo|nemo|nemo|nemo.desktop"
    "pkg|Yazi|yazi|$terminal_command -e yazi|"
  )

  choose_required_category \
    "Selecciona explorador ou exploradores de arquivos:" \
    "${file_explorer_entries[@]}"

  DEFAULT_ENTRY=$(choose_default_entry "Escolle explorador de arquivos por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
  file_explorer_command="$(app_command "$DEFAULT_ENTRY")"

  replace_hypr_placeholder "explorador_de_arquivos" "$file_explorer_command"

  if has_selected_app dolphin; then
    install_dolphin_config || return 1
  fi

  if has_selected_app yazi; then
    install_yazi_config || return 1
  fi
}

# Escolla das categorías opcionais e asociacións MIME relacionadas.
configure_optional_apps() {
  local audio_desktop
  local video_desktop
  local pdf_desktop
  local image_desktop
  local mail_desktop

  # Nestas categorías o usuario pode non escoller nada.
  # Se escolle varias apps nunha categoría con MIME, pedimos cal queda por defecto.

  # Escoller resproductores de audio

  local audio_entries=(
    "pkg|Amberol|amberol|amberol|io.bassi.Amberol.desktop"
    "pkg|Tauon|tauon-music-box|tauon|com.github.taiko2k.tauonmb.desktop"
    "pkg|VLC|vlc vlc-plugins-all|vlc|vlc.desktop"
    "pkg|MPV|mpv|mpv|mpv.desktop"
  )

  choose_optional_category "Selecciona reprodutor ou reprodutores de audio:" "${audio_entries[@]}"

  if [ ${#SELECTED_ENTRIES[@]} -gt 0 ]; then
    DEFAULT_ENTRY=$(choose_default_entry "Escolle reprodutor de audio por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
    audio_desktop="$(app_desktop "$DEFAULT_ENTRY")"
  fi

  if [ -n "$audio_desktop" ]; then
    set_default_apps "$audio_desktop" \
      audio/aac audio/flac audio/mpeg audio/ogg audio/opus audio/wav audio/x-wav audio/x-ms-wma
  fi

  # Escoller resproductores de vídeo

  local video_entries=(
    "pkg|VLC|vlc vlc-plugins-all|vlc|vlc.desktop"
    "pkg|MPV|mpv|mpv|mpv.desktop"
    "pkg|Clapper|clapper|clapper|com.github.rafostar.Clapper.desktop"
  )

  choose_optional_category "Selecciona reprodutor ou reprodutores de vídeo:" "${video_entries[@]}"

  if [ ${#SELECTED_ENTRIES[@]} -gt 0 ]; then
    DEFAULT_ENTRY=$(choose_default_entry "Escolle reprodutor de vídeo por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
    video_desktop="$(app_desktop "$DEFAULT_ENTRY")"
  fi

  if [ -n "$video_desktop" ]; then
    set_default_apps "$video_desktop" \
      video/mp2t video/mp4 video/mpeg video/ogg video/quicktime video/webm video/x-matroska video/x-msvideo video/x-ms-wmv
  fi

  # Escoller visores de PDF

  local pdf_entries=(
    "pkg|Okular|okular|okular|org.kde.okular.desktop"
    "pkg|Zathura|zathura zathura-pdf-mupdf|zathura|org.pwmt.zathura.desktop"
    "pkg|Evince|evince|evince|org.gnome.Evince.desktop"
  )

  choose_optional_category "Selecciona visor ou visores de PDF:" "${pdf_entries[@]}"

  if [ ${#SELECTED_ENTRIES[@]} -gt 0 ]; then
    DEFAULT_ENTRY=$(choose_default_entry "Escolle visor de PDF por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
    pdf_desktop="$(app_desktop "$DEFAULT_ENTRY")"
  fi

  if [ -n "$pdf_desktop" ]; then
    set_default_apps "$pdf_desktop" \
      application/pdf application/epub+zip application/vnd.comicbook+zip application/vnd.djvu image/vnd.djvu application/oxps application/vnd.ms-xpsdocument
  fi

  # Escoller visores de imaxes

  local image_entries=(
    "pkg|Loupe|loupe|loupe|org.gnome.Loupe.desktop"
    "pkg|GIMP|gimp|gimp|org.gimp.GIMP.desktop"
    "pkg|Krita|krita|krita|org.kde.krita.desktop"
  )

  choose_optional_category "Selecciona visor ou visores de imaxes:" "${image_entries[@]}"

  if [ ${#SELECTED_ENTRIES[@]} -gt 0 ]; then
    DEFAULT_ENTRY=$(choose_default_entry "Escolle visor de imaxes por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
    image_desktop="$(app_desktop "$DEFAULT_ENTRY")"
  fi

  if [ -n "$image_desktop" ]; then
    set_default_apps "$image_desktop" \
      image/avif image/bmp image/gif image/heif image/jpeg image/jxl image/png image/tiff image/webp image/x-xcf image/vnd.adobe.photoshop
  fi

  # Escoller clientes de correo

  local mail_entries=(
    "pkg|Thunderbird|thunderbird|thunderbird|thunderbird.desktop"
  )

  choose_optional_category "Selecciona cliente ou clientes de correo:" "${mail_entries[@]}"

  if [ ${#SELECTED_ENTRIES[@]} -gt 0 ]; then
    DEFAULT_ENTRY=$(choose_default_entry "Escolle cliente de correo por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
    mail_desktop="$(app_desktop "$DEFAULT_ENTRY")"
  fi

  if [ -n "$mail_desktop" ]; then
    set_default_apps "$mail_desktop" message/rfc822 x-scheme-handler/mailto x-scheme-handler/mid
  fi

  # Escoller apps de chat

  local chat_entries=(
    "pkg|Discord|discord|discord|discord.desktop"
    "pkg|Vesktop|vesktop|vesktop|vesktop.desktop"
    "pkg|Telegram|telegram-desktop|telegram-desktop|org.telegram.desktop.desktop"
    "pkg|Element|element-desktop|element-desktop|"
  )

  choose_optional_category "Selecciona apps de chat:" "${chat_entries[@]}"

  if has_selected_app vesktop; then
    set_default_apps vesktop.desktop x-scheme-handler/discord
  elif has_selected_app discord; then
    set_default_apps discord.desktop x-scheme-handler/discord
  fi

  # Escoller apps creativas

  local creative_entries=(
    "pkg|OBS Studio|obs-studio|obs|com.obsproject.Studio.desktop"
    "pkg|Krita|krita|krita|org.kde.krita.desktop"
    "pkg|GIMP|gimp|gimp|org.gimp.GIMP.desktop"
    "pkg|Inkscape|inkscape|inkscape|org.inkscape.Inkscape.desktop"
    "pkg|Blender|blender|blender|blender.desktop"
    "pkg|Kdenlive|kdenlive|kdenlive|org.kde.kdenlive.desktop"
    "pkg|Puddletag|puddletag|puddletag|"
    "pkg|HandBrake|handbrake|handbrake|"
  )

  choose_optional_category "Selecciona apps creativas:" "${creative_entries[@]}"

  if has_selected_app krita; then
    set_default_apps org.kde.krita.desktop application/x-krita image/openraster
  fi

  if has_selected_app inkscape; then
    set_default_apps org.inkscape.Inkscape.desktop image/svg+xml image/svg+xml-compressed application/postscript application/illustrator application/eps
  fi

  if has_selected_app blender; then
    set_default_apps blender.desktop application/x-blender
  fi

  if has_selected_app kdenlive; then
    set_default_apps org.kde.kdenlive.desktop application/x-kdenlive application/x-kdenlivetitle
  fi

  # Escoller apps de ofimática

  local office_entries=(
    "pkg|LibreOffice|libreoffice-still libreoffice-still-gl libreoffice-still-es|libreoffice|libreoffice-writer.desktop"
    "pkg|Obsidian|obsidian|obsidian|obsidian.desktop"
  )

  choose_optional_category "Selecciona apps de oficina e notas:" "${office_entries[@]}"

  if has_selected_app libreoffice-still; then
    set_default_apps libreoffice-writer.desktop \
      application/msword application/rtf application/vnd.oasis.opendocument.text \
      application/vnd.openxmlformats-officedocument.wordprocessingml.document text/rtf
    set_default_apps libreoffice-calc.desktop \
      application/vnd.ms-excel application/vnd.oasis.opendocument.spreadsheet \
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    set_default_apps libreoffice-impress.desktop \
      application/vnd.ms-powerpoint application/vnd.oasis.opendocument.presentation \
      application/vnd.openxmlformats-officedocument.presentationml.presentation
    set_default_apps libreoffice-draw.desktop application/vnd.oasis.opendocument.graphics
  fi

  # Escoller apps de xogos

  local gaming_entries=(
    "pkg|Steam|steam|steam|steam.desktop"
    "pkg|Prism Launcher|prismlauncher|prismlauncher|org.prismlauncher.PrismLauncher.desktop"
    "pkg|Lutris|lutris|lutris|"
    "flatpak|Bottles|com.usebottles.bottles|flatpak run com.usebottles.bottles|com.usebottles.bottles.desktop"
  )

  choose_optional_category "Selecciona xogos e tendas:" "${gaming_entries[@]}"

  if has_selected_app steam; then
    set_default_apps steam.desktop x-scheme-handler/steam x-scheme-handler/steamlink
  fi

  # Escoller apps de utilidades

  local utilities_entries=(
    "pkg|KeePassXC|keepassxc|keepassxc|org.keepassxc.KeePassXC.desktop"
    "pkg|qBittorrent|qbittorrent|qbittorrent|org.qbittorrent.qBittorrent.desktop"
  )

  choose_optional_category "Selecciona utilidades:" "${utilities_entries[@]}"

  if has_selected_app qbittorrent; then
    set_default_apps org.qbittorrent.qBittorrent.desktop application/x-bittorrent x-scheme-handler/magnet
  fi

  # Escoller apps de desenvolvemento

  local development_entries=(
    "flatpak|Bruno|com.usebruno.Bruno|bruno|"
    "pkg|FileZilla|filezilla|filezilla|"
  )

  choose_optional_category "Selecciona apps de desenvolvemento:" "${development_entries[@]}"

  # Escoller apps de rede e privacidade

  local network_entries=(
    "flatpak|Proton VPN|com.protonvpn.www|protonvpn|"
  )

  choose_optional_category "Selecciona apps de rede e privacidade:" "${network_entries[@]}"

  # Escoller scripts

  local script_entries=(
    "pkg|yt-dlp|yt-dlp|yt-dlp|"
    "pipx|SpotDL|spotdl|spotdl|"
  )

  choose_optional_category "Selecciona ferramentas de descarga e personalización:" "${script_entries[@]}"

  if has_selected_app yt-dlp; then
    configure_yt_dlp || return 1
  fi

  if has_pipx_app spotdl; then
    configure_spotdl || return 1
  fi
}

# Instalación base completa.
# Se "base" xa aparece en versions-instaladas, non repite o proceso.
install_base_version() {
  if is_version_installed "$VERSION"; then
    info "Gallaecia Dots $VERSION xa está instalado. Saltando instalación base..."
    return 0
  fi

  info "Agora que temos os dotfiles descargados, vamos a instalalos!"

  echo

  title "Cambiar idioma a Galego"
  info "Como bos dotfiles en Galego, temos que cambiar o idioma a Galego. Se engade un fallback a Español e logo a Inglés en caso de non haber nigún dos dous."

  echo

  if configure_locale; then
    success "Idioma cambiado con éxito!"
  else
    fail "Algo fallou ao cambiar o idioma! Abortando instalación..."
  fi

  title "Habilitar [multilib] e cores en pacman"
  info "Algúns dos paquetes obligatorios están en multilib polo que temos que habilitala."

  echo

  if configure_pacman; then
    success "[multilib] habilitado con éxito e cores activadas!"
  else
    fail "Algo fallou ao habilitar [multilib] ou activar cores! Abortando instalación..."
  fi

  title "Instalar paquetes obligatorios"
  info "Os programas obligatorios inclúen, entre outros, yay, Rust, Flatpak, Hyprland e Noctalia."

  echo

  if install_yay; then
    success "YAY instalado con éxito!"
  else
    fail "Algo fallou ao instalar YAY! Abortando instalación..."
  fi

  if install_rust; then
    success "Rust instalado con éxito!"
  else
    fail "Algo fallou durante a instalación de Rust! Abortando instalación..."
  fi

  if install_required_packages; then
    success "Paquetes requeridos instalados con éxito!"
  else
    fail "Algo fallou durante a instalación dos paquetes obligatorios! Abortando instalación..."
  fi

  if configure_required_services; then
    success "Servizos requeridos configurados con éxito!"
  else
    fail "Algo fallou durante a configuración dos servizos obligatorios! Abortando instalación..."
  fi

  title "Crear carpetas personales e configuralas"
  info "Os dotfiles necesitan multiples carpetas para certas cousas polo que é necesario crealas e configuralas."
  info "Estas carpetas son Aplicacións, Desarrollo, Descargas, Documentos, Escritorio, Imaxes, Modelos, Música, Público, Vídeos, e Xogos."
  info "Inda que como usuario non precises estas carpetas, certas funcionalidades incluídas nestes dotfiles e en certas aplicacións precisan que esas carpetas existan se non poden fallar ou non funcionar correctamente."

  echo

  if create_personal_dirs; then
    success "Carpetas creadas con éxito!"
  else
    fail "Algo fallou durante a creación das carpetas! Abortando instalación..."
  fi

  title "Instalar dotfiles"
  info "Todos os paquetes necesitan unha configuración tanto para o funcionamento como para os estilos. Iso mismo son os dotfiles."

  echo

  if install_dotfiles; then
    success "Dotfiles instalados con éxito!"
  else
    fail "Algo fallou ao instalar os dotfiles! Abortando instalación..."
  fi

  info "Xa temos os dotfiles base instalados e configurados! Agora imos escoller aplicacións."

  echo

  title "Aplicacións principais"
  info "Selecciona polo menos unha aplicación por categoría. Se escolles varias, poderás indicar cal usar por defecto."

  echo

  if configure_required_apps; then
    success "Aplicacións principais seleccionadas con éxito!"
  else
    fail "Algo fallou ao seleccionar as aplicacións principais! Abortando instalación..."
  fi

  echo

  title "Aplicacións opcionais"
  info "Selecciona aplicacións opcionais por categoría. Podes deixar categorías baleiras."

  echo

  if configure_optional_apps; then
    success "Aplicacións opcionais seleccionadas con éxito!"
  else
    fail "Algo fallou ao seleccionar as aplicacións opcionais! Abortando instalación..."
  fi

  echo
  title "Resumo da instalación de apps"
  # shellcheck disable=SC2154
  info "Paquetes pacman/AUR pendentes: ${#pkgs_apps[@]}"
  # shellcheck disable=SC2154
  info "Paquetes Flatpak pendentes: ${#flatpaks_apps[@]}"
  # shellcheck disable=SC2154
  info "Paquetes pipx pendentes: ${#pipx_apps[@]}"

  if [ ${#pkgs_apps[@]} -gt 0 ]; then
    info "Pacman/AUR: ${pkgs_apps[*]}"
  fi

  if [ ${#flatpaks_apps[@]} -gt 0 ]; then
    info "Flatpak: ${flatpaks_apps[*]}"
  fi

  if [ ${#pipx_apps[@]} -gt 0 ]; then
    info "Pipx: ${pipx_apps[*]}"
  fi
  echo

  if install_selected_apps; then
    success "Aplicacións instaladas con éxito!"
  else
    fail "Algo fallou ao instalar as aplicacións seleccionadas! Abortando instalación..."
  fi

}

# Fluxo principal da base: prepara estado, mostra benvida e instala a base.
main() {
  clear
  if ! ensure_gallaecia_state_dir; then
    fail "Non se puido preparar o estado de versións de Gallaecia Dots! Abortando instalación..."
  fi
  clear

  banner

  title "BENVID@ AO INSTALADOR DE GALLAECIA DOTS!"
  info "Con este script poderás instalar os dotfiles paso por paso para que poidas personalizar algunhas cousas e gardar copias de seguridade antes de que se sobreescriban polos dotfiles."
  info "Simplemente responde as preguntas que irán aparecendo en pantalla deixa que ocurra a maxia pagana."

  echo

  if ! gum_confirm "Queres instalar Gallaecia Dots agora?"; then
    info "Instalación cancelada."
    exit 0
  fi

  info "Instalando Gallaecia Dots desde $DOTFILES_DIR."

  install_base_version

  title "Reiniciar o sistema"
  info "Recoméndase reiniciar o sistema para aplicar correctamente todos os cambios."
  
  echo

  if gum_confirm "Reiniciar o sistema agora?"; then
    systemctl reboot
  fi
}

main "$@"
