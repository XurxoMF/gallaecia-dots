# shellcheck shell=bash

###############################################################################
# MÓDULO PÚBLICO DE APLICACIÓNS
#
# Este ficheiro si se carga en cada terminal e expón catro comandos:
#
#   has_package      -> consulta se algo xa está instalado.
#   yay-install      -> explora o catálogo combinado Arch + AUR.
#   flatpak-install  -> explora o catálogo dun remoto Flatpak.
#   pipx-install     -> valida e instala un nome exacto desde PyPI.
#
# Non comparte o estado nin o catálogo predefinido de `internal/apps.sh`.
# Estes comandos son ferramentas xenéricas para uso diario. O fluxo común dos
# tres instaladores interactivos é:
#
#   validar argumentos e dependencias
#          │
#          ▼
#   obter ou validar o catálogo
#          │
#          ▼
#   filtrar/seleccionar con Gum
#          │
#          ▼
#   mostrar información dos paquetes
#          │
#          ▼
#   pedir confirmación e instalar
#
# Yay pode mostrar todo o catálogo que mantén localmente. Flatpak consulta o
# remoto configurado. PyPI non ofrece busca parcial oficial mediante Pip/Pipx,
# polo que Pipx require un nome exacto.
###############################################################################

# Mostra a axuda específica de cada helper público de aplicacións.
_apps_help() {
  case "$1" in
    has_package)
      cat <<'EOF'
USO
  has_package [OPCIÓNS] PAQUETE

DESCRICIÓN
  Comproba se un paquete está instalado mediante Yay, Flatpak ou Pipx. Por
  defecto revisa os tres xestores dispoñibles.

PARÁMETROS
  PAQUETE
      Nome exacto do paquete ou identificador Flatpak que se quere comprobar.

OPCIÓNS
  --manager XESTOR
      Limita a comprobación a `yay`, `flatpak` ou `pipx`. O valor
      predeterminado é `any`.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite un nome que comece por guión.

RESULTADO
  Devolve 0 se o paquete está instalado nalgún dos xestores consultados.
  Devolve un código distinto de 0 se non está instalado, o xestor indicado non
  está dispoñible ou os argumentos non son válidos.

EXEMPLOS
  has_package git
  has_package --manager flatpak org.mozilla.firefox
  has_package --manager pipx yt-dlp
EOF
      ;;
    yay-install)
      cat <<'EOF'
USO
  yay-install [OPCIÓNS] [CONSULTA]

DESCRICIÓN
  Mostra o catálogo local completo de paquetes oficiais e AUR mantido por Yay,
  permite filtrar e seleccionar varios, mostra a súa información e pide
  confirmación antes de instalalos.

PARÁMETROS
  [CONSULTA]
      Texto co que se inicia o filtro do catálogo.

OPCIÓNS
  -r, --refresh
      Actualiza inmediatamente a caché de paquetes de Yay antes de mostrar o
      catálogo, sen modificar o intervalo gardado na súa configuración.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite unha consulta que comece por guión.

CONTROIS
  Escribir
      Reduce as coincidencias por nome ou orixe.

  Frechas ou Ctrl+j/Ctrl+k
      Move o cursor polos resultados.

  Tab ou Ctrl+Espazo
      Marca ou desmarca paquetes.

  Enter
      Confirma a selección.

RESULTADO
  Instala con Yay os paquetes seleccionados e devolve 0 se se completa.
  Cancelar non instala nada e devolve 0; os erros de catálogo ou instalación
  devolven un código distinto de 0.

EXEMPLOS
  yay-install
  yay-install alacritty
  yay-install --refresh
  yay-install --refresh firefox
EOF
      ;;
    flatpak-install)
      cat <<'EOF'
USO
  flatpak-install [OPCIÓNS]

DESCRICIÓN
  Obtén o catálogo completo de aplicacións dun remoto Flatpak, permite buscar
  e seleccionar varias, mostra a súa información e pide confirmación antes de
  instalalas.

OPCIÓNS
  --remote REMOTO
      Remoto que se consultará. O valor predeterminado é `flathub`.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións. Este comando non admite argumentos posicionais.

CONTROIS
  Escribir
      Busca por identificador, nome ou descrición.

  Frechas ou Ctrl+j/Ctrl+k
      Move o cursor polos resultados.

  Tab ou Ctrl+Espazo
      Marca ou desmarca aplicacións.

  Enter
      Confirma a selección.

RESULTADO
  Instala as aplicacións seleccionadas desde o remoto indicado.
  Cancelar non instala nada e devolve 0; os erros de catálogo ou instalación
  devolven un código distinto de 0.

EXEMPLOS
  flatpak-install
  flatpak-install --remote flathub
EOF
      ;;
    pipx-install)
      cat <<'EOF'
USO
  pipx-install [OPCIÓNS] [PAQUETE]

DESCRICIÓN
  Valida un paquete de Python, mostra as versións dispoñibles en PyPI e pide
  confirmación antes de instalalo con Pipx.

  Pip e Pipx non ofrecen unha busca parcial oficial de PyPI. Por iso este
  comando require o nome exacto do paquete, solicitado mediante un input cando
  non se proporciona como parámetro.

PARÁMETROS
  [PAQUETE]
      Nome exacto dun paquete publicado no índice configurado de Pip.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do wrapper.

RESULTADO
  Instala o paquete con Pipx e devolve 0 se se completa.
  Cancelar non instala nada e devolve 0; un paquete inexistente ou un erro de
  instalación devolven un código distinto de 0.

EXEMPLOS
  pipx-install
  pipx-install black
  pipx-install yt-dlp
EOF
      ;;
  esac
}

###############################################################################
# CONSULTA DE PAQUETES INSTALADOS
###############################################################################

# Recibe un nome exacto e consulta a base local combinada de Yay/Pacman.
# Primeiro comproba que Yay exista; devolve 0 só se `yay -Q` atopa o paquete.
_apps_has_yay_package() {
  local package_name="$1"

  command -v yay &> /dev/null &&
    yay -Q -- "$package_name" &> /dev/null
}

# Recibe un ID exacto e usa `flatpak info` para comprobar se hai unha
# aplicación ou runtime instalado con ese identificador.
_apps_has_flatpak_package() {
  local package_name="$1"

  command -v flatpak &> /dev/null &&
    flatpak info "$package_name" &> /dev/null
}

# Recibe un nome de paquete Python e revisa as instalacións Pipx do usuario e
# globais. Normaliza ambos nomes porque PyPI considera equivalentes guións,
# guións baixos, puntos e maiúsculas.
_apps_has_pipx_package() {
  local package_name="$1"
  local normalized_name installed_name

  if ! command -v pipx &> /dev/null; then
    return 1
  fi
  # PyPI considera equivalentes maiúsculas e secuencias de `.`, `_` ou `-`.
  normalized_name="$(_apps_normalize_python_package "$package_name")"
  while IFS= read -r installed_name; do
    if [ "$(_apps_normalize_python_package "$installed_name")" = \
      "$normalized_name" ]; then
      return 0
    fi
  done < <(
    pipx list --short 2> /dev/null
    pipx list --global --short 2> /dev/null
  )

  return 1
}

# Recibe un nome de paquete e imprime a súa forma comparable segundo PyPI:
# minúsculas e secuencias de `.`, `_` ou `-` convertidas nun único guión.
_apps_normalize_python_package() {
  local package_name="${1,,}"

  package_name="${package_name//./-}"
  package_name="${package_name//_/-}"
  while [[ "$package_name" == *--* ]]; do
    package_name="${package_name//--/-}"
  done

  printf '%s\n' "$package_name"
}

# Comando público que recibe un paquete e, opcionalmente, un xestor.
# Con `--manager` chama só o comprobador solicitado; co valor `any` proba Yay,
# Flatpak e Pipx por orde e devolve éxito coa primeira coincidencia.
# Non instala nin consulta catálogos remotos.
has_package() {
  local manager="any"
  local values=()
  local package_name

  while (($#)); do
    case "$1" in
      --manager)
        if [ $# -lt 2 ]; then
          printf 'Falta XESTOR para --manager. Usa has_package --help.\n' >&2
          return 1
        fi
        manager="$2"
        shift
        ;;
      -h|--help)
        _apps_help has_package
        return 0
        ;;
      --)
        shift
        values+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa has_package --help.\n' "$1" >&2
        return 1
        ;;
      *)
        values+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#values[@]} -ne 1 ]; then
    printf 'has_package require un PAQUETE. Usa has_package --help.\n' >&2
    return 1
  fi
  case "$manager" in
    any|yay|flatpak|pipx) ;;
    *)
      printf 'Xestor non válido: %s. Usa has_package --help.\n' "$manager" >&2
      return 1
      ;;
  esac
  package_name="${values[0]}"

  case "$manager" in
    yay) _apps_has_yay_package "$package_name" ;;
    flatpak) _apps_has_flatpak_package "$package_name" ;;
    pipx) _apps_has_pipx_package "$package_name" ;;
    any)
      _apps_has_yay_package "$package_name" ||
        _apps_has_flatpak_package "$package_name" ||
        _apps_has_pipx_package "$package_name"
      ;;
  esac
}

###############################################################################
# PEZAS COMÚNS DOS INSTALADORES INTERACTIVOS
###############################################################################

# Verifica que os wrappers de UI usados máis abaixo están definidos na shell.
# Isto produce un erro comprensible cando alguén carga apps.sh manualmente sen
# cargar tamén ui.sh, en lugar de fallar no medio dunha instalación.
_apps_require_public_helpers() {
  local helper

  for helper in gum_input gum_filter gum_pager gum_confirm info warning error; do
    if ! declare -F "$helper" &> /dev/null; then
      printf 'Helper público non cargado: %s\n' "$helper" >&2
      printf 'Carga todos os módulos de Gallaecia antes de usar estes comandos.\n' >&2
      return 1
    fi
  done
}

# Recibe o catálogo xa formatado, a cabeceira e un filtro inicial opcional.
# Envía as filas a gum_filter e devolve por stdout exactamente as seleccionadas.
_apps_filter_catalog() {
  local catalog="$1"
  local header="$2"
  local initial_value="${3:-}"

  printf '%s\n' "$catalog" |
    gum_filter -- \
      --no-limit \
      --header "$header" \
      --value "$initial_value"
}

# Recibe texto potencialmente longo e móstrao nun pager de Gum. O seu estado de
# saída permite tratar pechar/cancelar o pager como cancelación do fluxo.
_apps_show_information() {
  local information="$1"

  printf '%s\n' "$information" |
    gum_pager -- --soft-wrap
}

# Recibe unha cabeceira e un placeholder, abre `gum_input` coa mensaxe común e
# imprime en stdout o texto introducido. Non valida o significado da consulta:
# o xestor correspondente faino no fluxo que captura esta saída.
_apps_request_query() {
  local header="$1"
  local placeholder="$2"

  gum_input -- \
    --header "$header" \
    --placeholder "$placeholder"
}

# Recibe as filas tabuladas de `yay -Pc` e imprime `[ORIXE] paquete`.
# A orixe pode ser CORE, EXTRA, MULTILIB ou AUR e queda visible no filtro.
_apps_format_yay_catalog() {
  local catalog="$1"

  printf '%s\n' "$catalog" |
    awk -F $'\t' 'NF >= 2 { printf "[%s] %s\n", toupper($2), $1 }'
}

###############################################################################
# INSTALADORES PÚBLICOS
###############################################################################

# Obtén o catálogo local de Yay, opcionalmente o refresca, deixa seleccionar
# varias filas e instala os nomes resultantes.
#
# `yay -Pc` devolve paquete + orixe. O selector mostra ambas cousas, pero antes
# de chamar `yay -Si/-S` retírase o prefixo `[ORIXE]` e elimínanse duplicados.
yay-install() {
  local refresh=false
  local values=()
  local query catalog selected_output selected_line package_name information
  local selected_packages=()

  # Fase 1: separar as opcións do wrapper da consulta inicial do filtro.
  while (($#)); do
    case "$1" in
      -r|--refresh)
        refresh=true
        ;;
      -h|--help)
        _apps_help yay-install
        return 0
        ;;
      --)
        shift
        values+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa yay-install --help.\n' "$1" >&2
        return 1
        ;;
      *)
        values+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#values[@]} -gt 1 ]; then
    printf 'yay-install admite unha única CONSULTA. Usa yay-install --help.\n' >&2
    return 1
  fi
  if ! _apps_require_public_helpers; then
    return 1
  fi
  if ! command -v yay &> /dev/null; then
    error "Yay non está dispoñible."
    return 1
  fi

  query="${values[0]:-}"

  # Fase 2: obter o índice combinado. `--refresh` forza a actualización nesta
  # execución; o modo normal respecta o intervalo de caché configurado en Yay.
  if $refresh; then
    info "Actualizando a caché de paquetes oficiais e AUR de Yay..."
    if ! catalog="$(yay --completioninterval 0 -Pc)"; then
      error "Non se puido actualizar o catálogo de paquetes de Yay."
      return 1
    fi
  elif ! catalog="$(yay -Pc)"; then
    error "Non se puido obter o catálogo de paquetes de Yay."
    return 1
  fi
  if [ -z "$catalog" ]; then
    warning "O catálogo de paquetes de Yay está baleiro."
    return 0
  fi
  catalog="$(_apps_format_yay_catalog "$catalog")"
  if [ -z "$catalog" ]; then
    error "O catálogo de Yay non ten o formato esperado."
    return 1
  fi

  # Fase 3: mostrar todo o catálogo formatado e recuperar as filas marcadas.
  if ! selected_output="$(_apps_filter_catalog \
    "$catalog" \
    "Busca e marca os paquetes que queres instalar:" \
    "$query")"; then
    info "Selección cancelada."
    return 0
  fi
  if [ -z "$selected_output" ]; then
    info "Non se seleccionou ningún paquete."
    return 0
  fi

  while IFS= read -r selected_line; do
    [ -n "$selected_line" ] || continue
    # As filas do selector teñen o formato `[ORIXE] paquete`.
    package_name="${selected_line#*] }"
    selected_packages+=("$package_name")
  done <<< "$selected_output"
  # O mesmo nome pode figurar en máis dunha orixe ou ser seleccionado dúas veces.
  mapfile -t selected_packages < <(
    printf '%s\n' "${selected_packages[@]}" | LC_ALL=C sort -u
  )

  # Fase 4: Yay acepta varios nomes en -Si, polo que se mostra toda a
  # información nun único pager antes da confirmación final.
  if ! information="$(yay -Si -- "${selected_packages[@]}" 2>&1)"; then
    error "Non se puido obter a información dos paquetes seleccionados."
    return 1
  fi
  if ! _apps_show_information "$information"; then
    info "Instalación cancelada."
    return 0
  fi

  if ! gum_confirm "Instalar ${#selected_packages[@]} paquete(s) con Yay?"; then
    info "Instalación cancelada."
    return 0
  fi

  # Fase 5: `--needed` evita reinstalar paquetes xa presentes e `--` protexe
  # nomes que puidesen parecer opcións.
  yay -S --needed -- "${selected_packages[@]}"
}

# Consulta todas as aplicacións do remoto indicado, conserva as columnas
# ID/nome/descrición no filtro e extrae o ID da primeira columna tras a
# selección. Logo concatena `flatpak remote-info` de cada app para que o usuario
# revise os detalles antes dunha única confirmación e instalación.
flatpak-install() {
  local remote="flathub"
  local values=()
  local catalog selected_output selected_line package_id package_information
  local information=""
  local selected_packages=()

  # Fase 1: aceptar un remoto alternativo, pero ningún argumento posicional.
  while (($#)); do
    case "$1" in
      --remote)
        if [ $# -lt 2 ]; then
          printf 'Falta REMOTO para --remote. Usa flatpak-install --help.\n' >&2
          return 1
        fi
        remote="$2"
        shift
        ;;
      -h|--help)
        _apps_help flatpak-install
        return 0
        ;;
      --)
        shift
        values+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa flatpak-install --help.\n' "$1" >&2
        return 1
        ;;
      *)
        values+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#values[@]} -ne 0 ]; then
    printf 'flatpak-install non admite parámetros. Usa flatpak-install --help.\n' >&2
    return 1
  fi
  if ! _apps_require_public_helpers; then
    return 1
  fi
  if ! command -v flatpak &> /dev/null; then
    error "Flatpak non está dispoñible."
    return 1
  fi
  if ! flatpak remotes --columns=name | grep -qxF "$remote"; then
    error "O remoto Flatpak non está configurado: $remote"
    return 1
  fi

  # Fase 2: obter só aplicacións, non runtimes, mantendo tres columnas para que
  # o usuario poida buscar polo ID, o nome visible ou a descrición.
  info "Obtendo o catálogo de aplicacións de $remote..."
  if ! catalog="$(flatpak remote-ls \
    --app \
    --columns=application,name,description \
    "$remote")"; then
    error "Non se puido obter o catálogo de $remote."
    return 1
  fi
  if [ -z "$catalog" ]; then
    warning "O catálogo de $remote está baleiro."
    return 0
  fi

  # As columnas están separadas por tabuladores; ordénanse polo nome visible.
  catalog="$(printf '%s\n' "$catalog" |
    LC_ALL=C sort -f -t $'\t' -k2,2)"
  # Fase 3: seleccionar filas e extraer o ID estable da primeira columna.
  if ! selected_output="$(_apps_filter_catalog \
    "$catalog" \
    "Busca e marca as aplicacións que queres instalar:")"; then
    info "Selección cancelada."
    return 0
  fi
  if [ -z "$selected_output" ]; then
    info "Non se seleccionou ningunha aplicación."
    return 0
  fi

  while IFS= read -r selected_line; do
    [ -n "$selected_line" ] || continue
    # O identificador é a primeira columna da fila tabulada.
    package_id="${selected_line%%$'\t'*}"
    selected_packages+=("$package_id")
  done <<< "$selected_output"

  # Fase 4: remote-info execútase por separado porque Flatpak non ofrece a
  # información longa de varios IDs nunha única saída cómoda.
  for package_id in "${selected_packages[@]}"; do
    if ! package_information="$(flatpak remote-info \
      "$remote" \
      "$package_id" 2>&1)"; then
      error "Non se puido obter información de $package_id."
      return 1
    fi
    information+="$package_information"$'\n\n'
  done

  if ! _apps_show_information "$information"; then
    info "Instalación cancelada."
    return 0
  fi
  if ! gum_confirm \
    "Instalar ${#selected_packages[@]} aplicación(s) desde $remote?"; then
    info "Instalación cancelada."
    return 0
  fi

  # Fase 5: unha única chamada instala toda a selección desde o mesmo remoto.
  flatpak install -y "$remote" "${selected_packages[@]}"
}

# Recibe ou pregunta un nome exacto de PyPI. Valídao cunha regex local e con
# `python -m pip index versions`; se existe, mostra esa información e instálao
# con Pipx tras confirmar. Non intenta busca parcial porque Pip/Pipx non ofrecen
# unha API oficial para obter todo PyPI como catálogo filtrable.
pipx-install() {
  local values=()
  local package_name information

  # Fase 1: aceptar como máximo un nome exacto de paquete.
  while (($#)); do
    case "$1" in
      -h|--help)
        _apps_help pipx-install
        return 0
        ;;
      --)
        shift
        values+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa pipx-install --help.\n' "$1" >&2
        return 1
        ;;
      *)
        values+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#values[@]} -gt 1 ]; then
    printf 'pipx-install admite un único PAQUETE. Usa pipx-install --help.\n' >&2
    return 1
  fi
  if ! _apps_require_public_helpers; then
    return 1
  fi
  if ! command -v pipx &> /dev/null || ! command -v python &> /dev/null; then
    error "Pipx e Python deben estar dispoñibles."
    return 1
  fi

  package_name="${values[0]:-}"
  # Fase 2: se non chegou por argumento, solicitalo de forma interactiva.
  if [ -z "$package_name" ]; then
    if ! package_name="$(_apps_request_query \
      "Instalar unha aplicación de PyPI con Pipx" \
      "Nome exacto do paquete")"; then
      info "Instalación cancelada."
      return 0
    fi
  fi
  if [ -z "$package_name" ]; then
    warning "O nome do paquete non pode quedar baleiro."
    return 1
  fi
  # Os nomes normalizados de PyPI admiten letras, números, punto, guión e `_`.
  if [[ ! "$package_name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    error "Nome de paquete de PyPI non válido: $package_name"
    return 1
  fi

  # Fase 3: `pip index versions` confirma que o nome existe no índice actual e
  # proporciona información útil sen descargar nin instalar o paquete.
  info "Consultando as versións dispoñibles de $package_name..."
  if ! information="$(python -m pip index versions "$package_name" 2>&1)"; then
    error "Non se atopou o paquete «$package_name» no índice de Pip."
    return 1
  fi
  if ! _apps_show_information "$information"; then
    info "Instalación cancelada."
    return 0
  fi

  if ! gum_confirm "Instalar $package_name con Pipx?"; then
    info "Instalación cancelada."
    return 0
  fi

  # Fase 4: Pipx crea e xestiona o contorno illado da aplicación.
  pipx install "$package_name"
}
