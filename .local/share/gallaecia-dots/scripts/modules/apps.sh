# shellcheck shell=bash

###############################################################################
# MÓDULO PÚBLICO DE APLICACIÓNS
#
# Este ficheiro si se carga en cada terminal e expón sete comandos:
#
#   has_package      -> consulta se algo xa está instalado.
#   yay-install      -> explora o catálogo combinado Arch + AUR.
#   flatpak-install  -> explora o catálogo dun remoto Flatpak.
#   pipx-install     -> valida e instala un nome exacto desde PyPI.
#   yay-uninstall    -> elimina paquetes e dependencias que queden sen uso.
#   flatpak-uninstall -> elimina apps e limpa runtimes que queden sen uso.
#   pipx-uninstall   -> elimina contornos illados e os seus accesos directos.
#
# Non comparte estado coas funcións de categoría de `internal/apps.sh`.
# Estes comandos son ferramentas xenéricas para uso diario. O fluxo común dos
# instaladores e desinstaladores interactivos é:
#
#   validar argumentos e dependencias
#          │
#          ▼
#   obter ou validar o catálogo correspondente
#          │
#          ▼
#   filtrar/seleccionar con Gum
#          │
#          ▼
#   mostrar información dos paquetes
#          │
#          ▼
#   pedir confirmación e aplicar a operación
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
  --packages PAQUETE...
      Instala directamente os paquetes indicados, sen abrir o catálogo nin
      pedir confirmación. Debe ser a última opción do wrapper.

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
  yay-install --packages kitty foot
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
  --packages ID...
      Instala directamente os identificadores indicados, sen abrir o catálogo
      nin pedir confirmación. Debe ser a última opción do wrapper.

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
  flatpak-install --packages com.usebottles.bottles
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
  --packages PAQUETE...
      Instala directamente un ou máis paquetes, sen consultar PyPI nin pedir
      confirmación. Debe ser a última opción do wrapper.

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
  pipx-install --packages spotdl
EOF
      ;;
    yay-uninstall)
      cat <<'EOF'
USO
  yay-uninstall [OPCIÓNS] [-- ARGUMENTOS DE YAY]

DESCRICIÓN
  Mostra os paquetes instalados explicitamente con Pacman ou AUR, permite
  seleccionar varios e elimínaos con `yay -Rns`. Isto elimina tamén as
  dependencias que queden sen uso e non conserva ficheiros `.pacsave`.

OPCIÓNS
  --packages PAQUETE...
      Usa directamente os paquetes indicados en vez de abrir o selector. A
      información e a confirmación seguen sendo obrigatorias. Para reenviar
      opcións a Yay, remata a lista cun `--`.

  --clean-cache
      Despois da eliminación executa `yay -Sc --noconfirm`. Esta limpeza é
      global: borra da caché os paquetes que xa non están instalados.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do wrapper. Todo o posterior pásase a `yay -Rns`
      antes dos nomes dos paquetes.

CONTROIS
  Escribir
      Busca por nome, versión ou orixe.

  Frechas ou Ctrl+j/Ctrl+k
      Move o cursor polos resultados.

  Tab ou Ctrl+Espazo
      Marca ou desmarca paquetes.

  Enter
      Confirma a selección.

RESULTADO
  Elimina os paquetes seleccionados e as súas dependencias xa innecesarias.
  Cancelar non modifica nada e devolve 0; un erro devolve un código distinto
  de 0.

EXEMPLOS
  yay-uninstall
  yay-uninstall --packages firefox
  yay-uninstall --clean-cache
  yay-uninstall -- -u

COMANDO ORIXINAL
  Os argumentos situados despois de `--` reenvíanse a `yay -Rns`. Consulta as
  opcións dispoñibles con `yay -R --help`.
EOF
      ;;
    flatpak-uninstall)
      cat <<'EOF'
USO
  flatpak-uninstall [OPCIÓNS] [-- ARGUMENTOS DE FLATPAK]

DESCRICIÓN
  Mostra as aplicacións Flatpak instaladas, permite seleccionar varias,
  elimínaas da instalación correcta e limpa os runtimes e extensións que
  queden sen uso.

OPCIÓNS
  --packages ID...
      Usa directamente os identificadores indicados en vez de abrir o
      selector. A información e a confirmación seguen sendo obrigatorias. Para
      reenviar opcións a Flatpak, remata a lista cun `--`.

  --delete-data
      Elimina tamén os datos persistentes de cada aplicación en
      `~/.var/app/ID` e os seus permisos. Require unha segunda confirmación.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do wrapper. Todo o posterior pásase a cada chamada de
      `flatpak uninstall`.

CONTROIS
  Escribir
      Busca por identificador, nome, versión ou instalación.

  Frechas ou Ctrl+j/Ctrl+k
      Move o cursor polos resultados.

  Tab ou Ctrl+Espazo
      Marca ou desmarca aplicacións.

  Enter
      Confirma a selección.

RESULTADO
  Elimina as aplicacións seleccionadas e limpa os runtimes sen uso das
  instalacións afectadas. Con `--delete-data` borra tamén os seus datos.
  Cancelar non modifica nada e devolve 0; un erro devolve un código distinto
  de 0.

EXEMPLOS
  flatpak-uninstall
  flatpak-uninstall --packages org.gimp.GIMP
  flatpak-uninstall --delete-data

COMANDO ORIXINAL
  Os argumentos situados despois de `--` reenvíanse a `flatpak uninstall`.
  Consulta as opcións dispoñibles con `flatpak uninstall --help`.
EOF
      ;;
    pipx-uninstall)
      cat <<'EOF'
USO
  pipx-uninstall [OPCIÓNS] [-- ARGUMENTOS DE PIPX]

DESCRICIÓN
  Mostra os contornos xestionados por Pipx, permite seleccionar varios e
  elimina cada contorno illado xunto cos seus comandos e páxinas de manual.
  Pipx xa realiza esta limpeza como parte da desinstalación normal.

OPCIÓNS
  --packages PAQUETE...
      Usa directamente os paquetes indicados en vez de abrir o selector. A
      información e a confirmación seguen sendo obrigatorias. Para reenviar
      opcións a Pipx, remata a lista cun `--`.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do wrapper. Todo o posterior pásase a cada chamada de
      `pipx uninstall`.

CONTROIS
  Escribir
      Busca por nome, versión ou ámbito.

  Frechas ou Ctrl+j/Ctrl+k
      Move o cursor polos resultados.

  Tab ou Ctrl+Espazo
      Marca ou desmarca paquetes.

  Enter
      Confirma a selección.

RESULTADO
  Elimina os contornos seleccionados e os ficheiros que expoñen as súas apps.
  Cancelar non modifica nada e devolve 0; un erro devolve un código distinto
  de 0.

EXEMPLOS
  pipx-uninstall
  pipx-uninstall --packages yt-dlp
  pipx-uninstall -- --verbose

COMANDO ORIXINAL
  Os argumentos situados despois de `--` reenvíanse a `pipx uninstall`.
  Consulta as opcións dispoñibles con `pipx uninstall --help`.
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
  # `pipx list --short` devolve `nome versión`; só a primeira columna
  # identifica o paquete e debe entrar na comparación normalizada.
  while read -r installed_name _; do
    [ -n "$installed_name" ] || continue
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
  local direct_install=false
  local values=()
  local query catalog selected_output selected_line package_name information
  local selected_packages=()

  # Fase 1: separar as opcións do wrapper da consulta inicial do filtro.
  while (($#)); do
    case "$1" in
      --packages)
        shift
        selected_packages=("$@")
        direct_install=true
        break
        ;;
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

  if $direct_install && [ ${#selected_packages[@]} -eq 0 ]; then
    printf 'Falta PAQUETE... para --packages. Usa yay-install --help.\n' >&2
    return 1
  fi
  if ! $direct_install && [ ${#values[@]} -gt 1 ]; then
    printf 'yay-install admite unha única CONSULTA. Usa yay-install --help.\n' >&2
    return 1
  fi
  if ! command -v yay &> /dev/null; then
    printf 'Yay non está dispoñible.\n' >&2
    return 1
  fi

  # O modo directo úsano os instaladores de categorías: a selección xa se
  # confirmou alí e Yay recibe todos os nomes nunha única operación.
  if $direct_install; then
    yay -S --needed -- "${selected_packages[@]}"
    return
  fi
  if ! _apps_require_public_helpers; then
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
  local direct_install=false
  local values=()
  local catalog selected_output selected_line package_id package_information
  local information=""
  local selected_packages=()

  # Fase 1: aceptar un remoto alternativo, pero ningún argumento posicional.
  while (($#)); do
    case "$1" in
      --packages)
        shift
        selected_packages=("$@")
        direct_install=true
        break
        ;;
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

  if $direct_install && [ ${#selected_packages[@]} -eq 0 ]; then
    printf 'Falta ID... para --packages. Usa flatpak-install --help.\n' >&2
    return 1
  fi
  if ! $direct_install && [ ${#values[@]} -ne 0 ]; then
    printf 'flatpak-install non admite parámetros. Usa flatpak-install --help.\n' >&2
    return 1
  fi
  if ! command -v flatpak &> /dev/null; then
    printf 'Flatpak non está dispoñible.\n' >&2
    return 1
  fi
  if ! flatpak remotes --columns=name | grep -qxF "$remote"; then
    printf 'O remoto Flatpak non está configurado: %s\n' "$remote" >&2
    return 1
  fi

  # O modo directo evita volver preguntar por unha selección xa feita dentro
  # dunha categoría e instala todos os IDs no mesmo remoto.
  if $direct_install; then
    flatpak install -y "$remote" "${selected_packages[@]}"
    return
  fi
  if ! _apps_require_public_helpers; then
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
  local direct_install=false
  local values=()
  local direct_packages=()
  local package_name information

  # Fase 1: aceptar como máximo un nome exacto de paquete.
  while (($#)); do
    case "$1" in
      --packages)
        shift
        direct_packages=("$@")
        direct_install=true
        break
        ;;
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

  if $direct_install && [ ${#direct_packages[@]} -eq 0 ]; then
    printf 'Falta PAQUETE... para --packages. Usa pipx-install --help.\n' >&2
    return 1
  fi
  if ! $direct_install && [ ${#values[@]} -gt 1 ]; then
    printf 'pipx-install admite un único PAQUETE. Usa pipx-install --help.\n' >&2
    return 1
  fi
  if ! command -v pipx &> /dev/null; then
    printf 'Pipx non está dispoñible.\n' >&2
    return 1
  fi

  # No modo directo omítense os paquetes xa presentes e instálase o resto por
  # separado, porque Pipx só admite un paquete principal en cada chamada.
  if $direct_install; then
    for package_name in "${direct_packages[@]}"; do
      if has_package --manager pipx "$package_name"; then
        continue
      fi
      if ! pipx install "$package_name"; then
        return 1
      fi
    done
    return 0
  fi
  if ! command -v python &> /dev/null; then
    error "Python non está dispoñible."
    return 1
  fi
  if ! _apps_require_public_helpers; then
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

###############################################################################
# DESINSTALADORES PÚBLICOS
###############################################################################

# Constrúe o catálogo dos paquetes instalados explicitamente. Cruza `yay -Qe`
# coa base local dos repositorios de `pacman -Sl` para mostrar CORE, EXTRA,
# MULTILIB ou a orixe que corresponda. Os paquetes que xa non pertencen a un
# repositorio oficial quedan marcados como AUR/LOCAL, pois a base de Pacman non
# permite distinguir de forma fiable un paquete AUR doutro paquete local. Úsase
# Pacman só para ler os repositorios: `yay -Sl` engade unha consulta remota a
# AUR que non é necesaria para clasificar paquetes xa instalados.
_apps_installed_yay_catalog() {
  local installed_packages repository_packages
  local repository package_name installed_version
  local -A explicit_versions=()

  if ! installed_packages="$(yay -Qe)"; then
    return 1
  fi
  if ! repository_packages="$(pacman -Sl)"; then
    return 1
  fi

  while read -r package_name installed_version; do
    [ -n "$package_name" ] || continue
    explicit_versions["$package_name"]="$installed_version"
  done <<< "$installed_packages"

  # O `_` absorbe versión e posibles marcas como `[installed]`, que non se
  # necesitan porque a versión local xa se gardou desde `yay -Qe`.
  while read -r repository package_name _; do
    if [[ ! -v "explicit_versions[$package_name]" ]]; then
      continue
    fi
    printf '[%s] %s\t%s\n' \
      "${repository^^}" \
      "$package_name" \
      "${explicit_versions[$package_name]}"
    unset 'explicit_versions[$package_name]'
  done <<< "$repository_packages"

  for package_name in "${!explicit_versions[@]}"; do
    printf '[AUR/LOCAL] %s\t%s\n' \
      "$package_name" \
      "${explicit_versions[$package_name]}"
  done
}

# Permite seleccionar paquetes instalados explicitamente e elimínaos coa
# combinación recomendada `-Rns`: dependencias que queden sen uso, ficheiros
# do paquete e configuracións marcadas como backup. Os argumentos posteriores
# a `--` colócanse antes do separador de nomes, polo que unha opción adicional
# como `-u` si se combina coa operación xa definida polo wrapper.
yay-uninstall() {
  local clean_cache=false
  local direct_uninstall=false
  local catalog selected_output selected_line package_name information
  local package_information
  local removal_preview confirm_message
  local selected_packages=()
  local original_args=()
  local preview_args=()
  local values=()
  local original_arg

  # Fase 1: separar opcións propias, nomes directos e opcións para Yay.
  while (($#)); do
    case "$1" in
      --packages)
        direct_uninstall=true
        shift
        while (($#)) && [ "$1" != "--" ]; do
          selected_packages+=("$1")
          shift
        done
        if (($#)); then
          shift
          original_args=("$@")
        fi
        break
        ;;
      --clean-cache)
        clean_cache=true
        ;;
      -h|--help)
        _apps_help yay-uninstall
        return 0
        ;;
      --)
        shift
        original_args=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa yay-uninstall --help.\n' "$1" >&2
        return 1
        ;;
      *)
        values+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#values[@]} -ne 0 ]; then
    printf 'yay-uninstall non admite parámetros. Usa yay-uninstall --help.\n' >&2
    return 1
  fi
  if $direct_uninstall && [ ${#selected_packages[@]} -eq 0 ]; then
    printf 'Falta PAQUETE... para --packages. Usa yay-uninstall --help.\n' >&2
    return 1
  fi
  if ! command -v yay &> /dev/null; then
    printf 'Yay non está dispoñible.\n' >&2
    return 1
  fi
  if ! _apps_require_public_helpers; then
    return 1
  fi

  # Fase 2: no modo interactivo, mostrar só paquetes que o usuario marcou
  # como explícitos; así non se ofrecen dependencias internas para borrar.
  if ! $direct_uninstall; then
    if ! catalog="$(_apps_installed_yay_catalog)"; then
      error "Non se puido obter a lista de paquetes instalados."
      return 1
    fi
    if [ -z "$catalog" ]; then
      warning "Non hai paquetes instalados explicitamente."
      return 0
    fi
    catalog="$(printf '%s\n' "$catalog" | LC_ALL=C sort -f)"

    if ! selected_output="$(_apps_filter_catalog \
      "$catalog" \
      "Busca e marca os paquetes que queres desinstalar:")"; then
      info "Selección cancelada."
      return 0
    fi
    if [ -z "$selected_output" ]; then
      info "Non se seleccionou ningún paquete."
      return 0
    fi

    while IFS= read -r selected_line; do
      [ -n "$selected_line" ] || continue
      # A fila é `[ORIXE] nome<TAB>versión`: elimínanse ambos adornos.
      package_name="${selected_line#*] }"
      package_name="${package_name%%$'\t'*}"
      selected_packages+=("$package_name")
    done <<< "$selected_output"
  fi

  # Fase 3: `-Qi` valida tamén os nomes recibidos mediante `--packages`.
  # A simulación con `-Rs --print` calcula ademais as dependencias da
  # transacción. Reenvía as mesmas opcións agás `-n/--nosave`, porque Pacman non
  # permite combinar `--nosave` con `--print`; esa opción só decide se conserva
  # `.pacsave` e non cambia a lista de paquetes que se retirarán.
  if ! information="$(yay -Qi -- "${selected_packages[@]}" 2>&1)"; then
    error "Algún dos paquetes indicados non está instalado."
    return 1
  fi
  package_information="$information"
  for original_arg in "${original_args[@]}"; do
    case "$original_arg" in
      -n|--nosave) ;;
      *) preview_args+=("$original_arg") ;;
    esac
  done
  if ! removal_preview="$(yay \
    -Rs \
    "${preview_args[@]}" \
    --print-format '%n %v' \
    -- "${selected_packages[@]}" 2>&1)"; then
    error "Non se puido calcular a transacción de desinstalación."
    return 1
  fi
  information="Paquetes que retirará a transacción:"$'\n'
  information+="$removal_preview"$'\n\n'
  information+="Información dos paquetes seleccionados:"$'\n\n'
  information+="$package_information"
  if ! _apps_show_information "$information"; then
    info "Desinstalación cancelada."
    return 0
  fi

  confirm_message="Desinstalar ${#selected_packages[@]} paquete(s) con Yay?"
  if $clean_cache; then
    confirm_message="Desinstalar ${#selected_packages[@]} paquete(s) e limpar a caché global?"
  fi
  if ! gum_confirm "$confirm_message"; then
    info "Desinstalación cancelada."
    return 0
  fi

  # Fase 4: engade primeiro as opcións adicionais recibidas despois do `--` do wrapper.
  # O seguinte `--` pertence a Yay: separa as opcións dos nomes dos paquetes.
  # Exemplo: `yay-uninstall -- -u` executa `yay -Rns -u -- PAQUETE`.
  if ! yay -Rns "${original_args[@]}" -- "${selected_packages[@]}"; then
    return 1
  fi

  # A caché é compartida por todo Pacman/Yay. Só se limpa cando se solicita
  # expresamente, pois `-Sc` tamén elimina descargas alleas á selección.
  if $clean_cache; then
    if ! yay -Sc --noconfirm; then
      return 1
    fi
  fi
}

# Obtén todas as aplicacións Flatpak instaladas e antepón o ámbito que Flatpak
# devolve na columna `installation`. Esa columna permite que o desinstalador
# actúe sobre a copia exacta cando un mesmo ID existe no usuario e no sistema.
_apps_installed_flatpak_catalog() {
  local raw_catalog

  if ! raw_catalog="$(flatpak list \
    --app \
    --columns=application,name,version,installation)"; then
    return 1
  fi

  # Awk conserva campos tabulados baleiros. Isto é importante para aplicacións
  # que non publican versión: un `read` con tabulador como IFS colapsaría ese
  # baleiro e interpretaría `system` ou `user` como se fose a versión.
  printf '%s\n' "$raw_catalog" |
    awk -F $'\t' 'NF >= 4 { printf "[%s] %s\t%s\t%s\n", $4, $1, $2, $3 }'
}

# Elimina aplicacións Flatpak da instalación concreta que aparece no catálogo.
# Tras retirar todas as seleccionadas, executa `--unused` unha vez por cada
# instalación afectada. `--delete-data` queda separado porque borra datos do
# usuario e por iso require unha segunda confirmación explícita.
flatpak-uninstall() {
  local delete_data=false
  local direct_uninstall=false
  local catalog selected_output selected_line requested_id
  local installation row_without_installation package_id package_information
  local information=""
  local found=false
  local selected_records=()
  local requested_packages=()
  local original_args=()
  local values=()
  local scope_args=()
  local data_args=()
  local -A affected_installations=()

  # Fase 1: separar opcións propias, IDs directos e opcións para Flatpak.
  while (($#)); do
    case "$1" in
      --packages)
        direct_uninstall=true
        shift
        while (($#)) && [ "$1" != "--" ]; do
          requested_packages+=("$1")
          shift
        done
        if (($#)); then
          shift
          original_args=("$@")
        fi
        break
        ;;
      --delete-data)
        delete_data=true
        ;;
      -h|--help)
        _apps_help flatpak-uninstall
        return 0
        ;;
      --)
        shift
        original_args=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa flatpak-uninstall --help.\n' "$1" >&2
        return 1
        ;;
      *)
        values+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#values[@]} -ne 0 ]; then
    printf 'flatpak-uninstall non admite parámetros. Usa flatpak-uninstall --help.\n' >&2
    return 1
  fi
  if $direct_uninstall && [ ${#requested_packages[@]} -eq 0 ]; then
    printf 'Falta ID... para --packages. Usa flatpak-uninstall --help.\n' >&2
    return 1
  fi
  if ! command -v flatpak &> /dev/null; then
    printf 'Flatpak non está dispoñible.\n' >&2
    return 1
  fi
  if ! _apps_require_public_helpers; then
    return 1
  fi

  # Fase 2: o catálogo é necesario mesmo no modo directo para resolver se
  # cada ID pertence ao usuario, ao sistema ou a unha instalación con nome.
  if ! catalog="$(_apps_installed_flatpak_catalog)"; then
    error "Non se puido obter a lista de aplicacións Flatpak instaladas."
    return 1
  fi
  if [ -z "$catalog" ]; then
    warning "Non hai aplicacións Flatpak instaladas."
    return 0
  fi
  catalog="$(printf '%s\n' "$catalog" | LC_ALL=C sort -f)"

  if $direct_uninstall; then
    for requested_id in "${requested_packages[@]}"; do
      found=false
      while IFS= read -r selected_line; do
        row_without_installation="${selected_line#*] }"
        package_id="${row_without_installation%%$'\t'*}"
        if [ "$package_id" = "$requested_id" ]; then
          selected_records+=("$selected_line")
          found=true
        fi
      done <<< "$catalog"
      if ! $found; then
        error "A aplicación Flatpak non está instalada: $requested_id"
        return 1
      fi
    done
  else
    if ! selected_output="$(_apps_filter_catalog \
      "$catalog" \
      "Busca e marca as aplicacións que queres desinstalar:")"; then
      info "Selección cancelada."
      return 0
    fi
    if [ -z "$selected_output" ]; then
      info "Non se seleccionou ningunha aplicación."
      return 0
    fi
    mapfile -t selected_records <<< "$selected_output"
  fi

  # Fase 3: obter a información de cada referencia desde o ámbito exacto.
  for selected_line in "${selected_records[@]}"; do
    installation="${selected_line#\[}"
    installation="${installation%%]*}"
    row_without_installation="${selected_line#*] }"
    package_id="${row_without_installation%%$'\t'*}"
    case "$installation" in
      user) scope_args=(--user) ;;
      system) scope_args=(--system) ;;
      *) scope_args=("--installation=$installation") ;;
    esac
    if ! package_information="$(flatpak info \
      "${scope_args[@]}" \
      "$package_id" 2>&1)"; then
      error "Non se puido obter información de $package_id."
      return 1
    fi
    information+="$package_information"$'\n\n'
  done

  if ! _apps_show_information "$information"; then
    info "Desinstalación cancelada."
    return 0
  fi
  if ! gum_confirm \
    "Desinstalar ${#selected_records[@]} aplicación(s) Flatpak?"; then
    info "Desinstalación cancelada."
    return 0
  fi
  if $delete_data; then
    if ! gum_confirm \
      "Eliminar tamén os datos persistentes e permisos destas aplicacións?"; then
      info "Desinstalación cancelada."
      return 0
    fi
    data_args=(--delete-data)
  fi

  # Fase 4: eliminar unha referencia por chamada conserva a relación entre ID
  # e instalación. Só despois se limpan runtimes sen consumidores.
  for selected_line in "${selected_records[@]}"; do
    installation="${selected_line#\[}"
    installation="${installation%%]*}"
    row_without_installation="${selected_line#*] }"
    package_id="${row_without_installation%%$'\t'*}"
    case "$installation" in
      user) scope_args=(--user) ;;
      system) scope_args=(--system) ;;
      *) scope_args=("--installation=$installation") ;;
    esac
    if ! flatpak uninstall \
      -y \
      "${scope_args[@]}" \
      "${data_args[@]}" \
      "${original_args[@]}" \
      "$package_id"; then
      return 1
    fi
    affected_installations["$installation"]=1
  done

  for installation in "${!affected_installations[@]}"; do
    case "$installation" in
      user) scope_args=(--user) ;;
      system) scope_args=(--system) ;;
      *) scope_args=("--installation=$installation") ;;
    esac
    if ! flatpak uninstall -y "${scope_args[@]}" --unused; then
      return 1
    fi
  done
}

# Lista os contornos Pipx do usuario e os globais. A primeira columna visual
# conserva o ámbito para poder executar cada desinstalación coa opción correcta
# sen facer que o usuario manteña dúas listas separadas.
_apps_installed_pipx_catalog() {
  local package_name package_version

  while read -r package_name package_version; do
    [ -n "$package_name" ] || continue
    printf '[USER] %s\t%s\n' "$package_name" "$package_version"
  done < <(pipx list --short 2> /dev/null)

  while read -r package_name package_version; do
    [ -n "$package_name" ] || continue
    printf '[GLOBAL] %s\t%s\n' "$package_name" "$package_version"
  done < <(pipx list --global --short 2> /dev/null)
}

# Elimina un ou máis contornos Pipx logo de mostrar o ámbito e a versión. Non
# executa unha limpeza de caché adicional: `pipx uninstall` xa borra o contorno,
# as ligazóns aos comandos e as páxinas de manual pertencentes a esa app; unha
# purga global afectaría recursos compartidos por instalacións non seleccionadas.
pipx-uninstall() {
  local direct_uninstall=false
  local catalog selected_output selected_line requested_name
  local scope row_without_scope package_name
  local found=false
  local selected_records=()
  local requested_packages=()
  local original_args=()
  local values=()
  local scope_args=()

  # Fase 1: separar opcións propias, nomes directos e opcións para Pipx.
  while (($#)); do
    case "$1" in
      --packages)
        direct_uninstall=true
        shift
        while (($#)) && [ "$1" != "--" ]; do
          requested_packages+=("$1")
          shift
        done
        if (($#)); then
          shift
          original_args=("$@")
        fi
        break
        ;;
      -h|--help)
        _apps_help pipx-uninstall
        return 0
        ;;
      --)
        shift
        original_args=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa pipx-uninstall --help.\n' "$1" >&2
        return 1
        ;;
      *)
        values+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#values[@]} -ne 0 ]; then
    printf 'pipx-uninstall non admite parámetros. Usa pipx-uninstall --help.\n' >&2
    return 1
  fi
  if $direct_uninstall && [ ${#requested_packages[@]} -eq 0 ]; then
    printf 'Falta PAQUETE... para --packages. Usa pipx-uninstall --help.\n' >&2
    return 1
  fi
  if ! command -v pipx &> /dev/null; then
    printf 'Pipx non está dispoñible.\n' >&2
    return 1
  fi
  if ! _apps_require_public_helpers; then
    return 1
  fi

  # Fase 2: resolver tamén os nomes directos contra o catálogo evita confundir
  # unha app do usuario cunha instalación global do mesmo paquete.
  catalog="$(_apps_installed_pipx_catalog)"
  if [ -z "$catalog" ]; then
    warning "Non hai aplicacións xestionadas por Pipx."
    return 0
  fi
  catalog="$(printf '%s\n' "$catalog" | LC_ALL=C sort -f)"

  if $direct_uninstall; then
    for requested_name in "${requested_packages[@]}"; do
      found=false
      while IFS= read -r selected_line; do
        row_without_scope="${selected_line#*] }"
        package_name="${row_without_scope%%$'\t'*}"
        if [ "$(_apps_normalize_python_package "$package_name")" = \
          "$(_apps_normalize_python_package "$requested_name")" ]; then
          selected_records+=("$selected_line")
          found=true
        fi
      done <<< "$catalog"
      if ! $found; then
        error "O paquete Pipx non está instalado: $requested_name"
        return 1
      fi
    done
  else
    if ! selected_output="$(_apps_filter_catalog \
      "$catalog" \
      "Busca e marca as aplicacións que queres desinstalar:")"; then
      info "Selección cancelada."
      return 0
    fi
    if [ -z "$selected_output" ]; then
      info "Non se seleccionou ningunha aplicación."
      return 0
    fi
    mapfile -t selected_records <<< "$selected_output"
  fi

  # A lista curta xa contén nome, versión e ámbito das seleccións e evita
  # mostrar no pager os demais contornos non afectados.
  information="Contornos Pipx que se eliminarán:"$'\n\n'
  information+="$(printf '%s\n' "${selected_records[@]}")"
  if ! _apps_show_information "$information"; then
    info "Desinstalación cancelada."
    return 0
  fi
  if ! gum_confirm \
    "Desinstalar ${#selected_records[@]} contorno(s) de Pipx?"; then
    info "Desinstalación cancelada."
    return 0
  fi

  # Fase 3: Pipx acepta un único contorno por chamada. O ámbito gardado na fila
  # decide se se engade `--global`; o resto das opcións reenvíase sen cambios.
  for selected_line in "${selected_records[@]}"; do
    scope="${selected_line#\[}"
    scope="${scope%%]*}"
    row_without_scope="${selected_line#*] }"
    package_name="${row_without_scope%%$'\t'*}"
    if [ "$scope" = "GLOBAL" ]; then
      scope_args=(--global)
    else
      scope_args=()
    fi
    if ! pipx uninstall \
      "${scope_args[@]}" \
      "${original_args[@]}" \
      "$package_name"; then
      return 1
    fi
  done
}
