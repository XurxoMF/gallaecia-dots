#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="base"

DOTFILES_DIR="$HOME/.dotfiles"
MODULES_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules"
INTERNAL_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/internal"

if [ ! -r "$MODULES_DIR/apps.sh" ] ||
  [ ! -r "$MODULES_DIR/commands.sh" ] ||
  [ ! -r "$MODULES_DIR/files.sh" ] ||
  [ ! -r "$MODULES_DIR/gallaecia.sh" ] ||
  [ ! -r "$MODULES_DIR/network.sh" ] ||
  [ ! -r "$MODULES_DIR/ui.sh" ] ||
  [ ! -r "$INTERNAL_DIR/apps.sh" ] ||
  [ ! -r "$INTERNAL_DIR/mode.sh" ] ||
  [ ! -r "$INTERNAL_DIR/versions.sh" ]; then
  echo "Non se atoparon os módulos ou librarías internas de Gallaecia Dots." >&2
  echo "Clona o repo en $DOTFILES_DIR e executa $DOTFILES_DIR/install.sh." >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$MODULES_DIR/apps.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/commands.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/files.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/gallaecia.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/network.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/ui.sh"
# shellcheck source=/dev/null
source "$INTERNAL_DIR/apps.sh"
# shellcheck source=/dev/null
source "$INTERNAL_DIR/mode.sh"
# shellcheck source=/dev/null
source "$INTERNAL_DIR/versions.sh"

###############################################################################
# MAPA DA INSTALACIÓN BASE
#
# Este script instala directamente o estado final do proxecto. Non executa as
# migracións históricas. O fluxo principal, definido ao final, segue estas
# fases:
#
#   prerequisitos mínimos
#          │
#          ▼
#   estado, confirmación e modo desktop/server
#          │
#          ▼
#   idioma, Yay, paquetes e servizos comúns
#          │
#          ▼
#   ┌─────────────────────┴────────────────────┐
#   ▼                                          ▼
# escritorio: stack gráfico, XDG e apps      servidor: apps de terminal
#          │
#          ▼
#   rexistro de `base` e reinicio opcional
#
# Cada categoría vive nunha función `install-category-*` de
# `scripts/internal/apps.sh`. A función contén a lista visible, instala os
# paquetes seleccionados e aplica no mesmo paso só as configuracións que
# corresponden ao modo actual.
#
# PARA MODIFICAR A BASE
#
# - Paquete común: REQUIRED_PACKAGES.
# - Paquete exclusivo do escritorio: REQUIRED_DESKTOP_PACKAGES.
# - Directorio persoal de escritorio: PERSONAL_DIRS.
# - Aplicación dunha categoría: a súa función en internal/apps.sh.
# - Configuración controlada polo proxecto: función install_* correspondente.
# - Configuración opcional dunha app: dentro da mesma función de categoría.
###############################################################################

# Paquetes compartidos polos modos de escritorio e servidor. Esta base mantén
# só ferramentas de terminal, rede, paquetes e estado necesarias nos dous.
REQUIRED_PACKAGES=(
  util-linux dbus polkit libnewt trash-cli
  networkmanager nftables
  7zip jq fd ripgrep fzf zoxide
)

# Paquetes gráficos e multimedia instalados unicamente no modo escritorio.
REQUIRED_DESKTOP_PACKAGES=(
  noto-fonts-cjk noto-fonts-emoji noto-fonts ttf-noto-nerd
  papirus-icon-theme breeze breeze-icons
  flatpak pipewire gnome-keyring seahorse libsecret greetd cage wlr-randr ddcutil power-profiles-daemon
  networkmanager-openvpn
  python python-pip python-pipx ffmpeg mpv mpvpaper udisks2 poppler resvg imagemagick mediainfo
  hyprland hyprpicker uwsm
  noctalia noctalia-greeter
  qt5-base qt6-base qt5ct qt6ct qt5-wayland qt6-wayland xsettingsd hyprland-qt-support kservice
  xdg-utils xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-user-dirs archlinux-xdg-menu
  xorg-xrandr xorg-xwayland
  adw-gtk-theme
)

# Directorios persoais que se crean antes de instalar user-dirs.dirs.
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

# Imprime o logo ASCII ao comezo da instalación base.
# Non consulta nin modifica o sistema; serve só como cabeceira visual.
banner() {
  echo '  _____       _ _                 _       '
  echo ' / ____|     | | |               (_)      '
  echo '| |  __  __ _| | | __ _  ___  ___ _  __ _ '
  echo '| | |_ |/ _` | | |/ _` |/ _ \/ __| |/ _` |'
  echo '| |__| | (_| | | | (_| |  __/ (__| | (_| |'
  echo ' \_____|\__,_|_|_|\__,_|\___|\___|_|\__,_|'
  echo '                                          '
}

# Asegura que a base pode usar Gum e Git mesmo se se executa directamente.
# Neste punto Yay aínda non está garantido, polo que se usa Pacman.
install_prerequisites() {
  local missing_packages=()

  if ! has_command gum; then
    missing_packages+=(gum)
  fi

  if ! has_command git; then
    missing_packages+=(git)
  fi

  if [ ${#missing_packages[@]} -eq 0 ]; then
    return 0
  fi

  echo ":: Instalando programas requiridos para executar este script: ${missing_packages[*]}..."
  sudo pacman -S --needed -- "${missing_packages[@]}"
}

# Habilita en `/etc/locale.gen` galego, español e inglés, rexenera os locales e
# escribe a orde galego → español → inglés na configuración global do sistema.
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

# Activa cores e ILoveCandy en pacman nos dous modos.
configure_pacman() {
  sudo sed -i \
	-e 's/^#Color/Color/' \
	-e 's/^#ILoveCandy/ILoveCandy/' \
	-e '/^#Color/a ILoveCandy' \
	/etc/pacman.conf &&
  sudo pacman -Syy
}

# Habilita [multilib] só no escritorio, onde o precisan Steam e outras
# aplicacións gráficas. O servidor non activa repositorios innecesarios.
configure_desktop_pacman() {
  sudo sed -i \
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

# Instala Rustup só no escritorio e configura a toolchain estable para o
# usuario actual. Algunhas aplicacións gráficas da base dependen desta pila.
install_rust() {
  sudo pacman -Syu --needed rustup &&
  rustup default stable
}

# Instala os paquetes comúns aos dous modos.
install_required_packages() {
  yay -Syu --needed "${REQUIRED_PACKAGES[@]}"
}

# Instala os paquetes exclusivos do escritorio e prepara Flathub e os temas.
install_desktop_required_packages() {
  yay -Syu --needed "${REQUIRED_DESKTOP_PACKAGES[@]}" &&
  flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3-dark org.gtk.Gtk3theme.adw-gtk3
}

# Habilita NetworkManager e nftables para o seguinte arranque sen substituír a
# rede nin o firewall que manteñen conectada a instalación en curso.
configure_required_services() {
  if ! sudo systemctl enable NetworkManager.service; then
    return 1
  fi
  if ! sudo systemctl enable nftables.service; then
    return 1
  fi
}

# Restaura no escritorio o arranque previsto por Arch para GNOME Keyring. O
# paquete habilita globalmente o socket; non se debe habilitar tamén o servizo
# no usuario porque PAM debe crear e desbloquear primeiro o chaveiro `Login`.
configure_desktop_services() {
  # `disable` non detén o daemon da sesión actual. Só retira os symlinks que
  # Gallaecia puidese crear; o socket global do paquete segue habilitado.
  if ! systemctl --user disable gnome-keyring-daemon.service; then
    return 1
  fi
}

# Crea todos os directorios XDG persoais e instala os dous ficheiros que fixan
# os seus nomes galegos. Os ficheiros son controlados pola base e substitúense.
create_personal_dirs() {
  ensure_directory "${PERSONAL_DIRS[@]}" "$HOME/.config" &&
  replace_file "$DOTFILES_DIR/.config/user-dirs.dirs" "$HOME/.config/user-dirs.dirs" &&
  replace_file "$DOTFILES_DIR/.config/user-dirs.conf" "$HOME/.config/user-dirs.conf"
}

# Substitúe a configuración global de greetd e os datos de Noctalia Greeter,
# garante o usuario de sistema `greeter` e habilita o servizo para o arranque.
install_greetd_config() {
  sudo rm -rf "/etc/greetd" "/var/lib/noctalia-greeter" &&
  sudo cp -r "$DOTFILES_DIR/others/greetd" "/etc/greetd" &&
  sudo cp -r "$DOTFILES_DIR/others/noctalia-greeter" "/var/lib/noctalia-greeter" &&
  { sudo useradd -r -s /usr/bin/nologin -d /var/lib/noctalia-greeter greeter 2> /dev/null || true; } &&
  sudo systemctl enable greetd
}

# Instala a pila PAM de greetd controlada por Gallaecia. Mantén as regras base
# de Arch e engade GNOME Keyring nas fases `auth` e `session`: a primeira recibe
# o contrasinal validado por greetd e a segunda inicia e desbloquea o chaveiro
# cando Noctalia Greeter abre a sesión.
install_greetd_pam_config() {
  sudo install -Dm644 \
    "$DOTFILES_DIR/others/pam/greetd" \
    "/etc/pam.d/greetd"
}

# Instala só os scripts e librarías compartidos polos dous modos. As árbores de
# Hyprland, Noctalia e os fondos distribúense nun paso exclusivo do escritorio.
install_gallaecia_config() {
  local module internal_library script

  if ! ensure_directory \
    "$HOME/.local/share/gallaecia-dots/scripts/modules" \
    "$HOME/.local/share/gallaecia-dots/scripts/internal"; then
    return 1
  fi

  rm -f "$HOME/.local/share/gallaecia-dots/scripts/modules/versions.sh" || return 1

  for module in apps commands files gallaecia network ui; do
    if ! replace_file \
      "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/$module.sh" \
      "$HOME/.local/share/gallaecia-dots/scripts/modules/$module.sh"; then
      return 1
    fi
  done

  for internal_library in apps mode versions; do
    if ! replace_file \
      "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/internal/$internal_library.sh" \
      "$HOME/.local/share/gallaecia-dots/scripts/internal/$internal_library.sh"; then
      return 1
    fi
  done

  for script in gallaecia system-update; do
    if ! replace_file \
      "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/$script.sh" \
      "$HOME/.local/share/gallaecia-dots/scripts/$script.sh"; then
      return 1
    fi
  done

  sudo chmod +x -R "$HOME/.local/share/gallaecia-dots/scripts"
}

# Instala os recursos compartidos exclusivos do escritorio. As fusións dos
# fondos conservan imaxes persoais e a configuración MIME queda controlada.
install_desktop_gallaecia_config() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/run-terminal-as.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/run-terminal-as.sh" &&
  replace_path \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/hypr" \
    "$HOME/.local/share/gallaecia-dots/hypr" &&
  replace_path \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/noctalia" \
    "$HOME/.local/share/gallaecia-dots/noctalia" &&
  replace_file "$DOTFILES_DIR/.config/mimeapps.list" "$HOME/.config/mimeapps.list" &&
  ensure_directory "$HOME/.wallpaper-videos" &&
  merge_path "$DOTFILES_DIR/.wallpapers" "$HOME/.wallpapers"
}

# Fixa `Login` como chaveiro predeterminado para Secret Service sen substituír
# os demais chaveiros que poida ter o usuario. Nunha instalación nova o daemon
# aínda pode non ter creado o directorio onde se garda esta selección.
install_default_keyring() {
  ensure_directory "$HOME/.local/share/keyrings" &&
  replace_file \
    "$DOTFILES_DIR/.local/share/keyrings/default" \
    "$HOME/.local/share/keyrings/default"
}

# Instala os `.desktop` mínimos que ocultan utilidades técnicas do launcher.
# `merge_path` sobrescribe só estes IDs controlados por Gallaecia e conserva
# calquera outro lanzador ou override persoal do usuario no mesmo directorio.
install_desktop_overrides() {
  merge_path \
    "$DOTFILES_DIR/.local/share/applications" \
    "$HOME/.local/share/applications"
}

# Substitúe o `.bashrc` principal e a árbore inicial de módulos públicos.
# Esta función pertence á instalación base; as migracións posteriores preservan
# personalizacións xa existentes en `~/.config/bashrc`.
install_bashrc() {
  ensure_directory "$HOME/.config" &&
  replace_file "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc" &&
  replace_path "$DOTFILES_DIR/.config/bashrc" "$HOME/.config/bashrc"
}

# Substitúe as configuracións GTK 3 e GTK 4 completas polas distribuídas.
# Ambas rutas son propiedade da base durante esta instalación inicial.
install_gtk_config() {
  rm -rf "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" &&
  cp -r "$DOTFILES_DIR/.config/gtk-3.0" "$HOME/.config/gtk-3.0" &&
  cp -r "$DOTFILES_DIR/.config/gtk-4.0" "$HOME/.config/gtk-4.0"
}

# Substitúe as configuracións Qt5/Qt6 e `kdeglobals` para unificar tema e estilo.
# Elimina primeiro os destinos porque estes ficheiros pertencen á base inicial.
install_qt_config() {
  rm -rf "$HOME/.config/qt6ct" "$HOME/.config/qt5ct" "$HOME/.config/kdeglobals" &&
  cp -r "$DOTFILES_DIR/.config/qt6ct" "$HOME/.config/qt6ct" &&
  cp -r "$DOTFILES_DIR/.config/qt5ct" "$HOME/.config/qt5ct" &&
  cp "$DOTFILES_DIR/.config/kdeglobals" "$HOME/.config/kdeglobals"
}

# Substitúe a árbore de portais XDG que decide o backend usado baixo Hyprland.
# O destino é unha configuración base controlada por Gallaecia.
install_xdg_portals() {
  replace_path "$DOTFILES_DIR/.config/xdg-desktop-portal" "$HOME/.config/xdg-desktop-portal"
}

# Substitúe a configuración de xsettingsd que exporta o tema ás aplicacións X11.
# Non inicia o daemon; Hyprland encárgase de lanzalo coa configuración instalada.
install_xsettingsd() {
  replace_path "$DOTFILES_DIR/.config/xsettingsd" "$HOME/.config/xsettingsd"
}

# Instala a configuración global dos wrappers `electronXX` de Arch. A selección
# explícita evita a detección por nome de escritorio, que non recoñece Hyprland.
install_electron_config() {
  replace_file \
    "$DOTFILES_DIR/.config/electron-flags.conf" \
    "$HOME/.config/electron-flags.conf"
}

# Instala o wrapper de Hyprland en ~/.config.
# Ese ficheiro queda para o usuario; a base actualizable vive en ~/.local/share.
install_hyprland() {
  ensure_directory "$HOME/.config/hypr" &&
  replace_file "$DOTFILES_DIR/.config/hypr/hyprland.lua" "$HOME/.config/hypr/hyprland.lua"
}

# Instala Noctalia separando base e custom:
# gallaecia.toml pode actualizarse; custom.toml só se crea se non existe.
install_noctalia() {
  ensure_directory "$HOME/.config/noctalia" &&
  replace_file "$DOTFILES_DIR/.config/noctalia/gallaecia.toml" "$HOME/.config/noctalia/gallaecia.toml" &&
  if [ ! -f "$HOME/.config/noctalia/custom.toml" ]; then
    replace_file "$DOTFILES_DIR/.config/noctalia/custom.toml" "$HOME/.config/noctalia/custom.toml"
  fi
}

# Instala os scripts e o Bashrc compartidos polos dous modos.
install_common_dotfiles() {
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
}

# Aplica todos os ficheiros controlados exclusivos do escritorio. As configs de
# aplicacións opcionais instálanse máis tarde segundo a selección.
install_desktop_dotfiles() {
  if install_greetd_config; then
    success "Configuración de greetd instalada con éxito!"
  else
    fail "Algo fallou ao instalar a configuración de greetd! Abortando instalación..."
  fi

  if install_greetd_pam_config; then
    success "Desbloqueo automático de GNOME Keyring configurado con éxito!"
  else
    fail "Algo fallou ao configurar PAM para GNOME Keyring! Abortando instalación..."
  fi

  if install_desktop_gallaecia_config; then
    success "Recursos de escritorio de Gallaecia instalados con éxito!"
  else
    fail "Algo fallou ao instalar os recursos de escritorio! Abortando instalación..."
  fi

  if install_default_keyring; then
    success "Login configurado como chaveiro predeterminado con éxito!"
  else
    fail "Algo fallou ao configurar o chaveiro predeterminado! Abortando instalación..."
  fi

  if install_desktop_overrides; then
    success "Utilidades técnicas ocultadas do launcher con éxito!"
  else
    fail "Algo fallou ao instalar os overrides do launcher! Abortando instalación..."
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

  if install_electron_config; then
    success "Electron configurado para usar GNOME Keyring con éxito!"
  else
    fail "Algo fallou ao configurar Electron! Abortando instalación..."
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

# Executa, unha por unha, as cinco categorías imprescindibles. Cada función
# mostra e acepta as variantes completas xa instaladas, ofrece só as restantes
# e impide continuar sen ningunha app activa. Instala e configura inmediatamente
# as novas seleccións, polo que non existe unha fase posterior de colas.
install_desktop_required_app_categories() {
  install-category-terminal --required || return 1
  install-category-editor --required || return 1
  install-category-ide --required || return 1
  install-category-browser --required || return 1
  install-category-file-explorer --required || return 1
}

# Percorre as categorías opcionais na orde visible da instalación base. Cada
# función mostra por separado as variantes completas xa instaladas e ocúltaas
# do selector. Sen `--required`, Esc salta só a categoría actual.
# Cada función comparte exactamente o mesmo fluxo usado por `gallaecia
# install-category`, incluídas configuracións, MIME e Hyprland.
install_desktop_optional_app_categories() {
  install-category-audio || return 1
  install-category-video || return 1
  install-category-pdf || return 1
  install-category-images || return 1
  install-category-mail || return 1
  install-category-chat || return 1
  install-category-creativity || return 1
  install-category-office || return 1
  install-category-games || return 1
  install-category-utilities || return 1
  install-category-development || return 1
  install-category-network || return 1
  install-category-downloads || return 1
}

# O servidor require polo menos un editor de terminal. Esta variante non
# configura Hyprland nin integra o tema dinámico de Noctalia.
install_server_required_app_categories() {
  install-category-server-editor --required
}

# Percorre as categorías opcionais propias do servidor. Cada unha instala a
# selección inmediatamente e pode cancelarse sen deter as seguintes.
install_server_optional_app_categories() {
  install-category-administration || return 1
  install-category-server-files || return 1
  install-category-deployment || return 1
  install-category-server-network || return 1
}

# Conserva o modo xa rexistrado nas reinstalacións. Nunha instalación nova
# mostra a primeira elección do fluxo e garda `desktop` ou `server`.
select_install_mode() {
  local current_mode selected_mode

  if [ -e "$GALLAECIA_MODE_FILE" ]; then
    if ! current_mode="$(get_install_mode)"; then
      return 1
    fi
    info "Conservando o modo actual: $current_mode."
    return 0
  fi

  if ! selected_mode="$(choose --header "Escolle o modo de instalación:" \
    "Escritorio" "Servidor")"; then
    warning "Selección do modo cancelada."
    return 2
  fi

  case "$selected_mode" in
    Escritorio) set_install_mode desktop ;;
    Servidor) set_install_mode server ;;
    *)
      error "Modo de instalación descoñecido: $selected_mode"
      return 1
      ;;
  esac
}

# Instala os paquetes, servizos e ficheiros compartidos polos dous modos.
install_common_base() {
  title "Cambiar idioma a galego"
  info "Configurarase a orde Galego, Español e Inglés para o sistema."
  if ! configure_locale; then
    fail "Algo fallou ao cambiar o idioma! Abortando instalación..."
  fi

  title "Configurar pacman"
  info "Activaranse as cores e ILoveCandy na configuración de pacman."
  if ! configure_pacman; then
    fail "Algo fallou ao configurar pacman! Abortando instalación..."
  fi

  title "Instalar paquetes comúns"
  info "Instalaranse Yay, NetworkManager, nftables e as utilidades compartidas."
  if ! install_yay; then
    fail "Algo fallou ao instalar Yay! Abortando instalación..."
  fi
  if ! install_required_packages; then
    fail "Algo fallou ao instalar os paquetes comúns! Abortando instalación..."
  fi
  if ! configure_required_services; then
    fail "Algo fallou ao habilitar os servizos comúns! Abortando instalación..."
  fi

  title "Instalar dotfiles comúns"
  info "Instalaranse o Bashrc, os módulos públicos e as librarías internas."
  if ! install_common_dotfiles; then
    fail "Algo fallou ao instalar os dotfiles comúns! Abortando instalación..."
  fi
}

# Completa o modo escritorio co stack gráfico, os directorios XDG e todas as
# categorías actuais de aplicacións.
install_desktop_base() {
  title "Preparar paquetes de escritorio"
  info "Habilitarase [multilib] e instalaranse Rust, Flatpak, Hyprland e Noctalia."
  if ! configure_desktop_pacman; then
    fail "Algo fallou ao habilitar [multilib]! Abortando instalación..."
  fi
  if ! install_rust; then
    fail "Algo fallou durante a instalación de Rust! Abortando instalación..."
  fi
  if ! install_desktop_required_packages; then
    fail "Algo fallou ao instalar os paquetes de escritorio! Abortando instalación..."
  fi
  if ! configure_desktop_services; then
    fail "Algo fallou ao configurar os servizos de escritorio! Abortando instalación..."
  fi

  title "Crear directorios persoais"
  info "Crearanse e configuraranse os directorios XDG cos nomes en galego."
  if ! create_personal_dirs; then
    fail "Algo fallou ao crear os directorios persoais! Abortando instalación..."
  fi

  title "Instalar escritorio"
  info "Instalaranse greetd, Hyprland, Noctalia e as configuracións gráficas."
  if ! install_desktop_dotfiles; then
    fail "Algo fallou ao instalar os dotfiles de escritorio! Abortando instalación..."
  fi

  title "Aplicacións principais"
  info "Selecciona polo menos unha aplicación por categoría."
  if ! install_desktop_required_app_categories; then
    fail "Algo fallou ao instalar as aplicacións principais! Abortando instalación..."
  fi

  title "Aplicacións opcionais"
  info "Selecciona aplicacións opcionais por categoría ou preme Esc para saltalas."
  if ! install_desktop_optional_app_categories; then
    fail "Algo fallou ao instalar as aplicacións opcionais! Abortando instalación..."
  fi
}

# Completa o modo servidor coas categorías exclusivas de terminal.
install_server_base() {
  title "Editor de terminal"
  info "Selecciona polo menos un editor para administrar o servidor."
  if ! install_server_required_app_categories; then
    fail "Algo fallou ao instalar o editor do servidor! Abortando instalación..."
  fi

  title "Aplicacións de servidor"
  info "Selecciona ferramentas opcionais ou preme Esc para saltar cada categoría."
  if ! install_server_optional_app_categories; then
    fail "Algo fallou ao instalar as aplicacións de servidor! Abortando instalación..."
  fi
}

# Executa primeiro a base común e despois exactamente o modo persistente. Se
# `base` xa está rexistrada non repite o proceso.
install_base_version() {
  if is_version_installed "$VERSION"; then
    info "Gallaecia Dots $VERSION xa está instalado. Saltando instalación base..."
    return 0
  fi

  install_common_base

  if is_desktop; then
    install_desktop_base
  elif is_server; then
    install_server_base
  else
    fail "Non se puido determinar o modo da instalación."
  fi
}

# Punto de entrada: garante Gum/Git, prepara o directorio de estado, pide
# confirmación, executa install_base_version e ofrece reiniciar. Calquera fallo
# anterior ao rexistro final impide que a base quede marcada como instalada.
main() {
  local mode_status

  if ! install_prerequisites; then
    echo "Non se puideron instalar os prerequisitos da base. Abortando instalación..." >&2
    exit 1
  fi

  clear
  if ! ensure_gallaecia_state_dir; then
    fail "Non se puido preparar o estado de versións de Gallaecia Dots! Abortando instalación..."
  fi
  clear

  banner

  title "BENVID@ AO INSTALADOR DE GALLAECIA DOTS!"
  info "Con este script poderás instalar os dotfiles paso por paso para que poidas personalizar algunhas cousas e gardar copias de seguridade antes de que se sobreescriban polos dotfiles."
  info "Simplemente responde as preguntas que irán aparecendo en pantalla deixa que ocurra a maxia pagana."

  if ! confirm "Queres instalar Gallaecia Dots agora?"; then
    info "Instalación cancelada."
    exit 0
  fi

  select_install_mode
  mode_status=$?
  if [ "$mode_status" -eq 2 ]; then
    info "Instalación cancelada."
    exit 0
  fi
  if [ "$mode_status" -ne 0 ]; then
    fail "Non se puido preparar o modo da instalación."
  fi

  info "Instalando Gallaecia Dots en modo $(get_install_mode) desde $DOTFILES_DIR."

  install_base_version

  title "Reiniciar o sistema"
  info "Recoméndase reiniciar o sistema para aplicar correctamente todos os cambios."

  if confirm "Reiniciar o sistema agora?"; then
    systemctl reboot
  fi
}

main "$@"
