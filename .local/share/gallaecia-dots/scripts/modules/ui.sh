# shellcheck shell=bash

UI_COLORS_FILE="${UI_COLORS_FILE:-$HOME/.config/gallaecia-dots/ui-colors.sh}"

# Se Noctalia xerou cores para a UI, cárganse aquí e úsanse si existen.
if [ -r "$UI_COLORS_FILE" ]; then
  # shellcheck source=/dev/null
  source "$UI_COLORS_FILE"
fi

FOREGROUND="${FOREGROUND:-#dbe3ed}"
BACKGROUND="${BACKGROUND:-}"
BORDER_FOREGROUND="${BORDER_FOREGROUND:-#90CDFF}"
BORDER_BACKGROUND="${BORDER_BACKGROUND:-}"
ACCENT_FOREGROUND="${ACCENT_FOREGROUND:-#90CDFF}"
SUCCESS_FOREGROUND="${SUCCESS_FOREGROUND:-#2baf03}"
ERROR_FOREGROUND="${ERROR_FOREGROUND:-#cc2508}"
WARNING_FOREGROUND="${WARNING_FOREGROUND:-#D6C104}"
CONFIRM_PROMPT_FOREGROUND="${CONFIRM_PROMPT_FOREGROUND:-#90cdff}"
CONFIRM_PROMPT_BACKGROUND="${CONFIRM_PROMPT_BACKGROUND:-}"
CONFIRM_SELECTED_FOREGROUND="${CONFIRM_SELECTED_FOREGROUND:-#003350}"
CONFIRM_SELECTED_BACKGROUND="${CONFIRM_SELECTED_BACKGROUND:-#90cdff}"
CONFIRM_UNSELECTED_FOREGROUND="${CONFIRM_UNSELECTED_FOREGROUND:-#cce6ff}"
CONFIRM_UNSELECTED_BACKGROUND="${CONFIRM_UNSELECTED_BACKGROUND:-#004b72}"
CHOOSE_CURSOR_FOREGROUND="${CHOOSE_CURSOR_FOREGROUND:-#90cdff}"
CHOOSE_CURSOR_BACKGROUND="${CHOOSE_CURSOR_BACKGROUND:-}"
CHOOSE_HEADER_FOREGROUND="${CHOOSE_HEADER_FOREGROUND:-#dbe3ed}"
CHOOSE_HEADER_BACKGROUND="${CHOOSE_HEADER_BACKGROUND:-}"
CHOOSE_ITEM_FOREGROUND="${CHOOSE_ITEM_FOREGROUND:-#dbe3ed}"
CHOOSE_ITEM_BACKGROUND="${CHOOSE_ITEM_BACKGROUND:-}"
CHOOSE_SELECTED_FOREGROUND="${CHOOSE_SELECTED_FOREGROUND:-#90cdff}"
CHOOSE_SELECTED_BACKGROUND="${CHOOSE_SELECTED_BACKGROUND:-}"
INPUT_PROMPT_FOREGROUND="${INPUT_PROMPT_FOREGROUND:-#90cdff}"
INPUT_PROMPT_BACKGROUND="${INPUT_PROMPT_BACKGROUND:-}"
INPUT_PLACEHOLDER_FOREGROUND="${INPUT_PLACEHOLDER_FOREGROUND:-#6f7d8a}"
INPUT_PLACEHOLDER_BACKGROUND="${INPUT_PLACEHOLDER_BACKGROUND:-}"
INPUT_CURSOR_FOREGROUND="${INPUT_CURSOR_FOREGROUND:-#90cdff}"
INPUT_CURSOR_BACKGROUND="${INPUT_CURSOR_BACKGROUND:-}"
INPUT_HEADER_FOREGROUND="${INPUT_HEADER_FOREGROUND:-#dbe3ed}"
INPUT_HEADER_BACKGROUND="${INPUT_HEADER_BACKGROUND:-}"

# Todos os wrappers gardan os argumentos nun array para conservar espazos.
# Ao atopar `--`, deixan de interpretar opcións propias e reenvían o resto.

# Mostra a axuda específica de cada wrapper visual.
_ui_help() {
  case "$1" in
    gum_style)
      cat <<'EOF'
Uso: gum_style [-h|--help] [argumentos-gum-style] [-- argumentos-gum-style]

Executa `gum style` coa paleta de Gallaecia. Os argumentos directos mantéñense
por compatibilidade; `--` permite reenviar literalmente opcións como --help.

Exemplo: gum_style "Texto" -- --border rounded --bold
EOF
      ;;
    info|title|warning|success|fail)
      cat <<EOF
Uso: $1 [-h|--help] MENSAXE [-- argumentos-gum-style]

Mostra unha mensaxe co estilo de Gallaecia correspondente ao nome do helper.
Os argumentos posteriores a \`--\` reenvíanse a \`gum style\`.

Exemplo: $1 "Mensaxe" -- --border rounded
EOF
      ;;
    gum_confirm)
      cat <<'EOF'
Uso: gum_confirm [-h|--help] [argumentos-gum-confirm] [-- argumentos-gum-confirm]

Executa `gum confirm` coa paleta de Gallaecia e os textos Si/No. Devolve 0 ao
confirmar e un código distinto de cero ao cancelar.

Exemplo: gum_confirm "Continuar?" -- --default=false
EOF
      ;;
    gum_choose)
      cat <<'EOF'
Uso: gum_choose [-h|--help] [argumentos-gum-choose] [-- argumentos-gum-choose]

Executa `gum choose` coa paleta de Gallaecia. A selección escríbese en stdout;
usa --no-limit para permitir varias opcións.

Exemplo: gum_choose --header "Escolle:" "A" "B"
EOF
      ;;
    gum_input)
      cat <<'EOF'
Uso: gum_input [-h|--help] [argumentos-gum-input] [-- argumentos-gum-input]

Executa `gum input` coa paleta de Gallaecia e devolve o texto por stdout.

Exemplo: gum_input -- --password --header "Contrasinal"
EOF
      ;;
    gum_filter)
      cat <<'EOF'
Uso: gum_filter [-h|--help] [argumentos-gum-filter] [-- argumentos-gum-filter]

Filtra as opcións recibidas por stdin e escribe a selección en stdout. Usa
--no-limit para permitir varias seleccións.

Exemplo: printf '%s\n' A B C | gum_filter -- --no-limit
EOF
      ;;
    gum_write)
      cat <<'EOF'
Uso: gum_write [-h|--help] [argumentos-gum-write] [-- argumentos-gum-write]

Executa `gum write` coa paleta de Gallaecia e devolve texto multilínea.

Exemplo: gum_write -- --height 10 --show-line-numbers
EOF
      ;;
  esac
}

# Wrapper común para `gum style`.
# Centraliza cores e padding para que logo poida vir dun template/tema.
gum_style() {
  local original_args=()

  while (($#)); do
    case "$1" in
      -h|--help)
        _ui_help gum_style
        return 0
        ;;
      --)
        # `--` remata o parsing do wrapper; o resto pásase literalmente a gum.
        shift
        original_args+=("$@")
        break
        ;;
      *)
        original_args+=("$1")
        ;;
    esac
    shift
  done

  gum style \
	--background="$BACKGROUND" \
	--border-background="$BORDER_BACKGROUND" \
	--border-foreground="$BORDER_FOREGROUND" \
	--margin="0 0" \
	--padding="0 0" \
	"${original_args[@]}"
}

# Mensaxe informativa normal.
info() {
  local original_args=()

  while (($#)); do
    case "$1" in
      -h|--help)
        _ui_help info
        return 0
        ;;
      --)
        shift
        original_args+=("$@")
        break
        ;;
      *)
        original_args+=("$1")
        ;;
    esac
    shift
  done

  gum_style -- \
	--foreground="$FOREGROUND" \
	"${original_args[@]}"
}

# Título de sección.
title() {
  local original_args=()

  while (($#)); do
    case "$1" in
      -h|--help)
        _ui_help title
        return 0
        ;;
      --)
        shift
        original_args+=("$@")
        break
        ;;
      *)
        original_args+=("$1")
        ;;
    esac
    shift
  done

  gum_style -- \
	--foreground="$ACCENT_FOREGROUND" \
	--bold \
	"${original_args[@]}"
  echo
}

# Aviso visible, pero sen abortar.
warning() {
  local original_args=()

  while (($#)); do
    case "$1" in
      -h|--help)
        _ui_help warning
        return 0
        ;;
      --)
        shift
        original_args+=("$@")
        break
        ;;
      *)
        original_args+=("$1")
        ;;
    esac
    shift
  done

  gum_style -- \
	--foreground="$WARNING_FOREGROUND" \
	--bold \
	"${original_args[@]}"
}

# Mensaxe de éxito.
success() {
  local original_args=()

  while (($#)); do
    case "$1" in
      -h|--help)
        _ui_help success
        return 0
        ;;
      --)
        shift
        original_args+=("$@")
        break
        ;;
      *)
        original_args+=("$1")
        ;;
    esac
    shift
  done

  echo
  gum_style -- \
	--foreground="$SUCCESS_FOREGROUND" \
	--bold \
	"${original_args[@]}"
  echo
}

# Mensaxe de erro fatal: imprime e sae con código 1.
fail() {
  local original_args=()

  while (($#)); do
    case "$1" in
      -h|--help)
        _ui_help fail
        return 0
        ;;
      --)
        shift
        original_args+=("$@")
        break
        ;;
      *)
        original_args+=("$1")
        ;;
    esac
    shift
  done

  echo
  gum_style -- \
	--foreground="$ERROR_FOREGROUND" \
	--bold \
	"${original_args[@]}"
  exit 1
}

# Confirmación si/non co estilo de Gallaecia.
gum_confirm() {
  local original_args=()

  while (($#)); do
    case "$1" in
      -h|--help)
        _ui_help gum_confirm
        return 0
        ;;
      --)
        shift
        original_args+=("$@")
        break
        ;;
      *)
        original_args+=("$1")
        ;;
    esac
    shift
  done

  gum confirm \
	--affirmative="Si" \
	--negative="No" \
	--prompt.foreground="$CONFIRM_PROMPT_FOREGROUND" \
	--prompt.background="$CONFIRM_PROMPT_BACKGROUND" \
	--selected.foreground="$CONFIRM_SELECTED_FOREGROUND" \
	--selected.background="$CONFIRM_SELECTED_BACKGROUND" \
	--unselected.foreground="$CONFIRM_UNSELECTED_FOREGROUND" \
	--unselected.background="$CONFIRM_UNSELECTED_BACKGROUND" \
	--padding="0 0" \
	"${original_args[@]}"
}

# Selector de opcións co estilo de Gallaecia.
gum_choose() {
  local original_args=()

  while (($#)); do
    case "$1" in
      -h|--help)
        _ui_help gum_choose
        return 0
        ;;
      --)
        shift
        original_args+=("$@")
        break
        ;;
      *)
        original_args+=("$1")
        ;;
    esac
    shift
  done

  gum choose \
	--cursor.foreground="$CHOOSE_CURSOR_FOREGROUND" \
	--cursor.background="$CHOOSE_CURSOR_BACKGROUND" \
	--header.foreground="$CHOOSE_HEADER_FOREGROUND" \
	--header.background="$CHOOSE_HEADER_BACKGROUND" \
	--item.foreground="$CHOOSE_ITEM_FOREGROUND" \
	--item.background="$CHOOSE_ITEM_BACKGROUND" \
	--selected.foreground="$CHOOSE_SELECTED_FOREGROUND" \
	--selected.background="$CHOOSE_SELECTED_BACKGROUND" \
	--padding="0 0" \
	"${original_args[@]}"
}

# Entrada de texto co mesmo estilo visual que o resto da UI.
gum_input() {
  local original_args=()

  while (($#)); do
    case "$1" in
      -h|--help)
        _ui_help gum_input
        return 0
        ;;
      --)
        shift
        original_args+=("$@")
        break
        ;;
      *)
        original_args+=("$1")
        ;;
    esac
    shift
  done

  gum input \
	--prompt.foreground="$INPUT_PROMPT_FOREGROUND" \
	--prompt.background="$INPUT_PROMPT_BACKGROUND" \
	--placeholder.foreground="$INPUT_PLACEHOLDER_FOREGROUND" \
	--placeholder.background="$INPUT_PLACEHOLDER_BACKGROUND" \
	--cursor.foreground="$INPUT_CURSOR_FOREGROUND" \
	--cursor.background="$INPUT_CURSOR_BACKGROUND" \
	--header.foreground="$INPUT_HEADER_FOREGROUND" \
	--header.background="$INPUT_HEADER_BACKGROUND" \
	--padding="0 0" \
	"${original_args[@]}"
}

# Filtro interactivo para listas longas ou selección múltiple.
gum_filter() {
  local original_args=()

  while (($#)); do
    case "$1" in
      -h|--help)
        _ui_help gum_filter
        return 0
        ;;
      --)
        shift
        original_args+=("$@")
        break
        ;;
      *)
        original_args+=("$1")
        ;;
    esac
    shift
  done

  gum filter \
	--indicator.foreground="$CHOOSE_CURSOR_FOREGROUND" \
	--indicator.background="$CHOOSE_CURSOR_BACKGROUND" \
	--selected-indicator.foreground="$CHOOSE_SELECTED_FOREGROUND" \
	--selected-indicator.background="$CHOOSE_SELECTED_BACKGROUND" \
	--unselected-prefix.foreground="$CHOOSE_ITEM_FOREGROUND" \
	--unselected-prefix.background="$CHOOSE_ITEM_BACKGROUND" \
	--header.foreground="$CHOOSE_HEADER_FOREGROUND" \
	--header.background="$CHOOSE_HEADER_BACKGROUND" \
	--text.foreground="$CHOOSE_ITEM_FOREGROUND" \
	--text.background="$CHOOSE_ITEM_BACKGROUND" \
	--cursor-text.foreground="$CHOOSE_SELECTED_FOREGROUND" \
	--cursor-text.background="$CHOOSE_SELECTED_BACKGROUND" \
	--match.foreground="$ACCENT_FOREGROUND" \
	--match.background="$BACKGROUND" \
	--prompt.foreground="$INPUT_PROMPT_FOREGROUND" \
	--prompt.background="$INPUT_PROMPT_BACKGROUND" \
	--placeholder.foreground="$INPUT_PLACEHOLDER_FOREGROUND" \
	--placeholder.background="$INPUT_PLACEHOLDER_BACKGROUND" \
	--padding="0 0" \
	"${original_args[@]}"
}

# Entrada de texto de varias liñas co estilo común.
gum_write() {
  local original_args=()

  while (($#)); do
    case "$1" in
      -h|--help)
        _ui_help gum_write
        return 0
        ;;
      --)
        shift
        original_args+=("$@")
        break
        ;;
      *)
        original_args+=("$1")
        ;;
    esac
    shift
  done

  gum write \
	--base.foreground="$FOREGROUND" \
	--base.background="$BACKGROUND" \
	--cursor.foreground="$INPUT_CURSOR_FOREGROUND" \
	--cursor.background="$INPUT_CURSOR_BACKGROUND" \
	--header.foreground="$INPUT_HEADER_FOREGROUND" \
	--header.background="$INPUT_HEADER_BACKGROUND" \
	--placeholder.foreground="$INPUT_PLACEHOLDER_FOREGROUND" \
	--placeholder.background="$INPUT_PLACEHOLDER_BACKGROUND" \
	--prompt.foreground="$INPUT_PROMPT_FOREGROUND" \
	--prompt.background="$INPUT_PROMPT_BACKGROUND" \
	--padding="0 0" \
	"${original_args[@]}"
}
