# shellcheck shell=bash

# Mostra a axuda específica de cada operación con ficheiros.
_files_help() {
  case "$1" in
    replace_path)
      cat <<'EOF'
Uso: replace_path [--dry-run] [-h|--help] [--] ORIXE DESTINO

Elimina a árbore de destino e substitúea por unha copia da orixe.

  --dry-run   Mostra a operación sen modificar ficheiros.
  --          Remata as opcións e permite rutas que comecen por guión.
EOF
      ;;
    merge_path)
      cat <<'EOF'
Uso: merge_path [--dry-run] [-h|--help] [--] ORIXE DESTINO

Crea o destino se non existe e copia dentro del a árbore de orixe sen borrar
previamente o contido existente.

  --dry-run   Mostra a operación sen modificar ficheiros.
  --          Remata as opcións e permite rutas que comecen por guión.
EOF
      ;;
    replace_file)
      cat <<'EOF'
Uso: replace_file [--dry-run] [-h|--help] [--] ORIXE DESTINO

Elimina o ficheiro de destino e substitúeo por unha copia da orixe.

  --dry-run   Mostra a operación sen modificar ficheiros.
  --          Remata as opcións e permite rutas que comecen por guión.
EOF
      ;;
    file_exists)
      cat <<'EOF'
Uso: file_exists [-h|--help] [--] RUTA

Devolve éxito se a ruta recibida existe e é un ficheiro normal.
`--` permite comprobar unha ruta que comece por guión.
EOF
      ;;
  esac
}

# Rexeita destinos amplos que sería perigoso borrar ou substituír.
_validate_file_target() {
  local target="$1"

  # Inclúe rutas baleiras, o raíz, referencias relativas e o directorio persoal.
  case "$target" in
    ""|"/"|"."|".."|"$HOME")
      printf 'Destino non seguro para substituír: %s\n' "$target" >&2
      return 1
      ;;
  esac
}

# Substitúe unha carpeta/árbore completa.
# Úsase para configs que Gallaecia controla enteiras.
replace_path() {
  local dry_run=false
  local paths=()
  local source target

  while (($#)); do
    case "$1" in
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

  if [ ${#paths[@]} -ne 2 ]; then
    printf 'replace_path require ORIXE e DESTINO. Usa replace_path --help.\n' >&2
    return 1
  fi

  source="${paths[0]}"
  target="${paths[1]}"

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

  rm -rf -- "$target" && cp -r -- "$source" "$target"
}

# Copia unha árbore dentro doutra sen borrar o destino.
# Úsase para directorios que conteñen estado do usuario e non se pode perder.
merge_path() {
  local dry_run=false
  local paths=()
  local source target

  while (($#)); do
    case "$1" in
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

  if [ ${#paths[@]} -ne 2 ]; then
    printf 'merge_path require ORIXE e DESTINO. Usa merge_path --help.\n' >&2
    return 1
  fi

  source="${paths[0]}"
  target="${paths[1]}"

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

# Substitúe un único ficheiro.
replace_file() {
  local dry_run=false
  local paths=()
  local source target

  while (($#)); do
    case "$1" in
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

  if [ ${#paths[@]} -ne 2 ]; then
    printf 'replace_file require ORIXE e DESTINO. Usa replace_file --help.\n' >&2
    return 1
  fi

  source="${paths[0]}"
  target="${paths[1]}"

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

  rm -f -- "$target" && cp -- "$source" "$target"
}

# Comproba se existe un ficheiro normal.
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
