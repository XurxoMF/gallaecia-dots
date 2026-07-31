# shellcheck shell=bash

###############################################################################
# MÓDULO PÚBLICO DE FICHEIROS
#
# As operacións divídense por intención:
#
#   Substituír: replace_path, replace_file
#   Conservar destino: merge_path, copy_path, copy_file
#   Preparar: ensure_directory, ensure_symlink, backup_path
#   Consultar: *_exists, files_equal
#   Retirar de forma recuperable: trash_path
#
# `replace_*` úsase para ficheiros controlados por Gallaecia e pode eliminar o
# destino previo. `merge_*`/`copy_*` úsase cando debe conservarse estado do
# usuario. Antes de cambiar dunha familia á outra revisa a propiedade da ruta.
# Os comandos con `--dry-run` validan e describen a operación sen escribila.
###############################################################################

# Recibe o nome dun helper público e imprime a súa axuda completa.
# Agrupar aquí os textos evita repetir a estrutura documental nos parsers e
# permite que cada función se limite a validar argumentos e executar a operación.
# Non modifica o sistema de ficheiros e só a usan internamente os helpers.
_files_help() {
  case "$1" in
    replace_path)
      cat <<'EOF'
USO
  replace_path [OPCIÓNS] [ORIXE DESTINO]

DESCRICIÓN
  Elimina a árbore de destino e substitúea por unha copia da orixe.

PARÁMETROS
  ORIXE
      Directorio que se copiará.

  DESTINO
      Ruta que se eliminará e substituirá.

OPCIÓNS
  --origin RUTA
      Directorio que se copiará; se se omite, ábrese o selector.

  --destination RUTA
      Ruta que se substituirá; se se omite, pídese cun input.

  --dry-run
      Mostra a operación sen modificar ficheiros.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite rutas que comecen por guión.

RESULTADO
  Devolve 0 se a substitución se completa e un código distinto de 0 se falla.

EXEMPLOS
  replace_path ./config ~/.config/app
  replace_path --dry-run ./config ~/.config/app
EOF
      ;;
    merge_path)
      cat <<'EOF'
USO
  merge_path [OPCIÓNS] [ORIXE DESTINO]

DESCRICIÓN
  Crea o destino se non existe e copia nel o contido da orixe sen borrar
  previamente os ficheiros existentes.

PARÁMETROS
  ORIXE
      Directorio cuxo contido se copiará.

  DESTINO
      Directorio no que se combinará o contido.

OPCIÓNS
  --origin RUTA
      Directorio cuxo contido se copiará; se se omite, ábrese o selector.

  --destination RUTA
      Directorio de destino; se se omite, pídese cun input.

  --dry-run
      Mostra a operación sen modificar ficheiros.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite rutas que comecen por guión.

RESULTADO
  Devolve 0 se a combinación se completa e un código distinto de 0 se falla.

EXEMPLOS
  merge_path ./config ~/.config/app
  merge_path --dry-run ./config ~/.config/app
EOF
      ;;
    replace_file)
      cat <<'EOF'
USO
  replace_file [OPCIÓNS] [ORIXE DESTINO]

DESCRICIÓN
  Elimina o ficheiro de destino e substitúeo por unha copia da orixe.

PARÁMETROS
  ORIXE
      Ficheiro que se copiará.

  DESTINO
      Ruta do ficheiro que se substituirá.

OPCIÓNS
  --origin RUTA
      Ficheiro que se copiará; se se omite, ábrese o selector.

  --destination RUTA
      Ficheiro que se substituirá; se se omite, pídese cun input.

  --dry-run
      Mostra a operación sen modificar ficheiros.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite rutas que comecen por guión.

RESULTADO
  Devolve 0 se a substitución se completa e un código distinto de 0 se falla.

EXEMPLOS
  replace_file ./config.toml ~/.config/app/config.toml
  replace_file --dry-run ./config.toml ~/.config/app/config.toml
EOF
      ;;
    file_exists)
      cat <<'EOF'
USO
  file_exists [OPCIÓNS] RUTA

DESCRICIÓN
  Comproba se unha ruta existe e é un ficheiro normal.

PARÁMETROS
  RUTA
      Ficheiro que se quere comprobar.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite unha ruta que comece por guión.

RESULTADO
  Devolve 0 se o ficheiro existe e un código distinto de 0 se non existe.

EXEMPLOS
  file_exists ~/.bashrc
  file_exists -- ./-ficheiro
EOF
      ;;
    path_exists)
      cat <<'EOF'
USO
  path_exists [OPCIÓNS] RUTA

DESCRICIÓN
  Comproba se existe unha ruta de calquera tipo, incluídos enlaces rotos.

PARÁMETROS
  RUTA
      Ruta de calquera tipo que se quere comprobar.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite unha ruta que comece por guión.

RESULTADO
  Devolve 0 se a ruta existe e un código distinto de 0 se non existe.

EXEMPLOS
  path_exists ~/.config
  path_exists -- ./-ruta
EOF
      ;;
    directory_exists)
      cat <<'EOF'
USO
  directory_exists [OPCIÓNS] RUTA

DESCRICIÓN
  Comproba se unha ruta existe e é un directorio.

PARÁMETROS
  RUTA
      Directorio que se quere comprobar.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite unha ruta que comece por guión.

RESULTADO
  Devolve 0 se o directorio existe e un código distinto de 0 se non.

EXEMPLOS
  directory_exists ~/.config
  directory_exists -- ./-directorio
EOF
      ;;
    symlink_exists)
      cat <<'EOF'
USO
  symlink_exists [OPCIÓNS] RUTA

DESCRICIÓN
  Comproba se unha ruta é unha ligazón simbólica, aínda que estea rota.

PARÁMETROS
  RUTA
      Ligazón simbólica que se quere comprobar.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite unha ruta que comece por guión.

RESULTADO
  Devolve 0 se a ruta é unha ligazón simbólica e un código distinto de 0 se non.

EXEMPLOS
  symlink_exists ~/.config/app/config.toml
  symlink_exists -- ./-ligazon
EOF
      ;;
    copy_file)
      cat <<'EOF'
USO
  copy_file [OPCIÓNS] [ORIXE DESTINO]

DESCRICIÓN
  Copia un ficheiro conservando os metadatos e rexeita sobrescribir o destino.

PARÁMETROS
  ORIXE
      Ficheiro que se copiará.

  DESTINO
      Nova ruta que non debe existir.

OPCIÓNS
  --origin RUTA
      Ficheiro que se copiará; se se omite, ábrese o selector.

  --destination RUTA
      Nova ruta do ficheiro; se se omite, pídese cun input.

  --dry-run
      Mostra a operación sen modificar ficheiros.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite rutas que comecen por guión.

RESULTADO
  Devolve 0 se a copia se completa e un código distinto de 0 se falla.

EXEMPLOS
  copy_file
  copy_file --origin config.toml --destination ~/.config/app/config.toml
  copy_file --dry-run config.toml ~/.config/app/config.toml
EOF
      ;;
    copy_path)
      cat <<'EOF'
USO
  copy_path [OPCIÓNS] [ORIXE DESTINO]

DESCRICIÓN
  Copia unha árbore conservando os metadatos e rexeita sobrescribir o destino.

PARÁMETROS
  ORIXE
      Directorio que se copiará.

  DESTINO
      Nova ruta que non debe existir.

OPCIÓNS
  --origin RUTA
      Directorio que se copiará; se se omite, ábrese o selector.

  --destination RUTA
      Nova ruta do directorio; se se omite, pídese cun input.

  --dry-run
      Mostra a operación sen modificar ficheiros.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite rutas que comecen por guión.

RESULTADO
  Devolve 0 se a copia se completa e un código distinto de 0 se falla.

EXEMPLOS
  copy_path
  copy_path --origin ./config --destination ~/.config/app
  copy_path --dry-run ./config ~/.config/app
EOF
      ;;
    ensure_directory)
      cat <<'EOF'
USO
  ensure_directory [OPCIÓNS] [RUTA]

DESCRICIÓN
  Crea un directorio e os seus pais cando non existen.

PARÁMETROS
  RUTA
      Directorio que se quere garantir.

OPCIÓNS
  --destination RUTA
      Directorio que se creará; se se omite, pídese cun input.

  --mode VALOR
      Aplica un modo octal de tres ou catro cifras, tamén se xa existía.

  --dry-run
      Mostra a operación sen modificar ficheiros.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite unha ruta que comece por guión.

RESULTADO
  Devolve 0 se o directorio existe ao rematar e un código distinto de 0 se falla.

EXEMPLOS
  ensure_directory ~/.config/app
  ensure_directory --mode 700 ~/.local/share/app
EOF
      ;;
    backup_path)
      cat <<'EOF'
USO
  backup_path [OPCIÓNS] [RUTA]

DESCRICIÓN
  Crea unha copia con marca temporal dun ficheiro, directorio ou enlace.

PARÁMETROS
  RUTA
      Ruta da que se creará a copia.

OPCIÓNS
  --origin RUTA
      Ruta que se copiará; se se omite, ábrese o selector.

  --destination DIRECTORIO
      Garda a copia dentro deste directorio.

  --dry-run
      Calcula e mostra a ruta da copia sen modificar ficheiros.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite unha ruta que comece por guión.

RESULTADO
  Escribe en stdout a ruta da copia creada e devolve 0 se se completa.
  Devolve un código distinto de 0 se a orixe non existe ou a copia falla.

EXEMPLOS
  backup_path ~/.bashrc
  backup_path --destination ~/copias ~/.config/app
EOF
      ;;
    ensure_symlink)
      cat <<'EOF'
USO
  ensure_symlink [OPCIÓNS] [ORIXE DESTINO]

DESCRICIÓN
  Crea un enlace simbólico e os directorios pai necesarios.

PARÁMETROS
  ORIXE
      Ruta existente á que apuntará o enlace.

  DESTINO
      Ruta na que se creará o enlace.

OPCIÓNS
  --origin RUTA
      Ruta á que apuntará a ligazón; se se omite, ábrese o selector.

  --destination RUTA
      Ruta da ligazón; se se omite, pídese cun input.

  --replace
      Substitúe un ficheiro ou enlace existente. Nunca substitúe un directorio.

  --dry-run
      Mostra a operación sen modificar ficheiros.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite rutas que comecen por guión.

RESULTADO
  Devolve 0 se o enlace xa era correcto ou se creou correctamente.
  Devolve un código distinto de 0 se as rutas non son válidas ou a creación falla.

EXEMPLOS
  ensure_symlink ~/.dotfiles/app.toml ~/.config/app/config.toml
  ensure_symlink --replace ./config.toml ~/.config/app/config.toml
EOF
      ;;
    trash_path)
      cat <<'EOF'
USO
  trash_path [OPCIÓNS] [RUTA...]

DESCRICIÓN
  Envía unha ou máis rutas ao lixo mediante `trash-put`.

PARÁMETROS
  RUTA...
      Ficheiros, directorios ou enlaces que se enviarán ao lixo.

OPCIÓNS
  --origin RUTA
      Engade unha ruta á selección. Pode repetirse; se non se indica ningunha,
      ábrese o selector de ficheiros.

  --dry-run
      Mostra as rutas sen modificar ficheiros.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite rutas que comecen por guión.

RESULTADO
  Devolve 0 se todas as rutas se envían ao lixo e un código distinto de 0 se falla.

EXEMPLOS
  trash_path ficheiro.txt
  trash_path --dry-run ficheiro.txt directorio
EOF
      ;;
    files_equal)
      cat <<'EOF'
USO
  files_equal [OPCIÓNS] FICHEIRO_A FICHEIRO_B

DESCRICIÓN
  Compara byte a byte dous ficheiros normais mediante `cmp`.

PARÁMETROS
  FICHEIRO_A
      Primeiro ficheiro.

  FICHEIRO_B
      Segundo ficheiro.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite rutas que comecen por guión.

RESULTADO
  Devolve 0 se os ficheiros son iguais e un código distinto de 0 se difiren
  ou non se poden ler.

EXEMPLOS
  files_equal config.toml ~/.config/app/config.toml
  files_equal -- ./-a ./-b
EOF
      ;;
  esac
}

# Recibe unha ruta de destino antes dunha operación destrutiva ou de substitución.
# Normalízaa para detectar tamén variantes equivalentes e rexeita raíz, HOME,
# o directorio actual e o seu pai. Non comproba se a ruta existe: só establece
# unha barreira de seguridade e devolve 1 cun diagnóstico cando é demasiado ampla.
_validate_file_target() {
  local target="$1"
  local normalized_target normalized_home normalized_current normalized_parent

  # Inclúe rutas baleiras, o raíz, referencias relativas e o directorio persoal.
  case "$target" in
    ""|"/"|"."|".."|"$HOME")
      printf 'Destino non seguro para substituír: %s\n' "$target" >&2
      return 1
      ;;
  esac

  # Normaliza variantes como `$HOME/`, `/./` ou `../` antes de validalas.
  normalized_target="$(realpath -m -- "$target")" || return 1
  normalized_home="$(realpath -m -- "$HOME")" || return 1
  normalized_current="$(realpath -m -- "$PWD")" || return 1
  normalized_parent="$(realpath -m -- "$PWD/..")" || return 1

  case "$normalized_target" in
    "/"|"$normalized_home"|"$normalized_current"|"$normalized_parent")
      printf 'Destino non seguro para substituír: %s\n' "$target" >&2
      return 1
      ;;
  esac
}

# Recibe ORIXE e DESTINO, valida que a orixe sexa un directorio e que o destino
# sexa seguro, elimina este último e copia a árbore completa no seu lugar.
# É unha operación destrutiva reservada a configuracións controladas integramente
# por Gallaecia; `--dry-run` valida e describe a acción sen escribir nada.
replace_path() {
  local dry_run=false
  local interactive=false
  local paths=()
  local source=""
  local target=""

  while (($#)); do
    case "$1" in
      --origin)
        if [ $# -lt 2 ]; then
          printf 'Falta RUTA para --origin. Usa replace_path --help.\n' >&2
          return 1
        fi
        source="$2"
        shift
        ;;
      --destination)
        if [ $# -lt 2 ]; then
          printf 'Falta RUTA para --destination. Usa replace_path --help.\n' >&2
          return 1
        fi
        target="$2"
        shift
        ;;
      --dry-run)
        dry_run=true
        ;;
      -h|--help)
        _files_help replace_path
        return 0
        ;;
      --)
        # Desde aquí todos os valores son rutas, mesmo se comezan por guión.
        shift
        paths+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa replace_path --help.\n' "$1" >&2
        return 1
        ;;
      *)
        paths+=("$1")
        ;;
    esac
    shift
  done

  if [ -z "$source" ] && [ ${#paths[@]} -gt 0 ]; then
    source="${paths[0]}"
    paths=("${paths[@]:1}")
  fi
  if [ -z "$target" ] && [ ${#paths[@]} -gt 0 ]; then
    target="${paths[0]}"
    paths=("${paths[@]:1}")
  fi
  if [ ${#paths[@]} -gt 0 ]; then
    printf 'replace_path recibiu demasiadas rutas. Usa replace_path --help.\n' >&2
    return 1
  fi

  if [ -z "$source" ]; then
    source="$(gum_folder --header "Selecciona o directorio de orixe")" || return 0
    interactive=true
  fi
  if [ -z "$target" ]; then
    target="$(gum_input --header "Directorio de destino" -- \
      --placeholder "$HOME/.config/aplicacion")" || return 0
    interactive=true
  fi
  [ -n "$target" ] || return 0

  if [ ! -d "$source" ]; then
    printf 'A orixe non é un directorio: %s\n' "$source" >&2
    return 1
  fi
  if [ "$source" = "$target" ]; then
    printf 'A orixe e o destino non poden ser iguais.\n' >&2
    return 1
  fi
  _validate_file_target "$target" || return 1

  if $dry_run; then
    printf 'Substituiríase %s por unha copia de %s.\n' "$target" "$source"
    return 0
  fi

  if $interactive && path_exists -- "$target"; then
    gum_confirm "Substituír todo o contido de $target?" || return 0
  fi

  rm -rf -- "$target" && cp -r -- "$source" "$target"
}

# Recibe dous directorios e combina o contido da ORIXE dentro do DESTINO.
# Crea o destino cando falta e sobrescribe coincidencias durante a copia, pero
# non elimina outros ficheiros xa presentes; por iso se usa en árbores con estado
# do usuario. `--dry-run` realiza as validacións sen tocar o sistema de ficheiros.
merge_path() {
  local dry_run=false
  local paths=()
  local source=""
  local target=""

  while (($#)); do
    case "$1" in
      --origin)
        if [ $# -lt 2 ]; then
          printf 'Falta RUTA para --origin. Usa merge_path --help.\n' >&2
          return 1
        fi
        source="$2"
        shift
        ;;
      --destination)
        if [ $# -lt 2 ]; then
          printf 'Falta RUTA para --destination. Usa merge_path --help.\n' >&2
          return 1
        fi
        target="$2"
        shift
        ;;
      --dry-run)
        dry_run=true
        ;;
      -h|--help)
        _files_help merge_path
        return 0
        ;;
      --)
        # Desde aquí todos os valores son rutas, mesmo se comezan por guión.
        shift
        paths+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa merge_path --help.\n' "$1" >&2
        return 1
        ;;
      *)
        paths+=("$1")
        ;;
    esac
    shift
  done

  if [ -z "$source" ] && [ ${#paths[@]} -gt 0 ]; then
    source="${paths[0]}"
    paths=("${paths[@]:1}")
  fi
  if [ -z "$target" ] && [ ${#paths[@]} -gt 0 ]; then
    target="${paths[0]}"
    paths=("${paths[@]:1}")
  fi
  if [ ${#paths[@]} -gt 0 ]; then
    printf 'merge_path recibiu demasiadas rutas. Usa merge_path --help.\n' >&2
    return 1
  fi

  if [ -z "$source" ]; then
    source="$(gum_folder --header "Selecciona o directorio de orixe")" || return 0
  fi
  if [ -z "$target" ]; then
    target="$(gum_input --header "Directorio de destino" -- \
      --placeholder "$HOME/.config/aplicacion")" || return 0
  fi
  [ -n "$target" ] || return 0

  if [ ! -d "$source" ]; then
    printf 'A orixe non é un directorio: %s\n' "$source" >&2
    return 1
  fi
  if [ "$source" = "$target" ]; then
    printf 'A orixe e o destino non poden ser iguais.\n' >&2
    return 1
  fi
  _validate_file_target "$target" || return 1

  if $dry_run; then
    printf 'Combinaríase o contido de %s dentro de %s.\n' "$source" "$target"
    return 0
  fi

  # `source/.` copia tamén ficheiros ocultos e só o contido, non a carpeta raíz.
  mkdir -p -- "$target" &&
  cp -r -- "$source"/. "$target"/
}

# Recibe un ficheiro ORIXE e unha ruta DESTINO segura, elimina o ficheiro de
# destino e coloca unha copia nova. Úsase para ficheiros propiedade do proxecto;
# non crea os directorios pai e `--dry-run` non realiza ningunha modificación.
replace_file() {
  local dry_run=false
  local interactive=false
  local paths=()
  local source=""
  local target=""

  while (($#)); do
    case "$1" in
      --origin)
        if [ $# -lt 2 ]; then
          printf 'Falta RUTA para --origin. Usa replace_file --help.\n' >&2
          return 1
        fi
        source="$2"
        shift
        ;;
      --destination)
        if [ $# -lt 2 ]; then
          printf 'Falta RUTA para --destination. Usa replace_file --help.\n' >&2
          return 1
        fi
        target="$2"
        shift
        ;;
      --dry-run)
        dry_run=true
        ;;
      -h|--help)
        _files_help replace_file
        return 0
        ;;
      --)
        # Desde aquí todos os valores son rutas, mesmo se comezan por guión.
        shift
        paths+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa replace_file --help.\n' "$1" >&2
        return 1
        ;;
      *)
        paths+=("$1")
        ;;
    esac
    shift
  done

  if [ -z "$source" ] && [ ${#paths[@]} -gt 0 ]; then
    source="${paths[0]}"
    paths=("${paths[@]:1}")
  fi
  if [ -z "$target" ] && [ ${#paths[@]} -gt 0 ]; then
    target="${paths[0]}"
    paths=("${paths[@]:1}")
  fi
  if [ ${#paths[@]} -gt 0 ]; then
    printf 'replace_file recibiu demasiadas rutas. Usa replace_file --help.\n' >&2
    return 1
  fi

  if [ -z "$source" ]; then
    source="$(gum_file --header "Selecciona o ficheiro de orixe")" || return 0
    interactive=true
  fi
  if [ -z "$target" ]; then
    target="$(gum_input --header "Ficheiro de destino" -- \
      --placeholder "$HOME/.config/aplicacion/config.toml")" || return 0
    interactive=true
  fi
  [ -n "$target" ] || return 0

  if [ ! -f "$source" ]; then
    printf 'A orixe non é un ficheiro normal: %s\n' "$source" >&2
    return 1
  fi
  if [ "$source" = "$target" ]; then
    printf 'A orixe e o destino non poden ser iguais.\n' >&2
    return 1
  fi
  _validate_file_target "$target" || return 1

  if $dry_run; then
    printf 'Substituiríase %s por unha copia de %s.\n' "$target" "$source"
    return 0
  fi

  if $interactive && path_exists -- "$target"; then
    gum_confirm "Substituír o ficheiro $target?" || return 0
  fi

  rm -f -- "$target" && cp -- "$source" "$target"
}

# Recibe exactamente unha ruta e devolve 0 só se apunta a un ficheiro normal.
# Non produce saída no caso habitual, polo que serve como predicado dentro dun
# `if`; os erros de uso si se explican en stderr.
file_exists() {
  local paths=()
  local file_path

  while (($#)); do
    case "$1" in
      -h|--help)
        _files_help file_exists
        return 0
        ;;
      --)
        # Desde aquí todos os valores son rutas, mesmo se comezan por guión.
        shift
        paths+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa file_exists --help.\n' "$1" >&2
        return 1
        ;;
      *)
        paths+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#paths[@]} -ne 1 ]; then
    printf 'file_exists require unha RUTA. Usa file_exists --help.\n' >&2
    return 1
  fi
  file_path="${paths[0]}"

  [ -f "$file_path" ]
}

# Recibe exactamente unha ruta e devolve 0 para calquera obxecto existente.
# A comprobación adicional con `-L` fai que tamén considere existentes os
# enlaces simbólicos rotos. Non imprime nada salvo os erros de argumentos.
path_exists() {
  local paths=()
  local file_path

  while (($#)); do
    case "$1" in
      -h|--help)
        _files_help path_exists
        return 0
        ;;
      --)
        shift
        paths+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa path_exists --help.\n' "$1" >&2
        return 1
        ;;
      *)
        paths+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#paths[@]} -ne 1 ]; then
    printf 'path_exists require unha RUTA. Usa path_exists --help.\n' >&2
    return 1
  fi
  file_path="${paths[0]}"

  [ -e "$file_path" ] || [ -L "$file_path" ]
}

# Recibe exactamente unha ruta e devolve 0 só cando é un directorio accesible.
# Actúa como predicado silencioso; non crea a ruta nin resolve a súa ausencia.
directory_exists() {
  local paths=()
  local directory_path

  while (($#)); do
    case "$1" in
      -h|--help)
        _files_help directory_exists
        return 0
        ;;
      --)
        shift
        paths+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa directory_exists --help.\n' "$1" >&2
        return 1
        ;;
      *)
        paths+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#paths[@]} -ne 1 ]; then
    printf 'directory_exists require unha RUTA. Usa directory_exists --help.\n' >&2
    return 1
  fi
  directory_path="${paths[0]}"

  [ -d "$directory_path" ]
}

# Recibe exactamente unha ruta e devolve 0 cando o propio obxecto é un enlace
# simbólico, independentemente de que o seu destino exista. Non produce saída
# salvo cando a chamada ten argumentos inválidos.
symlink_exists() {
  local paths=()
  local symlink_path

  while (($#)); do
    case "$1" in
      -h|--help)
        _files_help symlink_exists
        return 0
        ;;
      --)
        shift
        paths+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa symlink_exists --help.\n' "$1" >&2
        return 1
        ;;
      *)
        paths+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#paths[@]} -ne 1 ]; then
    printf 'symlink_exists require unha RUTA. Usa symlink_exists --help.\n' >&2
    return 1
  fi
  symlink_path="${paths[0]}"

  [ -L "$symlink_path" ]
}

# Recibe un ficheiro ORIXE e un DESTINO que aínda non debe existir.
# Valida a ruta, crea os directorios pai e copia con `cp -a` para conservar os
# metadatos. Nunca sobrescribe estado previo; `--dry-run` só describe a copia.
copy_file() {
  local dry_run=false
  local paths=()
  local source=""
  local target=""
  local target_parent

  while (($#)); do
    case "$1" in
      --origin)
        if [ $# -lt 2 ]; then
          printf 'Falta RUTA para --origin. Usa copy_file --help.\n' >&2
          return 1
        fi
        source="$2"
        shift
        ;;
      --destination)
        if [ $# -lt 2 ]; then
          printf 'Falta RUTA para --destination. Usa copy_file --help.\n' >&2
          return 1
        fi
        target="$2"
        shift
        ;;
      --dry-run)
        dry_run=true
        ;;
      -h|--help)
        _files_help copy_file
        return 0
        ;;
      --)
        shift
        paths+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa copy_file --help.\n' "$1" >&2
        return 1
        ;;
      *)
        paths+=("$1")
        ;;
    esac
    shift
  done

  if [ -z "$source" ] && [ ${#paths[@]} -gt 0 ]; then
    source="${paths[0]}"
    paths=("${paths[@]:1}")
  fi
  if [ -z "$target" ] && [ ${#paths[@]} -gt 0 ]; then
    target="${paths[0]}"
    paths=("${paths[@]:1}")
  fi
  if [ ${#paths[@]} -gt 0 ]; then
    printf 'copy_file recibiu demasiadas rutas. Usa copy_file --help.\n' >&2
    return 1
  fi
  if [ -z "$source" ]; then
    source="$(gum_file --header "Selecciona o ficheiro de orixe")" || return 0
  fi
  if [ -z "$target" ]; then
    target="$(gum_input --header "Novo ficheiro de destino" -- \
      --placeholder "$HOME/.config/aplicacion/config.toml")" || return 0
  fi
  [ -n "$target" ] || return 0

  if [ ! -f "$source" ]; then
    printf 'A orixe non é un ficheiro normal: %s\n' "$source" >&2
    return 1
  fi
  if path_exists -- "$target"; then
    printf 'O destino xa existe: %s\n' "$target" >&2
    return 1
  fi
  _validate_file_target "$target" || return 1

  if $dry_run; then
    printf 'Copiaríase %s en %s.\n' "$source" "$target"
    return 0
  fi

  target_parent="$(dirname -- "$target")"
  mkdir -p -- "$target_parent" &&
  cp -a -- "$source" "$target"
}

# Recibe un directorio ORIXE e un DESTINO completamente novo.
# Crea os pais necesarios e copia a árbore con metadatos mediante `cp -a`;
# rexeita calquera tipo de destino existente, incluído un enlace roto.
# `--dry-run` conserva todas as validacións pero non crea nin copia nada.
copy_path() {
  local dry_run=false
  local paths=()
  local source=""
  local target=""
  local target_parent

  while (($#)); do
    case "$1" in
      --origin)
        if [ $# -lt 2 ]; then
          printf 'Falta RUTA para --origin. Usa copy_path --help.\n' >&2
          return 1
        fi
        source="$2"
        shift
        ;;
      --destination)
        if [ $# -lt 2 ]; then
          printf 'Falta RUTA para --destination. Usa copy_path --help.\n' >&2
          return 1
        fi
        target="$2"
        shift
        ;;
      --dry-run)
        dry_run=true
        ;;
      -h|--help)
        _files_help copy_path
        return 0
        ;;
      --)
        shift
        paths+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa copy_path --help.\n' "$1" >&2
        return 1
        ;;
      *)
        paths+=("$1")
        ;;
    esac
    shift
  done

  if [ -z "$source" ] && [ ${#paths[@]} -gt 0 ]; then
    source="${paths[0]}"
    paths=("${paths[@]:1}")
  fi
  if [ -z "$target" ] && [ ${#paths[@]} -gt 0 ]; then
    target="${paths[0]}"
    paths=("${paths[@]:1}")
  fi
  if [ ${#paths[@]} -gt 0 ]; then
    printf 'copy_path recibiu demasiadas rutas. Usa copy_path --help.\n' >&2
    return 1
  fi
  if [ -z "$source" ]; then
    source="$(gum_folder --header "Selecciona o directorio de orixe")" || return 0
  fi
  if [ -z "$target" ]; then
    target="$(gum_input --header "Novo directorio de destino" -- \
      --placeholder "$HOME/.config/aplicacion")" || return 0
  fi
  [ -n "$target" ] || return 0

  if [ ! -d "$source" ]; then
    printf 'A orixe non é un directorio: %s\n' "$source" >&2
    return 1
  fi
  if path_exists -- "$target"; then
    printf 'O destino xa existe: %s\n' "$target" >&2
    return 1
  fi
  _validate_file_target "$target" || return 1

  if $dry_run; then
    printf 'Copiaríase a árbore %s en %s.\n' "$source" "$target"
    return 0
  fi

  target_parent="$(dirname -- "$target")"
  mkdir -p -- "$target_parent" &&
  cp -a -- "$source" "$target"
}

# Recibe unha ruta de directorio e garante que exista xunto cos seus pais.
# Se se indica `--mode`, valida o valor octal e aplícao incluso a un directorio
# que xa existía. Rexeita unha ruta ocupada por outro tipo de obxecto e permite
# comprobar a acción sen cambios mediante `--dry-run`.
ensure_directory() {
  local dry_run=false
  local mode=""
  local paths=()
  local directory_path=""

  while (($#)); do
    case "$1" in
      --destination)
        if [ $# -lt 2 ]; then
          printf 'Falta RUTA para --destination. Usa ensure_directory --help.\n' >&2
          return 1
        fi
        directory_path="$2"
        shift
        ;;
      --mode)
        if [ $# -lt 2 ]; then
          printf 'Falta VALOR para --mode. Usa ensure_directory --help.\n' >&2
          return 1
        fi
        mode="$2"
        shift
        ;;
      --dry-run)
        dry_run=true
        ;;
      -h|--help)
        _files_help ensure_directory
        return 0
        ;;
      --)
        shift
        paths+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa ensure_directory --help.\n' "$1" >&2
        return 1
        ;;
      *)
        paths+=("$1")
        ;;
    esac
    shift
  done

  if [ -z "$directory_path" ] && [ ${#paths[@]} -gt 0 ]; then
    directory_path="${paths[0]}"
    paths=("${paths[@]:1}")
  fi
  if [ ${#paths[@]} -gt 0 ]; then
    printf 'ensure_directory recibiu demasiadas rutas. Usa ensure_directory --help.\n' >&2
    return 1
  fi
  if [ -z "$directory_path" ]; then
    directory_path="$(gum_input --header "Directorio que se creará" -- \
      --placeholder "$HOME/.config/aplicacion")" || return 0
  fi
  [ -n "$directory_path" ] || return 0

  if [ -n "$mode" ] && [[ ! "$mode" =~ ^[0-7]{3,4}$ ]]; then
    printf -- '--mode debe ser un modo octal de tres ou catro cifras.\n' >&2
    return 1
  fi
  if path_exists -- "$directory_path" && [ ! -d "$directory_path" ]; then
    printf 'A ruta existe pero non é un directorio: %s\n' "$directory_path" >&2
    return 1
  fi

  if $dry_run; then
    if [ -n "$mode" ]; then
      printf 'Garantiríase o directorio %s co modo %s.\n' "$directory_path" "$mode"
    else
      printf 'Garantiríase o directorio %s.\n' "$directory_path"
    fi
    return 0
  fi

  if ! mkdir -p -- "$directory_path"; then
    return 1
  fi
  if [ -n "$mode" ]; then
    chmod "$mode" -- "$directory_path"
  fi
}

# Recibe unha ruta existente de calquera tipo e crea ao seu lado, ou dentro do
# directorio indicado, unha copia `*.backup-MARCA_TEMPORAL` con `cp -a`.
# Engade un contador para non colidir con copias do mesmo segundo e imprime en
# stdout a ruta final, tamén en `--dry-run`, para que o chamador poida gardala.
backup_path() {
  local dry_run=false
  local destination=""
  local paths=()
  local source=""
  local timestamp source_name candidate target target_parent
  local counter=1

  while (($#)); do
    case "$1" in
      --origin)
        if [ $# -lt 2 ]; then
          printf 'Falta RUTA para --origin. Usa backup_path --help.\n' >&2
          return 1
        fi
        source="$2"
        shift
        ;;
      --destination)
        if [ $# -lt 2 ]; then
          printf 'Falta DIRECTORIO para --destination. Usa backup_path --help.\n' >&2
          return 1
        fi
        destination="$2"
        shift
        ;;
      --dry-run)
        dry_run=true
        ;;
      -h|--help)
        _files_help backup_path
        return 0
        ;;
      --)
        shift
        paths+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa backup_path --help.\n' "$1" >&2
        return 1
        ;;
      *)
        paths+=("$1")
        ;;
    esac
    shift
  done

  if [ -z "$source" ] && [ ${#paths[@]} -gt 0 ]; then
    source="${paths[0]}"
    paths=("${paths[@]:1}")
  fi
  if [ ${#paths[@]} -gt 0 ]; then
    printf 'backup_path recibiu demasiadas rutas. Usa backup_path --help.\n' >&2
    return 1
  fi
  if [ -z "$source" ]; then
    source="$(gum_file --header "Selecciona a ruta da que crear unha copia")" || return 0
  fi

  if ! path_exists -- "$source"; then
    printf 'A ruta de orixe non existe: %s\n' "$source" >&2
    return 1
  fi
  if [ -n "$destination" ] &&
    path_exists -- "$destination" &&
    [ ! -d "$destination" ]; then
    printf 'O destino das copias non é un directorio: %s\n' "$destination" >&2
    return 1
  fi

  timestamp="$(date '+%Y%m%d-%H%M%S')" || return 1
  source_name="$(basename -- "$source")" || return 1
  if [ -n "$destination" ]; then
    candidate="${destination%/}/${source_name}.backup-${timestamp}"
  else
    candidate="${source}.backup-${timestamp}"
  fi
  target="$candidate"

  # Engade un contador cando xa existe unha copia creada no mesmo segundo.
  while path_exists -- "$target"; do
    target="${candidate}.${counter}"
    ((counter++))
  done

  if $dry_run; then
    printf '%s\n' "$target"
    return 0
  fi

  target_parent="$(dirname -- "$target")"
  mkdir -p -- "$target_parent" &&
  cp -a -- "$source" "$target" &&
  printf '%s\n' "$target"
}

# Recibe ORIXE e DESTINO e garante que o segundo sexa un enlace ao primeiro.
# Se xa é correcto non fai nada; se hai outro obxecto só o substitúe con
# `--replace`, e nunca elimina un directorio real. Crea os pais do enlace e
# `--dry-run` valida e informa sen modificar o destino.
ensure_symlink() {
  local dry_run=false
  local replace=false
  local paths=()
  local source=""
  local target=""
  local target_parent current_source

  while (($#)); do
    case "$1" in
      --origin)
        if [ $# -lt 2 ]; then
          printf 'Falta RUTA para --origin. Usa ensure_symlink --help.\n' >&2
          return 1
        fi
        source="$2"
        shift
        ;;
      --destination)
        if [ $# -lt 2 ]; then
          printf 'Falta RUTA para --destination. Usa ensure_symlink --help.\n' >&2
          return 1
        fi
        target="$2"
        shift
        ;;
      --replace)
        replace=true
        ;;
      --dry-run)
        dry_run=true
        ;;
      -h|--help)
        _files_help ensure_symlink
        return 0
        ;;
      --)
        shift
        paths+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa ensure_symlink --help.\n' "$1" >&2
        return 1
        ;;
      *)
        paths+=("$1")
        ;;
    esac
    shift
  done

  if [ -z "$source" ] && [ ${#paths[@]} -gt 0 ]; then
    source="${paths[0]}"
    paths=("${paths[@]:1}")
  fi
  if [ -z "$target" ] && [ ${#paths[@]} -gt 0 ]; then
    target="${paths[0]}"
    paths=("${paths[@]:1}")
  fi
  if [ ${#paths[@]} -gt 0 ]; then
    printf 'ensure_symlink recibiu demasiadas rutas. Usa ensure_symlink --help.\n' >&2
    return 1
  fi
  if [ -z "$source" ]; then
    source="$(gum_file --header "Selecciona a orixe da ligazón")" || return 0
  fi
  if [ -z "$target" ]; then
    target="$(gum_input --header "Destino da ligazón" -- \
      --placeholder "$HOME/.config/aplicacion/config.toml")" || return 0
  fi
  [ -n "$target" ] || return 0

  if ! path_exists -- "$source"; then
    printf 'A orixe do enlace non existe: %s\n' "$source" >&2
    return 1
  fi
  if [ "$source" = "$target" ]; then
    printf 'A orixe e o destino non poden ser iguais.\n' >&2
    return 1
  fi
  _validate_file_target "$target" || return 1

  if [ -L "$target" ]; then
    current_source="$(readlink -- "$target")" || return 1
    if [ "$current_source" = "$source" ]; then
      return 0
    fi
  fi

  if [ -d "$target" ] && [ ! -L "$target" ]; then
    printf 'Non se substitúe un directorio por un enlace: %s\n' "$target" >&2
    return 1
  fi
  if path_exists -- "$target" && ! $replace; then
    printf 'O destino xa existe; usa --replace para substituílo: %s\n' "$target" >&2
    return 1
  fi

  if $dry_run; then
    printf 'Garantiríase o enlace %s -> %s.\n' "$target" "$source"
    return 0
  fi

  target_parent="$(dirname -- "$target")"
  mkdir -p -- "$target_parent" || return 1
  if path_exists -- "$target"; then
    rm -f -- "$target" || return 1
  fi
  ln -s -- "$source" "$target"
}

# Recibe unha ou máis rutas, valida primeiro o conxunto completo e despois
# envíao nunha soa chamada a `trash-put`. A validación previa evita un resultado
# parcial se unha ruta non existe ou é demasiado ampla. `--dry-run` enumera o
# que se retiraría. A operación real require sempre unha confirmación explícita.
trash_path() {
  local dry_run=false
  local paths=()
  local file_path

  while (($#)); do
    case "$1" in
      --origin)
        if [ $# -lt 2 ]; then
          printf 'Falta RUTA para --origin. Usa trash_path --help.\n' >&2
          return 1
        fi
        paths+=("$2")
        shift
        ;;
      --dry-run)
        dry_run=true
        ;;
      -h|--help)
        _files_help trash_path
        return 0
        ;;
      --)
        shift
        paths+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa trash_path --help.\n' "$1" >&2
        return 1
        ;;
      *)
        paths+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#paths[@]} -eq 0 ]; then
    file_path="$(gum_file --header "Selecciona a ruta que enviar ao lixo")" || return 0
    [ -n "$file_path" ] || return 0
    paths+=("$file_path")
  fi
  if ! command -v trash-put &> /dev/null; then
    printf 'trash-put non está dispoñible.\n' >&2
    return 1
  fi

  for file_path in "${paths[@]}"; do
    _validate_file_target "$file_path" || return 1
    if ! path_exists -- "$file_path"; then
      printf 'A ruta non existe: %s\n' "$file_path" >&2
      return 1
    fi
  done

  if $dry_run; then
    for file_path in "${paths[@]}"; do
      printf 'Enviaríase ao lixo: %s\n' "$file_path"
    done
    return 0
  fi

  gum_confirm "Enviar ${#paths[@]} ruta(s) ao lixo?" || return 0
  trash-put -- "${paths[@]}"
}

# Recibe exactamente dous ficheiros normais e compáraos con `cmp -s`.
# Non imprime diferenzas: devolve 0 cando o contido é idéntico e un código
# distinto cando difire ou non se pode ler, para usalo directamente como predicado.
files_equal() {
  local paths=()
  local first_file second_file

  while (($#)); do
    case "$1" in
      -h|--help)
        _files_help files_equal
        return 0
        ;;
      --)
        shift
        paths+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa files_equal --help.\n' "$1" >&2
        return 1
        ;;
      *)
        paths+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#paths[@]} -ne 2 ]; then
    printf 'files_equal require FICHEIRO_A e FICHEIRO_B. Usa files_equal --help.\n' >&2
    return 1
  fi
  first_file="${paths[0]}"
  second_file="${paths[1]}"

  if [ ! -f "$first_file" ]; then
    printf 'Non é un ficheiro normal: %s\n' "$first_file" >&2
    return 1
  fi
  if [ ! -f "$second_file" ]; then
    printf 'Non é un ficheiro normal: %s\n' "$second_file" >&2
    return 1
  fi

  cmp -s -- "$first_file" "$second_file"
}

# Completa opcións e rutas dos helpers de ficheiros. Usa `mapfile` para manter
# nomes con espazos e marca os resultados como ficheiros para que Bash os cite.
_files_completion() {
  local command_name="${COMP_WORDS[0]:-}"
  local current="${COMP_WORDS[COMP_CWORD]:-}"
  local previous=""
  local options=""
  local path_mode="files"

  COMPREPLY=()
  if ((COMP_CWORD > 0)); then
    previous="${COMP_WORDS[COMP_CWORD - 1]}"
  fi

  if [ "$previous" = "--mode" ]; then
    mapfile -t COMPREPLY < <(compgen -W "700 750 755 775" -- "$current")
    return
  fi

  case "$command_name" in
    replace_path|merge_path|copy_path)
      options="--origin --destination --dry-run -h --help --"
      path_mode="directories"
      ;;
    replace_file|copy_file)
      options="--origin --destination --dry-run -h --help --"
      ;;
    file_exists|path_exists|symlink_exists|files_equal)
      options="-h --help --"
      ;;
    directory_exists)
      options="-h --help --"
      path_mode="directories"
      ;;
    ensure_directory)
      options="--destination --mode --dry-run -h --help --"
      path_mode="directories"
      ;;
    backup_path)
      options="--origin --destination --dry-run -h --help --"
      if [ "$previous" = "--destination" ]; then
        path_mode="directories"
      fi
      ;;
    ensure_symlink)
      options="--origin --destination --replace --dry-run -h --help --"
      ;;
    trash_path)
      options="--origin --dry-run -h --help --"
      ;;
  esac

  if [[ "$current" == -* ]]; then
    mapfile -t COMPREPLY < <(compgen -W "$options" -- "$current")
    return
  fi

  compopt -o filenames
  if [ "$path_mode" = "directories" ]; then
    mapfile -t COMPREPLY < <(compgen -d -- "$current")
  else
    mapfile -t COMPREPLY < <(compgen -f -- "$current")
  fi
}

# Rexistra os completados deste módulo unicamente nas shells interactivas.
if [[ $- == *i* ]]; then
  complete -F _files_completion \
    replace_path merge_path replace_file \
    file_exists path_exists directory_exists symlink_exists \
    copy_file copy_path ensure_directory backup_path ensure_symlink \
    trash_path files_equal
fi
