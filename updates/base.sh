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
#          │
#          ▼
#   instalación das colas Yay/Flatpak/Pipx
#          │
#          ▼
#   rexistro de `base` e reinicio opcional
#
# As categorías non se definen neste ficheiro: veñen do catálogo único de
# `scripts/internal/apps.sh`. As funcións choose_* dese módulo van acumulando
# paquetes nas tres colas globais e esta base chama `install_selected_apps` unha
# soa vez despois de rematar todas as preguntas.
#
# PARA MODIFICAR A BASE
#
# - Paquete imprescindible para todos: REQUIRED_PACKAGES.
# - Directorio persoal: PERSONAL_DIRS.
# - Aplicación dunha categoría: internal/apps.sh, non a dupliques aquí.
# - Configuración controlada polo proxecto: función install_* correspondente.
# - Configuración opcional dunha app: mantén tamén configure_installed_app_entry
#   en internal/apps.sh sincronizada para `gallaecia install-category`.
###############################################################################

# Paquetes que sempre forman parte do escritorio, independentemente das
# aplicacións que o usuario escolla despois nas categorías.
REQUIRED_PACKAGES=(
  noto-fonts-cjk noto-fonts-emoji noto-fonts ttf-noto-nerd
  papirus-icon-theme breeze breeze-icons
  flatpak util-linux pipewire gnome-keyring libsecret greetd cage wlr-randr dbus polkit libnewt ddcutil power-profiles-daemon trash-cli
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

# Comandos predeterminados escollidos nas cinco categorías principais.
# Gárdanse porque se reutilizan ao configurar Hyprland e, no caso do terminal,
# para construír o comando `TERMINAL -e yazi`.
terminal_command=""
editor_command=""
ide_command=""
browser_command=""
file_explorer_command=""

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

# Habilita e inicia o daemon de chaveiros na sesión do usuario.
# Ambos pasos deben completarse para que as aplicacións poidan gardar segredos.
configure_required_services() {
  systemctl --user enable gnome-keyring-daemon.service &&
  systemctl --user start gnome-keyring-daemon.service
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

# Substitúe a configuración opcional de Kitty pola plantilla distribuída.
# Só a chama o fluxo de categorías cando Kitty foi unha selección do usuario.
install_kitty_config() {
  replace_path "$DOTFILES_DIR/optional/.config/kitty" "$HOME/.config/kitty"
}

# Substitúe a configuración opcional de Alacritty, aliñada co aspecto base.
# Só se executa cando Alacritty aparece entre as seleccións instaladas.
install_alacritty_config() {
  replace_path "$DOTFILES_DIR/optional/.config/alacritty" "$HOME/.config/alacritty"
}

# Substitúe a configuración opcional de Foot coa fonte e tamaño comúns.
# Non se aplica a instalacións que non escolleron este terminal.
install_foot_config() {
  replace_path "$DOTFILES_DIR/optional/.config/foot" "$HOME/.config/foot"
}

# Substitúe a configuración opcional de Ghostty co aspecto común do proxecto.
# O dispatcher de aplicacións só a chama cando Ghostty foi seleccionado.
install_ghostty_config() {
  replace_path "$DOTFILES_DIR/optional/.config/ghostty" "$HOME/.config/ghostty"
}

# Substitúe a configuración opcional de WezTerm coa fonte e tamaño da base.
# Só modifica o destino cando o usuario escolle esta aplicación.
install_wezterm_config() {
  replace_path "$DOTFILES_DIR/optional/.config/wezterm" "$HOME/.config/wezterm"
}

# Instala o único ficheiro opcional de Dolphin controlado por Gallaecia.
# Só se chama tras seleccionar Dolphin como explorador de ficheiros.
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

# Instala os flags opcionais de VS Code usados para a sesión Wayland.
# Só se chama cando a entrada de VS Code foi seleccionada na categoría IDE.
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

# Habilita o daemon de Docker e engade o usuario actual ao grupo `docker`.
# O novo grupo adoita facerse efectivo no seguinte inicio de sesión.
install_docker() {
  sudo systemctl enable docker.service &&
  sudo usermod -aG docker "$USER"
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

# Substitúe a configuración de yt-dlp e instala o seu módulo Bash opcional.
# Ambas pezas se manteñen xuntas porque os wrappers dependen deses perfís.
configure_yt_dlp() {
  mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" &&
  replace_path "$DOTFILES_DIR/optional/.config/yt-dlp" "$HOME/.config/yt-dlp" &&
  replace_file "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/201-yt-dlp" "$HOME/.local/share/gallaecia-dots/bashrc/201-yt-dlp"
}

# Substitúe a configuración de SpotDL e instala o wrapper Bash correspondente.
# Só se chama cando SpotDL foi seleccionado e instalado mediante Pipx.
configure_spotdl() {
  mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" &&
  replace_path "$DOTFILES_DIR/optional/.config/spotdl" "$HOME/.config/spotdl" &&
  replace_file "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/202-spotdl" "$HOME/.local/share/gallaecia-dots/bashrc/202-spotdl"
}

# Copia o módulo de comandos interactivos de Git á área cargada polo Bashrc.
# A función non configura credenciais nin modifica ningún repositorio.
configure_git() {
  mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" &&
  replace_file "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/203-git" "$HOME/.local/share/gallaecia-dots/bashrc/203-git"
}

# Copia o módulo de Docker/Compose á área opcional cargada polo Bashrc.
# Non inicia contedores; `install_docker` xestiona por separado servizo e grupo.
configure_docker() {
  mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" &&
  replace_file "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/204-docker" "$HOME/.local/share/gallaecia-dots/bashrc/204-docker"
}

# Escolla das cinco categorías obrigatorias.
# Primeiro se escolle terminal porque Yazi usa "$terminal_command -e yazi"
# cando se configura como explorador de arquivos.
#
# Cada bloque repite o mesmo patrón de forma explícita:
#   1. load_app_category enche APP_CATEGORY_ENTRIES.
#   2. choose_required_category enche SELECTED_ENTRIES e as colas.
#   3. choose_default_entry devolve unha entrada completa.
#   4. app_command extrae o comando e set_hypr_app_command escríbeo.
#   5. Se corresponde, aplícanse MIME e configuracións opcionais.
#
# SELECTED_ENTRIES e DEFAULT_ENTRY reutilízanse entre categorías: ao comezar a
# seguinte selección substitúen o valor da anterior. As colas de paquetes, en
# cambio, acumúlanse ata install_selected_apps.
configure_required_apps() {
  # Cada entrada segue: "tipo|Nome|paquetes|comando|desktop".
  # A orde tamén importa: a primeira opción adoita ser a recomendada.

  # Seleccionar terminal

  load_app_category terminal
  local terminal_entries=("${APP_CATEGORY_ENTRIES[@]}")

  choose_required_category \
    "Selecciona terminal ou terminais:" \
    "${terminal_entries[@]}"
  
  DEFAULT_ENTRY=$(choose_default_entry "Escolle terminal por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
  terminal_command="$(app_command "$DEFAULT_ENTRY")"

  set_hypr_app_command terminal "$terminal_command"

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

  load_app_category editor
  local editor_entries=("${APP_CATEGORY_ENTRIES[@]}")

  choose_required_category \
    "Selecciona editor ou editores de terminal:" \
    "${editor_entries[@]}"

  DEFAULT_ENTRY=$(choose_default_entry "Escolle editor de terminal por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
  editor_command="$(app_command "$DEFAULT_ENTRY")"

  set_hypr_app_command editor "$editor_command"

  # Seleccionar IDE

  load_app_category ide
  local ide_entries=("${APP_CATEGORY_ENTRIES[@]}")

  choose_required_category \
    "Selecciona IDE ou editores con interface gráfica:" \
    "${ide_entries[@]}"

  DEFAULT_ENTRY=$(choose_default_entry "Escolle IDE por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
  ide_command="$(app_command "$DEFAULT_ENTRY")"

  set_hypr_app_command ide "$ide_command"

  apply_app_category_default ide "$DEFAULT_ENTRY"

  if has_selected_app visual-studio-code-bin; then
    install_vscode_config || return 1
  fi

  # Seleccionar buscador

  load_app_category browser
  local browser_entries=("${APP_CATEGORY_ENTRIES[@]}")

  choose_required_category \
    "Selecciona navegador ou navegadores:" \
    "${browser_entries[@]}"

  DEFAULT_ENTRY=$(choose_default_entry "Escolle navegador por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
  browser_command="$(app_command "$DEFAULT_ENTRY")"

  set_hypr_app_command browser "$browser_command"

  apply_app_category_default browser "$DEFAULT_ENTRY"

  # Seleccionar explorador de arquivos

  load_app_category file-explorer "$terminal_command"
  local file_explorer_entries=("${APP_CATEGORY_ENTRIES[@]}")

  choose_required_category \
    "Selecciona explorador ou exploradores de arquivos:" \
    "${file_explorer_entries[@]}"

  DEFAULT_ENTRY=$(choose_default_entry "Escolle explorador de arquivos por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
  file_explorer_command="$(app_command "$DEFAULT_ENTRY")"

  set_hypr_app_command file-explorer "$file_explorer_command"
  apply_app_category_default file-explorer "$DEFAULT_ENTRY"

  if has_selected_app dolphin; then
    install_dolphin_config || return 1
  fi

  if has_selected_app yazi; then
    install_yazi_config || return 1
  fi
}

# Percorre as categorías opcionais. `choose_optional_category` permite unha
# selección baleira, pero as eleccións non baleiras seguen acumulando paquetes
# nas colas globais.
#
# As categorías cunha app xenérica predeterminada chaman
# apply_app_category_default. As que teñen regras por aplicación chaman
# apply_selected_app_mime_rules. Desenvolvemento e descargas tamén instalan os
# seus Bashrc/configuracións opcionais cando a app foi seleccionada.
configure_optional_apps() {
  # Nestas categorías o usuario pode non escoller nada.
  # Se escolle varias apps nunha categoría con MIME, pedimos cal queda por defecto.

  # Escoller resproductores de audio

  load_app_category audio
  local audio_entries=("${APP_CATEGORY_ENTRIES[@]}")

  choose_optional_category "Selecciona reprodutor ou reprodutores de audio:" "${audio_entries[@]}"

  if [ ${#SELECTED_ENTRIES[@]} -gt 0 ]; then
    DEFAULT_ENTRY=$(choose_default_entry "Escolle reprodutor de audio por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
    apply_app_category_default audio "$DEFAULT_ENTRY"
  fi

  # Escoller resproductores de vídeo

  load_app_category video
  local video_entries=("${APP_CATEGORY_ENTRIES[@]}")

  choose_optional_category "Selecciona reprodutor ou reprodutores de vídeo:" "${video_entries[@]}"

  if [ ${#SELECTED_ENTRIES[@]} -gt 0 ]; then
    DEFAULT_ENTRY=$(choose_default_entry "Escolle reprodutor de vídeo por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
    apply_app_category_default video "$DEFAULT_ENTRY"
  fi

  # Escoller visores de PDF

  load_app_category pdf
  local pdf_entries=("${APP_CATEGORY_ENTRIES[@]}")

  choose_optional_category "Selecciona visor ou visores de PDF:" "${pdf_entries[@]}"

  if [ ${#SELECTED_ENTRIES[@]} -gt 0 ]; then
    DEFAULT_ENTRY=$(choose_default_entry "Escolle visor de PDF por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
    apply_app_category_default pdf "$DEFAULT_ENTRY"
  fi

  # Escoller visores de imaxes

  load_app_category images
  local image_entries=("${APP_CATEGORY_ENTRIES[@]}")

  choose_optional_category "Selecciona visor ou visores de imaxes:" "${image_entries[@]}"

  if [ ${#SELECTED_ENTRIES[@]} -gt 0 ]; then
    DEFAULT_ENTRY=$(choose_default_entry "Escolle visor de imaxes por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
    apply_app_category_default images "$DEFAULT_ENTRY"
  fi

  # Escoller clientes de correo

  load_app_category mail
  local mail_entries=("${APP_CATEGORY_ENTRIES[@]}")

  choose_optional_category "Selecciona cliente ou clientes de correo:" "${mail_entries[@]}"

  if [ ${#SELECTED_ENTRIES[@]} -gt 0 ]; then
    DEFAULT_ENTRY=$(choose_default_entry "Escolle cliente de correo por defecto:" "${SELECTED_ENTRIES[@]}") || return 1
    apply_app_category_default mail "$DEFAULT_ENTRY"
  fi

  # Escoller apps de chat

  load_app_category chat
  local chat_entries=("${APP_CATEGORY_ENTRIES[@]}")

  choose_optional_category "Selecciona apps de chat:" "${chat_entries[@]}"

  if has_selected_app vesktop; then
    apply_app_category_default chat \
      "$(find_app_by_label Vesktop "${SELECTED_ENTRIES[@]}")"
  elif has_selected_app discord; then
    apply_app_category_default chat \
      "$(find_app_by_label Discord "${SELECTED_ENTRIES[@]}")"
  fi

  # Escoller apps creativas

  load_app_category creativity
  local creative_entries=("${APP_CATEGORY_ENTRIES[@]}")

  choose_optional_category "Selecciona apps creativas:" "${creative_entries[@]}"
  apply_selected_app_mime_rules creativity

  # Escoller apps de ofimática

  load_app_category office
  local office_entries=("${APP_CATEGORY_ENTRIES[@]}")

  choose_optional_category "Selecciona apps de oficina e notas:" "${office_entries[@]}"
  apply_selected_app_mime_rules office

  # Escoller apps de xogos

  load_app_category games
  local gaming_entries=("${APP_CATEGORY_ENTRIES[@]}")

  choose_optional_category "Selecciona xogos e tendas:" "${gaming_entries[@]}"
  apply_selected_app_mime_rules games

  # Escoller apps de utilidades

  load_app_category utilities
  local utilities_entries=("${APP_CATEGORY_ENTRIES[@]}")

  choose_optional_category "Selecciona utilidades:" "${utilities_entries[@]}"
  apply_selected_app_mime_rules utilities

  # Escoller apps de desenvolvemento

  load_app_category development
  local development_entries=("${APP_CATEGORY_ENTRIES[@]}")

  choose_optional_category "Selecciona apps de desenvolvemento:" "${development_entries[@]}"

  if has_selected_app git; then
    configure_git || return 1
  fi

  if has_selected_app docker; then
    configure_docker || return 1
  fi

  # Escoller apps de rede e privacidade

  load_app_category network
  local network_entries=("${APP_CATEGORY_ENTRIES[@]}")

  choose_optional_category "Selecciona apps de rede e privacidade:" "${network_entries[@]}"

  # Escoller scripts

  load_app_category downloads
  local script_entries=("${APP_CATEGORY_ENTRIES[@]}")

  choose_optional_category "Selecciona ferramentas de descarga e personalización:" "${script_entries[@]}"

  if has_selected_app yt-dlp; then
    configure_yt_dlp || return 1
  fi

  if has_pipx_app spotdl; then
    configure_spotdl || return 1
  fi
}

# Executa as fases visuais e técnicas da instalación base na orde necesaria.
# Se "base" xa aparece en versions-instaladas, non repite o proceso.
#
# É importante que `install_selected_apps` se execute despois das dúas funcións
# de selección: ata ese momento os helpers só estiveron enchendo colas.
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

  if configure_required_apps; then
    success "Aplicacións principais seleccionadas con éxito!"
  else
    fail "Algo fallou ao seleccionar as aplicacións principais! Abortando instalación..."
  fi

  title "Aplicacións opcionais"
  info "Selecciona aplicacións opcionais por categoría. Podes deixar categorías baleiras."

  if configure_optional_apps; then
    success "Aplicacións opcionais seleccionadas con éxito!"
  else
    fail "Algo fallou ao seleccionar as aplicacións opcionais! Abortando instalación..."
  fi

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

  if has_pkg_app docker; then
    install_docker || fail "Algo fallou ao configurar Docker! Abortando instalación..."
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
