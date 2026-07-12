#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="2.2.0-09-07-2026"
DOTFILES_DIR="$HOME/.dotfiles"
GREEN="#2baf03"
RED="#cc2508"
BLUE="#90CDFF"
YELLOW="#D6C104"

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
  kitty seahorse neovim visual-studio-code-bin dolphin yazi firefox tor-browser-bin
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

pkgs_apps=()
flatpaks_apps=()
pipx_apps=()

banner() {
  echo '  _____       _ _                 _       '
  echo ' / ____|     | | |               (_)      '
  echo '| |  __  __ _| | | __ _  ___  ___ _  __ _ '
  echo '| | |_ |/ _` | | |/ _` |/ _ \/ __| |/ _` |'
  echo '| |__| | (_| | | | (_| |  __/ (__| | (_| |'
  echo ' \_____|\__,_|_|_|\__,_|\___|\___|_|\__,_|'
  echo '                                          '
}

gum_style() {
  gum style \
	--background="" \
	--border-background="" \
	--border-foreground="$BLUE" \
	--margin="0 0" \
	--padding="0 0" \
	"$@"
}

info() {
  gum_style \
	--foreground="#dbe3ed" \
	"$@"
}

title() {
  gum_style \
	--foreground="$BLUE" \
	--bold \
	"$1"
  echo
}

warning() {
  gum_style \
	--foreground="$YELLOW" \
	--bold \
	"$1"
}

success() {
  echo
  gum_style \
	--foreground="$GREEN" \
	--bold \
	"$1"
  echo
}

fail() {
  echo
  gum_style \
	--foreground="$RED" \
	--bold \
	"$1"
  exit 1
}

gum_confirm() {
  gum confirm \
	--affirmative="Si" \
	--negative="No" \
	--prompt.foreground="#90cdff" \
	--prompt.background="" \
	--selected.foreground="#003350" \
	--selected.background="#90cdff" \
	--unselected.foreground="#cce6ff" \
	--unselected.background="#004b72" \
	--padding="0 0" \
	"$@"
}

gum_choose() {
  gum choose \
	--cursor.foreground="#90cdff" \
	--cursor.background="" \
	--header.foreground="#dbe3ed" \
	--header.background="" \
	--item.foreground="#dbe3ed" \
	--item.background="" \
	--selected.foreground="#90cdff" \
	--selected.background="" \
	--padding="0 0" \
	"$@"
}

confirm_or_abort() {
  local question="$1"
  local abort_message="$2"

  if ! gum_confirm "$question"; then
    gum_style \
		--foreground="$RED" \
		--bold \
		"$abort_message"
    exit 1
  fi
}

confirm_step() {
  local question="$1"
  local success_message="$2"
  local error_message="$3"
  local step="$4"

  if gum_confirm "$question"; then
    run_step \
		"$success_message" \
		"$error_message" \
		"$step"
  fi
}

run_step() {
  local success_message="$1"
  local error_message="$2"
  local step="$3"

  if "$step"; then
    success "$success_message"
  else
    fail "$error_message"
  fi
}

replace_path() {
  local source="$1"
  local target="$2"

  rm -rf "$target" && cp -r "$source" "$target"
}

replace_file() {
  local source="$1"
  local target="$2"

  rm -f "$target" && cp "$source" "$target"
}

ensure_command() {
  local command_name="$1"
  local package_name="$2"

  if ! command -v "$command_name" &> /dev/null; then
    sudo pacman -Sy --needed "$package_name"
  fi
}

install_prerequisites() {
  if ! command -v gum &> /dev/null || ! command -v git &> /dev/null; then
    echo ":: Instalando programas requeridos para executar este script (gum e git)..."
    echo
    ensure_command gum gum &&
    ensure_command git git
  fi
}

download_dotfiles() {
  rm -rf "$DOTFILES_DIR" &&
  git clone https://github.com/XurxoMF/gallaecia-dots.git "$DOTFILES_DIR"
}

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

install_rust() {
  sudo pacman -Syu --needed rustup &&
  rustup default stable
}

install_required_packages() {
  yay -Syu --needed "${REQUIRED_PACKAGES[@]}" &&
  flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3-dark org.gtk.Gtk3theme.adw-gtk3
}

configure_required_services() {
  systemctl --user enable gnome-keyring-daemon.service &&
  systemctl --user start gnome-keyring-daemon.service
}

create_personal_dirs() {
  mkdir -p "${PERSONAL_DIRS[@]}" "$HOME/.config" &&
  replace_file "$DOTFILES_DIR/.config/user-dirs.dirs" "$HOME/.config/user-dirs.dirs" &&
  replace_file "$DOTFILES_DIR/.config/user-dirs.conf" "$HOME/.config/user-dirs.conf"
}

install_greetd_config() {
  sudo rm -rf "/etc/greetd" "/var/lib/noctalia-greeter" &&
  sudo cp -r "$DOTFILES_DIR/others/greetd" "/etc/greetd" &&
  sudo cp -r "$DOTFILES_DIR/others/noctalia-greeter" "/var/lib/noctalia-greeter" &&
  { sudo useradd -r -s /usr/bin/nologin -d /var/lib/noctalia-greeter greeter 2> /dev/null || true; } &&
  sudo systemctl enable greetd
}

install_gallaecia_config() {
  replace_path "$DOTFILES_DIR/.config/gallaecia-dots" "$HOME/.config/gallaecia-dots" &&
  replace_file "$DOTFILES_DIR/.config/mimeapps.list" "$HOME/.config/mimeapps.list" &&
  sudo chmod +x -R "$HOME/.config/gallaecia-dots/scripts" &&
  mkdir -p "$HOME/.wallpapers" &&
  cp -rf "$DOTFILES_DIR/.wallpapers/." "$HOME/.wallpapers/"
}

install_bashrc() {
  replace_file "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc" &&
  replace_path "$DOTFILES_DIR/.config/bashrc" "$HOME/.config/bashrc" &&
  source "$HOME/.bashrc"
}

install_gtk_config() {
  rm -rf "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" &&
  cp -r "$DOTFILES_DIR/.config/gtk-3.0" "$HOME/.config/gtk-3.0" &&
  cp -r "$DOTFILES_DIR/.config/gtk-4.0" "$HOME/.config/gtk-4.0"
}

install_qt_config() {
  rm -rf "$HOME/.config/qt6ct" "$HOME/.config/qt5ct" "$HOME/.config/kdeglobals" &&
  cp -r "$DOTFILES_DIR/.config/qt6ct" "$HOME/.config/qt6ct" &&
  cp -r "$DOTFILES_DIR/.config/qt5ct" "$HOME/.config/qt5ct" &&
  cp "$DOTFILES_DIR/.config/kdeglobals" "$HOME/.config/kdeglobals"
}

install_xdg_portals() {
  replace_path "$DOTFILES_DIR/.config/xdg-desktop-portal" "$HOME/.config/xdg-desktop-portal"
}

install_xsettingsd() {
  replace_path "$DOTFILES_DIR/.config/xsettingsd" "$HOME/.config/xsettingsd"
}

install_kitty() {
  replace_path "$DOTFILES_DIR/.config/kitty" "$HOME/.config/kitty"
}

install_dolphin() {
  replace_file "$DOTFILES_DIR/.config/dolphinrc" "$HOME/.config/dolphinrc"
}

install_yazi() {
  replace_path "$DOTFILES_DIR/.config/yazi" "$HOME/.config/yazi" &&
  ya pkg add yazi-rs/plugins:git &&
  ya pkg add yazi-rs/plugins:mount &&
  ya pkg add yazi-rs/plugins:chmod &&
  ya pkg add boydaihungst/restore &&
  ya pkg add boydaihungst/mediainfo
}

install_vscode() {
  replace_file "$DOTFILES_DIR/.config/code-flags.conf" "$HOME/.config/code-flags.conf"
}

install_hyprland() {
  replace_path "$DOTFILES_DIR/.config/hypr" "$HOME/.config/hypr"
}

install_noctalia() {
  replace_path "$DOTFILES_DIR/.config/noctalia" "$HOME/.config/noctalia"
}

install_dotfiles() {
  run_step \
	"Configuración de greetd instalada con éxito!" \
	"Algo fallou ao instalar a configuración de greetd! Abortando instalación..." \
	install_greetd_config

  run_step \
	"Configs propias de Gallaecia Dots instaladas con éxito!" \
	"Algo fallou ao instalar as configs propias de Gallaecia Dots! Abortando instalación..." \
	install_gallaecia_config

  run_step \
	"Bashrc instalado con éxito!" \
	"Algo fallou ao instalar o bashrc! Abortando instalación..." \
	install_bashrc

  run_step \
	"XDG Desktop Portals configurados con éxito!" \
	"Algo fallou ao configurar os XDG Desktop Portals! Abortando instalación..." \
	install_xdg_portals

  run_step \
	"XSettingsd configurado con éxito!" \
	"Algo fallou ao configurar o XSettingsd! Abortando instalación..." \
	install_xsettingsd

  run_step \
	"GTK3 e GTK4 configurados con éxito!" \
	"Algo fallou ao configurar GTK3 e GTK4! Abortando instalación..." \
	install_gtk_config

  run_step \
	"QT5 e QT6 configurados con éxito!" \
	"Algo fallou ao configurar QT5 e QT6! Abortando instalación..." \
	install_qt_config

  run_step \
	"Kitty configurado con éxito!" \
	"Algo fallou ao configurar Kitty! Abortando instalación..." \
	install_kitty

  run_step \
	"Dolphin configurado con éxito!" \
	"Algo fallou ao configurar Dolphin! Abortando instalación..." \
	install_dolphin

  run_step \
	"Yazi configurado con éxito!" \
	"Algo fallou ao configurar Yazi! Abortando instalación..." \
	install_yazi

  run_step \
	"VS Code configurado con éxito!" \
	"Algo fallou ao configurar VS Code! Abortando instalación..." \
	install_vscode

  run_step \
	"Hyprland configurado con éxito!" \
	"Algo fallou ao configurar Hyprland! Abortando instalación..." \
	install_hyprland

  run_step \
	"Noctalia configurado con éxito!" \
	"Algo fallou ao configurar Noctalia! Abortando instalación..." \
	install_noctalia
}

configure_yt_dlp() {
  replace_path "$DOTFILES_DIR/optional/.config/yt-dlp" "$HOME/.config/yt-dlp" &&
  replace_file "$DOTFILES_DIR/optional/.config/bashrc/201-yt-dlp" "$HOME/.config/bashrc/201-yt-dlp" &&
  source "$HOME/.bashrc"
}

configure_spotdl() {
  replace_path "$DOTFILES_DIR/optional/.config/spotdl" "$HOME/.config/spotdl"
}

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

set_default_apps() {
  local desktop_file="$1"
  shift

  for mime_type in "$@"; do
    set_default_app "$mime_type" "$desktop_file"
  done
}

has_pkg_app() {
  local package_name="$1"
  local app

  for app in "${pkgs_apps[@]}"; do
    if [ "$app" = "$package_name" ]; then
      return 0
    fi
  done

  return 1
}

choose_default_desktop() {
  local header="$1"
  shift
  local choices=("$@")
  local selected

  case "${#choices[@]}" in
    0)
      return 1
      ;;
    1)
      printf '%s\n' "${choices[0]#*|}"
      return 0
      ;;
  esac

  selected=$(gum_choose \
    --header "$header" \
    "${choices[@]%%|*}")

  case "$selected" in
    "Amberol") printf '%s\n' "io.bassi.Amberol.desktop" ;;
    "Discord") printf '%s\n' "discord.desktop" ;;
    "Firefox") printf '%s\n' "firefox.desktop" ;;
    "GIMP") printf '%s\n' "org.gimp.GIMP.desktop" ;;
    "Inkscape") printf '%s\n' "org.inkscape.Inkscape.desktop" ;;
    "Krita") printf '%s\n' "org.kde.krita.desktop" ;;
    "LibreOffice") printf '%s\n' "libreoffice-writer.desktop" ;;
    "Loupe") printf '%s\n' "org.gnome.Loupe.desktop" ;;
    "MPV") printf '%s\n' "mpv.desktop" ;;
    "Okular") printf '%s\n' "org.kde.okular.desktop" ;;
    "Vesktop") printf '%s\n' "vesktop.desktop" ;;
    "VLC") printf '%s\n' "vlc.desktop" ;;
    *) return 1 ;;
  esac
}

configure_optional_mimeapps() {
  local image_choices=("Firefox|firefox.desktop")
  local vector_choices=("Firefox|firefox.desktop")
  local video_choices=("Firefox|firefox.desktop")
  local music_choices=("Firefox|firefox.desktop")
  local document_choices=("Firefox|firefox.desktop")
  local chat_choices=()
  local image_desktop vector_desktop video_desktop music_desktop document_desktop chat_desktop

  if has_pkg_app loupe; then
    image_choices=("Loupe|org.gnome.Loupe.desktop" "${image_choices[@]}")
  fi
  if has_pkg_app krita; then
    image_choices+=("Krita|org.kde.krita.desktop")
    vector_choices+=("Krita|org.kde.krita.desktop")
    set_default_apps org.kde.krita.desktop application/x-krita image/openraster
  fi
  if has_pkg_app gimp; then
    image_choices+=("GIMP|org.gimp.GIMP.desktop")
  fi
  if has_pkg_app inkscape; then
    vector_choices=("Inkscape|org.inkscape.Inkscape.desktop" "${vector_choices[@]}")
    set_default_apps org.inkscape.Inkscape.desktop application/illustrator application/eps
  fi
  if has_pkg_app okular; then
    document_choices=("Okular|org.kde.okular.desktop" "${document_choices[@]}")
  fi
  if has_pkg_app libreoffice-still; then
    document_choices+=("LibreOffice|libreoffice-writer.desktop")
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
  if has_pkg_app amberol; then
    music_choices=("Amberol|io.bassi.Amberol.desktop" "${music_choices[@]}")
  fi
  if has_pkg_app vlc; then
    video_choices+=("VLC|vlc.desktop")
    music_choices+=("VLC|vlc.desktop")
  fi
  if has_pkg_app mpv; then
    video_choices+=("MPV|mpv.desktop")
    music_choices+=("MPV|mpv.desktop")
  fi
  if has_pkg_app discord; then
    chat_choices+=("Discord|discord.desktop")
  fi
  if has_pkg_app vesktop; then
    chat_choices+=("Vesktop|vesktop.desktop")
  fi

  image_desktop=$(choose_default_desktop "Escolle visor de imaxes por defecto:" "${image_choices[@]}") &&
  set_default_apps "$image_desktop" \
    image/avif image/bmp image/gif image/heif image/jpeg image/jxl image/png image/tiff image/webp image/x-xcf image/vnd.adobe.photoshop

  vector_desktop=$(choose_default_desktop "Escolle visor/editor vectorial por defecto:" "${vector_choices[@]}") &&
  set_default_apps "$vector_desktop" image/svg+xml image/svg+xml-compressed application/postscript

  video_desktop=$(choose_default_desktop "Escolle reprodutor de vídeo por defecto:" "${video_choices[@]}") &&
  set_default_apps "$video_desktop" \
    video/mp2t video/mp4 video/mpeg video/ogg video/quicktime video/webm video/x-matroska video/x-msvideo video/x-ms-wmv

  music_desktop=$(choose_default_desktop "Escolle reprodutor de música por defecto:" "${music_choices[@]}") &&
  set_default_apps "$music_desktop" \
    audio/aac audio/flac audio/mpeg audio/ogg audio/opus audio/wav audio/x-wav audio/x-ms-wma

  document_desktop=$(choose_default_desktop "Escolle visor de documentos por defecto:" "${document_choices[@]}") &&
  set_default_apps "$document_desktop" \
    application/pdf application/epub+zip application/vnd.comicbook+zip application/vnd.djvu image/vnd.djvu application/oxps application/vnd.ms-xpsdocument

  chat_desktop=$(choose_default_desktop "Escolle cliente de Discord por defecto:" "${chat_choices[@]}") &&
  set_default_apps "$chat_desktop" x-scheme-handler/discord

  if has_pkg_app qbittorrent; then
    set_default_apps org.qbittorrent.qBittorrent.desktop application/x-bittorrent x-scheme-handler/magnet
  fi
  if has_pkg_app blender; then
    set_default_apps blender.desktop application/x-blender
  fi
  if has_pkg_app kdenlive; then
    set_default_apps org.kde.kdenlive.desktop application/x-kdenlive application/x-kdenlivetitle
  fi
  if has_pkg_app steam; then
    set_default_apps steam.desktop x-scheme-handler/steam x-scheme-handler/steamlink
  fi
  if has_pkg_app spotify; then
    set_default_apps spotify.desktop x-scheme-handler/spotify
  fi
  if has_pkg_app keepassxc; then
    set_default_apps org.keepassxc.KeePassXC.desktop application/x-keepass2
  fi
  if has_pkg_app thunderbird; then
    set_default_apps thunderbird.desktop message/rfc822 x-scheme-handler/mailto x-scheme-handler/mid
  fi
}

choose_optional_apps() {
  local apps_populares app

  apps_populares=$(gum_choose \
	--no-limit \
	--header "Selecciona as aplicacións que queiras instalar ou preme Esc para non instalar ningunha:" \
	"Discord" \
	"Vesktop" \
	"OBS Studio" \
	"Krita" \
	"GIMP" \
	"Inkscape" \
	"qBittorrent" \
	"Blender" \
	"Kdenlive" \
	"Steam" \
	"Spotify" \
	"KeePassXC" \
	"LibreOffice" \
	"Thunderbird" \
	"Okular" \
	"Amberol" \
	"VLC" \
	"MPV" \
	"Loupe" \
	"yt-dlp" \
	"SpotDL")

  while IFS= read -r app; do
    case "$app" in
      "Discord") pkgs_apps+=("discord") ;;
      "Vesktop") pkgs_apps+=("vesktop") ;;
      "OBS Studio") pkgs_apps+=("obs-studio") ;;
      "Krita") pkgs_apps+=("krita") ;;
      "GIMP") pkgs_apps+=("gimp") ;;
      "Inkscape") pkgs_apps+=("inkscape") ;;
      "qBittorrent") pkgs_apps+=("qbittorrent") ;;
      "Blender") pkgs_apps+=("blender") ;;
      "Kdenlive") pkgs_apps+=("kdenlive") ;;
      "Steam") pkgs_apps+=("steam") ;;
      "Spotify") pkgs_apps+=("spotify") ;;
      "KeePassXC") pkgs_apps+=("keepassxc") ;;
      "LibreOffice") pkgs_apps+=("libreoffice-still" "libreoffice-still-gl" "libreoffice-still-es") ;;
      "Thunderbird") pkgs_apps+=("thunderbird") ;;
      "Okular") pkgs_apps+=("okular") ;;
      "Amberol") pkgs_apps+=("amberol") ;;
      "VLC") pkgs_apps+=("vlc" "vlc-plugins-all") ;;
      "MPV") pkgs_apps+=("mpv") ;;
      "Loupe") pkgs_apps+=("loupe") ;;
      "yt-dlp")
        pkgs_apps+=("yt-dlp")
        run_step \
          "yt-dlp configurado con éxito!" \
          "Algo fallou ao configurar yt-dlp! Abortando instalación..." \
          configure_yt_dlp
        ;;
      "SpotDL")
        pipx_apps+=("spotdl")
        run_step \
          "SpotDL configurado con éxito!" \
          "Algo fallou ao configurar SpotDL! Abortando instalación..." \
          configure_spotdl
        ;;
    esac
  done <<< "$apps_populares"
}

install_optional_apps() {
  if [ ${#pkgs_apps[@]} -gt 0 ]; then
    yay -Syu --needed "${pkgs_apps[@]}"
  fi

  if [ ${#flatpaks_apps[@]} -gt 0 ]; then
    flatpak install -y flathub "${flatpaks_apps[@]}"
  fi

  if [ ${#pipx_apps[@]} -gt 0 ]; then
    pipx install "${pipx_apps[@]}"
  fi
}

save_install_version() {
  mkdir -p "$HOME/.local/share/gallaecia-dots" &&
  echo "$VERSION" > "$HOME/.local/share/gallaecia-dots/version" &&
  date +%d-%m-%Y > "$HOME/.local/share/gallaecia-dots/instalado"
}

main() {
  clear
  install_prerequisites
  clear

  banner

  title "BENVID@ AO INSTALADOR DE GALLAECIA DOTS!"
  info "Con este script poderás instalar os dotfiles paso por paso para que poidas personalizar algunhas cousas e gardar copias de seguridade antes de que se sobreescriban polos dotfiles."
  info "Simplemente responde as preguntas que irán aparecendo en pantalla deixa que ocurra a maxia pagana."

  echo

  warning "IMPORTANTE"
  warning "Ten en conta que algunhas das opcións durante a instalación borrarán ou editarán certas carpetas e arquivos no sistema!"
  warning "Antes de borrar ou editar nada avisaráse de que arquivos se verán afectados e como."

  echo

  info "Primeiro vamos a descargar Gallaecia Dots!"

  echo

  confirm_or_abort \
    "Descargar Gallaecia Dots?" \
    "Non se poden instalar os dotfiles sen descargalos primeiro! Abortando instalación..."

  run_step \
    "Gallaecia Dots descargado con éxito!" \
    "Algo fallou ao descargar Gallaecia Dots! Abortando instalación..." \
    download_dotfiles

  info "Agora que temos os dotfiles descargados, vamos a instalalos!"

  echo

  title "Cambiar idioma a Galego"
  info "Como bos dotfiles en Galego, temos que cambiar o idioma a Galego. Se engade un fallback a Español e logo a Inglés en caso de non haber nigún dos dous."

  echo

  warning "Isto modificará o ficheiro /etc/locale.gen e sobreescribirá o ficheiro /etc/locale.conf!"

  echo

  confirm_step \
    "Cambiar idioma a Galego > Español > Inglés?" \
    "Idioma cambiado con éxito!" \
    "Algo fallou ao cambiar o idioma! Abortando instalación..." \
    configure_locale

  title "Habilitar [multilib] e cores en pacman"
  info "Algúns dos paquetes obligatorios están en multilib polo que temos que habilitala."

  echo

  warning "Isto modificará o ficheiro /etc/pacman.conf!"

  echo

  confirm_or_abort \
    "Habilitar [multilib] e cores en pacman? (Obligatorio)" \
    "Sen [multilib] algúns paquetes obligatorios non poderán ser instalados! Abortando instalación..."

  run_step \
    "[multilib] habilitado con éxito e cores activadas!" \
    "Algo fallou ao habilitar [multilib] ou activar cores! Abortando instalación..." \
    configure_pacman

  title "Instalar paquetes obligatorios? (Obligatorio)"
  info "Os programas obligatorios inclúen, entre outros, yay, Rust, Flatpak, Kitty, Hyprland..."

  echo

  confirm_or_abort \
    "Instalar YAY? (Obligatorio)" \
    "Sen os paquetes obligatorios os dotfiles non funcionarán! Abortando instalación..."

  run_step \
    "YAY instalado con éxito!" \
    "Algo fallou ao instalar YAY! Abortando instalación..." \
    install_yay

  run_step \
    "Rust instalado con éxito!" \
    "Algo fallou durante a instalación de Rust! Abortando instalación..." \
    install_rust

  run_step \
	"Paquetes requeridos instalados con éxito!" \
	"Algo fallou durante a instalación dos paquetes obligatorios! Abortando instalación..." \
	install_required_packages

  run_step \
	"Servizos requeridos configurados con éxito!" \
	"Algo fallou durante a configuración dos servizos obligatorios! Abortando instalación..." \
	configure_required_services

  title "Crear carpetas personales e configuralas"
  info "Os dotfiles necesitan multiples carpetas para certas cousas polo que é necesario crealas e configuralas."
  info "Estas carpetas son Aplicacións, Desarrollo, Descargas, Documentos, Escritorio, Imaxes, Modelos, Música, Público, Vídeos, e Xogos."
  info "Inda que como usuario non precises estas carpetas, certas funcionalidades incluídas nestes dotfiles e en certas aplicacións precisan que esas carpetas existan se non poden fallar ou non funcionar correctamente."

  echo

  warning "Isto substituirá os ficheiros ~/.config/user-dirs.dirs e ~/.config/user-dirs.conf!"

  echo

  confirm_or_abort \
    "Crear carpetas? (Obligatorio)" \
    "Sen estas carpetas algunhas aplicacións e programas non funcionrán correctamente! Abortando instalación..."

  run_step \
    "Carpetas creadas con éxito!" \
    "Algo fallou durante a creación das carpetas! Abortando instalación..." \
    create_personal_dirs

  title "Instalar dotfiles"
  info "Todos os paquetes necesitan unha configuración tanto para o funcionamento como para os estilos. Iso mismo son os dotfiles."

  echo

  warning "Isto eliminará e modificará multiples ficheiros en ~/.config/ e ~/."

  echo

  confirm_or_abort \
    "Instalar dotfiles? (Obligatorio)" \
    "Sen dotfiles... non hai dotfiles... curiosamente... Abortando instalación..."
  install_dotfiles

  info "Xa temos os dotfiles instalados e configurados! Agora solo faltan as partes opcionales!"

  echo

  title "Instalar outras aplicacións"
  info "Selecciona outras aplicacións que queiras instalar no teu equipo. Podes seleccionar varias opcións ou non instalar ningunha."

  echo

  warning "Isto eliminará e modificará multiples ficheiros en ~/.config/ dependendo de que selecciones"

  echo

  choose_optional_apps
  install_optional_apps
  run_step \
	"Asociacións de ficheiros opcionais configuradas con éxito!" \
	"Algo fallou ao configurar as asociacións de ficheiros opcionais! Abortando instalación..." \
	configure_optional_mimeapps

  run_step \
	"Versión instalada gardada con éxito!" \
	"Algo fallou ao gardar a versión instalada! Abortando instalación..." \
	save_install_version

  title "Reiniciar o sistema"
  info "Recoméndase reiniciar o sistema para aplicar correctamente todos os cambios."
  
  echo

  if gum_confirm "Reiniciar o sistema agora?"; then
    systemctl reboot
  fi
}

main "$@"
