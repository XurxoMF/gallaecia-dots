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
#      ├─ install-category  -> sincroniza repo + internal/apps.sh nun subshell
#      ├─ wallpaper-add     -> copia a ~/.wallpapers
#      └─ wallpaper-video-add -> copia a ~/.wallpaper-videos
#
# O repo sincronízase antes dos fluxos que precisan os fontes máis recentes.
# `install-category` execútase entre parénteses para que as funcións e variables
# de `scripts/internal/` desaparezan ao rematar e non contaminen a terminal.
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
      Copia imaxes ao directorio de fondos estáticos.

  wallpaper-video-add
      Copia vídeos ao directorio de fondos animados.

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
  aplicacións. Non elimina as xa instaladas e pregunta antes de modificar os
  valores predeterminados de mimeapps.list e Hyprland.

PARÁMETROS
  [CATEGORÍA]
      Identificador interno opcional, por exemplo `audio`, `development` ou
      `downloads`. Se se omite, mostra un selector.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

RESULTADO
  Instala as aplicacións seleccionadas e as súas configuracións opcionais. A
  mesma elección predeterminada aplícase a MIME e Hyprland cando corresponda.
  Cancelar unha selección non modifica nada.

EXEMPLOS
  gallaecia install-category
  gallaecia install-category development
EOF
      ;;
    wallpaper-add|wallpaper-video-add)
      local destination description example

      if [ "$1" = "wallpaper-add" ]; then
        destination="$HOME/.wallpapers/"
        description="imaxes para os fondos estáticos"
        example="gallaecia wallpaper-add $HOME/Imaxes/fondo.jpg"
      else
        destination="$HOME/.wallpaper-videos/"
        description="vídeos para os fondos animados"
        example="gallaecia wallpaper-video-add $HOME/Vídeos/fondo.mp4"
      fi

      cat <<EOF
USO
  gallaecia $1 [OPCIÓNS] FICHEIRO...

DESCRICIÓN
  Copia un ou máis $description en $destination. Non sobrescribe ficheiros
  existentes.

PARÁMETROS
  FICHEIRO...
      Un ou máis ficheiros que se copiarán.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite rutas que comecen por guión.

RESULTADO
  Conserva o nome de cada ficheiro e devolve un código distinto de 0 se algunha
  copia falla.

EXEMPLOS
  $example
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
wallpaper-add        Engade fondos estáticos.
wallpaper-video-add  Engade fondos animados.
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

# Resolve a categoría dentro dun subshell. Primeiro sincroniza `release`;
# despois carga desde ese repo as sete librarías estándar e chama
# install_app_category. As parénteses fan que todo o estado interno se destrúa
# ao volver á shell do usuario.
_gallaecia_install_category() (
  local category_id=""
  local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
  local modules_dir internal_dir

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

  _gallaecia_sync_repo || return 1

  modules_dir="$dotfiles_dir/.local/share/gallaecia-dots/scripts/modules"
  internal_dir="$dotfiles_dir/.local/share/gallaecia-dots/scripts/internal"

  if [ ! -r "$modules_dir/apps.sh" ] ||
    [ ! -r "$modules_dir/commands.sh" ] ||
    [ ! -r "$modules_dir/files.sh" ] ||
    [ ! -r "$modules_dir/gallaecia.sh" ] ||
    [ ! -r "$modules_dir/ui.sh" ] ||
    [ ! -r "$internal_dir/apps.sh" ] ||
    [ ! -r "$internal_dir/versions.sh" ]; then
    error "Non se atoparon todos os módulos de Gallaecia Dots."
    return 1
  fi

  # Todo se carga dentro deste subshell e desaparece ao rematar o comando.
  # shellcheck source=/dev/null
  source "$modules_dir/apps.sh"
  # shellcheck source=/dev/null
  source "$modules_dir/commands.sh"
  # shellcheck source=/dev/null
  source "$modules_dir/files.sh"
  # shellcheck source=/dev/null
  source "$modules_dir/gallaecia.sh"
  # shellcheck source=/dev/null
  source "$modules_dir/ui.sh"
  # shellcheck source=/dev/null
  source "$internal_dir/apps.sh"
  # shellcheck source=/dev/null
  source "$internal_dir/versions.sh"

  DOTFILES_DIR="$dotfiles_dir"
  install_app_category "$category_id"
)

# Recibe o nome do subcomando, o directorio destino e unha ou máis rutas.
# Comparte o parser entre imaxes e vídeos, crea o destino e usa copy_file para
# rexeitar sobrescrituras. Non valida o formato multimedia: Noctalia decide que
# ficheiros pode reproducir ou mostrar.
_gallaecia_add_wallpapers() {
  local command_name="$1"
  local destination="$2"
  shift 2
  local files=()
  local source_file target_file

  while (($#)); do
    case "$1" in
      -h|--help)
        _gallaecia_help "$command_name"
        return 0
        ;;
      --)
        shift
        files+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa gallaecia %s --help.\n' \
          "$1" "$command_name" >&2
        return 1
        ;;
      *)
        files+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#files[@]} -eq 0 ]; then
    printf 'gallaecia %s require polo menos un FICHEIRO. Usa --help.\n' \
      "$command_name" >&2
    return 1
  fi

  ensure_directory "$destination" || return 1

  for source_file in "${files[@]}"; do
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
      _gallaecia_add_wallpapers \
        wallpaper-add "$HOME/.wallpapers" "$@"
      ;;
    wallpaper-video-add)
      _gallaecia_add_wallpapers \
        wallpaper-video-add "$HOME/.wallpaper-videos" "$@"
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
