# shellcheck shell=bash

# Rutas do repo.
DOTFILES_DIR="$HOME/.dotfiles"
UPDATES_DIR="$DOTFILES_DIR/updates"

# Estado da instalación.
STATE_DIR="$HOME/.local/share/gallaecia-dots"
CURRENT_VERSION_FILE="$STATE_DIR/version"
INSTALLED_VERSIONS_FILE="$STATE_DIR/versions-instaladas"
INSTALLED_MARK_FILE="$STATE_DIR/instalado"

# Garante que existe o directorio onde gardamos o estado da instalación.
# `versions-instaladas` é unha versión por liña: base, 3.0.1, 3.0.2...
ensure_gallaecia_state_dir() {
  mkdir -p "$STATE_DIR" &&
  touch "$INSTALLED_VERSIONS_FILE"
}

# Devolve éxito se a versión recibida xa aparece en versions-instaladas.
is_version_installed() {
  local version="$1"

  [ -f "$INSTALLED_VERSIONS_FILE" ] &&
  grep -qxF "$version" "$INSTALLED_VERSIONS_FILE"
}

# Devolve éxito se hai calquera versión rexistrada.
# Úsase para saber se debemos preguntar entre actualizar ou reinstalar.
has_installed_versions() {
  [ -s "$INSTALLED_VERSIONS_FILE" ]
}

# Baleira o rexistro de versións para forzar unha reinstalación desde cero.
# Non borra configs reais: só fai que os scripts pensen que nada foi aplicado.
clear_installed_versions() {
  ensure_gallaecia_state_dir &&
  : > "$INSTALLED_VERSIONS_FILE" &&
  rm -f "$CURRENT_VERSION_FILE"
}

# Marca unha versión como instalada sen duplicala se xa estaba rexistrada.
mark_version_installed() {
  local version="$1"

  ensure_gallaecia_state_dir &&
  if ! is_version_installed "$version"; then
    printf '%s\n' "$version" >> "$INSTALLED_VERSIONS_FILE"
  fi
}

# Devolve todas as versións dispoñibles, comezando por `base`.
# Os updates gardan un nome estilo 3_0_1.sh, que aquí se transforma a 3.0.1.
list_available_versions() {
  local update_file
  local version_name

  printf '%s\n' "base"

  if [ ! -d "$UPDATES_DIR" ]; then
    return 0
  fi

  while IFS= read -r update_file; do
    [ -n "$update_file" ] || continue

    version_name="${update_file##*/}"
    version_name="${version_name%.sh}"
    version_name="${version_name//_/.}"

    printf '%s\n' "$version_name"
  done < <(find "$UPDATES_DIR" -maxdepth 1 -type f -name '[0-9]*_[0-9]*_[0-9]*.sh' | sort -V)
}

# Marca de golpe todas as versións dispoñibles.
mark_all_available_versions() {
  local version

  ensure_gallaecia_state_dir || return 1

  while IFS= read -r version; do
    [ -n "$version" ] || continue
    mark_version_installed "$version"
  done < <(list_available_versions)
}

# Devolve a última versión dispoñible segundo a listaxe ordenada.
# Úsase para gardar a versión actual tras completar unha instalación base.
latest_available_version() {
  list_available_versions | tail -n 1
}

# Garda a versión actual e a data da última instalación/update aplicado.
set_gallaecia_current_version() {
  local version="$1"

  ensure_gallaecia_state_dir &&
  printf '%s\n' "$version" > "$CURRENT_VERSION_FILE" &&
  date +%d-%m-%Y > "$INSTALLED_MARK_FILE"
}
