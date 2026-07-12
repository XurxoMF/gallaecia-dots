# shellcheck shell=bash

GALLAECIA_STATE_DIR="${GALLAECIA_STATE_DIR:-$HOME/.local/share/gallaecia-dots}"
GALLAECIA_CURRENT_VERSION_FILE="${GALLAECIA_CURRENT_VERSION_FILE:-$GALLAECIA_STATE_DIR/version}"
GALLAECIA_INSTALLED_VERSIONS_FILE="${GALLAECIA_INSTALLED_VERSIONS_FILE:-$GALLAECIA_STATE_DIR/installed-versions}"

# Garante que existe o directorio onde gardamos o estado da instalación.
# `installed-versions` é unha versión por liña: base, 3.0.1, 3.0.2...
ensure_gallaecia_state_dir() {
  mkdir -p "$GALLAECIA_STATE_DIR" &&
  touch "$GALLAECIA_INSTALLED_VERSIONS_FILE"
}

# Devolve éxito se a versión recibida xa aparece en installed-versions.
is_version_installed() {
  local version="$1"

  [ -f "$GALLAECIA_INSTALLED_VERSIONS_FILE" ] &&
  grep -qxF "$version" "$GALLAECIA_INSTALLED_VERSIONS_FILE"
}

# Devolve éxito se hai calquera versión rexistrada.
# Úsase para saber se debemos preguntar entre actualizar ou reinstalar.
has_installed_versions() {
  [ -s "$GALLAECIA_INSTALLED_VERSIONS_FILE" ]
}

# Baleira o rexistro de versións para forzar unha reinstalación desde cero.
# Non borra configs reais: só fai que os scripts pensen que nada foi aplicado.
clear_installed_versions() {
  ensure_gallaecia_state_dir &&
  : > "$GALLAECIA_INSTALLED_VERSIONS_FILE" &&
  rm -f "$GALLAECIA_CURRENT_VERSION_FILE"
}

# Marca unha versión como instalada sen duplicala se xa estaba rexistrada.
mark_version_installed() {
  local version="$1"

  ensure_gallaecia_state_dir &&
  if ! is_version_installed "$version"; then
    printf '%s\n' "$version" >> "$GALLAECIA_INSTALLED_VERSIONS_FILE"
  fi
}

# Garda a versión actual e a data da última instalación/update aplicado.
set_gallaecia_current_version() {
  local version="$1"

  ensure_gallaecia_state_dir &&
  printf '%s\n' "$version" > "$GALLAECIA_CURRENT_VERSION_FILE" &&
  date +%d-%m-%Y > "$GALLAECIA_STATE_DIR/instalado"
}
