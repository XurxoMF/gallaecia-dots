# shellcheck shell=bash

###############################################################################
# MÓDULO PÚBLICO DE COMANDOS
#
# Estes helpers non instalan programas. Traballan co que xa existe:
#
#   has_command          -> proba se o PATH resolve un nome.
#   require_command(s)   -> valida dependencias e explica o que falta.
#   command_path         -> imprime o executable resolto.
#   package_owns_command -> consulta que paquete fornece un executable.
#   retry_command        -> repite un comando fallido cun límite.
#   run-terminal-as      -> abre un comando cun app_id identificable.
#
# Usa has_command para ramas opcionais e require_command(s) cando continuar sen
# a dependencia non teña sentido. A instalación debe facerse explicitamente no
# script chamador co xestor apropiado.
###############################################################################

# Recibe como único argumento o nome dun helper público e imprime a súa axuda.
# Centralizar aquí os textos mantén o formato común sen mesturar documentación
# longa co fluxo de validación de cada comando. Non modifica estado e non se
# considera unha API pública: chámaa cada helper ao procesar `-h|--help`.
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
    require_command)
      cat <<'EOF'
USO
  require_command [OPCIÓNS] COMANDO

DESCRICIÓN
  Comproba que un comando está dispoñible e mostra un erro claro se falta.

PARÁMETROS
  COMANDO
      Nome do comando requirido.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite un nome que comece por guión.

RESULTADO
  Devolve 0 se o comando existe e 1 se non está dispoñible.

EXEMPLOS
  require_command git
  require_command -- -comando
EOF
      ;;
    require_commands)
      cat <<'EOF'
USO
  require_commands [OPCIÓNS] COMANDO...

DESCRICIÓN
  Comproba varios comandos e informa de todos os que faltan.

PARÁMETROS
  COMANDO...
      Un ou máis nomes de comandos requiridos.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite nomes que comecen por guión.

RESULTADO
  Devolve 0 se todos os comandos existen e 1 se falta algún.

EXEMPLOS
  require_commands git gum
  require_commands -- git -comando
EOF
      ;;
    command_path)
      cat <<'EOF'
USO
  command_path [OPCIÓNS] [COMANDO]

DESCRICIÓN
  Resolve un comando mediante `command -v`.

PARÁMETROS
  COMANDO
      Nome do comando que se quere resolver.

OPCIÓNS
  --command COMANDO
      Nome que se resolverá; se se omite, pídese cun input.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite un nome que comece por guión.

RESULTADO
  Escribe a ruta ou descrición resolta en stdout.
  Devolve un código distinto de 0 se o comando non existe.

EXEMPLOS
  command_path
  command_path --command git
EOF
      ;;
    package_owns_command)
      cat <<'EOF'
USO
  package_owns_command [OPCIÓNS] [COMANDO]

DESCRICIÓN
  Resolve un executable e consulta con Yay que paquete instalado o proporciona.

PARÁMETROS
  COMANDO
      Nome dun comando ou ruta dun executable.

OPCIÓNS
  --command COMANDO
      Nome ou executable que se consultará; se se omite, pídese cun input.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite un valor que comece por guión.

RESULTADO
  Escribe a información do paquete propietario.
  Devolve un código distinto de 0 se o comando ou o paquete non se atopan.

EXEMPLOS
  package_owns_command
  package_owns_command --command /usr/bin/git
EOF
      ;;
    retry_command)
      cat <<'EOF'
USO
  retry_command [OPCIÓNS] -- COMANDO...

DESCRICIÓN
  Repite un comando cando falla, sen usar `eval` e conservando os argumentos.

PARÁMETROS
  COMANDO...
      Comando e argumentos que se executarán.

OPCIÓNS
  --attempts VALOR
      Número máximo de intentos. O valor predeterminado é 3.

  --delay VALOR
      Segundos de espera entre intentos. Admite decimais e o valor
      predeterminado é 1.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper e introduce o comando.

RESULTADO
  Devolve 0 no primeiro intento correcto.
  Se todos fallan, devolve o código de saída do último intento.

EXEMPLOS
  retry_command -- curl -fLO https://example.com/file
  retry_command --attempts 5 --delay 2 -- git pull

COMANDO ORIXINAL
  Todo o situado despois de `--` execútase directamente como comando.
  Usa `retry_command -- COMANDO --help` para consultar a axuda do programa real.
EOF
      ;;
    run-terminal-as)
      cat <<'EOF'
USO
  run-terminal-as [OPCIÓNS] NOME -- COMANDO...

DESCRICIÓN
  Abre unha terminal nova co comando indicado e asígnalle o `app_id` de
  Wayland `gallaecia.NOME`. Adapta a opción necesaria ao terminal
  predeterminado entre Kitty, Alacritty, Foot, Ghostty e WezTerm.

PARÁMETROS
  NOME
      Identificador en minúsculas que comeza por letra e pode conter letras,
      números e guións.

  COMANDO...
      Comando e argumentos que se executarán dentro da terminal nova.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper e introduce o comando.

RESULTADO
  Abre unha terminal coa clase `gallaecia.NOME` e devolve o código do
  terminal utilizado para crear a xanela.
  Devolve 1 se faltan argumentos, `$TERMINAL` non está dispoñible ou o
  terminal predeterminado non é compatible.

EXEMPLOS
  run-terminal-as monitor -- btop
  run-terminal-as system-update -- bash -lc ~/.local/share/gallaecia-dots/scripts/system-update.sh

COMANDO ORIXINAL
  Todo o situado despois de `--` execútase dentro da terminal nova.
  Usa `run-terminal-as NOME -- COMANDO --help` para consultar a axuda do
  programa real dentro desa terminal.
EOF
      ;;
  esac
}

# Recibe exactamente un nome e comproba se Bash pode resolvelo no PATH.
# Non imprime a ruta: comunica o resultado unicamente co código de saída de
# `command -v`, polo que está pensado para usarse directamente nun `if`.
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

# Recibe exactamente un nome e reutiliza `has_command` para validalo.
# Devolve 0 cando existe; se falta, devolve 1 e escribe en stderr unha mensaxe
# apta para mostrar ao usuario, sen intentar instalar nada automaticamente.
require_command() {
  local values=()
  local command_name

  while (($#)); do
    case "$1" in
      -h|--help)
        _commands_help require_command
        return 0
        ;;
      --)
        shift
        values+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa require_command --help.\n' "$1" >&2
        return 1
        ;;
      *)
        values+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#values[@]} -ne 1 ]; then
    printf 'require_command require un COMANDO. Usa require_command --help.\n' >&2
    return 1
  fi
  command_name="${values[0]}"

  if ! has_command -- "$command_name"; then
    printf 'Comando requirido non dispoñible: %s\n' "$command_name" >&2
    return 1
  fi
}

# Recibe un ou máis nomes, comproba todos e informa de cada dependencia ausente.
# Non se detén no primeiro fallo: remata o percorrido para ofrecer un diagnóstico
# completo e só entón devolve 1 se faltaba polo menos un comando.
require_commands() {
  local command_names=()
  local command_name
  local missing=false

  while (($#)); do
    case "$1" in
      -h|--help)
        _commands_help require_commands
        return 0
        ;;
      --)
        shift
        command_names+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa require_commands --help.\n' "$1" >&2
        return 1
        ;;
      *)
        command_names+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#command_names[@]} -eq 0 ]; then
    printf 'require_commands require COMANDO... Usa require_commands --help.\n' >&2
    return 1
  fi

  for command_name in "${command_names[@]}"; do
    if ! has_command -- "$command_name"; then
      printf 'Comando requirido non dispoñible: %s\n' "$command_name" >&2
      missing=true
    fi
  done

  if $missing; then
    return 1
  fi
}

# Recibe exactamente un nome e imprime en stdout o resultado de `command -v`.
# Conserva tanto a saída como o código do builtin, de modo que pode devolver
# unha ruta, un alias ou unha función segundo o tipo de comando resolto.
command_path() {
  local values=()
  local command_name=""

  while (($#)); do
    case "$1" in
      --command)
        if [ $# -lt 2 ]; then
          printf 'Falta COMANDO para --command. Usa command_path --help.\n' >&2
          return 1
        fi
        command_name="$2"
        shift
        ;;
      -h|--help)
        _commands_help command_path
        return 0
        ;;
      --)
        shift
        values+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa command_path --help.\n' "$1" >&2
        return 1
        ;;
      *)
        values+=("$1")
        ;;
    esac
    shift
  done

  if [ -z "$command_name" ] && [ ${#values[@]} -gt 0 ]; then
    command_name="${values[0]}"
    values=("${values[@]:1}")
  fi
  if [ ${#values[@]} -gt 0 ]; then
    printf 'command_path recibiu demasiados comandos. Usa command_path --help.\n' >&2
    return 1
  fi
  if [ -z "$command_name" ]; then
    command_name="$(input --header "Comando que queres localizar" -- \
      --placeholder "git")" || return 0
  fi
  [ -n "$command_name" ] || return 0

  command -v "$command_name"
}

# Recibe un nome resoluble no PATH ou a ruta dun ficheiro executable.
# Resolve o ficheiro real e pásao a `yay -Qo`, que consulta conxuntamente a base
# de paquetes instalada por Pacman/Yay. Imprime a resposta de Yay en stdout e
# falla de forma explícita se Yay, o comando ou un ficheiro consultable faltan.
package_owns_command() {
  local values=()
  local command_name=""
  local command_location

  while (($#)); do
    case "$1" in
      --command)
        if [ $# -lt 2 ]; then
          printf 'Falta COMANDO para --command. Usa package_owns_command --help.\n' >&2
          return 1
        fi
        command_name="$2"
        shift
        ;;
      -h|--help)
        _commands_help package_owns_command
        return 0
        ;;
      --)
        shift
        values+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa package_owns_command --help.\n' "$1" >&2
        return 1
        ;;
      *)
        values+=("$1")
        ;;
    esac
    shift
  done

  if [ -z "$command_name" ] && [ ${#values[@]} -gt 0 ]; then
    command_name="${values[0]}"
    values=("${values[@]:1}")
  fi
  if [ ${#values[@]} -gt 0 ]; then
    printf 'package_owns_command recibiu demasiados comandos. Usa --help.\n' >&2
    return 1
  fi
  if [ -z "$command_name" ]; then
    command_name="$(input --header "Comando ou executable que queres consultar" -- \
      --placeholder "git")" || return 0
  fi
  [ -n "$command_name" ] || return 0

  if ! has_command yay; then
    printf 'Yay non está dispoñible para consultar paquetes.\n' >&2
    return 1
  fi

  if [ -f "$command_name" ]; then
    command_location="$command_name"
  else
    command_location="$(command -v "$command_name")" || {
      printf 'Comando non dispoñible: %s\n' "$command_name" >&2
      return 1
    }
  fi

  if [ ! -f "$command_location" ]; then
    printf 'O comando non resolve a un executable consultable: %s\n' "$command_name" >&2
    return 1
  fi

  yay -Qo -- "$command_location"
}

# Recibe opcións de reintentos e, tras `--`, o comando completo nun array.
# Execútao sen `eval`, espera só entre fallos e detense no primeiro éxito.
# Se se esgotan os intentos devolve exactamente o código do último fallo, o que
# permite ao chamador conservar a semántica do comando orixinal.
retry_command() {
  local attempts=3
  local delay=1
  local command_args=()
  local attempt exit_code=1

  while (($#)); do
    case "$1" in
      --attempts)
        if [ $# -lt 2 ]; then
          printf 'Falta VALOR para --attempts. Usa retry_command --help.\n' >&2
          return 1
        fi
        attempts="$2"
        shift
        ;;
      --delay)
        if [ $# -lt 2 ]; then
          printf 'Falta VALOR para --delay. Usa retry_command --help.\n' >&2
          return 1
        fi
        delay="$2"
        shift
        ;;
      -h|--help)
        _commands_help retry_command
        return 0
        ;;
      --)
        shift
        command_args=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa retry_command --help.\n' "$1" >&2
        return 1
        ;;
      *)
        printf 'O comando debe ir despois de --. Usa retry_command --help.\n' >&2
        return 1
        ;;
    esac
    shift
  done

  # Só admite enteiros positivos para evitar bucles baleiros ou infinitos.
  if [[ ! "$attempts" =~ ^[1-9][0-9]*$ ]]; then
    printf -- '--attempts debe ser un enteiro positivo.\n' >&2
    return 1
  fi
  # `sleep` admite segundos enteiros ou cunha parte decimal.
  if [[ ! "$delay" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    printf -- '--delay debe ser un número de segundos non negativo.\n' >&2
    return 1
  fi
  if [ ${#command_args[@]} -eq 0 ]; then
    printf 'retry_command require un COMANDO despois de --.\n' >&2
    return 1
  fi

  for ((attempt = 1; attempt <= attempts; attempt++)); do
    if "${command_args[@]}"; then
      return 0
    else
      exit_code=$?
    fi

    if [ "$attempt" -lt "$attempts" ]; then
      printf 'Intento %d/%d fallido; repetirase en %s segundos.\n' \
        "$attempt" "$attempts" "$delay" >&2
      sleep "$delay"
    fi
  done

  return "$exit_code"
}

# Recibe un nome estable e un comando completo tras `--`, comproba o terminal
# exportado por Hyprland e traduce o identificador común á opción específica de
# cada terminal ofrecido por Gallaecia. O comando mantense nun array para
# conservar exactamente os seus argumentos; non usa `eval` nin abre unha shell
# intermedia. A clase resultante permite aplicar regras de Hyprland sen afectar
# o resto de xanelas do mesmo terminal.
run-terminal-as() {
  local names=()
  local command_args=()
  local name terminal terminal_path terminal_name application_id

  while (($#)); do
    case "$1" in
      -h|--help)
        _commands_help run-terminal-as
        return 0
        ;;
      --)
        shift
        command_args=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa run-terminal-as --help.\n' "$1" >&2
        return 1
        ;;
      *)
        names+=("$1")
        ;;
    esac
    shift
  done

  if [ ${#names[@]} -ne 1 ]; then
    printf 'run-terminal-as require un NOME. Usa run-terminal-as --help.\n' >&2
    return 1
  fi
  if [ ${#command_args[@]} -eq 0 ]; then
    printf 'run-terminal-as require un COMANDO despois de --.\n' >&2
    return 1
  fi

  name="${names[0]}"
  # Este formato produce un compoñente válido e predicible para o app_id.
  if [[ ! "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
    printf 'NOME debe comezar por letra minúscula e conter só letras minúsculas, números ou guións.\n' >&2
    return 1
  fi

  terminal="${TERMINAL:-}"
  if [ -z "$terminal" ]; then
    printf 'A variable TERMINAL non está definida.\n' >&2
    return 1
  fi
  if ! terminal_path="$(command_path -- "$terminal")"; then
    printf 'A terminal predeterminada non está dispoñible: %s\n' "$terminal" >&2
    return 1
  fi

  terminal_name="${terminal_path##*/}"
  application_id="gallaecia.$name"

  case "$terminal_name" in
    kitty)
      "$terminal_path" --app-id "$application_id" "${command_args[@]}"
      ;;
    alacritty)
      "$terminal_path" --class "$application_id" -e "${command_args[@]}"
      ;;
    foot)
      "$terminal_path" --app-id "$application_id" -e "${command_args[@]}"
      ;;
    ghostty)
      "$terminal_path" --class="$application_id" -e "${command_args[@]}"
      ;;
    wezterm)
      "$terminal_path" start --class "$application_id" -- "${command_args[@]}"
      ;;
    *)
      printf 'Terminal non compatible con run-terminal-as: %s\n' "$terminal_name" >&2
      printf 'Terminais compatibles: Kitty, Alacritty, Foot, Ghostty e WezTerm.\n' >&2
      return 1
      ;;
  esac
}

# Completa nomes de executables e as opcións propias dos helpers de comandos.
# Os argumentos posteriores ao comando envolto usan o completado predeterminado.
_commands_completion() {
  local command_name="${COMP_WORDS[0]:-}"
  local current="${COMP_WORDS[COMP_CWORD]:-}"
  local previous=""
  local options=""
  local separator_index=-1
  local index

  COMPREPLY=()
  if ((COMP_CWORD > 0)); then
    previous="${COMP_WORDS[COMP_CWORD - 1]}"
  fi

  if [ "$previous" = "--command" ]; then
    mapfile -t COMPREPLY < <(compgen -c -- "$current")
    return
  fi

  for ((index = 1; index < COMP_CWORD; index++)); do
    if [ "${COMP_WORDS[index]}" = "--" ]; then
      separator_index="$index"
      break
    fi
  done
  if [ "$separator_index" -ge 0 ]; then
    if [ "$COMP_CWORD" -eq $((separator_index + 1)) ]; then
      mapfile -t COMPREPLY < <(compgen -c -- "$current")
    else
      compopt -o default
    fi
    return
  fi

  case "$command_name" in
    has_command|require_command|require_commands)
      if [[ "$current" != -* ]]; then
        mapfile -t COMPREPLY < <(compgen -c -- "$current")
        return
      fi
      options="-h --help --"
      ;;
    command_path|package_owns_command)
      if [[ "$current" != -* ]]; then
        mapfile -t COMPREPLY < <(compgen -c -- "$current")
        return
      fi
      options="--command -h --help --"
      ;;
    retry_command)
      options="--attempts --delay -h --help --"
      ;;
    run-terminal-as)
      options="-h --help --"
      ;;
  esac

  mapfile -t COMPREPLY < <(compgen -W "$options" -- "$current")
}

# Rexistra os completados deste módulo unicamente nas shells interactivas.
if [[ $- == *i* ]]; then
  complete -F _commands_completion \
    has_command require_command require_commands \
    command_path package_owns_command retry_command run-terminal-as
fi
