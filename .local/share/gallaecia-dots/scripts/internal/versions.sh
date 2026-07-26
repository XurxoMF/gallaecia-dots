# shellcheck shell=bash

###############################################################################
# NON USAR ESTAS FUNCIÓNS EN COMANDOS PERSONALIZADOS
#
# Este módulo é API interna do sistema de migracións de Gallaecia Dots. Cambia
# o rexistro de versións instaladas e pode alterar o fluxo de actualización.
# Para scripts propios usa os módulos públicos de `scripts/modules/`.
###############################################################################

###############################################################################
# MAPA DO ESTADO DE VERSIÓNS
#
# O sistema mantén tres ficheiros en ~/.local/share/gallaecia-dots:
#
#   versions-instaladas -> historial, unha versión ou `base` por liña.
#   version             -> última versión que se mostra ao usuario.
#   instalado           -> data da última instalación/actualización completa.
#
# Fluxo dunha actualización:
#
#   list_available_versions
#          │
#          ▼
#   install.sh filtra con is_version_installed
#          │
#          ▼
#   executa updates/X_Y_Z.sh
#          │
#          ▼
#   mark_version_installed + set_gallaecia_current_version
#
# Nunha instalación base, mark_all_available_versions evita reproducir
# migracións históricas. Nun reinstall, clear_installed_versions borra só este
# estado; non elimina directamente configuracións nin paquetes.
###############################################################################

# Avisa de que estes helpers só deben empregarse no fluxo de actualización.
_versions_internal_help() {
  cat <<EOF
USO
  ${FUNCNAME[1]} -h|--help

DESCRICIÓN
  NON USAR: esta función pertence á API interna do sistema de versións.
  Pode modificar o estado de instalación e actualización de Gallaecia Dots.

OPCIÓNS
  -h, --help
      Mostra este aviso.

RESULTADO
  A axuda devolve 0 sen modificar o estado. O resto do comportamento forma
  parte do fluxo interno e non constitúe unha API pública.

EXEMPLOS
  ${FUNCNAME[1]} --help

ALTERNATIVAS
  Para comandos personalizados usa os helpers documentados de scripts/modules/.
EOF
}

# Rutas do repo.
DOTFILES_DIR="$HOME/.dotfiles"
UPDATES_DIR="$DOTFILES_DIR/updates"

# Estado da instalación.
STATE_DIR="$HOME/.local/share/gallaecia-dots"
CURRENT_VERSION_FILE="$STATE_DIR/version"
INSTALLED_VERSIONS_FILE="$STATE_DIR/versions-instaladas"
INSTALLED_MARK_FILE="$STATE_DIR/instalado"

# Crea STATE_DIR e o historial se faltan. Non engade ningunha versión.
# `versions-instaladas` é unha versión por liña: base, 3.0.1, 3.0.2...
ensure_gallaecia_state_dir() {
  mkdir -p "$STATE_DIR" &&
  touch "$INSTALLED_VERSIONS_FILE"
}

# Recibe unha versión exacta e busca unha liña completa igual no historial.
# Só consulta estado; non crea o ficheiro nin modifica a versión actual.
is_version_installed() {
  while (($#)); do
    case "$1" in
      -h|--help) _versions_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  local version="$1"

  [ -f "$INSTALLED_VERSIONS_FILE" ] &&
  grep -qxF "$version" "$INSTALLED_VERSIONS_FILE"
}

# Non recibe argumentos. Devolve 0 cando o historial existe e non está baleiro.
# install.sh úsao para distinguir unha instalación nova dunha xa existente.
has_installed_versions() {
  [ -s "$INSTALLED_VERSIONS_FILE" ]
}

# Prepara o estado, baleira o historial e retira CURRENT_VERSION_FILE para que a
# seguinte execución aplique a base. Non borra configuracións nin paquetes.
clear_installed_versions() {
  ensure_gallaecia_state_dir &&
  : > "$INSTALLED_VERSIONS_FILE" &&
  rm -f "$CURRENT_VERSION_FILE"
}

# Recibe unha versión, garante o estado e engádea como nova liña só se non
# figuraba. Non actualiza CURRENT_VERSION_FILE: o chamador faino cando remata o
# fluxo completo que corresponda.
mark_version_installed() {
  while (($#)); do
    case "$1" in
      -h|--help) _versions_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  local version="$1"

  ensure_gallaecia_state_dir &&
  if ! is_version_installed "$version"; then
    printf '%s\n' "$version" >> "$INSTALLED_VERSIONS_FILE"
  fi
}

# Imprime `base` e despois todas as migracións numéricas ordenadas con sort -V.
# Os nomes 3_0_1.sh transfórmanse en 3.0.1. Ficheiros que non cumpren o patrón,
# incluída a plantilla X_X_X.sh.example, ignóranse.
list_available_versions() {
  local update_file
  local version_name

  printf '%s\n' "base"

  if [ ! -d "$UPDATES_DIR" ]; then
    return 0
  fi

  while IFS= read -r update_file; do
    [ -n "$update_file" ] || continue

    # As expansións eliminan a ruta, o sufixo .sh e cambian 1_2_3 por 1.2.3.
    version_name="${update_file##*/}"
    version_name="${version_name%.sh}"
    version_name="${version_name//_/.}"

    printf '%s\n' "$version_name"
  # O patrón só acepta migracións numéricas e sort -V ordénaas por versión.
  done < <(find "$UPDATES_DIR" -maxdepth 1 -type f -name '[0-9]*_[0-9]*_[0-9]*.sh' | sort -V)
}

# Percorre a saída de list_available_versions e marca cada elemento.
# A base úsaa ao final dunha instalación nova para non executar despois
# migracións cuxo resultado xa está integrado no estado actual.
mark_all_available_versions() {
  local version

  ensure_gallaecia_state_dir || return 1

  while IFS= read -r version; do
    [ -n "$version" ] || continue
    mark_version_installed "$version"
  done < <(list_available_versions)
}

# Imprime a última liña da listaxe ordenada. Se non hai migracións, será `base`.
# Úsase como versión visible tras completar unha instalación base.
latest_available_version() {
  list_available_versions | tail -n 1
}

# Recibe a versión visible final, sobrescribe CURRENT_VERSION_FILE e rexistra a
# data actual en INSTALLED_MARK_FILE. Debe chamarse só tras completar o fluxo.
set_gallaecia_current_version() {
  while (($#)); do
    case "$1" in
      -h|--help) _versions_internal_help; return 0 ;;
      *) break ;;
    esac
  done

  local version="$1"

  ensure_gallaecia_state_dir &&
  printf '%s\n' "$version" > "$CURRENT_VERSION_FILE" &&
  date +%d-%m-%Y > "$INSTALLED_MARK_FILE"
}
