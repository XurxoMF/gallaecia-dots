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
#   estado de versións e confirmación
#          │
#          ▼
#   idioma, Yay, Rust e paquetes obrigatorios
#          │
#          ▼
#   ficheiros base, servizos e configuración do escritorio
#          │
#          ▼
#   categorías principais
#   (terminal/editor/IDE/navegador/explorador)
#          │
#          ▼
#   categorías opcionais
#   (cada categoría instala e configura a súa selección ao momento)
#          │
#          ▼
#   rexistro de `base` e reinicio opcional
#
# Cada categoría vive nunha función `install-category-*` de
# `scripts/internal/apps.sh`. A función contén a lista visible, instala os
# paquetes seleccionados e aplica as configuracións, MIME e valores de
# Hyprland que lle corresponden antes de pasar á seguinte categoría.
#
# PARA MODIFICAR A BASE
#
# - Paquete imprescindible para todos: REQUIRED_PACKAGES.
# - Directorio persoal: PERSONAL_DIRS.
# - Aplicación dunha categoría: a súa función en internal/apps.sh.
# - Configuración controlada polo proxecto: función install_* correspondente.
# - Configuración opcional dunha app: dentro da mesma función de categoría.
###############################################################################

# Paquetes que sempre forman parte do escritorio, independentemente das
# aplicacións que o usuario escolla despois nas categorías.
REQUIRED_PACKAGES=(
  noto-fonts-cjk noto-fonts-emoji noto-fonts ttf-noto-nerd
  papirus-icon-theme breeze breeze-icons
  flatpak util-linux pipewire gnome-keyring seahorse libsecret greetd cage wlr-randr dbus polkit libnewt ddcutil power-profiles-daemon trash-cli
  networkmanager networkmanager-openvpn
  python python-pip python-pipx ffmpeg mpv mpvpaper udisks2 7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick mediainfo
  hyprland uwsm
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

# Instala Rustup desde os repositorios e configura a toolchain estable para o
# usuario actual. Modifica paquetes do sistema e o estado persoal de Rustup.
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

# Habilita NetworkManager para Noctalia e o daemon de chaveiros da sesión. O
# plugin OpenVPN xa se instalou cos paquetes obrigatorios; o chaveiro permite
# que NetworkManager e outras aplicacións garden segredos cando corresponda.
configure_required_services() {
  if ! sudo systemctl enable --now NetworkManager.service; then
    return 1
  fi
  if ! systemctl --user enable gnome-keyring-daemon.service; then
    return 1
  fi
  if ! systemctl --user start gnome-keyring-daemon.service; then
    return 1
  fi
}

# Crea todos os directorios XDG persoais e instala os dous ficheiros que fixan
# os seus nomes galegos. Os ficheiros son controlados pola base e substitúense.
create_personal_dirs() {
  mkdir -p "${PERSONAL_DIRS[@]}" "$HOME/.config" &&
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

# Instala os ficheiros controlados por Gallaecia en ~/.local/share.
# Estes son actualizables porque non son configs directas do usuario.
install_gallaecia_config() {
  rm -f "$HOME/.local/share/gallaecia-dots/scripts/modules/versions.sh" &&
  merge_path "$DOTFILES_DIR/.local/share/gallaecia-dots" "$HOME/.local/share/gallaecia-dots" &&
  replace_file "$DOTFILES_DIR/.config/mimeapps.list" "$HOME/.config/mimeapps.list" &&
  sudo chmod +x -R "$HOME/.local/share/gallaecia-dots/scripts" &&
  mkdir -p "$HOME/.wallpapers" "$HOME/.wallpaper-videos" &&
  cp -rf "$DOTFILES_DIR/.wallpapers/." "$HOME/.wallpapers/"
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

  if install_greetd_pam_config; then
    success "Desbloqueo automático de GNOME Keyring configurado con éxito!"
  else
    fail "Algo fallou ao configurar PAM para GNOME Keyring! Abortando instalación..."
  fi

  if install_gallaecia_config; then
    success "Configs propias de Gallaecia Dots instaladas con éxito!"
  else
    fail "Algo fallou ao instalar as configs propias de Gallaecia Dots! Abortando instalación..."
  fi

  if install_desktop_overrides; then
    success "Utilidades técnicas ocultadas do launcher con éxito!"
  else
    fail "Algo fallou ao instalar os overrides do launcher! Abortando instalación..."
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

# Executa, unha por unha, as cinco categorías imprescindibles. `--required`
# impide continuar cunha selección baleira. Cada función instala e configura
# inmediatamente as súas apps, polo que non existe unha fase posterior de colas.
install_required_app_categories() {
  install-category-terminal --required || return 1
  install-category-editor --required || return 1
  install-category-ide --required || return 1
  install-category-browser --required || return 1
  install-category-file-explorer --required || return 1
}

# Percorre as categorías opcionais na orde visible da instalación base. Sen
# `--required`, Esc ou unha selección baleira salta só a categoría actual.
# Cada función comparte exactamente o mesmo fluxo usado por `gallaecia
# install-category`, incluídas configuracións, MIME e Hyprland.
install_optional_app_categories() {
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

# Executa as fases visuais e técnicas da instalación base na orde necesaria.
# Se "base" xa aparece en versions-instaladas, non repite o proceso.
#
# As categorías instalan inmediatamente as súas seleccións. Se unha delas
# falla, a base non se marca como instalada e o erro queda localizado nesa fase.
install_base_version() {
  if is_version_installed "$VERSION"; then
    info "Gallaecia Dots $VERSION xa está instalado. Saltando instalación base..."
    return 0
  fi

  info "Agora que temos os dotfiles descargados, vamos a instalalos!"

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

  title "Aplicacións principais"
  info "Selecciona polo menos unha aplicación por categoría. Se escolles varias, poderás indicar cal usar por defecto."

  if install_required_app_categories; then
    success "Aplicacións principais instaladas e configuradas con éxito!"
  else
    fail "Algo fallou ao instalar as aplicacións principais! Abortando instalación..."
  fi

  title "Aplicacións opcionais"
  info "Selecciona aplicacións opcionais por categoría. Podes deixar categorías baleiras."

  if install_optional_app_categories; then
    success "Aplicacións opcionais instaladas e configuradas con éxito!"
  else
    fail "Algo fallou ao instalar as aplicacións opcionais! Abortando instalación..."
  fi
}

# Punto de entrada: garante Gum/Git, prepara o directorio de estado, pide
# confirmación, executa install_base_version e ofrece reiniciar. Calquera fallo
# anterior ao rexistro final impide que a base quede marcada como instalada.
main() {
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

  if ! gum_confirm "Queres instalar Gallaecia Dots agora?"; then
    info "Instalación cancelada."
    exit 0
  fi

  info "Instalando Gallaecia Dots desde $DOTFILES_DIR."

  install_base_version

  title "Reiniciar o sistema"
  info "Recoméndase reiniciar o sistema para aplicar correctamente todos os cambios."
  
  if gum_confirm "Reiniciar o sistema agora?"; then
    systemctl reboot
  fi
}

main "$@"
