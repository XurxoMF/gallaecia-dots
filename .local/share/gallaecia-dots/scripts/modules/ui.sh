# shellcheck shell=bash

###############################################################################
# MÓDULO PÚBLICO DE INTERFACE
#
# Este ficheiro é a única capa que debe chamar directamente a Gum nos fluxos de
# Gallaecia. Agrupa:
#
#   Mensaxes: gum_style, info, title, warning, error, success, fail
#   Interacción: gum_confirm, gum_choose, gum_input, gum_filter, gum_write
#   Ferramentas: gum_file, gum_folder, gum_spin, gum_pager, gum_table,
#                gum_format, gum_join, gum_log
#
# A paleta pode xerala Noctalia en UI_COLORS_FILE. Se non existe, os valores
# seguintes actúan como fallback. Os roles son semánticos e compartidos: cambia
# PROMPT_FOREGROUND para todos os prompts, SELECTED_BACKGROUND para todas as
# seleccións, etc.; non engadas cores soltas dentro dun comando consumidor.
#
# Cada wrapper analiza só as súas opcións ata `--` e reenvía o resto ao comando
# Gum orixinal. O padding visual tamén se decide aquí para que os chamadores non
# teñan que inserir `echo` nin coñecer detalles de estilo.
###############################################################################

UI_COLORS_FILE="${UI_COLORS_FILE:-$HOME/.config/gallaecia-dots/ui-colors.sh}"

# Se Noctalia xerou cores para a UI, cárganse aquí e úsanse si existen.
if [ -r "$UI_COLORS_FILE" ]; then
  # shellcheck source=/dev/null
  source "$UI_COLORS_FILE"
fi

FOREGROUND="${FOREGROUND:-#dbe3ed}"
BACKGROUND="${BACKGROUND:-}"
MUTED_FOREGROUND="${MUTED_FOREGROUND:-#6f7d8a}"
MUTED_BACKGROUND="${MUTED_BACKGROUND:-}"
BORDER_FOREGROUND="${BORDER_FOREGROUND:-#90CDFF}"
BORDER_BACKGROUND="${BORDER_BACKGROUND:-}"
ACCENT_FOREGROUND="${ACCENT_FOREGROUND:-#90CDFF}"
SUCCESS_FOREGROUND="${SUCCESS_FOREGROUND:-#2baf03}"
ERROR_FOREGROUND="${ERROR_FOREGROUND:-#cc2508}"
WARNING_FOREGROUND="${WARNING_FOREGROUND:-#D6C104}"

# Os roles xenéricos reutilízanse en todos os comandos de Gum.
PROMPT_FOREGROUND="${PROMPT_FOREGROUND:-#90cdff}"
PROMPT_BACKGROUND="${PROMPT_BACKGROUND:-}"
CURSOR_FOREGROUND="${CURSOR_FOREGROUND:-#90cdff}"
CURSOR_BACKGROUND="${CURSOR_BACKGROUND:-}"
HEADER_FOREGROUND="${HEADER_FOREGROUND:-#dbe3ed}"
HEADER_BACKGROUND="${HEADER_BACKGROUND:-}"
ITEM_FOREGROUND="${ITEM_FOREGROUND:-#dbe3ed}"
ITEM_BACKGROUND="${ITEM_BACKGROUND:-$BACKGROUND}"
SELECTED_FOREGROUND="${SELECTED_FOREGROUND:-#003350}"
SELECTED_BACKGROUND="${SELECTED_BACKGROUND:-#90cdff}"
UNSELECTED_FOREGROUND="${UNSELECTED_FOREGROUND:-#cce6ff}"
UNSELECTED_BACKGROUND="${UNSELECTED_BACKGROUND:-#004b72}"

# Todos os wrappers gardan os argumentos nun array para conservar espazos.
# Ao atopar `--`, deixan de interpretar opcións propias e reenvían o resto.

# Recibe o nome dun wrapper visual e imprime a súa axuda completa.
# Mantén nun único lugar o formato común, os controis interactivos e a relación
# co comando Gum orixinal. Non mostra unha interface nin altera o terminal por
# si mesma; cada wrapper chámaa ao procesar `-h|--help`.
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
    info)
      cat <<'EOF'
USO
  info [OPCIÓNS] MENSAXE [-- ARGUMENTOS DE GUM STYLE]

DESCRICIÓN
  Mostra unha mensaxe informativa coa cor principal de Gallaecia.

PARÁMETROS
  MENSAXE
      Texto informativo que se mostrará.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum style`.

RESULTADO
  Escribe a mensaxe formatada en stdout sen engadir separación vertical.

EXEMPLOS
  info "Instalando paquetes..."
  info "Detalles" -- --border rounded

COMANDO ORIXINAL
  Todo o situado despois de `--` reenvíase a `gum style`.
  Usa `info "Axuda" -- --help` para consultar as súas opcións.
EOF
      ;;
    title)
      cat <<'EOF'
USO
  title [OPCIÓNS] MENSAXE [-- ARGUMENTOS DE GUM STYLE]

DESCRICIÓN
  Mostra o título dunha sección en cor de acento, letra grosa e con separación.

PARÁMETROS
  MENSAXE
      Texto que identificará a sección.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum style`.

RESULTADO
  Escribe o título con padding superior e inferior.

EXEMPLOS
  title "Aplicacións principais"
  title "Resumo" -- --align center

COMANDO ORIXINAL
  Todo o situado despois de `--` reenvíase a `gum style`.
  Usa `title "Axuda" -- --help` para consultar as súas opcións.
EOF
      ;;
    warning)
      cat <<'EOF'
USO
  warning [OPCIÓNS] MENSAXE [-- ARGUMENTOS DE GUM STYLE]

DESCRICIÓN
  Mostra unha advertencia destacada sen interromper o proceso.

PARÁMETROS
  MENSAXE
      Aviso que se mostrará ao usuario.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum style`.

RESULTADO
  Escribe a advertencia coa cor correspondente e devolve o código de Gum.

EXEMPLOS
  warning "A operación pode tardar."
  warning "Revisa a configuración" -- --border rounded

COMANDO ORIXINAL
  Todo o situado despois de `--` reenvíase a `gum style`.
  Usa `warning "Axuda" -- --help` para consultar as súas opcións.
EOF
      ;;
    error)
      cat <<'EOF'
USO
  error [OPCIÓNS] MENSAXE [-- ARGUMENTOS DE GUM STYLE]

DESCRICIÓN
  Mostra un erro recuperable sen finalizar o proceso actual.

PARÁMETROS
  MENSAXE
      Descrición do erro que se mostrará.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum style`.

RESULTADO
  Escribe a mensaxe coa cor de erro e devolve o código de Gum.

EXEMPLOS
  error "Non se puido ler o ficheiro."
  error "Operación incompleta" -- --border double

COMANDO ORIXINAL
  Todo o situado despois de `--` reenvíase a `gum style`.
  Usa `error "Axuda" -- --help` para consultar as súas opcións.
EOF
      ;;
    success)
      cat <<'EOF'
USO
  success [OPCIÓNS] MENSAXE [-- ARGUMENTOS DE GUM STYLE]

DESCRICIÓN
  Mostra unha mensaxe de operación completada coa cor de éxito e separación.

PARÁMETROS
  MENSAXE
      Resultado satisfactorio que se mostrará.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum style`.

RESULTADO
  Escribe a mensaxe con padding superior e inferior.

EXEMPLOS
  success "Instalación completada."
  success "Todo listo" -- --align center

COMANDO ORIXINAL
  Todo o situado despois de `--` reenvíase a `gum style`.
  Usa `success "Axuda" -- --help` para consultar as súas opcións.
EOF
      ;;
    fail)
      cat <<'EOF'
USO
  fail [OPCIÓNS] MENSAXE [-- ARGUMENTOS DE GUM STYLE]

DESCRICIÓN
  Mostra un erro fatal e finaliza inmediatamente o proceso.

PARÁMETROS
  MENSAXE
      Motivo polo que o proceso non pode continuar.

OPCIÓNS
  -h, --help
      Mostra esta axuda sen finalizar cun erro.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum style`.

RESULTADO
  Escribe a mensaxe con padding superior e finaliza co código 1.

EXEMPLOS
  fail "Non se pode continuar."
  fail "Dependencia ausente" -- --border thick

COMANDO ORIXINAL
  Todo o situado despois de `--` reenvíase a `gum style`.
  Usa `fail --help` para consultar esta axuda sen finalizar o proceso.

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
  --header TEXTO
      Cabeceira mostrada sobre as opcións.

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
  gum_choose --header "Escolle unha ferramenta:" "Git" "Docker"
  gum_choose --header "Escolle varias:" "Git" "Docker" -- --no-limit

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
  --header TEXTO
      Cabeceira mostrada sobre a entrada.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum input`.

RESULTADO
  Escribe en stdout o texto introducido.
  Devolve un código distinto de 0 se o usuario cancela.

EXEMPLOS
  gum_input
  gum_input --header "Nome" -- --placeholder "Escribe o teu nome"
  gum_input --header "Contrasinal" -- --password

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
  --header TEXTO
      Cabeceira mostrada sobre o filtro.

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
  printf '%s\n' A B C | gum_filter --header "Escolle:" -- --no-limit

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
  --header TEXTO
      Cabeceira mostrada sobre o editor.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum write`.

RESULTADO
  Escribe en stdout o texto introducido.
  Devolve un código distinto de 0 se o usuario cancela.

EXEMPLOS
  gum_write
  gum_write --header "Descrición" -- --height 10 --show-line-numbers

COMANDO ORIXINAL
  Os argumentos de Gum tamén se aceptan directamente por compatibilidade,
  pero recoméndase escribilos despois de `--`.

  gum_write -- --help
EOF
      ;;
    gum_file)
      cat <<'EOF'
USO
  gum_file [OPCIÓNS] [RUTA] [-- ARGUMENTOS DE GUM FILE]

DESCRICIÓN
  Permite navegar e seleccionar un ficheiro ou directorio coa paleta de
  Gallaecia.

PARÁMETROS
  [RUTA]
      Directorio desde o que comezará a navegación.

OPCIÓNS
  --header TEXTO
      Cabeceira mostrada sobre o selector.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum file`.

CONTROIS
  Frechas ou h/j/k/l
      Navega polos directorios e elementos.

  Enter
      Abre un directorio ou confirma a selección.

  q ou Esc
      Cancela a selección.

RESULTADO
  Escribe en stdout a ruta seleccionada.
  Devolve un código distinto de 0 se o usuario cancela.

EXEMPLOS
  gum_file ~/.config
  gum_file --header "Escolle un ficheiro:" "$HOME" -- --file --all
  gum_file "$HOME" -- --directory

COMANDO ORIXINAL
  Os argumentos de Gum tamén se aceptan directamente por compatibilidade,
  pero recoméndase escribilos despois de `--`.

  gum_file . -- --help
EOF
      ;;
    gum_folder)
      cat <<'EOF'
USO
  gum_folder [OPCIÓNS] [RUTA] [-- ARGUMENTOS DE GUM FILE]

DESCRICIÓN
  Permite navegar e seleccionar unicamente un directorio coa paleta de
  Gallaecia. Reutiliza `gum_file` con `--directory --file=false` por defecto.

PARÁMETROS
  [RUTA]
      Directorio desde o que comezará a navegación.

OPCIÓNS
  --header TEXTO
      Cabeceira mostrada sobre o selector.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum file`.

CONTROIS
  Frechas ou h/j/k/l
      Navega polos directorios.

  Enter
      Abre ou confirma o directorio seleccionado.

  q ou Esc
      Cancela a selección.

RESULTADO
  Escribe en stdout a ruta do directorio seleccionado.
  Devolve un código distinto de 0 se o usuario cancela.

EXEMPLOS
  gum_folder
  gum_folder --header "Escolle un directorio:" "$HOME" -- --all

COMANDO ORIXINAL
  Os argumentos de Gum tamén se aceptan directamente por compatibilidade,
  pero recoméndase escribilos despois de `--`.

  gum_folder . -- --help
EOF
      ;;
    gum_spin)
      cat <<'EOF'
USO
  gum_spin [OPCIÓNS] -- COMANDO...

DESCRICIÓN
  Mostra un indicador de progreso mentres executa un comando.

PARÁMETROS
  COMANDO...
      Comando e argumentos que se executarán.

OPCIÓNS
  --title TEXTO
      Texto mostrado xunto ao indicador. O predeterminado é «Procesando...».

  --spinner VALOR
      Tipo de indicador admitido por Gum. O predeterminado é `dot`.

  --timeout VALOR
      Tempo máximo admitido por Gum, por exemplo `30s` ou `2m`.

  --show-error
      Mostra a saída do comando unicamente cando falla.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper e introduce o comando.

RESULTADO
  Devolve o código de saída do comando ou un código distinto de 0 se Gum falla.

EXEMPLOS
  gum_spin --title "Actualizando..." -- git pull
  gum_spin --show-error --timeout 30s -- curl -fLO URL

COMANDO ORIXINAL
  Todo o situado despois de `--` execútase directamente como comando.
  As opcións de `gum spin` limítanse ás documentadas polo wrapper para non
  mesturalas cos argumentos do comando.
EOF
      ;;
    gum_pager)
      cat <<'EOF'
USO
  gum_pager [OPCIÓNS] [CONTIDO] [-- ARGUMENTOS DE GUM PAGER]

DESCRICIÓN
  Mostra contido longo nun visor interactivo coa paleta de Gallaecia.

PARÁMETROS
  [CONTIDO]
      Texto que se mostrará. Tamén se pode recibir por stdin.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum pager`.

CONTROIS
  Frechas, j/k, PgUp ou PgDn
      Despraza o contido.

  /
      Busca dentro do contido.

  q ou Esc
      Pecha o visor.

RESULTADO
  Mostra o contido e devolve o código de saída de `gum pager`.

EXEMPLOS
  gum_pager < README.md
  git diff | gum_pager -- --show-line-numbers

COMANDO ORIXINAL
  Os argumentos de Gum tamén se aceptan directamente por compatibilidade,
  pero recoméndase escribilos despois de `--`.

  printf '%s\n' exemplo | gum_pager -- --help
EOF
      ;;
    gum_table)
      cat <<'EOF'
USO
  gum_table [OPCIÓNS] [-- ARGUMENTOS DE GUM TABLE]

DESCRICIÓN
  Presenta datos CSV recibidos por stdin ou desde un ficheiro como unha táboa.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum table`.

CONTROIS
  Frechas ou j/k
      Move a selección polas filas.

  Enter
      Confirma a fila seleccionada.

  q ou Esc
      Cancela a selección.

RESULTADO
  Escribe a fila seleccionada, ou debuxa unha táboa estática con `--print`.
  Devolve un código distinto de 0 se o usuario cancela.

EXEMPLOS
  printf '%s\n' 'Nome,Estado' 'Git,OK' | gum_table -- --print
  gum_table -- --file datos.csv --return-column 1

COMANDO ORIXINAL
  Os argumentos de Gum tamén se aceptan directamente por compatibilidade,
  pero recoméndase escribilos despois de `--`.

  gum_table -- --help
EOF
      ;;
    gum_format)
      cat <<'EOF'
USO
  gum_format [OPCIÓNS] [TEXTO...] [-- ARGUMENTOS DE GUM FORMAT]

DESCRICIÓN
  Renderiza Markdown, código, templates ou emoji mediante `gum format`.

PARÁMETROS
  [TEXTO...]
      Contido que se renderizará. Tamén se pode recibir por stdin.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum format`.

RESULTADO
  Escribe en stdout o contido formatado e devolve o código de `gum format`.

EXEMPLOS
  gum_format '# Título'
  printf '%s\n' 'print("Ola")' | gum_format -- --type code --language python

COMANDO ORIXINAL
  Os argumentos de Gum tamén se aceptan directamente por compatibilidade,
  pero recoméndase escribilos despois de `--`.

  gum_format exemplo -- --help
EOF
      ;;
    gum_join)
      cat <<'EOF'
USO
  gum_join [OPCIÓNS] TEXTO... [-- ARGUMENTOS DE GUM JOIN]

DESCRICIÓN
  Une bloques de texto, mesmo multilínea, en horizontal ou vertical.

PARÁMETROS
  TEXTO...
      Dous ou máis bloques que se unirán.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum join`.

RESULTADO
  Escribe en stdout os bloques unidos e devolve o código de `gum join`.

EXEMPLOS
  gum_join "Un" "Dous" -- --horizontal
  gum_join "Cabeceira" "Contido" -- --vertical --align center

COMANDO ORIXINAL
  Os argumentos de Gum tamén se aceptan directamente por compatibilidade,
  pero recoméndase escribilos despois de `--`.

  gum_join exemplo -- --help
EOF
      ;;
    gum_log)
      cat <<'EOF'
USO
  gum_log [OPCIÓNS] MENSAXE... [-- ARGUMENTOS DE GUM LOG]

DESCRICIÓN
  Escribe mensaxes con nivel, hora ou campos estruturados mediante `gum log`.

PARÁMETROS
  MENSAXE...
      Texto principal do rexistro.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións do helper. Todo o posterior reenvíase a `gum log`.

RESULTADO
  Escribe o rexistro en stderr ou no ficheiro indicado e devolve o código de
  `gum log`.

EXEMPLOS
  gum_log "Instalación iniciada" -- --level info --time kitchen
  gum_log "Paquete ausente" -- --level warn --prefix gallaecia

COMANDO ORIXINAL
  Os argumentos de Gum tamén se aceptan directamente por compatibilidade,
  pero recoméndase escribilos despois de `--`.

  gum_log exemplo -- --help
EOF
      ;;
  esac
}

# Recibe texto e opcións compatibles con `gum style`, aplica a paleta base e
# reenvía os argumentos sen reinterpretalos. É a capa común usada polas mensaxes
# seguintes; imprime o renderizado e conserva o código de saída de Gum.
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

# Recibe texto e opcións de estilo e mostra unha mensaxe informativa coa cor
# principal do tema. Reutiliza `gum_style`, non engade separación vertical e
# conserva a saída e o código devoltos por Gum.
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

# Recibe o texto dunha sección e móstrao en cor de acento e letra grosa.
# Engade padding superior e inferior mediante Gum, de modo que a separación
# desaparece coa interface interactiva e non deixa liñas permanentes no terminal.
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

# Recibe unha mensaxe e móstraa coa cor de advertencia e letra grosa.
# Non cambia o fluxo do script nin forza un código de erro; o chamador decide
# se o aviso debe ir acompañado doutra acción.
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

# Recibe unha mensaxe e represéntaa coa cor de erro e letra grosa.
# A diferenza de `fail`, non termina o proceso: devolve o resultado de Gum para
# que poida empregarse ao informar dun fallo recuperable.
error() {
  local original_args=()

  while (($#)); do
    case "$1" in
      -h|--help)
        _ui_help error
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
	"${original_args[@]}"
}

# Recibe unha mensaxe final ou de paso completado e móstraa coa cor de éxito.
# Engade padding vertical para delimitar o bloque e conserva o código de Gum.
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

# Recibe unha mensaxe fatal, móstraa coa cor de erro e padding superior e remata
# o proceso completo con código 1. Debe reservarse para puntos de entrada onde
# xa non sexa posible recuperar; non se pode tratar como un simple `return`.
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

# Recibe a pregunta e calquera opción adicional de `gum confirm`, fixa as
# etiquetas galegas e a paleta común e mostra a interacción con padding superior.
# Devolve 0 para «Si» e un código distinto para «No» ou cancelación, sen imprimir
# unha resposta que o chamador teña que analizar.
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
	--prompt.foreground="$PROMPT_FOREGROUND" \
	--prompt.background="$PROMPT_BACKGROUND" \
	--selected.foreground="$SELECTED_FOREGROUND" \
	--selected.background="$SELECTED_BACKGROUND" \
	--unselected.foreground="$UNSELECTED_FOREGROUND" \
	--unselected.background="$UNSELECTED_BACKGROUND" \
	--padding="1 0 0 0" \
	"${original_args[@]}"
}

# Recibe as opcións que entende `gum choose`, aplica cores, axuda de controis e
# padding superior. Imprime en stdout a selección de Gum —unha ou varias liñas
# se se activa selección múltiple— e conserva o seu código de cancelación.
gum_choose() {
  local header=""
  local original_args=()

  while (($#)); do
    case "$1" in
      --header)
        if [ $# -lt 2 ]; then
          printf 'Falta TEXTO para --header. Usa gum_choose --help.\n' >&2
          return 1
        fi
        header="$2"
        shift
        ;;
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
	--header="$header" \
	--show-help \
	--cursor.foreground="$CURSOR_FOREGROUND" \
	--cursor.background="$CURSOR_BACKGROUND" \
	--header.foreground="$HEADER_FOREGROUND" \
	--header.background="$HEADER_BACKGROUND" \
	--item.foreground="$ITEM_FOREGROUND" \
	--item.background="$ITEM_BACKGROUND" \
	--selected.foreground="$SELECTED_FOREGROUND" \
	--selected.background="$SELECTED_BACKGROUND" \
	--padding="1 0 0 0" \
	"${original_args[@]}"
}

# Recibe o prompt e as opcións propias de `gum input`, aplica a paleta común e
# engade padding superior. Escribe en stdout o texto introducido e conserva o
# código de saída, polo que unha substitución de comando pode detectar cancelacións.
gum_input() {
  local header=""
  local original_args=()

  while (($#)); do
    case "$1" in
      --header)
        if [ $# -lt 2 ]; then
          printf 'Falta TEXTO para --header. Usa gum_input --help.\n' >&2
          return 1
        fi
        header="$2"
        shift
        ;;
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
	--header="$header" \
	--prompt.foreground="$PROMPT_FOREGROUND" \
	--prompt.background="$PROMPT_BACKGROUND" \
	--placeholder.foreground="$MUTED_FOREGROUND" \
	--placeholder.background="$MUTED_BACKGROUND" \
	--cursor.foreground="$CURSOR_FOREGROUND" \
	--cursor.background="$CURSOR_BACKGROUND" \
	--header.foreground="$HEADER_FOREGROUND" \
	--header.background="$HEADER_BACKGROUND" \
	--padding="1 0 0 0" \
	"${original_args[@]}"
}

# Recibe por stdin ou por argumentos unha lista para `gum filter` e aplica cores
# a procura, cursor e selección. Imprime as entradas escollidas e conserva o
# código de Gum. Non engade padding porque o filtro ocupa a pantalla completa.
gum_filter() {
  local header=""
  local original_args=()

  while (($#)); do
    case "$1" in
      --header)
        if [ $# -lt 2 ]; then
          printf 'Falta TEXTO para --header. Usa gum_filter --help.\n' >&2
          return 1
        fi
        header="$2"
        shift
        ;;
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

  # Os fondos baleiros evitan estilos herdados. A coincidencia conserva o seu
  # primeiro plano, pero non pode fixar un fondo propio: Lip Gloss insíreo
  # dentro do estilo da fila e o seu reset cortaría o fondo do cursor xusto
  # despois do primeiro tramo coincidente.
  gum filter \
	--header="$header" \
	--show-help \
	--indicator.foreground="$CURSOR_FOREGROUND" \
	--indicator.background="$CURSOR_BACKGROUND" \
	--selected-indicator.foreground="$SELECTED_FOREGROUND" \
	--selected-indicator.background="$SELECTED_BACKGROUND" \
	--unselected-prefix.foreground="$UNSELECTED_FOREGROUND" \
	--unselected-prefix.background="" \
	--header.foreground="$HEADER_FOREGROUND" \
	--header.background="$HEADER_BACKGROUND" \
	--text.foreground="$ITEM_FOREGROUND" \
	--text.background="$ITEM_BACKGROUND" \
	--cursor-text.foreground="$SELECTED_FOREGROUND" \
	--cursor-text.background="$SELECTED_BACKGROUND" \
	--match.foreground="$ACCENT_FOREGROUND" \
	--match.background="" \
	--prompt.foreground="$PROMPT_FOREGROUND" \
	--prompt.background="$PROMPT_BACKGROUND" \
	--placeholder.foreground="$MUTED_FOREGROUND" \
	--placeholder.background="$MUTED_BACKGROUND" \
	"${original_args[@]}"
}

# Recibe as opcións de `gum write` e abre un editor de texto multilínea coa
# paleta do proxecto. A saída editada escríbese en stdout e o código de Gum
# permite distinguir unha confirmación dunha cancelación.
gum_write() {
  local header=""
  local original_args=()

  while (($#)); do
    case "$1" in
      --header)
        if [ $# -lt 2 ]; then
          printf 'Falta TEXTO para --header. Usa gum_write --help.\n' >&2
          return 1
        fi
        header="$2"
        shift
        ;;
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
	--header="$header" \
	--base.foreground="$FOREGROUND" \
	--base.background="$BACKGROUND" \
	--cursor-line-number.foreground="$MUTED_FOREGROUND" \
	--cursor-line-number.background="$MUTED_BACKGROUND" \
	--cursor-line.foreground="$SELECTED_FOREGROUND" \
	--cursor-line.background="$SELECTED_BACKGROUND" \
	--cursor.foreground="$CURSOR_FOREGROUND" \
	--cursor.background="$CURSOR_BACKGROUND" \
	--end-of-buffer.foreground="$MUTED_FOREGROUND" \
	--end-of-buffer.background="$MUTED_BACKGROUND" \
	--line-number.foreground="$MUTED_FOREGROUND" \
	--line-number.background="$MUTED_BACKGROUND" \
	--header.foreground="$HEADER_FOREGROUND" \
	--header.background="$HEADER_BACKGROUND" \
	--placeholder.foreground="$MUTED_FOREGROUND" \
	--placeholder.background="$MUTED_BACKGROUND" \
	--prompt.foreground="$PROMPT_FOREGROUND" \
	--prompt.background="$PROMPT_BACKGROUND" \
	--padding="1 0 0 0" \
	"${original_args[@]}"
}

# Recibe unha ruta inicial e opcións de `gum file`, aplica cores distintas a
# ficheiros, directorios, enlaces e metadatos, e engade padding superior.
# Imprime a ruta escollida e devolve o código de Gum sen copiar nin alterar nada.
gum_file() {
  local header=""
  local original_args=()

  while (($#)); do
    case "$1" in
      --header)
        if [ $# -lt 2 ]; then
          printf 'Falta TEXTO para --header. Usa gum_file --help.\n' >&2
          return 1
        fi
        header="$2"
        shift
        ;;
      -h|--help)
        _ui_help gum_file
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

  gum file \
	--header="$header" \
	--cursor.foreground="$CURSOR_FOREGROUND" \
	--cursor.background="$CURSOR_BACKGROUND" \
	--symlink.foreground="$WARNING_FOREGROUND" \
	--symlink.background="$BACKGROUND" \
	--directory.foreground="$ACCENT_FOREGROUND" \
	--directory.background="$BACKGROUND" \
	--file.foreground="$ITEM_FOREGROUND" \
	--file.background="$ITEM_BACKGROUND" \
	--permissions.foreground="$MUTED_FOREGROUND" \
	--permissions.background="$MUTED_BACKGROUND" \
	--selected.foreground="$SELECTED_FOREGROUND" \
	--selected.background="$SELECTED_BACKGROUND" \
	--file-size.foreground="$MUTED_FOREGROUND" \
	--file-size.background="$MUTED_BACKGROUND" \
	--header.foreground="$HEADER_FOREGROUND" \
	--header.background="$HEADER_BACKGROUND" \
	--padding="1 0 0 0" \
	"${original_args[@]}"
}

# Recibe unha ruta inicial e opcións de `gum file`, antepón os modos que
# permiten confirmar directorios e impiden escoller ficheiros, e delega en
# `gum_file` para conservar a mesma paleta, padding e código de cancelación.
gum_folder() {
  local header=""
  local original_args=()

  while (($#)); do
    case "$1" in
      --header)
        if [ $# -lt 2 ]; then
          printf 'Falta TEXTO para --header. Usa gum_folder --help.\n' >&2
          return 1
        fi
        header="$2"
        shift
        ;;
      -h|--help)
        _ui_help gum_folder
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

  gum_file --header "$header" -- \
	--directory \
	--file=false \
	"${original_args[@]}"
}

# Recibe opcións propias do spinner e, obrigatoriamente tras `--`, un comando.
# Constrúe o indicador coa paleta común, executa os argumentos sen `eval` e
# conserva o código do comando envolto. `--show-error` e `--timeout` pásanse
# de forma controlada a Gum; esta función non interpreta a saída do proceso.
gum_spin() {
  local title_text="Procesando..."
  local spinner="dot"
  local timeout=""
  local show_error=false
  local command_args=()
  local gum_args=()

  while (($#)); do
    case "$1" in
      --title)
        if [ $# -lt 2 ]; then
          printf 'Falta TEXTO para --title. Usa gum_spin --help.\n' >&2
          return 1
        fi
        title_text="$2"
        shift
        ;;
      --spinner)
        if [ $# -lt 2 ]; then
          printf 'Falta VALOR para --spinner. Usa gum_spin --help.\n' >&2
          return 1
        fi
        spinner="$2"
        shift
        ;;
      --timeout)
        if [ $# -lt 2 ]; then
          printf 'Falta VALOR para --timeout. Usa gum_spin --help.\n' >&2
          return 1
        fi
        timeout="$2"
        shift
        ;;
      --show-error)
        show_error=true
        ;;
      -h|--help)
        _ui_help gum_spin
        return 0
        ;;
      --)
        shift
        command_args=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa gum_spin --help.\n' "$1" >&2
        return 1
        ;;
      *)
        printf 'O comando debe ir despois de --. Usa gum_spin --help.\n' >&2
        return 1
        ;;
    esac
    shift
  done

  if [ ${#command_args[@]} -eq 0 ]; then
    printf 'gum_spin require un COMANDO despois de --.\n' >&2
    return 1
  fi

  if $show_error; then
    gum_args+=(--show-error)
  fi
  if [ -n "$timeout" ]; then
    gum_args+=(--timeout "$timeout")
  fi

  gum spin \
	--title="$title_text" \
	--spinner="$spinner" \
	--spinner.foreground="$ACCENT_FOREGROUND" \
	--spinner.background="$BACKGROUND" \
	--title.foreground="$FOREGROUND" \
	--title.background="$BACKGROUND" \
	--padding="1 0 0 0" \
	"${gum_args[@]}" \
	-- "${command_args[@]}"
}

# Recibe texto por stdin e opcións de `gum pager`, abre un visor coa paleta común
# e reenvía todos os controis ao comando orixinal. Non transforma o contido e
# conserva o código de saída ou cancelación do paginador.
gum_pager() {
  local original_args=()

  while (($#)); do
    case "$1" in
      -h|--help)
        _ui_help gum_pager
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

  gum pager \
	--foreground="$FOREGROUND" \
	--background="$BACKGROUND" \
	--line-number.foreground="$MUTED_FOREGROUND" \
	--line-number.background="$MUTED_BACKGROUND" \
	--match.foreground="$ACCENT_FOREGROUND" \
	--match.background="$BACKGROUND" \
	--match-highlight.foreground="$SELECTED_FOREGROUND" \
	--match-highlight.background="$SELECTED_BACKGROUND" \
	--help.foreground="$MUTED_FOREGROUND" \
	--help.background="$MUTED_BACKGROUND" \
	"${original_args[@]}"
}

# Recibe datos e opcións compatibles con `gum table`, engade as cores de bordos,
# cabeceiras, celas e selección e imprime a fila que Gum devolva. Pode funcionar
# como táboa estática ou selector segundo as opcións reenviadas.
gum_table() {
  local original_args=()

  while (($#)); do
    case "$1" in
      -h|--help)
        _ui_help gum_table
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

  gum table \
	--border.foreground="$BORDER_FOREGROUND" \
	--border.background="$BORDER_BACKGROUND" \
	--cell.foreground="$ITEM_FOREGROUND" \
	--cell.background="$ITEM_BACKGROUND" \
	--header.foreground="$HEADER_FOREGROUND" \
	--header.background="$HEADER_BACKGROUND" \
	--selected.foreground="$SELECTED_FOREGROUND" \
	--selected.background="$SELECTED_BACKGROUND" \
	"${original_args[@]}"
}

# Recibe directamente o tipo de formato, o contido e as opcións de `gum format`.
# Non impón cores porque cada formato controla o seu propio renderizado; limita
# o wrapper a ofrecer axuda uniforme e conservar stdout e o código de Gum.
gum_format() {
  local original_args=()

  while (($#)); do
    case "$1" in
      -h|--help)
        _ui_help gum_format
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

  gum format "${original_args[@]}"
}

# Recibe bloques e opcións de `gum join` e reenvíaos literalmente.
# Imprime a composición final en stdout sen engadir estilo propio, para que os
# bloques xa renderizados conserven as súas cores e dimensións.
gum_join() {
  local original_args=()

  while (($#)); do
    case "$1" in
      -h|--help)
        _ui_help gum_join
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

  gum join "${original_args[@]}"
}

# Recibe unha mensaxe e opcións de `gum log`, aplica a paleta aos distintos
# compoñentes do rexistro e deixa que Gum decida o destino final. Conserva o
# código de saída e admite niveis, prefixos e pares chave-valor sen interpretalos.
gum_log() {
  local original_args=()

  while (($#)); do
    case "$1" in
      -h|--help)
        _ui_help gum_log
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

  gum log \
	--level.foreground="$ACCENT_FOREGROUND" \
	--level.background="$BACKGROUND" \
	--time.foreground="$MUTED_FOREGROUND" \
	--time.background="$MUTED_BACKGROUND" \
	--prefix.foreground="$WARNING_FOREGROUND" \
	--prefix.background="$BACKGROUND" \
	--message.foreground="$FOREGROUND" \
	--message.background="$BACKGROUND" \
	--key.foreground="$ACCENT_FOREGROUND" \
	--key.background="$BACKGROUND" \
	--value.foreground="$FOREGROUND" \
	--value.background="$BACKGROUND" \
	--separator.foreground="$MUTED_FOREGROUND" \
	--separator.background="$MUTED_BACKGROUND" \
	"${original_args[@]}"
}

# Completa as opcións propias dos wrappers de Gum. Os argumentos posteriores a
# `--` quedan para Gum; no spinner, o primeiro deles complétase como comando.
_ui_completion() {
  local command_name="${COMP_WORDS[0]:-}"
  local current="${COMP_WORDS[COMP_CWORD]:-}"
  local options=""
  local separator_index=-1
  local index

  COMPREPLY=()
  for ((index = 1; index < COMP_CWORD; index++)); do
    if [ "${COMP_WORDS[index]}" = "--" ]; then
      separator_index="$index"
      break
    fi
  done
  if [ "$separator_index" -ge 0 ]; then
    if [ "$command_name" = "gum_spin" ] &&
      [ "$COMP_CWORD" -eq $((separator_index + 1)) ]; then
      mapfile -t COMPREPLY < <(compgen -c -- "$current")
    else
      compopt -o default
    fi
    return
  fi

  case "$command_name" in
    gum_confirm|gum_choose|gum_input|gum_filter|gum_write)
      options="--header -h --help --"
      ;;
    gum_file)
      options="--header -h --help --"
      if [[ "$current" != -* ]]; then
        compopt -o filenames
        mapfile -t COMPREPLY < <(compgen -f -- "$current")
        return
      fi
      ;;
    gum_folder)
      options="--header -h --help --"
      if [[ "$current" != -* ]]; then
        compopt -o filenames
        mapfile -t COMPREPLY < <(compgen -d -- "$current")
        return
      fi
      ;;
    gum_spin)
      options="--title --spinner --timeout --show-error -h --help --"
      ;;
    gum_style|info|title|warning|error|success|fail|gum_pager|gum_table|gum_format|gum_join|gum_log)
      options="-h --help --"
      ;;
  esac

  mapfile -t COMPREPLY < <(compgen -W "$options" -- "$current")
}

# Rexistra os completados deste módulo unicamente nas shells interactivas.
if [[ $- == *i* ]]; then
  complete -F _ui_completion \
    gum_style info title warning error success fail \
    gum_confirm gum_choose gum_input gum_filter gum_write gum_file gum_folder \
    gum_spin gum_pager gum_table gum_format gum_join gum_log
fi
