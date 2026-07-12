# shellcheck shell=bash

# Substitúe unha carpeta/árbore completa.
# Úsase para configs que Gallaecia controla enteiras.
replace_path() {
  local source="$1"
  local target="$2"

  rm -rf "$target" && cp -r "$source" "$target"
}

# Copia unha árbore dentro doutra sen borrar o destino.
# Úsase para directorios que conteñen estado do usuario e non se pode perder.
merge_path() {
  local source="$1"
  local target="$2"

  mkdir -p "$target" &&
  cp -r "$source"/. "$target"/
}

# Substitúe un único ficheiro.
replace_file() {
  local source="$1"
  local target="$2"

  rm -f "$target" && cp "$source" "$target"
}
