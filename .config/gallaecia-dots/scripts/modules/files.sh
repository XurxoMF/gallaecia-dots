# shellcheck shell=bash

replace_path() {
  local source="$1"
  local target="$2"

  rm -rf "$target" && cp -r "$source" "$target"
}

replace_file() {
  local source="$1"
  local target="$2"

  rm -f "$target" && cp "$source" "$target"
}
