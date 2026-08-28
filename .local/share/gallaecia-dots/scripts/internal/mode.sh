#!/usr/bin/env bash

###############################################################################
# MODO INTERNO DA INSTALACIÓN
#
# Esta libraría pertence ao instalador, ás migracións e aos módulos que necesitan
# adaptar o seu comportamento ao modo. `commands.sh` cárgaa como dependencia ao
# iniciar o Bashrc; segue sen ser unha API estable para scripts personalizados.
#
# O modo persistente vive nun ficheiro de texto cun único valor admitido:
# `desktop` ou `server`. Os predicados seguen a convención de Bash: devolven 0
# cando o modo coincide e 1 cando non coincide.
###############################################################################

GALLAECIA_MODE_FILE="$HOME/.local/share/gallaecia-dots/mode"

# Imprime a advertencia común da API interna e o uso da función solicitante.
_mode_internal_help() {
  cat <<EOF
USO
  ${FUNCNAME[1]} -h|--help

DESCRICIÓN
  NON USAR: esta función pertence á API interna do modo de Gallaecia Dots.
  Pode consultar ou modificar o perfil persistente da instalación.

OPCIÓNS
  -h, --help
      Mostra este aviso.

RESULTADO
  A axuda devolve 0 sen modificar o estado. O resto do comportamento forma
  parte do fluxo interno e non constitúe unha API pública.

EXEMPLOS
  ${FUNCNAME[1]} --help
EOF
}

# Le e imprime o modo persistente. Un ficheiro ausente, baleiro ou cun valor
# distinto de `desktop` e `server` considérase estado inválido.
get_install_mode() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    _mode_internal_help
    return 0
  fi
  if [ $# -ne 0 ]; then
    printf 'get_install_mode non admite argumentos.\n' >&2
    return 1
  fi

  local mode="" extra_line=""

  if [ ! -s "$GALLAECIA_MODE_FILE" ]; then
    printf 'Non existe un modo de Gallaecia Dots válido en %s.\n' \
      "$GALLAECIA_MODE_FILE" >&2
    return 1
  fi

  IFS= read -r mode < "$GALLAECIA_MODE_FILE"
  if IFS= read -r extra_line; then
    printf 'O ficheiro de modo debe conter unha única liña.\n' >&2
    return 1
  fi < <(tail -n +2 "$GALLAECIA_MODE_FILE")

  case "$mode" in
    desktop|server) printf '%s\n' "$mode" ;;
    *)
      printf 'Modo de Gallaecia Dots descoñecido: %s\n' "$mode" >&2
      return 1
      ;;
  esac
}

# Valida e garda atomicamente `desktop` ou `server` como modo persistente.
set_install_mode() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    _mode_internal_help
    return 0
  fi
  if [ $# -ne 1 ]; then
    printf 'set_install_mode require un MODO.\n' >&2
    return 1
  fi

  local mode="$1"
  local state_dir="${GALLAECIA_MODE_FILE%/*}"
  local temporary_file

  case "$mode" in
    desktop|server) ;;
    *)
      printf 'Modo de Gallaecia Dots non admitido: %s\n' "$mode" >&2
      return 1
      ;;
  esac

  if ! mkdir -p "$state_dir"; then
    return 1
  fi
  temporary_file="$(mktemp "$state_dir/.mode.XXXXXX")" || return 1
  if ! printf '%s\n' "$mode" > "$temporary_file" ||
    ! mv -f "$temporary_file" "$GALLAECIA_MODE_FILE"; then
    rm -f "$temporary_file"
    return 1
  fi
}

# Devolve 0 unicamente cando a instalación persistente é de escritorio.
is_desktop() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    _mode_internal_help
    return 0
  fi
  if [ $# -ne 0 ]; then
    printf 'is_desktop non admite argumentos.\n' >&2
    return 1
  fi

  local mode
  mode="$(get_install_mode)" || return 1
  [ "$mode" = "desktop" ]
}

# Devolve 0 unicamente cando a instalación persistente é de servidor.
is_server() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    _mode_internal_help
    return 0
  fi
  if [ $# -ne 0 ]; then
    printf 'is_server non admite argumentos.\n' >&2
    return 1
  fi

  local mode
  mode="$(get_install_mode)" || return 1
  [ "$mode" = "server" ]
}
