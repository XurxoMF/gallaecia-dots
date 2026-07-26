#!/usr/bin/env bash

###############################################################################
# NON USAR ESTAS FUNCIÓNS EN COMANDOS PERSONALIZADOS
#
# Este módulo é API interna do instalador de Gallaecia Dots. Modifica colas e
# arrays globais compartidos e depende da orde concreta do fluxo de selección.
# Para scripts propios usa os módulos públicos de `scripts/modules/`.
###############################################################################

###############################################################################
# GUÍA DE LECTURA E FLUXO DOS DATOS
#
# Este ficheiro concentra a lóxica interna de aplicacións que comparten:
#
#   1. `updates/base.sh`, durante unha instalación completa.
#   2. `gallaecia install-category`, para instalar máis aplicacións despois.
#
# Non é un conxunto de funcións independentes. É un pequeno fluxo con estado:
#
#   load_app_category
#          │
#          ├─> APP_CATEGORY_LABEL
#          └─> APP_CATEGORY_ENTRIES
#                       │
#                       ▼
#       choose_required_category / choose_optional_category
#                       │
#                       ├─> SELECTED_ENTRIES
#                       ├─> pkgs_apps
#                       ├─> flatpaks_apps
#                       └─> pipx_apps
#                                  │
#                                  ▼
#                      install_selected_apps
#                                  │
#                                  ▼
#                    configuracións opcionais
#                                  │
#                                  ▼
#              predeterminadas de MIME e Hyprland
#
# Bash non pode devolver arrays dunha función de forma cómoda. Por iso algunhas
# funcións escriben nos arrays globais anteriores e a seguinte fase léos. Antes
# de modificar unha función, comproba na guía anterior que variable recibe e cal
# deixa preparada para a seguinte fase.
#
# COMO ENGADIR OU MODIFICAR UNHA APLICACIÓN
#
#   1. Edita unicamente a súa entrada dentro de `load_app_category`.
#   2. Se precisa ficheiros propios, engade o caso en
#      `configure_installed_app_entry`.
#   3. Se debe abrir tipos MIME, revisa `apply_app_category_default` ou
#      `apply_selected_app_mime_rules`.
#   4. Se debe ser unha app principal de Hyprland, revisa tamén
#      `hypr_app_category_key`.
#   5. Actualiza o catálogo do README.
#
# COMO ENGADIR UNHA CATEGORÍA
#
#   1. Engade o ID a APP_CATEGORY_IDS.
#   2. Engade o seu `case` en `load_app_category`.
#   3. Decide se ten unha única app predeterminada, regras MIME por aplicación,
#      unha variable de Hyprland ou ningunha destas cousas.
#   4. Engade só os casos necesarios nas funcións da sección
#      «PREDETERMINADAS: MIME E HYPRLAND».
#
# MATRIZ DAS PREDETERMINADAS
#
#   Categorías                       Hyprland   MIME
#   --------------------------------------------------------------------------
#   terminal, editor                 si         non
#   ide, browser, file-explorer      si         unha app predeterminada
#   audio, video, pdf, images, mail  non        unha app predeterminada
#   chat                             non        Discord ou Vesktop
#   creativity, office, games,
#   utilities                        non        regras propias por aplicación
#   development, network, downloads  non        non
#
# `update_app_category_defaults` é o punto que une estas decisións. Non todas as
# categorías aparecen en todos os `case`: cada bloque enumera só as categorías
# ás que realmente lles aplica esa responsabilidade.
###############################################################################

# Avisa de que os helpers deste módulo son internos e non unha API pública.
_apps_internal_help() {
  cat <<EOF
USO
  ${FUNCNAME[1]} -h|--help

DESCRICIÓN
  NON USAR: esta función pertence á API interna do instalador de aplicacións.
  Pode modificar colas e estado global.

OPCIÓNS
  -h, --help
      Mostra este aviso.

RESULTADO
  A axuda devolve 0 sen modificar o estado. O resto do comportamento forma
  parte do fluxo interno e non constitúe unha API pública.

EXEMPLOS
  ${FUNCNAME[1]} --help

ALTERNATIVAS
  Para comandos personalizados usa os helpers documentados de scripts/modules/.
EOF
}

###############################################################################
# ESTADO COMPARTIDO ENTRE AS FASES
###############################################################################

# Colas acumuladas por xestor. Cada choose_* engade paquetes sen duplicados e
# install_selected_apps consómeas máis tarde. A base acumula nelas todas as
# categorías; install_app_category límpaas ao comezo de cada execución.
pkgs_apps=()
flatpaks_apps=()
pipx_apps=()

# Entradas completas da última categoría preguntada. Substitúense en cada
# choose_required_category/choose_optional_category; non son un historial.
SELECTED_ENTRIES=()

# Entrada completa escollida como predeterminada dentro da categoría actual.
# Só ten sentido despois de choose_default_entry/update_app_category_defaults.
DEFAULT_ENTRY=""

# IDs estables e ordenados de todas as categorías. A orde é tamén a que mostra
# `gallaecia install-category`.
APP_CATEGORY_IDS=(
  terminal editor ide browser file-explorer
  audio video pdf images mail chat creativity office games
  utilities development network downloads
)

# Saída de load_app_category. A etiqueta é humana; as entradas conservan os
# cinco campos internos necesarios para as fases posteriores.
APP_CATEGORY_LABEL=""
APP_CATEGORY_ENTRIES=()

###############################################################################
# CATÁLOGO DE CATEGORÍAS E APLICACIÓNS
###############################################################################

# Carga nun array global as aplicacións dunha categoría.
# Entrada:
#   $1: ID interno presente en APP_CATEGORY_IDS.
#   $2: terminal que se usará para construír o comando de Yazi.
# Saída:
#   APP_CATEGORY_LABEL: nome visible da categoría.
#   APP_CATEGORY_ENTRIES: entradas completas no formato documentado máis abaixo.
# Non imprime as entradas: modifica eses dous valores globais.
load_app_category() {
  local category_id="$1"
  local terminal_command="${2:-kitty}"

  APP_CATEGORY_ENTRIES=()

  case "$category_id" in
    # Categorías principais: a base esixe unha selección e garda o comando en
    # ~/.config/hypr/hyprland.lua.
    terminal)
      APP_CATEGORY_LABEL="Terminal"
      APP_CATEGORY_ENTRIES=(
        "pkg|Kitty|kitty|kitty|kitty.desktop"
        "pkg|Alacritty|alacritty|alacritty|Alacritty.desktop"
        "pkg|Foot|foot|foot|foot.desktop"
        "pkg|Ghostty|ghostty|ghostty|com.mitchellh.ghostty.desktop"
        "pkg|WezTerm|wezterm|wezterm|org.wezfurlong.wezterm.desktop"
      )
      ;;
    editor)
      APP_CATEGORY_LABEL="Editor de terminal"
      APP_CATEGORY_ENTRIES=(
        "pkg|Neovim|neovim|nvim|nvim.desktop"
        "pkg|Helix|helix|hx|"
        "pkg|Vim|vim|vim|vim.desktop"
        "pkg|Nano|nano|nano|"
        "pkg|Micro|micro|micro|"
      )
      ;;
    ide)
      APP_CATEGORY_LABEL="IDE ou editor gráfico"
      APP_CATEGORY_ENTRIES=(
        "pkg|Visual Studio Code|visual-studio-code-bin|code|visual-studio-code.desktop"
        "pkg|Zed|zed|zed|dev.zed.Zed.desktop"
        "pkg|Obsidian|obsidian|obsidian|obsidian.desktop"
        "pkg|Geany|geany|geany|geany.desktop"
      )
      ;;
    browser)
      APP_CATEGORY_LABEL="Navegador"
      APP_CATEGORY_ENTRIES=(
        "pkg|Firefox|firefox|firefox|firefox.desktop"
        "pkg|LibreWolf|librewolf-bin|librewolf|librewolf.desktop"
        "pkg|Zen Browser|zen-browser|zen-browser|zen.desktop"
        "pkg|Tor Browser|tor-browser-bin|tor-browser|torbrowser.desktop"
      )
      ;;
    file-explorer)
      APP_CATEGORY_LABEL="Explorador de arquivos"
      APP_CATEGORY_ENTRIES=(
        "pkg|Dolphin|dolphin ark|dolphin|org.kde.dolphin.desktop"
        "pkg|Nautilus|nautilus|nautilus|org.gnome.Nautilus.desktop"
        "pkg|Nemo|nemo|nemo|nemo.desktop"
        "pkg|Yazi|yazi|$terminal_command -e yazi|"
      )
      ;;
    # Categorías multimedia: permiten varias apps, pero unha soa queda como
    # predeterminada para o grupo de tipos MIME correspondente.
    audio)
      APP_CATEGORY_LABEL="Audio"
      APP_CATEGORY_ENTRIES=(
        "pkg|Amberol|amberol|amberol|io.bassi.Amberol.desktop"
        "pkg|Tauon|tauon-music-box|tauon|com.github.taiko2k.tauonmb.desktop"
        "pkg|VLC|vlc vlc-plugins-all|vlc|vlc.desktop"
        "pkg|MPV|mpv|mpv|mpv.desktop"
      )
      ;;
    video)
      APP_CATEGORY_LABEL="Vídeo"
      APP_CATEGORY_ENTRIES=(
        "pkg|VLC|vlc vlc-plugins-all|vlc|vlc.desktop"
        "pkg|MPV|mpv|mpv|mpv.desktop"
        "pkg|Clapper|clapper|clapper|com.github.rafostar.Clapper.desktop"
      )
      ;;
    pdf)
      APP_CATEGORY_LABEL="PDF"
      APP_CATEGORY_ENTRIES=(
        "pkg|Okular|okular|okular|org.kde.okular.desktop"
        "pkg|Zathura|zathura zathura-pdf-mupdf|zathura|org.pwmt.zathura.desktop"
        "pkg|Evince|evince|evince|org.gnome.Evince.desktop"
      )
      ;;
    images)
      APP_CATEGORY_LABEL="Imaxes"
      APP_CATEGORY_ENTRIES=(
        "pkg|Loupe|loupe|loupe|org.gnome.Loupe.desktop"
        "pkg|GIMP|gimp|gimp|org.gimp.GIMP.desktop"
        "pkg|Krita|krita|krita|org.kde.krita.desktop"
      )
      ;;
    mail)
      APP_CATEGORY_LABEL="Correo"
      APP_CATEGORY_ENTRIES=(
        "pkg|Thunderbird|thunderbird|thunderbird|thunderbird.desktop"
      )
      ;;
    # Categorías con protocolos ou formatos propios dalgunhas apps. Non todas
    # as entradas da categoría precisan unha asociación MIME.
    chat)
      APP_CATEGORY_LABEL="Chat"
      APP_CATEGORY_ENTRIES=(
        "pkg|Discord|discord|discord|discord.desktop"
        "pkg|Vesktop|vesktop|vesktop|vesktop.desktop"
        "pkg|Telegram|telegram-desktop|telegram-desktop|org.telegram.desktop.desktop"
        "pkg|Element|element-desktop|element-desktop|"
      )
      ;;
    creativity)
      APP_CATEGORY_LABEL="Creatividade"
      APP_CATEGORY_ENTRIES=(
        "pkg|OBS Studio|obs-studio|obs|com.obsproject.Studio.desktop"
        "pkg|Krita|krita|krita|org.kde.krita.desktop"
        "pkg|GIMP|gimp|gimp|org.gimp.GIMP.desktop"
        "pkg|Inkscape|inkscape|inkscape|org.inkscape.Inkscape.desktop"
        "pkg|Blender|blender|blender|blender.desktop"
        "pkg|Kdenlive|kdenlive|kdenlive|org.kde.kdenlive.desktop"
        "pkg|Puddletag|puddletag|puddletag|"
        "pkg|HandBrake|handbrake|handbrake|"
      )
      ;;
    office)
      APP_CATEGORY_LABEL="Oficina e notas"
      APP_CATEGORY_ENTRIES=(
        "pkg|LibreOffice|libreoffice-still libreoffice-still-gl libreoffice-still-es|libreoffice|libreoffice-writer.desktop"
        "pkg|Obsidian|obsidian|obsidian|obsidian.desktop"
      )
      ;;
    games)
      APP_CATEGORY_LABEL="Xogos e tendas"
      APP_CATEGORY_ENTRIES=(
        "pkg|Steam|steam|steam|steam.desktop"
        "pkg|Prism Launcher|prismlauncher|prismlauncher|org.prismlauncher.PrismLauncher.desktop"
        "pkg|Lutris|lutris|lutris|"
        "flatpak|Bottles|com.usebottles.bottles|flatpak run com.usebottles.bottles|com.usebottles.bottles.desktop"
      )
      ;;
    utilities)
      APP_CATEGORY_LABEL="Utilidades"
      APP_CATEGORY_ENTRIES=(
        "pkg|KeePassXC|keepassxc|keepassxc|org.keepassxc.KeePassXC.desktop"
        "pkg|qBittorrent|qbittorrent|qbittorrent|org.qbittorrent.qBittorrent.desktop"
      )
      ;;
    # Categorías sen predeterminada xenérica. Só instalan paquetes e, cando
    # corresponda, configuracións opcionais tratadas máis adiante.
    development)
      APP_CATEGORY_LABEL="Desenvolvemento"
      APP_CATEGORY_ENTRIES=(
        "pkg|Git + GitHub CLI|git github-cli|git|"
        "pkg|Docker + Compose|docker docker-compose docker-buildx|docker|"
        "flatpak|Bruno|com.usebruno.Bruno|bruno|"
        "pkg|FileZilla|filezilla|filezilla|"
      )
      ;;
    network)
      APP_CATEGORY_LABEL="Rede e privacidade"
      APP_CATEGORY_ENTRIES=(
        "flatpak|Proton VPN|com.protonvpn.www|protonvpn|"
      )
      ;;
    downloads)
      APP_CATEGORY_LABEL="Descargas e personalización"
      APP_CATEGORY_ENTRIES=(
        "pkg|yt-dlp|yt-dlp|yt-dlp|"
        "pipx|SpotDL|spotdl|spotdl|"
      )
      ;;
    *)
      printf 'Categoría descoñecida: %s\n' "$category_id" >&2
      return 1
      ;;
  esac
}

# Esta conversión é necesaria porque Gum mostra etiquetas humanas, mentres que
# os `case` internos traballan con IDs estables como `file-explorer`.
# Recibe a etiqueta visible devolta por Gum e busca o ID interno correspondente.
# Para facelo percorre APP_CATEGORY_IDS e carga temporalmente cada categoría.
# Imprime o ID atopado; non conserva unha categoría anterior nos globais.
app_category_id_from_label() {
  local selected_label="$1"
  local category_id

  for category_id in "${APP_CATEGORY_IDS[@]}"; do
    load_app_category "$category_id"
    if [ "$APP_CATEGORY_LABEL" = "$selected_label" ]; then
      printf '%s\n' "$category_id"
      return 0
    fi
  done

  return 1
}

# Constrúe o menú de categorías a partir do catálogo, mostra as etiquetas con
# Gum e imprime o ID interno da escollida. O chamador captura ese ID; cancelar o
# selector devolve un código distinto de cero sen modificar paquetes.
choose_app_category() {
  local labels=()
  local category_id selected_label

  for category_id in "${APP_CATEGORY_IDS[@]}"; do
    load_app_category "$category_id"
    labels+=("$APP_CATEGORY_LABEL")
  done

  selected_label="$(gum_choose --header "Selecciona unha categoría:" "${labels[@]}")" ||
    return 1
  app_category_id_from_label "$selected_label"
}

###############################################################################
# COLAS DE PAQUETES POR XESTOR
#
# Estas funcións non instalan nada. Só preparan tres arrays sen duplicados para
# que unha aplicación con varios paquetes ou dúas categorías cun paquete
# compartido non provoquen instalacións repetidas.
###############################################################################

# Recibe un nome de paquete Pacman/AUR e engádeo a pkgs_apps só se non figuraba.
# Devolve 0 tanto se o engade como se xa existía; non consulta o sistema.
add_pkg_app() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  local package_name="$1"
  local app

  for app in "${pkgs_apps[@]}"; do
    if [ "$app" = "$package_name" ]; then
      return 0
    fi
  done

  pkgs_apps+=("$package_name")
}

# Recibe un ID Flatpak e engádeo a flatpaks_apps só se non figuraba.
# Devolve 0 tanto se o engade como se xa existía; non consulta ningún remoto.
add_flatpak_app() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  local package_name="$1"
  local app

  for app in "${flatpaks_apps[@]}"; do
    if [ "$app" = "$package_name" ]; then
      return 0
    fi
  done

  flatpaks_apps+=("$package_name")
}

# Recibe un nome de paquete Python e engádeo a pipx_apps só se non figuraba.
# Devolve 0 tanto se o engade como se xa existía; aínda non executa Pipx.
add_pipx_app() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  local package_name="$1"
  local app

  for app in "${pipx_apps[@]}"; do
    if [ "$app" = "$package_name" ]; then
      return 0
    fi
  done

  pipx_apps+=("$package_name")
}

# Recibe un nome exacto e devolve 0 se xa está en pkgs_apps. Esta comprobación
# mira a cola da instalación actual, non os paquetes instalados no equipo.
has_pkg_app() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  local package_name="$1"
  local app

  for app in "${pkgs_apps[@]}"; do
    if [ "$app" = "$package_name" ]; then
      return 0
    fi
  done

  return 1
}

# Recibe un ID exacto e devolve 0 se xa está en flatpaks_apps. Non chama
# `flatpak info`; só consulta a selección acumulada durante este proceso.
has_flatpak_app() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  local package_name="$1"
  local app

  for app in "${flatpaks_apps[@]}"; do
    if [ "$app" = "$package_name" ]; then
      return 0
    fi
  done

  return 1
}

# Recibe un nome exacto e devolve 0 se xa está en pipx_apps. Non comproba aínda
# se Pipx o ten instalado; esa comprobación faise en install_selected_apps.
has_pipx_app() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  local package_name="$1"
  local app

  for app in "${pipx_apps[@]}"; do
    if [ "$app" = "$package_name" ]; then
      return 0
    fi
  done

  return 1
}

# Recibe un nome de paquete e consulta a base local de Pacman con `pacman -Q`.
# Devolve 0 se está instalado e distinto de cero se falta.
is_pkg_installed() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  local package_name="$1"

  pacman -Q "$package_name" &> /dev/null
}

###############################################################################
# FORMATO E CONSULTA DAS ENTRADAS DO CATÁLOGO
###############################################################################

# As entradas de apps usan este formato:
#
#   "tipo|Nome visible|paquetes|comando para Hypr/env|ficheiro .desktop"
#
# Exemplo:
#   "pkg|Nemo|nemo|nemo|nemo.desktop"
#   "pipx|SpotDL|spotdl|spotdl|"
#   "flatpak|Amberol|io.bassi.Amberol|amberol|io.bassi.Amberol.desktop"
#
# 1. tipo: onde se instala a app.
#    - pkg: pacman/AUR usando yay.
#    - flatpak: Flatpak desde Flathub.
#    - pipx: paquete Python instalado con pipx.
# 2. Nome visible: o que ve o usuario no menú de gum.
# 3. paquetes: un ou varios paquetes/IDs a instalar, separados por espazo.
# 4. comando: valor configurable para scripts, Hyprland, ENV, etc.
# 5. .desktop: ficheiro usado en mimeapps.list. Pode quedar baleiro se non aplica.
app_field() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  local entry="$1"
  local index="$2"

  # `cut` interpreta `|` como separador e devolve o campo numerado desde 1.
  cut -d '|' -f "$index" <<< "$entry"
}

# Recibe unha entrada completa do catálogo e imprime o primeiro campo, que
# identifica o xestor (`pkg`, `flatpak` ou `pipx`). Non valida nin instala nada.
app_type() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  app_field "$1" 1
}

# Recibe unha entrada completa e imprime o segundo campo, usado como etiqueta
# humana nos selectores e nas comparacións con aplicacións configurables.
app_label() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  app_field "$1" 2
}

# Recibe unha entrada completa e imprime o campo 3. Pode conter varios paquetes
# separados por espazos, polo que o chamador decide cando dividir o resultado.
app_packages() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  app_field "$1" 3
}

# Recibe unha entrada completa e imprime o campo 4: o comando que se gardará en
# Hyprland ou se empregará desde os scripts. Non executa ese comando.
app_command() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  app_field "$1" 4
}

###############################################################################
# APLICACIÓNS PRINCIPAIS DE HYPRLAND
#
# O wrapper persoal contén unha táboa Lua chamada `Gallaecia`. As funcións
# seguintes traducen o ID da categoría á clave desa táboa, len o valor actual e
# actualízano sen depender de que aínda exista un `{{placeholder}}`.
###############################################################################

# Recibe un ID de categoría e imprime a clave equivalente da táboa Lua
# `Gallaecia`. Só cinco categorías controlan comandos globais de Hyprland; para
# calquera outra devolve erro porque non existe unha asignación que actualizar.
hypr_app_category_key() {
  local category_id="$1"

  case "$category_id" in
    terminal|editor|ide)
      printf '%s\n' "$category_id"
      ;;
    browser)
      printf 'navegador\n'
      ;;
    file-explorer)
      printf 'explorador_de_arquivos\n'
      ;;
    *)
      return 1
      ;;
  esac
}

# Recibe unha categoría principal e, opcionalmente, unha ruta hyprland.lua.
# Localiza a clave só dentro da táboa `Gallaecia` e imprime o valor actual.
# Úsase sobre todo para que Yazi reutilice o terminal xa configurado.
current_hypr_app_command() {
  local category_id="$1"
  local hypr_config="${2:-$HOME/.config/hypr/hyprland.lua}"
  local config_key

  config_key="$(hypr_app_category_key "$category_id")" || return 1
  [ -r "$hypr_config" ] || return 1

  awk -v config_key="$config_key" '
    /^[[:space:]]*Gallaecia[[:space:]]*=[[:space:]]*{/ {
      in_gallaecia = 1
      next
    }

    in_gallaecia && $0 ~ "^[[:space:]]*" config_key "[[:space:]]*=" {
      value = $0
      sub("^[[:space:]]*" config_key "[[:space:]]*=[[:space:]]*\"", "", value)
      sub("\"[[:space:]]*,?[[:space:]]*$", "", value)
      print value
      exit
    }

    in_gallaecia && /^[[:space:]]*}[[:space:]]*,?[[:space:]]*$/ {
      exit
    }
  ' "$hypr_config"
}

# Recibe unha categoría principal, o novo comando e opcionalmente a ruta Lua.
# Traduce a categoría á súa clave, escapa o comando como cadea Lua e substitúe
# esa asignación unicamente dentro da táboa `Gallaecia`. Se a clave falta,
# créaa; se falta a táboa completa, conserva o ficheiro orixinal e devolve erro.
set_hypr_app_command() {
  local category_id="$1"
  local command_value="$2"
  local hypr_config="${3:-$HOME/.config/hypr/hyprland.lua}"
  local config_key escaped_value replacement temporary_file

  config_key="$(hypr_app_category_key "$category_id")" || return 1

  if [ ! -f "$hypr_config" ]; then
    error "Non se atopou a configuración de Hyprland en $hypr_config."
    return 1
  fi

  # As cadeas Lua precisan escapar primeiro as barras e despois as comiñas.
  escaped_value="${command_value//\\/\\\\}"
  escaped_value="${escaped_value//\"/\\\"}"
  replacement="  $config_key = \"$escaped_value\","
  temporary_file="$(mktemp "${hypr_config}.XXXXXX")" || return 1

  # O parser limita a substitución á táboa Gallaecia. Se a clave foi retirada,
  # créaa antes de pechar a táboa; se falta a táboa completa, non toca o destino.
  # A liña viaxa no contorno para que `awk -v` non reinterprete os escapes Lua.
  if ! GALLAECIA_HYPR_REPLACEMENT="$replacement" \
    awk -v config_key="$config_key" '
    /^[[:space:]]*Gallaecia[[:space:]]*=[[:space:]]*{/ {
      in_gallaecia = 1
      found_gallaecia = 1
      print
      next
    }

    in_gallaecia && $0 ~ "^[[:space:]]*" config_key "[[:space:]]*=" {
      if (!wrote_value) {
        print ENVIRON["GALLAECIA_HYPR_REPLACEMENT"]
        wrote_value = 1
      }
      next
    }

    in_gallaecia && /^[[:space:]]*}[[:space:]]*,?[[:space:]]*$/ {
      if (!wrote_value) {
        print ENVIRON["GALLAECIA_HYPR_REPLACEMENT"]
        wrote_value = 1
      }
      in_gallaecia = 0
    }

    {
      print
    }

    END {
      if (!found_gallaecia) {
        exit 2
      }
    }
  ' "$hypr_config" > "$temporary_file"; then
    rm -f "$temporary_file"
    error "Non se atopou unha táboa Gallaecia válida en $hypr_config."
    return 1
  fi

  if ! chmod --reference="$hypr_config" "$temporary_file" ||
    ! mv -f "$temporary_file" "$hypr_config"; then
    rm -f "$temporary_file"
    return 1
  fi
}

###############################################################################
# SELECCIÓN DE ENTRADAS E CONVERSIÓN A COLAS
###############################################################################

# Recibe unha entrada completa e imprime o campo 5, o ficheiro .desktop usado
# por mimeapps.list. Un resultado baleiro significa que a app non pode ser
# candidata a unha asociación MIME xenérica.
app_desktop() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  app_field "$1" 5
}

# Recibe primeiro unha etiqueta visible e despois unha lista de entradas.
# Compara o campo 2 de cada unha e imprime a entrada completa correspondente.
# Serve para converter a saída humana de Gum de novo ao formato interno.
find_app_by_label() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  local label="$1"
  shift
  local entry

  for entry in "$@"; do
    if [ "$(app_label "$entry")" = "$label" ]; then
      printf '%s\n' "$entry"
      return 0
    fi
  done

  return 1
}

# Recibe un nome visible ou un paquete e percorre SELECTED_ENTRIES.
# Devolve 0 cando algunha entrada seleccionada coincide pola etiqueta ou contén
# ese paquete. Isto permite que os `case` posteriores pregunten por `docker`,
# `Vesktop` ou outro identificador sen coñecer a posición da entrada.
has_selected_app() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  local app_name="$1"
  local selected_entry package

  for selected_entry in "${SELECTED_ENTRIES[@]}"; do
    if [ "$(app_label "$selected_entry")" = "$app_name" ]; then
      return 0
    fi

    for package in $(app_packages "$selected_entry"); do
      if [ "$package" = "$app_name" ]; then
        return 0
      fi
    done
  done

  return 1
}

# Recibe unha entrada completa, le o seu xestor e separa o campo de paquetes.
# Envía cada paquete á cola Yay, Flatpak ou Pipx correspondente. Se aparece un
# tipo novo no catálogo, falla aquí ata que se defina como debe instalarse.
add_entry_packages() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  local entry="$1"
  local install_type packages package

  install_type="$(app_type "$entry")"
  packages="$(app_packages "$entry")"

  # A separación en palabras é deliberada: o terceiro campo permite varios
  # paquetes separados por espazos, por exemplo `dolphin ark`.
  for package in $packages; do
    case "$install_type" in
      pkg)
        add_pkg_app "$package"
        ;;
      flatpak)
        add_flatpak_app "$package"
        ;;
      pipx)
        add_pipx_app "$package"
        ;;
      *)
        warning "Tipo de instalación descoñecido para $(app_label "$entry"): $install_type"
        return 1
        ;;
    esac
  done
}

# Mostra etiquetas humanas, pero devolve por stdout as entradas completas.
# `choose_required_category` e `choose_optional_category` capturan esa saída con
# mapfile para reconstruír SELECTED_ENTRIES sen perder espazos.
choose_entries() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  local header="$1"
  shift
  local entries=("$@")
  local labels=()
  local entry selected label

  for entry in "${entries[@]}"; do
    labels+=("$(app_label "$entry")")
  done

  selected=$(gum_choose \
    --no-limit \
    --header "$header" \
    "${labels[@]}")

  # Léese liña a liña porque gum devolve unha selección por liña.
  while IFS= read -r label; do
    [ -n "$label" ] || continue
    find_app_by_label "$label" "${entries[@]}"
  done <<< "$selected"
}

# Recibe unha cabeceira e unha ou máis entradas completas. Cunha única entrada
# devólvea directamente; con varias mostra as etiquetas e imprime a entrada
# completa elixida. Non modifica DEFAULT_ENTRY por si mesma.
choose_default_entry() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  local header="$1"
  shift
  local entries=("$@")
  local labels=()
  local entry selected

  case "${#entries[@]}" in
    0)
      return 1
      ;;
    1)
      printf '%s\n' "${entries[0]}"
      return 0
      ;;
  esac

  for entry in "${entries[@]}"; do
    labels+=("$(app_label "$entry")")
  done

  selected=$(gum_choose \
    --header "$header" \
    "${labels[@]}")

  find_app_by_label "$selected" "${entries[@]}"
}

# Percorre SELECTED_ENTRIES e converte cada entrada nas colas por xestor.
# É a ponte entre a fase de selección e a fase de instalación.
add_selected_entries_packages() {
  local selected_entry

  for selected_entry in "${SELECTED_ENTRIES[@]}"; do
    add_entry_packages "$selected_entry"
  done
}

# Selección obrigatoria:
# - repite ata que o usuario escolla polo menos unha app,
# - garda as apps escollidas en SELECTED_ENTRIES.
#
# Non escolle DEFAULT_ENTRY por si mesma. Se a categoría precisa unha app por
# defecto, o script pode chamar choose_default_entry despois.
choose_required_category() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  local header="$1"
  shift
  local entries=("$@")

  SELECTED_ENTRIES=()
  DEFAULT_ENTRY=""

  while [ ${#SELECTED_ENTRIES[@]} -eq 0 ]; do
    # `mapfile` conserva cada entrada devolta por choose_entries como un elemento.
    mapfile -t SELECTED_ENTRIES < <(choose_entries "$header" "${entries[@]}")
    if [ ${#SELECTED_ENTRIES[@]} -eq 0 ]; then
      warning "Tes que escoller polo menos unha opción."
    fi
  done

  add_selected_entries_packages
}

# Recibe unha cabeceira e as entradas dunha categoría opcional. Garda en
# SELECTED_ENTRIES cero ou máis eleccións, limpa DEFAULT_ENTRY e actualiza as
# colas. Unha selección baleira é válida e non repite a pregunta.
choose_optional_category() {
  while (($#)); do
    case "$1" in
      -h|--help) _apps_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  local header="$1"
  shift
  local entries=("$@")

  SELECTED_ENTRIES=()
  # shellcheck disable=SC2034
  DEFAULT_ENTRY=""

  # A substitución de proceso alimenta mapfile sen executar o bucle nun subshell.
  mapfile -t SELECTED_ENTRIES < <(choose_entries "$header" "${entries[@]}")

  add_selected_entries_packages
}

###############################################################################
# INSTALACIÓN DAS COLAS
###############################################################################

# Instala todos os paquetes acumulados polas seleccións anteriores.
# Primeiro calcula que falta para non reinstalar aplicacións xa presentes.
# Despois executa como máximo unha instalación Yay, unha Flatpak e as Pipx que
# correspondan. Non configura aplicacións: esa é unha fase posterior.
install_selected_apps() {
  local pending_pkgs=()
  local pending_flatpaks=()
  local package_name

  for package_name in "${pkgs_apps[@]}"; do
    if ! is_pkg_installed "$package_name"; then
      pending_pkgs+=("$package_name")
    fi
  done

  for package_name in "${flatpaks_apps[@]}"; do
    if ! flatpak info "$package_name" &> /dev/null; then
      pending_flatpaks+=("$package_name")
    fi
  done

  if [ ${#pending_pkgs[@]} -gt 0 ]; then
    yay -S --needed -- "${pending_pkgs[@]}" || return 1
  fi

  if [ ${#pending_flatpaks[@]} -gt 0 ]; then
    flatpak install -y flathub "${pending_flatpaks[@]}" || return 1
  fi

  for package_name in "${pipx_apps[@]}"; do
    if ! has_package --manager pipx "$package_name"; then
      pipx install "$package_name" || return 1
    fi
  done
}

###############################################################################
# PREDETERMINADAS: MIME E HYPRLAND
#
# Hai dous modelos MIME:
#
#   1. Categoría cunha única app predeterminada: navegador, audio, PDF...
#      `apply_app_category_default` recibe a entrada elixida.
#   2. Regras propias dunha app: Steam abre steam://, qBittorrent magnet:...
#      `apply_selected_app_mime_rules` revisa toda SELECTED_ENTRIES.
#
# Para IDE, navegador e explorador a mesma DEFAULT_ENTRY tamén se escribe na
# táboa Gallaecia de Hyprland. Así só se pregunta unha vez.
###############################################################################

# Recibe un tipo MIME e un ficheiro .desktop. Edita só a sección
# `[Default Applications]` de ~/.config/mimeapps.list: substitúe a regra se xa
# existe ou insírea se falta. Outras seccións como `[Added Associations]`
# consérvanse. A escritura faise nun temporal e só despois substitúe o destino.
set_default_app() {
  local mime_type="$1"
  local desktop_file="$2"
  local mimeapps="$HOME/.config/mimeapps.list"
  local temporary_file

  mkdir -p "$HOME/.config"
  touch "$mimeapps"

  temporary_file="$(mktemp "$HOME/.config/.mimeapps.list.XXXXXX")" || return 1

  # O parser modifica exclusivamente [Default Applications]. Ao atopar outra
  # sección pecha a anterior e insire a regra se aínda non existía.
  if ! awk -v mime_type="$mime_type" -v desktop_file="$desktop_file" '
    BEGIN {
      in_defaults = 0
      found_defaults = 0
      wrote_rule = 0
    }

    $0 == "[Default Applications]" {
      in_defaults = 1
      found_defaults = 1
      print
      next
    }

    /^\[/ {
      if (in_defaults && !wrote_rule) {
        print mime_type "=" desktop_file
        wrote_rule = 1
      }
      in_defaults = 0
    }

    in_defaults && index($0, mime_type "=") == 1 {
      if (!wrote_rule) {
        print mime_type "=" desktop_file
        wrote_rule = 1
      }
      next
    }

    {
      print
    }

    END {
      if (!found_defaults) {
        if (NR > 0) {
          print ""
        }
        print "[Default Applications]"
        print mime_type "=" desktop_file
      } else if (in_defaults && !wrote_rule) {
        print mime_type "=" desktop_file
      }
    }
  ' "$mimeapps" > "$temporary_file"; then
    rm -f "$temporary_file"
    return 1
  fi

  if ! chmod --reference="$mimeapps" "$temporary_file" ||
    ! mv -f "$temporary_file" "$mimeapps"; then
    rm -f "$temporary_file"
    return 1
  fi
}

# Recibe primeiro un ficheiro .desktop e despois un ou máis tipos MIME.
# Chama set_default_app por cada tipo para asignar todos á mesma aplicación.
set_default_apps() {
  local desktop_file="$1"
  shift
  local mime_type

  for mime_type in "$@"; do
    set_default_app "$mime_type" "$desktop_file"
  done
}

# Recibe o ID dunha categoría e revisa SELECTED_ENTRIES para decidir se algunha
# app seleccionada ten regras MIME que Gallaecia saiba configurar.
#
# As categorías xenéricas só precisan un campo .desktop non baleiro. As ramas
# especiais comproban aplicacións concretas porque non toda a categoría comparte
# os mesmos formatos: por exemplo, qBittorrent abre magnet: pero KeePassXC non.
# Só devolve verdadeiro ou falso; non escolle defaults nin escribe ficheiros.
selected_apps_have_mime_rules() {
  local category_id="$1"
  local entry

  case "$category_id" in
    # Nestas categorías calquera entrada cun .desktop pode recibir o grupo MIME.
    ide|browser|file-explorer|audio|video|pdf|images|mail)
      for entry in "${SELECTED_ENTRIES[@]}"; do
        if [ -n "$(app_desktop "$entry")" ]; then
          return 0
        fi
      done
      ;;
    # Nas seguintes categorías só certas aplicacións teñen regras coñecidas.
    chat)
      has_selected_app vesktop || has_selected_app discord
      return
      ;;
    creativity)
      has_selected_app krita ||
        has_selected_app inkscape ||
        has_selected_app blender ||
        has_selected_app kdenlive
      return
      ;;
    office)
      has_selected_app libreoffice-still
      return
      ;;
    games)
      has_selected_app steam
      return
      ;;
    utilities)
      has_selected_app qbittorrent
      return
      ;;
  esac

  return 1
}

# Recibe o ID da categoría e a entrada completa elixida como DEFAULT_ENTRY.
# Obtén o seu .desktop e, segundo a categoría, asígnalle o grupo de formatos
# xenéricos correspondente: navegación web, audio, vídeo, PDF, imaxes, correo...
#
# Terminal e editor non aparecen porque non teñen MIME que configurar. As
# categorías con regras por aplicación tampouco aparecen: resólvense na función
# seguinte. Unha entrada sen .desktop, como Yazi, non modifica mimeapps.list.
apply_app_category_default() {
  local category_id="$1"
  local entry="$2"
  local desktop_file

  desktop_file="$(app_desktop "$entry")"
  if [ -z "$desktop_file" ]; then
    return 0
  fi

  case "$category_id" in
    # O IDE predeterminado abre texto plano; outros formatos de código xa poden
    # estar definidos no mimeapps.list base.
    ide)
      set_default_apps "$desktop_file" text/plain
      ;;
    browser)
      set_default_apps "$desktop_file" \
        text/html application/xhtml+xml x-scheme-handler/http x-scheme-handler/https
      ;;
    file-explorer)
      set_default_apps "$desktop_file" inode/directory
      ;;
    audio)
      set_default_apps "$desktop_file" \
        audio/aac audio/flac audio/mpeg audio/ogg audio/opus audio/wav audio/x-wav audio/x-ms-wma
      ;;
    video)
      set_default_apps "$desktop_file" \
        video/mp2t video/mp4 video/mpeg video/ogg video/quicktime video/webm \
        video/x-matroska video/x-msvideo video/x-ms-wmv
      ;;
    pdf)
      set_default_apps "$desktop_file" \
        application/pdf application/epub+zip application/vnd.comicbook+zip \
        application/vnd.djvu image/vnd.djvu application/oxps \
        application/vnd.ms-xpsdocument
      ;;
    images)
      set_default_apps "$desktop_file" \
        image/avif image/bmp image/gif image/heif image/jpeg image/jxl image/png \
        image/tiff image/webp image/x-xcf image/vnd.adobe.photoshop
      ;;
    mail)
      set_default_apps "$desktop_file" \
        message/rfc822 x-scheme-handler/mailto x-scheme-handler/mid
      ;;
    # Telegram e Element non abren discord://; por iso este segundo filtro.
    chat)
      case "$(app_packages "$entry")" in
        *vesktop*)
          set_default_apps vesktop.desktop x-scheme-handler/discord
          ;;
        *discord*)
          set_default_apps discord.desktop x-scheme-handler/discord
          ;;
      esac
      ;;
  esac
}

# Recibe o ID da categoría e consulta SELECTED_ENTRIES mediante
# has_selected_app. Non usa DEFAULT_ENTRY: aplica todas as regras específicas
# das apps presentes, pois non compiten entre si necesariamente.
#
# Exemplos: Krita recibe .kra/OpenRaster, LibreOffice reparte documentos entre
# Writer/Calc/Impress, Steam recibe steam:// e qBittorrent magnet:. As categorías
# que só teñen unha predeterminada xenérica resólvense na función anterior.
apply_selected_app_mime_rules() {
  local category_id="$1"

  case "$category_id" in
    # Cada ferramenta creativa recibe só os seus formatos nativos.
    creativity)
      if has_selected_app krita; then
        set_default_apps org.kde.krita.desktop application/x-krita image/openraster
      fi
      if has_selected_app inkscape; then
        set_default_apps org.inkscape.Inkscape.desktop \
          image/svg+xml image/svg+xml-compressed application/postscript \
          application/illustrator application/eps
      fi
      if has_selected_app blender; then
        set_default_apps blender.desktop application/x-blender
      fi
      if has_selected_app kdenlive; then
        set_default_apps org.kde.kdenlive.desktop \
          application/x-kdenlive application/x-kdenlivetitle
      fi
      ;;
    # LibreOffice reparte os formatos entre os catro executables especializados.
    office)
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
        set_default_apps libreoffice-draw.desktop \
          application/vnd.oasis.opendocument.graphics
      fi
      ;;
    # Steam e qBittorrent rexistran protocolos, non unha predeterminada global.
    games)
      if has_selected_app steam; then
        set_default_apps steam.desktop \
          x-scheme-handler/steam x-scheme-handler/steamlink
      fi
      ;;
    utilities)
      if has_selected_app qbittorrent; then
        set_default_apps org.qbittorrent.qBittorrent.desktop \
          application/x-bittorrent x-scheme-handler/magnet
      fi
      ;;
  esac
}

# Recibe o ID da categoría e usa APP_CATEGORY_LABEL e SELECTED_ENTRIES cargados
# previamente. É o coordinador das predeterminadas:
#
# - Se hai MIME xenérico, descarta entradas sen .desktop.
# - Se non hai MIME pero si variable Hyprland (terminal/editor), admite todas.
# - En chat limita candidatos a Discord/Vesktop porque son os únicos que abren
#   o protocolo discord://.
# - Garda a elección en DEFAULT_ENTRY.
# - Se a categoría ten clave Hyprland, escribe o comando desa mesma entrada.
# - Aplica despois o MIME xenérico e as regras específicas da categoría.
#
# Así IDE, navegador e explorador usan unha única elección para Hyprland e MIME.
update_app_category_defaults() {
  local category_id="$1"
  local candidates=()
  local entry
  local has_mime_defaults=false

  if selected_apps_have_mime_rules "$category_id"; then
    has_mime_defaults=true
  fi

  for entry in "${SELECTED_ENTRIES[@]}"; do
    if [ "$category_id" = "chat" ]; then
      case " $(app_packages "$entry") " in
        *" vesktop "*|*" discord "*) candidates+=("$entry") ;;
      esac
    elif $has_mime_defaults && [ -n "$(app_desktop "$entry")" ]; then
      candidates+=("$entry")
    elif ! $has_mime_defaults &&
      hypr_app_category_key "$category_id" > /dev/null; then
      candidates+=("$entry")
    fi
  done

  case "$category_id" in
    terminal|editor|ide|browser|file-explorer|audio|video|pdf|images|mail|chat)
      if [ ${#candidates[@]} -gt 0 ]; then
        DEFAULT_ENTRY="$(choose_default_entry \
          "Escolle a aplicación predeterminada para $APP_CATEGORY_LABEL:" \
          "${candidates[@]}")" || return 1

        if hypr_app_category_key "$category_id" > /dev/null; then
          set_hypr_app_command \
            "$category_id" "$(app_command "$DEFAULT_ENTRY")" || return 1
        fi

        apply_app_category_default "$category_id" "$DEFAULT_ENTRY" || return 1
      fi
      ;;
  esac

  apply_selected_app_mime_rules "$category_id"
}

###############################################################################
# CONFIGURACIÓNS OPCIONAIS E ORQUESTRACIÓN DE INSTALL-CATEGORY
###############################################################################

# Recibe unha entrada completa xa instalada e mira o seu campo de paquetes.
# O `case` busca nomes coas marxes de espazo para non confundir coincidencias
# parciais. Só aparecen aquí aplicacións que precisan algo ademais do paquete:
# configuracións de terminal, plugins de Yazi, Bashrc opcionais ou servizos.
#
# Unha entrada que non coincide con ningún caso non é un erro: significa que o
# paquete funciona sen configuración adicional controlada por Gallaecia.
configure_installed_app_entry() {
  local entry="$1"
  local packages

  packages="$(app_packages "$entry")"

  case " $packages " in
    # Terminais con configuración controlada dentro de optional/.
    *" kitty "*)
      replace_path "$DOTFILES_DIR/optional/.config/kitty" "$HOME/.config/kitty"
      ;;
    *" alacritty "*)
      replace_path "$DOTFILES_DIR/optional/.config/alacritty" "$HOME/.config/alacritty"
      ;;
    *" foot "*)
      replace_path "$DOTFILES_DIR/optional/.config/foot" "$HOME/.config/foot"
      ;;
    *" ghostty "*)
      replace_path "$DOTFILES_DIR/optional/.config/ghostty" "$HOME/.config/ghostty"
      ;;
    *" wezterm "*)
      replace_path "$DOTFILES_DIR/optional/.config/wezterm" "$HOME/.config/wezterm"
      ;;
    # Exploradores con configuración ou plugins adicionais.
    *" dolphin "*)
      replace_file \
        "$DOTFILES_DIR/optional/.config/dolphinrc" \
        "$HOME/.config/dolphinrc"
      ;;
    *" yazi "*)
      replace_path "$DOTFILES_DIR/optional/.config/yazi" "$HOME/.config/yazi" &&
        ya pkg add yazi-rs/plugins:git &&
        ya pkg add yazi-rs/plugins:mount &&
        ya pkg add yazi-rs/plugins:chmod &&
        ya pkg add boydaihungst/restore &&
        ya pkg add boydaihungst/mediainfo
      ;;
    # Aplicacións que instalan flags, módulos Bashrc ou servizos.
    *" visual-studio-code-bin "*)
      replace_file \
        "$DOTFILES_DIR/optional/.config/code-flags.conf" \
        "$HOME/.config/code-flags.conf"
      ;;
    *" git "*)
      mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" &&
        replace_file \
          "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/203-git" \
          "$HOME/.local/share/gallaecia-dots/bashrc/203-git"
      ;;
    *" docker "*)
      mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" &&
        replace_file \
          "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/204-docker" \
          "$HOME/.local/share/gallaecia-dots/bashrc/204-docker" &&
        sudo systemctl enable docker.service &&
        sudo usermod -aG docker "$USER"
      ;;
    *" yt-dlp "*)
      mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" &&
        replace_path \
          "$DOTFILES_DIR/optional/.config/yt-dlp" \
          "$HOME/.config/yt-dlp" &&
        replace_file \
          "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/201-yt-dlp" \
          "$HOME/.local/share/gallaecia-dots/bashrc/201-yt-dlp"
      ;;
    *" spotdl "*)
      mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" &&
        replace_path \
          "$DOTFILES_DIR/optional/.config/spotdl" \
          "$HOME/.config/spotdl" &&
        replace_file \
          "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/202-spotdl" \
          "$HOME/.local/share/gallaecia-dots/bashrc/202-spotdl"
      ;;
  esac
}

# Recibe opcionalmente un ID de categoría; se falta, deixa que o usuario o
# escolla. É o orquestrador completo de `gallaecia install-category`.
# Este é o punto de entrada usado por `gallaecia install-category`:
#
#   1. Limpa o estado deixado por seleccións anteriores.
#   2. Resolve a categoría e carga o seu catálogo.
#   3. Pregunta que aplicacións engadir e enche as colas.
#   4. Instala só o que falta.
#   5. Copia configuracións opcionais.
#   6. Se corresponde, pregunta unha vez polas predeterminadas e aplica esa
#      elección tanto en MIME como en Hyprland.
#
# Para `file-explorer` le primeiro o terminal actual de Hyprland, porque o
# comando de Yazi se constrúe como `TERMINAL -e yazi`.
#
# A función non desinstala aplicacións nin tenta reconstruír seleccións antigas.
# Se non se escolle nada, remata correctamente sen modificar o sistema.
install_app_category() {
  local category_id="${1:-}"
  local entry
  local terminal_for_yazi="${TERMINAL:-kitty}"

  # Fase 1: este comando pode executarse varias veces na mesma sesión interna.
  # As colas e a selección deben empezar baleiras en cada invocación.
  pkgs_apps=()
  flatpaks_apps=()
  pipx_apps=()
  SELECTED_ENTRIES=()

  if [ -z "$category_id" ]; then
    category_id="$(choose_app_category)" || return 0
  fi

  # Fase 2: Yazi necesita coñecer o terminal xa gardado. Para o resto das
  # categorías o segundo argumento de load_app_category non ten efecto.
  if [ "$category_id" = "file-explorer" ]; then
    terminal_for_yazi="$(
      current_hypr_app_command terminal ||
        printf '%s' "$terminal_for_yazi"
    )"
  fi

  load_app_category "$category_id" "$terminal_for_yazi" || return 1

  # Fase 3: a selección é opcional porque este comando serve para engadir apps,
  # non para repetir as cinco obrigatorias da instalación inicial.
  choose_optional_category \
    "Selecciona aplicacións de $APP_CATEGORY_LABEL:" \
    "${APP_CATEGORY_ENTRIES[@]}"

  if [ ${#SELECTED_ENTRIES[@]} -eq 0 ]; then
    info "Non se seleccionou ningunha aplicación."
    return 0
  fi

  if ! install_selected_apps; then
    return 1
  fi

  # Fase 4: os paquetes xa existen neste punto; agora é seguro copiar configs,
  # engadir plugins ou habilitar servizos dependentes desas aplicacións.
  for entry in "${SELECTED_ENTRIES[@]}"; do
    if ! configure_installed_app_entry "$entry"; then
      return 1
    fi
  done

  # Fase 5: só se pregunta cando a categoría ten unha variable Hyprland ou
  # algunha regra MIME coñecida. A elección resultante é única para ambos.
  if hypr_app_category_key "$category_id" > /dev/null ||
    selected_apps_have_mime_rules "$category_id"; then
    if gum_confirm "Queres actualizar os valores predeterminados desta categoría?"; then
      update_app_category_defaults "$category_id" || return 1
    fi
  fi

  success "Aplicacións de $APP_CATEGORY_LABEL instaladas correctamente."
}
