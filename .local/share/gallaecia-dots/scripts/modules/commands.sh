# shellcheck shell=bash

# Mostra a axuda específica de cada helper público deste módulo.
_commands_help() {
  case "$1" in
    has_command)
      cat <<'EOF'
USO
  has_command [OPCIÓNS] COMANDO

DESCRICIÓN
  Comproba mediante `command -v` se un comando está dispoñible no PATH.

PARÁMETROS
  COMANDO
      Nome do comando que se quere comprobar.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite comprobar un nome que comece por guión.

RESULTADO
  Devolve 0 se o comando existe e un código distinto de 0 se non existe.

EXEMPLOS
  has_command git
  has_command -- -comando
EOF
      ;;
    ensure_command)
      cat <<'EOF'
USO
  ensure_command [OPCIÓNS] COMANDO PAQUETE

DESCRICIÓN
  Instala un paquete con Pacman só cando o comando asociado non está
  dispoñible no PATH.

PARÁMETROS
  COMANDO
      Nome do executable que se comprobará.

  PAQUETE
      Nome do paquete que se instalará se falta o comando.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite valores que comecen por guión.

RESULTADO
  Devolve 0 se o comando xa existía ou o paquete se instalou correctamente.
  Devolve un código distinto de 0 se a validación ou Pacman fallan.

EXEMPLOS
  ensure_command gum gum
  ensure_command git git
EOF
      ;;
  esac
}

# Comproba se un comando está dispoñible no PATH.
has_command() {
  local values=()
  local command_name

  while (($#)); do
    case "$1" in
      -h|--help)
        _commands_help has_command
        return 0
        ;;
      --)
        # Todo o que segue deixa de interpretarse como opción do helper.
        shift
        values+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa has_command --help.\n' "$1" >&2
        return 1
        ;;
      *)
        values+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#values[@]} -ne 1 ]; then
    printf 'has_command require un COMANDO. Usa has_command --help.\n' >&2
    return 1
  fi
  command_name="${values[0]}"

  command -v "$command_name" &> /dev/null
}

# Instala un paquete de pacman só se o comando asociado aínda non existe.
# Úsase para prerequisitos básicos como gum/git.
ensure_command() {
  local values=()
  local command_name package_name

  while (($#)); do
    case "$1" in
      -h|--help)
        _commands_help ensure_command
        return 0
        ;;
      --)
        # Permite nomes de comando ou paquete que comecen por guión.
        shift
        values+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa ensure_command --help.\n' "$1" >&2
        return 1
        ;;
      *)
        values+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#values[@]} -ne 2 ]; then
    printf 'ensure_command require COMANDO e PAQUETE. Usa ensure_command --help.\n' >&2
    return 1
  fi
  command_name="${values[0]}"
  package_name="${values[1]}"

  if ! has_command -- "$command_name"; then
    sudo pacman -Sy --needed -- "$package_name"
  fi
}
