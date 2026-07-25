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
USO
  gum_style [OPCIÓNS] TEXTO... [-- ARGUMENTOS DE GUM STYLE]

DESCRICIÓN
  Mostra un ou máis textos usando `gum style` e a paleta de Gallaecia.

PARÁMETROS
  TEXTO...
      Un ou máis textos que se mostrarán.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum style`.

RESULTADO
  Escribe o texto formatado en stdout e devolve o código de `gum style`.

EXEMPLOS
  gum_style "Texto normal"
  gum_style "Título" -- --border rounded --bold

COMANDO ORIXINAL
  Os argumentos de Gum tamén se aceptan directamente por compatibilidade,
  pero recoméndase escribilos despois de `--`.

  gum_style "Axuda" -- --help
EOF
      ;;
    info|title|warning|success|fail)
      cat <<EOF
USO
  $1 [OPCIÓNS] MENSAXE [-- ARGUMENTOS DE GUM STYLE]

DESCRICIÓN
  Mostra unha mensaxe co estilo de Gallaecia correspondente a \`$1\`.

PARÁMETROS
  MENSAXE
      Texto que se mostrará.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a \`gum style\`.

RESULTADO
  Escribe a mensaxe formatada en stdout.
  \`fail\` remata o proceso con código 1; os demais helpers devolven o código
  de \`gum style\`.

EXEMPLOS
  $1 "Mensaxe"
  $1 "Mensaxe con bordo" -- --border rounded

COMANDO ORIXINAL
  Para consultar as opcións admitidas por Gum:

  $1 "Axuda" -- --help
EOF
      ;;
    gum_confirm)
      cat <<'EOF'
USO
  gum_confirm [OPCIÓNS] PREGUNTA [-- ARGUMENTOS DE GUM CONFIRM]

DESCRICIÓN
  Mostra unha pregunta de confirmación coa paleta de Gallaecia e as opcións
  «Si» e «No».

PARÁMETROS
  PREGUNTA
      Texto que se mostrará ao usuario.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum confirm`.

RESULTADO
  Devolve 0 se o usuario escolle «Si».
  Devolve un código distinto de 0 se escolle «No» ou cancela.

EXEMPLOS
  gum_confirm "Continuar coa instalación?"
  gum_confirm "Eliminar o ficheiro?" -- --default=false
  gum_confirm "Publicar?" -- --affirmative "Publicar" --negative "Cancelar"

COMANDO ORIXINAL
  Os argumentos de Gum tamén se aceptan directamente por compatibilidade,
  pero recoméndase escribilos despois de `--`.

  gum_confirm "Axuda" -- --help
EOF
      ;;
    gum_choose)
      cat <<'EOF'
USO
  gum_choose [OPCIÓNS] OPCIÓN... [-- ARGUMENTOS DE GUM CHOOSE]

DESCRICIÓN
  Mostra un selector coa paleta de Gallaecia.

PARÁMETROS
  OPCIÓN...
      Unha ou máis opcións que se mostrarán no selector.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum choose`.

CONTROIS
  Frechas ou j/k
      Move o cursor pola lista.

  Tab ou Ctrl+Espazo
      Marca ou desmarca o elemento actual cando se usa `--limit` ou
      `--no-limit`.

  Enter
      Confirma a selección.

RESULTADO
  Escribe cada opción seleccionada nunha liña de stdout.
  Devolve un código distinto de 0 se o usuario cancela.

EXEMPLOS
  gum_choose "Git" "Docker" "Bruno"
  gum_choose "Git" "Docker" -- --header "Escolle unha ferramenta:"
  gum_choose "Git" "Docker" -- --header "Escolle varias:" --no-limit

COMANDO ORIXINAL
  Os argumentos de Gum tamén se aceptan directamente por compatibilidade,
  pero recoméndase escribilos despois de `--`.

  gum_choose "Exemplo" -- --help
EOF
      ;;
    gum_input)
      cat <<'EOF'
USO
  gum_input [OPCIÓNS] [-- ARGUMENTOS DE GUM INPUT]

DESCRICIÓN
  Mostra unha entrada de texto coa paleta de Gallaecia.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum input`.

RESULTADO
  Escribe en stdout o texto introducido.
  Devolve un código distinto de 0 se o usuario cancela.

EXEMPLOS
  gum_input
  gum_input -- --header "Nome" --placeholder "Escribe o teu nome"
  gum_input -- --password --header "Contrasinal"

COMANDO ORIXINAL
  Os argumentos de Gum tamén se aceptan directamente por compatibilidade,
  pero recoméndase escribilos despois de `--`.

  gum_input -- --help
EOF
      ;;
    gum_filter)
      cat <<'EOF'
USO
  gum_filter [OPCIÓNS] [-- ARGUMENTOS DE GUM FILTER]

DESCRICIÓN
  Filtra interactivamente as opcións recibidas por stdin.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum filter`.

CONTROIS
  Escribir
      Filtra a lista usando o texto introducido.

  Frechas ou Ctrl+j/Ctrl+k
      Move o cursor polos resultados.

  Tab ou Ctrl+Espazo
      Marca ou desmarca o resultado actual cando se usa `--limit` ou
      `--no-limit`. Espazo sen Ctrl forma parte do texto do filtro.

  Enter
      Confirma a selección.

RESULTADO
  Escribe cada opción seleccionada nunha liña de stdout.
  Devolve un código distinto de 0 se o usuario cancela.

EXEMPLOS
  printf '%s\n' A B C | gum_filter
  printf '%s\n' A B C | gum_filter -- --no-limit --header "Escolle:"

COMANDO ORIXINAL
  Os argumentos de Gum tamén se aceptan directamente por compatibilidade,
  pero recoméndase escribilos despois de `--`.

  printf '%s\n' exemplo | gum_filter -- --help
EOF
      ;;
    gum_write)
      cat <<'EOF'
USO
  gum_write [OPCIÓNS] [-- ARGUMENTOS DE GUM WRITE]

DESCRICIÓN
  Mostra un editor de texto multilínea coa paleta de Gallaecia.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum write`.

RESULTADO
  Escribe en stdout o texto introducido.
  Devolve un código distinto de 0 se o usuario cancela.

EXEMPLOS
  gum_write
  gum_write -- --height 10 --show-line-numbers

COMANDO ORIXINAL
  Os argumentos de Gum tamén se aceptan directamente por compatibilidade,
  pero recoméndase escribilos despois de `--`.

  gum_write -- --help
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

# Título de sección, separado do contido anterior e posterior mediante padding.
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
	--padding="1 0 1 0" \
	"${original_args[@]}"
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

# Mensaxe de éxito, separada do contido anterior e posterior mediante padding.
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

  gum_style -- \
	--foreground="$SUCCESS_FOREGROUND" \
	--bold \
	--padding="1 0 1 0" \
	"${original_args[@]}"
}

# Mensaxe de erro fatal: engade padding superior, imprime e sae con código 1.
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

  gum_style -- \
	--foreground="$ERROR_FOREGROUND" \
	--bold \
	--padding="1 0 0 0" \
	"${original_args[@]}"
  exit 1
}

# Confirmación si/non co estilo de Gallaecia e padding superior.
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
	--padding="1 0 0 0" \
	"${original_args[@]}"
}

# Selector de opcións co estilo de Gallaecia e padding superior.
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
	--show-help \
	--cursor.foreground="$CHOOSE_CURSOR_FOREGROUND" \
	--cursor.background="$CHOOSE_CURSOR_BACKGROUND" \
	--header.foreground="$CHOOSE_HEADER_FOREGROUND" \
	--header.background="$CHOOSE_HEADER_BACKGROUND" \
	--item.foreground="$CHOOSE_ITEM_FOREGROUND" \
	--selected.foreground="$CHOOSE_SELECTED_FOREGROUND" \
	--selected.background="$CHOOSE_SELECTED_BACKGROUND" \
	--padding="1 0 0 0" \
	"${original_args[@]}"
}

# Entrada de texto co estilo común e padding superior.
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
	--padding="1 0 0 0" \
	"${original_args[@]}"
}

# Filtro interactivo a pantalla completa para listas longas.
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

  # O fondo baleiro do indicador desmarcado anula tamén estilos do ambiente.
  gum filter \
	--show-help \
	--indicator.foreground="$CHOOSE_CURSOR_FOREGROUND" \
	--indicator.background="$CHOOSE_CURSOR_BACKGROUND" \
	--selected-indicator.foreground="$CHOOSE_SELECTED_FOREGROUND" \
	--selected-indicator.background="$CHOOSE_SELECTED_BACKGROUND" \
	--unselected-prefix.foreground="$CHOOSE_ITEM_FOREGROUND" \
	--unselected-prefix.background="" \
	--header.foreground="$CHOOSE_HEADER_FOREGROUND" \
	--header.background="$CHOOSE_HEADER_BACKGROUND" \
	--text.foreground="$CHOOSE_ITEM_FOREGROUND" \
	--cursor-text.foreground="$CHOOSE_SELECTED_FOREGROUND" \
	--cursor-text.background="$CHOOSE_SELECTED_BACKGROUND" \
	--match.foreground="$ACCENT_FOREGROUND" \
	--match.background="$BACKGROUND" \
	--prompt.foreground="$INPUT_PROMPT_FOREGROUND" \
	--prompt.background="$INPUT_PROMPT_BACKGROUND" \
	--placeholder.foreground="$INPUT_PLACEHOLDER_FOREGROUND" \
	--placeholder.background="$INPUT_PLACEHOLDER_BACKGROUND" \
	"${original_args[@]}"
}

# Entrada de varias liñas co estilo común e padding superior.
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
	--padding="1 0 0 0" \
	"${original_args[@]}"
}
