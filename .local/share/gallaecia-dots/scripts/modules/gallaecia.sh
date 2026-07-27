# shellcheck shell=bash

###############################################################################
# DISPATCHER PÚBLICO DE GALLAECIA
#
# Este módulo expón unha única función pública: `gallaecia`. O resto dos nomes
# comezan por `_gallaecia_` e son implementación interna do dispatcher.
#
# `gallaecia` só analiza o primeiro nivel e delega:
#
#   gallaecia
#      ├─ commands          -> referencia curta
#      ├─ update            -> system-update.sh
#      ├─ reinstall         -> sincroniza repo + install.sh en modo reinstall
#      ├─ install-category  -> módulos da versión instalada nun subshell
#      └─ wallpaper-add     -> clasifica e copia imaxes ou fondos animados
#
# `update` e `reinstall` sincronizan o repo cando precisan os fontes máis
# recentes. `install-category` usa os módulos xa instalados e execútase entre
# parénteses para que as funcións e variables de `scripts/internal/`
# desaparezan ao rematar e non contaminen a terminal.
#
# PARA ENGADIR UN SUBCOMANDO
#
#   1. Engade a súa axuda en `_gallaecia_help`.
#   2. Engade unha liña en `_gallaecia_commands`.
#   3. Crea un helper `_gallaecia_nome`.
#   4. Engade o caso correspondente no `case` final de `gallaecia`.
#   5. Documenta o comando no README.
###############################################################################

# Mostra a axuda principal ou a dun subcomando de Gallaecia.
_gallaecia_help() {
  case "${1:-main}" in
    main)
      cat <<'EOF'
USO
  gallaecia [OPCIÓNS] COMANDO [ARGUMENTOS]

DESCRICIÓN
  Xestiona Gallaecia Dots desde unha única interface. Permite consultar os
  comandos, actualizar ou reinstalar os dots, instalar novas aplicacións por
  categoría e engadir fondos.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  -v, --version
      Mostra a versión instalada de Gallaecia Dots.

COMANDOS
  commands
      Lista os subcomandos dispoñibles.

  update
      Abre o actualizador completo do sistema e dos dotfiles.

  reinstall
      Sincroniza o repositorio e executa de novo a instalación base.

  install-category
      Instala máis aplicacións dunha categoría sen retirar as existentes.

  wallpaper-add
      Engade imaxes ou fondos animados ao directorio correspondente.

RESULTADO
  Devolve 0 cando o subcomando remata correctamente e un código distinto de 0
  cando falla ou recibe argumentos non válidos.

EXEMPLOS
  gallaecia commands
  gallaecia install-category
  gallaecia wallpaper-add ~/Imaxes/fondo.jpg
EOF
      ;;
    commands)
      cat <<'EOF'
USO
  gallaecia commands [OPCIÓNS]

DESCRICIÓN
  Lista os subcomandos públicos de Gallaecia e unha descrición breve.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

RESULTADO
  Escribe a lista de comandos en stdout.

EXEMPLOS
  gallaecia commands
EOF
      ;;
    update)
      cat <<'EOF'
USO
  gallaecia update [OPCIÓNS]

DESCRICIÓN
  Executa o actualizador interactivo de Rust, Yay/Pacman, Flatpak, Yazi e
  Gallaecia Dots.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

RESULTADO
  Devolve o código de saída de system-update.sh.

EXEMPLOS
  gallaecia update
EOF
      ;;
    reinstall)
      cat <<'EOF'
USO
  gallaecia reinstall [OPCIÓNS]

DESCRICIÓN
  Sincroniza ~/.dotfiles, limpa o rexistro de versións mediante install.sh e
  volve aplicar a instalación base. Require confirmación.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

RESULTADO
  Devolve o código do instalador. Cancelar non modifica nada e devolve 0.

EXEMPLOS
  gallaecia reinstall
EOF
      ;;
    install-category)
      cat <<'EOF'
USO
  gallaecia install-category [OPCIÓNS] [CATEGORÍA]

DESCRICIÓN
  Mostra as categorías da instalación base e permite instalar novas
  aplicacións. Mostra por separado as variantes completas xa instaladas e
  ocúltaas do selector. Non elimina as xa instaladas. A aplicación escollida
  como predeterminada entre as existentes e as novas aplícase tamén a
  mimeapps.list e Hyprland cando corresponda. Usa exclusivamente as categorías
  da versión instalada e non sincroniza o repositorio.

PARÁMETROS
  [CATEGORÍA]
      Identificador interno opcional, por exemplo `audio`, `development` ou
      `downloads`. Se se omite, mantén o selector aberto ata premer Esc.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

CONTROIS
  Frechas e Enter
      Navegan e confirman a categoría ou a aplicación predeterminada.

  Tab ou Ctrl+Espazo
      Marca ou desmarca aplicacións no selector múltiple.

  Esc
      Cancela a selección actual; no menú de categorías pecha o comando.

RESULTADO
  Instala as aplicacións seleccionadas e as súas configuracións opcionais. A
  mesma elección predeterminada aplícase a MIME e Hyprland nas categorías
  homoxéneas. As heteroxéneas aplican os MIME propios sen pedir unha
  predeterminada común. Esc salta a selección actual ou pecha o menú.

EXEMPLOS
  gallaecia install-category
  gallaecia install-category development
EOF
      ;;
    wallpaper-add)
      cat <<'EOF'
USO
  gallaecia wallpaper-add [OPCIÓNS] FICHEIRO...

DESCRICIÓN
  Clasifica cada fondo pola extensión e cópiao ao directorio correspondente:
  as imaxes van a ~/.wallpapers e os vídeos animados a ~/.wallpaper-videos.
  Non sobrescribe ficheiros existentes.

PARÁMETROS
  FICHEIRO...
      Un ou máis fondos. Admítense como imaxes JPG, JPEG, PNG, WEBP, AVIF e BMP;
      e como fondos animados MP4, WEBM, MKV, MOV e GIF.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite rutas que comecen por guión.

RESULTADO
  Conserva os nomes e copia cada formato no seu directorio. Valida todos os
  ficheiros antes de copiar e devolve un código distinto de 0 se algún formato
  non está admitido ou unha copia falla.

EXEMPLOS
  gallaecia wallpaper-add ~/Imaxes/fondo.jpg
  gallaecia wallpaper-add ~/Vídeos/fondo.mp4 ~/Imaxes/outro.webp
EOF
      ;;
  esac
}

# Imprime unha referencia breve dos subcomandos. A axuda longa segue
# centralizada en `_gallaecia_help` para manter un único formato.
_gallaecia_commands() {
  cat <<'EOF'
commands             Lista esta referencia.
update               Actualiza o sistema e os dotfiles.
reinstall            Reinstala Gallaecia Dots desde a base actual.
install-category     Instala máis aplicacións dunha categoría.
wallpaper-add        Engade imaxes e fondos animados.
EOF
}

# Le a primeira liña do ficheiro de estado `version`. Non calcula a versión
# desde Git: mostra exactamente a última que o instalador marcou como aplicada.
_gallaecia_version() {
  local version_file="$HOME/.local/share/gallaecia-dots/version"

  if [ -s "$version_file" ]; then
    printf 'Gallaecia Dots %s\n' "$(head -n 1 "$version_file")"
  else
    printf 'Gallaecia Dots sen versión rexistrada\n'
  fi
}

# Recibe a ruta candidata e comproba dúas cousas: que Git a recoñeza como
# worktree e que conteña un install.sh lexible. Non modifica o repo.
_gallaecia_has_repo() {
  local dotfiles_dir="$1"

  git -C "$dotfiles_dir" rev-parse --is-inside-work-tree &> /dev/null &&
    [ -r "$dotfiles_dir/install.sh" ]
}

# Recibe opcionalmente `--confirm` e sincroniza sempre a rama `release`.
#
# - Se DOTFILES_DIR non existe, clona directamente `release`.
# - Se existe, valida o repo, fai fetch, cambia a `release` e compara as versións.
# - Se hai cambios remotos, pode pedir confirmación e fai pull con autostash.
# - Se a ruta existe pero non é un repo válido, non a elimina nin sobrescribe.
#
# É un subcomando interno reutilizado polo actualizador, reinstall e
# install-category. Executar `gallaecia _sync-repo` manualmente tamén é seguro.
_gallaecia_sync_repo() {
  local confirm_update=false
  local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
  local repo_url="${GALLAECIA_REPO_URL:-https://github.com/XurxoMF/gallaecia-dots.git}"
  local local_head remote_head

  while (($#)); do
    case "$1" in
      --confirm)
        confirm_update=true
        ;;
      *)
        printf 'Opción interna descoñecida: %s\n' "$1" >&2
        return 1
        ;;
    esac
    shift
  done

  if ! has_command git; then
    error "Git non está dispoñible para sincronizar os dotfiles."
    return 1
  fi

  if [ ! -e "$dotfiles_dir" ]; then
    title "Clonando Gallaecia Dots"
    git clone -b release "$repo_url" "$dotfiles_dir"
    return
  fi

  if ! _gallaecia_has_repo "$dotfiles_dir"; then
    error "$dotfiles_dir existe, pero non é un repositorio válido de Gallaecia Dots."
    return 1
  fi

  if ! git -C "$dotfiles_dir" fetch --quiet origin release; then
    error "Non se puido consultar a versión release do repositorio remoto."
    return 1
  fi
  if ! git -C "$dotfiles_dir" switch release; then
    error "Non se puido activar a versión release dos dotfiles."
    return 1
  fi

  local_head="$(git -C "$dotfiles_dir" rev-parse HEAD)"
  remote_head="$(git -C "$dotfiles_dir" rev-parse origin/release)"

  if [ "$local_head" = "$remote_head" ]; then
    info "Os dotfiles xa están sincronizados."
    return 0
  fi

  if $confirm_update &&
    ! gum_confirm "Hai cambios novos nos dotfiles. Queres descargalos?"; then
    info "Sincronización dos dotfiles cancelada."
    return 2
  fi

  if [ -n "$(git -C "$dotfiles_dir" status --porcelain)" ]; then
    warning "Hai cambios locais en $dotfiles_dir. Git tentará conservalos mediante autostash."
  fi

  title "Sincronizando Gallaecia Dots"
  git -C "$dotfiles_dir" pull --ff-only --autostash origin release
}

# Analiza unicamente a axuda de `gallaecia update` e executa system-update.sh
# nun Bash fillo. O script xestiona o sistema, sincroniza `release` e aplica as
# migracións pendentes.
_gallaecia_update() {
  while (($#)); do
    case "$1" in
      -h|--help)
        _gallaecia_help update
        return 0
        ;;
      --)
        shift
        if [ $# -gt 0 ]; then
          printf 'gallaecia update non admite argumentos posicionais.\n' >&2
          return 1
        fi
        break
        ;;
      *)
        printf 'Opción descoñecida: %s. Usa gallaecia update --help.\n' "$1" >&2
        return 1
        ;;
    esac
    shift
  done

  bash "$HOME/.local/share/gallaecia-dots/scripts/system-update.sh"
}

# Analiza a axuda, pide unha confirmación explícita, sincroniza `release` e chama
# install.sh con SKIP_CLONE=1 e INSTALL_MODE=reinstall. A limpeza do estado de
# versións pertence ao instalador, non a este wrapper.
_gallaecia_reinstall() {
  local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"

  while (($#)); do
    case "$1" in
      -h|--help)
        _gallaecia_help reinstall
        return 0
        ;;
      --)
        shift
        if [ $# -gt 0 ]; then
          printf 'gallaecia reinstall non admite argumentos posicionais.\n' >&2
          return 1
        fi
        break
        ;;
      *)
        printf 'Opción descoñecida: %s. Usa gallaecia reinstall --help.\n' "$1" >&2
        return 1
        ;;
    esac
    shift
  done

  if ! gum_confirm "Queres reinstalar Gallaecia Dots desde a base actual?"; then
    info "Reinstalación cancelada."
    return 0
  fi

  _gallaecia_sync_repo || return 1
  SKIP_CLONE=1 INSTALL_MODE=reinstall bash "$dotfiles_dir/install.sh"
}

# Instala categorías dentro dun subshell para que a libraría interna e as súas
# variables desaparezan ao volver á terminal do usuario. Sen CATEGORÍA mantén
# aberto un menú declarado aquí ata que se prema Esc; cun identificador procesa
# unha única categoría. En ambos casos reutiliza exactamente as mesmas funcións
# que a instalación base, pero sen --required.
_gallaecia_install_category() (
  local category_id=""
  local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
  local modules_dir="$HOME/.local/share/gallaecia-dots/scripts/modules"
  local internal_dir="$HOME/.local/share/gallaecia-dots/scripts/internal"
  local selected_category=""

  while (($#)); do
    case "$1" in
      -h|--help)
        _gallaecia_help install-category
        return 0
        ;;
      --)
        shift
        if [ $# -gt 1 ]; then
          printf 'gallaecia install-category admite unha única CATEGORÍA.\n' >&2
          return 1
        fi
        category_id="${1:-}"
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa gallaecia install-category --help.\n' "$1" >&2
        return 1
        ;;
      *)
        if [ -n "$category_id" ]; then
          printf 'gallaecia install-category admite unha única CATEGORÍA.\n' >&2
          return 1
        fi
        category_id="$1"
        ;;
    esac
    shift
  done

  if [ ! -r "$modules_dir/apps.sh" ] ||
    [ ! -r "$modules_dir/commands.sh" ] ||
    [ ! -r "$modules_dir/files.sh" ] ||
    [ ! -r "$modules_dir/gallaecia.sh" ] ||
    [ ! -r "$modules_dir/network.sh" ] ||
    [ ! -r "$modules_dir/ui.sh" ] ||
    [ ! -r "$internal_dir/apps.sh" ] ||
    [ ! -r "$internal_dir/versions.sh" ]; then
    error "Non se atoparon todos os módulos de Gallaecia Dots."
    return 1
  fi

  # As oito cargas estándar quedan confinadas neste subshell.
  # shellcheck source=/dev/null
  source "$modules_dir/apps.sh"
  # shellcheck source=/dev/null
  source "$modules_dir/commands.sh"
  # shellcheck source=/dev/null
  source "$modules_dir/files.sh"
  # shellcheck source=/dev/null
  source "$modules_dir/gallaecia.sh"
  # shellcheck source=/dev/null
  source "$modules_dir/network.sh"
  # shellcheck source=/dev/null
  source "$modules_dir/ui.sh"
  # shellcheck source=/dev/null
  source "$internal_dir/apps.sh"
  # shellcheck source=/dev/null
  source "$internal_dir/versions.sh"

  DOTFILES_DIR="$dotfiles_dir"

  # Este case é a lista pública de categorías do subcomando. Mantense manual e
  # explícito para que engadir unha categoría non introduza outro catálogo global.
  _gallaecia_run_category() {
    case "$1" in
      terminal|"Terminal") install-category-terminal ;;
      editor|"Editor de terminal") install-category-editor ;;
      ide|"IDE ou editor gráfico") install-category-ide ;;
      browser|"Navegador") install-category-browser ;;
      file-explorer|"Explorador de arquivos") install-category-file-explorer ;;
      audio|"Audio") install-category-audio ;;
      video|"Vídeo") install-category-video ;;
      pdf|"PDF") install-category-pdf ;;
      images|"Imaxes") install-category-images ;;
      mail|"Correo") install-category-mail ;;
      chat|"Chat") install-category-chat ;;
      creativity|"Creatividade") install-category-creativity ;;
      office|"Oficina e notas") install-category-office ;;
      games|"Xogos e tendas") install-category-games ;;
      utilities|"Utilidades") install-category-utilities ;;
      development|"Desenvolvemento") install-category-development ;;
      network|"Rede e privacidade") install-category-network ;;
      downloads|"Descargas e personalización") install-category-downloads ;;
      *)
        error "Categoría descoñecida: $1"
        return 1
        ;;
    esac
  }

  if [ -n "$category_id" ]; then
    _gallaecia_run_category "$category_id"
    return
  fi

  while true; do
    if ! selected_category="$(gum_choose --header "Escolle unha categoría; preme Esc para saír:" \
      "Terminal" \
      "Editor de terminal" \
      "IDE ou editor gráfico" \
      "Navegador" \
      "Explorador de arquivos" \
      "Audio" \
      "Vídeo" \
      "PDF" \
      "Imaxes" \
      "Correo" \
      "Chat" \
      "Creatividade" \
      "Oficina e notas" \
      "Xogos e tendas" \
      "Utilidades" \
      "Desenvolvemento" \
      "Rede e privacidade" \
      "Descargas e personalización")"; then
      return 0
    fi

    _gallaecia_run_category "$selected_category" || return 1
  done
)

# Recibe unha ou máis rutas e clasifícaas pola extensión, sen inspeccionar o
# contido multimedia:
#
# - JPG, JPEG, PNG, WEBP, AVIF e BMP van a `~/.wallpapers`.
# - MP4, WEBM, MKV, MOV e GIF van a `~/.wallpaper-videos`.
#
# A primeira pasada comproba que todas as rutas sexan ficheiros normais e que
# todos os formatos estean admitidos. Así, un argumento incorrecto non deixa
# unha copia parcial. A segunda crea os destinos e usa `copy_file`, que conserva
# o nome e rexeita sobrescrituras.
_gallaecia_add_wallpapers() {
  local files=()
  local source_file extension destination target_file

  while (($#)); do
    case "$1" in
      -h|--help)
        _gallaecia_help wallpaper-add
        return 0
        ;;
      --)
        shift
        files+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa gallaecia wallpaper-add --help.\n' \
          "$1" >&2
        return 1
        ;;
      *)
        files+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#files[@]} -eq 0 ]; then
    printf 'gallaecia wallpaper-add require polo menos un FICHEIRO. Usa --help.\n' >&2
    return 1
  fi

  for source_file in "${files[@]}"; do
    if [ ! -f "$source_file" ]; then
      error "A orixe non é un ficheiro normal: $source_file"
      return 1
    fi

    extension="${source_file##*.}"
    extension="${extension,,}"
    case "$extension" in
      jpg|jpeg|png|webp|avif|bmp|mp4|webm|mkv|mov|gif) ;;
      *)
        error "Formato de fondo non admitido: $source_file"
        return 1
        ;;
    esac
  done

  for source_file in "${files[@]}"; do
    extension="${source_file##*.}"
    extension="${extension,,}"
    case "$extension" in
      jpg|jpeg|png|webp|avif|bmp)
        destination="$HOME/.wallpapers"
        ;;
      mp4|webm|mkv|mov|gif)
        destination="$HOME/.wallpaper-videos"
        ;;
    esac

    target_file="$destination/${source_file##*/}"
    copy_file "$source_file" "$target_file" || return 1
    success "Engadido: $target_file"
  done
}

# Analiza as opcións globais, extrae o nome do subcomando e reenvía o resto dos
# argumentos ao helper correspondente. Este é o único nome deste módulo pensado
# para ser chamado directamente polo usuario.
gallaecia() {
  local command_name=""

  while (($#)); do
    case "$1" in
      -h|--help)
        _gallaecia_help main
        return 0
        ;;
      -v|--version)
        _gallaecia_version
        return 0
        ;;
      --)
        shift
        command_name="${1:-}"
        if [ $# -gt 0 ]; then
          shift
        fi
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa gallaecia --help.\n' "$1" >&2
        return 1
        ;;
      *)
        command_name="$1"
        shift
        break
        ;;
    esac
    shift
  done

  if [ -z "$command_name" ]; then
    _gallaecia_help main
    return 0
  fi

  case "$command_name" in
    commands)
      if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        _gallaecia_help commands
      elif [ $# -gt 0 ]; then
        printf 'gallaecia commands non admite argumentos. Usa --help.\n' >&2
        return 1
      else
        _gallaecia_commands
      fi
      ;;
    update)
      _gallaecia_update "$@"
      ;;
    reinstall)
      _gallaecia_reinstall "$@"
      ;;
    install-category)
      _gallaecia_install_category "$@"
      ;;
    wallpaper-add)
      _gallaecia_add_wallpapers "$@"
      ;;
    _sync-repo)
      _gallaecia_sync_repo "$@"
      ;;
    *)
      printf 'Comando descoñecido: %s. Usa gallaecia --help.\n' \
        "$command_name" >&2
      return 1
      ;;
  esac
}
