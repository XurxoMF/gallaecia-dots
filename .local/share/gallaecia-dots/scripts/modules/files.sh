# shellcheck shell=bash

# Substitúe unha carpeta/árbore completa.
# Úsase para configs que Gallaecia controla enteiras.
replace_path() {
  local source="$1"
  local target="$2"

  rm -rf "$target" && cp -r "$source" "$target"
}

# Substitúe un único ficheiro.
replace_file() {
  local source="$1"
  local target="$2"

  rm -f "$target" && cp "$source" "$target"
}
