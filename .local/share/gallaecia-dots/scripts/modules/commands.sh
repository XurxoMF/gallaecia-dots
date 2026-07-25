# shellcheck shell=bash

# Mostra a axuda específica de cada helper público deste módulo.
_commands_help() {
  case "$1" in
    has_command)
      cat <<'EOF'
Uso: has_command [-h|--help] [--] COMANDO

Devolve éxito se COMANDO está dispoñible no PATH mediante `command -v`.
`--` permite comprobar un nome que comece por guión.
EOF
      ;;
    ensure_command)
      cat <<'EOF'
Uso: ensure_command [-h|--help] [--] COMANDO PAQUETE

Instala PAQUETE con Pacman só cando COMANDO non está dispoñible no PATH.
Non admite passthrough porque combina a comprobación, sudo e Pacman.
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
