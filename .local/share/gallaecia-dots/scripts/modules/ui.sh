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
INPUT_TEXT_FOREGROUND="${INPUT_TEXT_FOREGROUND:-#dbe3ed}"
INPUT_TEXT_BACKGROUND="${INPUT_TEXT_BACKGROUND:-}"
INPUT_CURSOR_FOREGROUND="${INPUT_CURSOR_FOREGROUND:-#90cdff}"
INPUT_CURSOR_BACKGROUND="${INPUT_CURSOR_BACKGROUND:-}"

# Wrapper común para `gum style`.
# Centraliza cores e padding para que logo poida vir dun template/tema.
gum_style() {
  gum style \
	--background="$BACKGROUND" \
	--border-background="$BORDER_BACKGROUND" \
	--border-foreground="$BORDER_FOREGROUND" \
	--margin="0 0" \
	--padding="0 0" \
	"$@"
}

# Mensaxe informativa normal.
info() {
  gum_style \
	--foreground="$FOREGROUND" \
	"$@"
}

# Título de sección.
title() {
  gum_style \
	--foreground="$ACCENT_FOREGROUND" \
	--bold \
	"$1"
  echo
}

# Aviso visible, pero sen abortar.
warning() {
  gum_style \
	--foreground="$WARNING_FOREGROUND" \
	--bold \
	"$1"
}

# Mensaxe de éxito.
success() {
  echo
  gum_style \
	--foreground="$SUCCESS_FOREGROUND" \
	--bold \
	"$1"
  echo
}

# Mensaxe de erro fatal: imprime e sae con código 1.
fail() {
  echo
  gum_style \
	--foreground="$ERROR_FOREGROUND" \
	--bold \
	"$1"
  exit 1
}

# Confirmación si/non co estilo de Gallaecia.
gum_confirm() {
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
	"$@"
}

# Selector de opcións co estilo de Gallaecia.
gum_choose() {
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
	"$@"
}

# Entrada de texto co mesmo estilo visual que o resto da UI.
gum_input() {
  gum input \
	--prompt.foreground="$INPUT_PROMPT_FOREGROUND" \
	--prompt.background="$INPUT_PROMPT_BACKGROUND" \
	--text.foreground="$INPUT_TEXT_FOREGROUND" \
	--text.background="$INPUT_TEXT_BACKGROUND" \
	--cursor.foreground="$INPUT_CURSOR_FOREGROUND" \
	--cursor.background="$INPUT_CURSOR_BACKGROUND" \
	--padding="0 0" \
	"$@"
}
