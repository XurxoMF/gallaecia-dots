#!/usr/bin/env bash

# Colas de instalación compartidas polos scripts que usen este módulo.
# Cada choose_* engade aquí os paquetes escollidos, e logo o script final
# decide cando chamar yay/flatpak/pipx para instalalos.
pkgs_apps=()
flatpaks_apps=()
pipx_apps=()

# Resultado da última pregunta de apps.
# Bash non devolve arrays comodamente desde funcións, así que as funcións
# choose_required_category/choose_optional_category escriben aquí.
SELECTED_ENTRIES=()
DEFAULT_ENTRY=""

# Engade un paquete á lista pacman/AUR sen duplicalo.
add_pkg_app() {
  local package_name="$1"
  local app

  for app in "${pkgs_apps[@]}"; do
    if [ "$app" = "$package_name" ]; then
      return 0
    fi
  done

  pkgs_apps+=("$package_name")
}

# Engade un paquete á lista flatpak sen duplicalo.
add_flatpak_app() {
  local package_name="$1"
  local app

  for app in "${flatpaks_apps[@]}"; do
    if [ "$app" = "$package_name" ]; then
      return 0
    fi
  done

  flatpaks_apps+=("$package_name")
}

# Engade un paquete á lista pipx sen duplicalo.
add_pipx_app() {
  local package_name="$1"
  local app

  for app in "${pipx_apps[@]}"; do
    if [ "$app" = "$package_name" ]; then
      return 0
    fi
  done

  pipx_apps+=("$package_name")
}

# Comproba se un paquete xa foi escollido para instalar por pacman/AUR.
has_pkg_app() {
  local package_name="$1"
  local app

  for app in "${pkgs_apps[@]}"; do
    if [ "$app" = "$package_name" ]; then
      return 0
    fi
  done

  return 1
}

# Comproba se un paquete xa foi escollido para instalar por flatpak.
has_flatpak_app() {
  local package_name="$1"
  local app

  for app in "${flatpaks_apps[@]}"; do
    if [ "$app" = "$package_name" ]; then
      return 0
    fi
  done

  return 1
}

# Comproba se unha app xa foi escollida para instalar por pipx.
has_pipx_app() {
  local package_name="$1"
  local app

  for app in "${pipx_apps[@]}"; do
    if [ "$app" = "$package_name" ]; then
      return 0
    fi
  done

  return 1
}

# As entradas de apps usan este formato:
#
#   "tipo|Nome visible|paquetes|comando para Hypr/env|ficheiro .desktop"
#
# Exemplo:
#   "pkg|Nemo|nemo|nemo|nemo.desktop"
#   "pipx|SpotDL|spotdl|spotdl|"
#   "flatpak|Amberol|io.bassi.Amberol|amberol|io.bassi.Amberol.desktop"
#
# 1. tipo: onde se instala a app.
#    - pkg: pacman/AUR usando yay.
#    - flatpak: Flatpak desde Flathub.
#    - pipx: paquete Python instalado con pipx.
# 2. Nome visible: o que ve o usuario no menú de gum.
# 3. paquetes: un ou varios paquetes/IDs a instalar, separados por espazo.
# 4. comando: valor configurable para scripts, Hyprland, ENV, etc.
# 5. .desktop: ficheiro usado en mimeapps.list. Pode quedar baleiro se non aplica.
app_field() {
  local entry="$1"
  local index="$2"

  cut -d '|' -f "$index" <<< "$entry"
}

app_type() {
  app_field "$1" 1
}

app_label() {
  app_field "$1" 2
}

app_packages() {
  app_field "$1" 3
}

app_command() {
  app_field "$1" 4
}

app_desktop() {
  app_field "$1" 5
}

# Busca unha entrada completa polo seu nome visible.
find_app_by_label() {
  local label="$1"
  shift
  local entry

  for entry in "$@"; do
    if [ "$(app_label "$entry")" = "$label" ]; then
      printf '%s\n' "$entry"
      return 0
    fi
  done

  return 1
}

# Comproba se unha app foi escollida na categoría actual.
# Acepta tanto o nome visible como calquera paquete da entrada.
has_selected_app() {
  local app_name="$1"
  local selected_entry package

  for selected_entry in "${SELECTED_ENTRIES[@]}"; do
    if [ "$(app_label "$selected_entry")" = "$app_name" ]; then
      return 0
    fi

    for package in $(app_packages "$selected_entry"); do
      if [ "$package" = "$app_name" ]; then
        return 0
      fi
    done
  done

  return 1
}

# Engade á cola de instalación todos os paquetes dunha entrada.
add_entry_packages() {
  local entry="$1"
  local install_type packages package

  install_type="$(app_type "$entry")"
  packages="$(app_packages "$entry")"

  for package in $packages; do
    case "$install_type" in
      pkg)
        add_pkg_app "$package"
        ;;
      flatpak)
        add_flatpak_app "$package"
        ;;
      pipx)
        add_pipx_app "$package"
        ;;
      *)
        warning "Tipo de instalación descoñecido para $(app_label "$entry"): $install_type"
        return 1
        ;;
    esac
  done
}

# Mostra unha lista multi-selección e devolve as entradas completas escollidas.
choose_entries() {
  local header="$1"
  shift
  local entries=("$@")
  local labels=()
  local entry selected label

  for entry in "${entries[@]}"; do
    labels+=("$(app_label "$entry")")
  done

  selected=$(gum_choose \
    --no-limit \
    --header "$header" \
    "${labels[@]}")

  while IFS= read -r label; do
    [ -n "$label" ] || continue
    find_app_by_label "$label" "${entries[@]}"
  done <<< "$selected"
}

# Dada unha lista de entradas xa escollidas, pide cal será a predeterminada.
choose_default_entry() {
  local header="$1"
  shift
  local entries=("$@")
  local labels=()
  local entry selected

  case "${#entries[@]}" in
    0)
      return 1
      ;;
    1)
      printf '%s\n' "${entries[0]}"
      return 0
      ;;
  esac

  for entry in "${entries[@]}"; do
    labels+=("$(app_label "$entry")")
  done

  selected=$(gum_choose \
    --header "$header" \
    "${labels[@]}")

  find_app_by_label "$selected" "${entries[@]}"
}

# Engade á cola de instalación todos os paquetes das entradas escollidas.
add_selected_entries_packages() {
  local selected_entry

  for selected_entry in "${SELECTED_ENTRIES[@]}"; do
    add_entry_packages "$selected_entry"
  done
}

# Selección obrigatoria:
# - repite ata que o usuario escolla polo menos unha app,
# - garda as apps escollidas en SELECTED_ENTRIES.
#
# Non escolle DEFAULT_ENTRY por si mesma. Se a categoría precisa unha app por
# defecto, o script pode chamar choose_default_entry despois.
choose_required_category() {
  local header="$1"
  shift
  local entries=("$@")

  SELECTED_ENTRIES=()
  DEFAULT_ENTRY=""

  while [ ${#SELECTED_ENTRIES[@]} -eq 0 ]; do
    mapfile -t SELECTED_ENTRIES < <(choose_entries "$header" "${entries[@]}")
    if [ ${#SELECTED_ENTRIES[@]} -eq 0 ]; then
      warning "Tes que escoller polo menos unha opción."
    fi
  done

  add_selected_entries_packages
}

# Selección opcional: pode quedar baleira.
choose_optional_category() {
  local header="$1"
  shift
  local entries=("$@")

  SELECTED_ENTRIES=()
  # shellcheck disable=SC2034
  DEFAULT_ENTRY=""

  mapfile -t SELECTED_ENTRIES < <(choose_entries "$header" "${entries[@]}")

  add_selected_entries_packages
}

# Instala todos os paquetes acumulados polas seleccións anteriores.
install_selected_apps() {
  if [ ${#pkgs_apps[@]} -gt 0 ]; then
    yay -Syu --needed "${pkgs_apps[@]}"
  fi

  if [ ${#flatpaks_apps[@]} -gt 0 ]; then
    flatpak install -y flathub "${flatpaks_apps[@]}"
  fi

  if [ ${#pipx_apps[@]} -gt 0 ]; then
    pipx install "${pipx_apps[@]}"
  fi
}
