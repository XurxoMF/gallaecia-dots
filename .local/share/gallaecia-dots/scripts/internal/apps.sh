#!/usr/bin/env bash

###############################################################################
# INSTALACIÓN INTERNA DE CATEGORÍAS
#
# Esta libraría só a cargan install.sh, as migracións e o subcomando
# `gallaecia install-category`. Non é unha API para scripts personalizados.
#
# Non conserva seleccións nin colas globais. Cada función
# `install-category-*` declara as súas aplicacións e completa todo o fluxo:
#
#   1. Separa as aplicacións xa instaladas das dispoñibles para seleccionar.
#   2. Instala inmediatamente os paquetes desa categoría.
#   3. Copia as configuracións opcionais das aplicacións seleccionadas.
#   4. Escolle, cando corresponde, unha predeterminada entre as aplicacións xa
#      instaladas e as novas, e actualiza Hyprland.
#   5. Combina os MIME das aplicacións activas e aplica a predeterminada ao final.
#
# A repetición dos `case` é intencionada: ao abrir unha categoría pódese ver
# todo o seu comportamento sen saltar a táboas nin políticas noutro ficheiro.
###############################################################################

# As entradas locais de cada categoría usan catro campos:
#
#   xestor|Nome visible|paquetes|comando
#
# `paquetes` admite varios nomes separados por espazos. O comando só se usa nas
# categorías que actualizan a táboa `Gallaecia` de Hyprland. Os ficheiros
# .desktop viven xunto aos seus MIME dentro da propia función de categoría.

###############################################################################
# HELPERS PEQUENOS DE SELECCIÓN E INSTALACIÓN
###############################################################################

# Recibe unha entrada e un número de campo e imprime ese valor.
# Centraliza unicamente a lectura do formato; non mantén estado compartido.
_app_field() {
  local entry="$1"
  local field_number="$2"

  cut -d '|' -f "$field_number" <<< "$entry"
}

# Imprime o xestor declarado no primeiro campo dunha entrada.
_app_manager() {
  _app_field "$1" 1
}

# Imprime a etiqueta humana declarada no segundo campo dunha entrada.
_app_label() {
  _app_field "$1" 2
}

# Imprime os paquetes declarados no terceiro campo dunha entrada.
_app_packages() {
  _app_field "$1" 3
}

# Imprime o comando declarado no cuarto campo dunha entrada.
_app_command() {
  _app_field "$1" 4
}

# Recibe unha etiqueta e unha lista de entradas e imprime a entrada coincidente.
# Gum traballa con nomes visibles, mentres que o resto do fluxo conserva a
# entrada completa para instalar os seus paquetes.
_entry_from_label() {
  local selected_label="$1"
  shift
  local entry

  for entry in "$@"; do
    if [ "$(_app_label "$entry")" = "$selected_label" ]; then
      printf '%s\n' "$entry"
      return 0
    fi
  done

  return 1
}

# Mostra un selector múltiple e imprime unha entrada completa por selección.
# O primeiro argumento indica se Esc debe repetir a pregunta (`true`) ou
# devolver 2 para cancelar a categoría (`false`).
_select_category_apps() {
  local required="$1"
  local header="$2"
  shift 2
  local entries=("$@")
  local labels=()
  local entry selection selected_label

  for entry in "${entries[@]}"; do
    labels+=("$(_app_label "$entry")")
  done

  while true; do
    if ! selection="$(choose \
      --header "$header" \
      "${labels[@]}" -- --no-limit)"; then
      if $required; then
        warning "Tes que escoller polo menos unha aplicación." >&2
        continue
      fi
      return 2
    fi

    if [ -z "$selection" ]; then
      if $required; then
        warning "Tes que escoller polo menos unha aplicación." >&2
        continue
      fi
      return 2
    fi

    while IFS= read -r selected_label; do
      [ -n "$selected_label" ] || continue
      _entry_from_label "$selected_label" "${entries[@]}" || return 1
    done <<< "$selection"
    return 0
  done
}

# Devolve 0 só cando todos os paquetes dunha variante están instalados co
# xestor declarado. A separación en palabras do terceiro campo é deliberada:
# variantes como LibreOffice ou VLC requiren varios paquetes para estar completas.
_category_app_is_installed() {
  local entry="$1"
  local manager packages package_name package_manager

  manager="$(_app_manager "$entry")"
  packages="$(_app_packages "$entry")"
  case "$manager" in
    pkg) package_manager="yay" ;;
    flatpak) package_manager="flatpak" ;;
    pipx) package_manager="pipx" ;;
    *)
      error "Xestor descoñecido para $(_app_label "$entry"): $manager"
      return 1
      ;;
  esac

  for package_name in $packages; do
    if ! has_package --manager "$package_manager" "$package_name"; then
      return 1
    fi
  done
}

# Enche dous arrays locais do chamador: novas seleccións e conxunto activo.
# Mantén internamente as variantes instaladas e dispoñibles, mostra as primeiras
# antes do selector e ocúltaas del. Devolve 2 cando unha categoría opcional se
# cancela; na base, se xa existe unha variante dunha categoría obrigatoria, Esc
# conserva só as instaladas para poder escoller despois a predeterminada.
_prepare_category_apps() {
  local -n selected_entries_ref="$1"
  local -n active_entries_ref="$2"
  local required="$3"
  local header="$4"
  shift 4
  local entries=("$@")
  local installed_entries=()
  local available_entries=()
  local entry active_entry selection selection_status
  local selector_required="$required"

  selected_entries_ref=()
  active_entries_ref=()

  for entry in "${entries[@]}"; do
    if _category_app_is_installed "$entry"; then
      installed_entries+=("$entry")
    else
      available_entries+=("$entry")
    fi
  done

  if [ ${#installed_entries[@]} -gt 0 ]; then
    info "Xa instaladas:"
    for entry in "${installed_entries[@]}"; do
      info "· $(_app_label "$entry")"
    done
    selector_required=false
  fi

  if [ ${#available_entries[@]} -gt 0 ]; then
    selection="$(_select_category_apps "$selector_required" \
      "$header" "${available_entries[@]}")"
    selection_status=$?
    if [ "$selection_status" -eq 2 ]; then
      if $required && [ ${#installed_entries[@]} -gt 0 ]; then
        active_entries_ref=("${installed_entries[@]}")
        return 0
      fi
      return 2
    fi
    if [ "$selection_status" -ne 0 ]; then
      return 1
    fi

    while IFS= read -r entry; do
      [ -n "$entry" ] || continue
      selected_entries_ref+=("$entry")
    done <<< "$selection"
  fi

  # Reconstrúe o conxunto activo na orde declarada pola categoría. Así as
  # categorías sen predeterminada resolven coincidencias MIME dunha maneira
  # estable, independentemente da orde na que Gum devolva as marcas.
  for entry in "${entries[@]}"; do
    for active_entry in \
      "${installed_entries[@]}" "${selected_entries_ref[@]}"; do
      if [ "$entry" = "$active_entry" ]; then
        active_entries_ref+=("$entry")
        break
      fi
    done
  done
}

# Recibe se a elección é obrigatoria, unha cabeceira e as entradas xa
# activas. Imprime unha única entrada predeterminada; Esc devolve baleiro nas
# categorías opcionais e repite a pregunta nas obrigatorias.
_select_default_app() {
  local required="$1"
  local header="$2"
  shift 2
  local entries=("$@")
  local labels=()
  local entry selection

  for entry in "${entries[@]}"; do
    labels+=("$(_app_label "$entry")")
  done

  while true; do
    if ! selection="$(choose --header "$header" "${labels[@]}")"; then
      if $required; then
        warning "Tes que escoller unha aplicación predeterminada." >&2
        continue
      fi
      return 0
    fi

    [ -n "$selection" ] || continue
    _entry_from_label "$selection" "${entries[@]}"
    return
  done
}

# Devolve 0 cando a etiqueta aparece entre as entradas recibidas.
# Úsase só para decidir configuracións opcionais dentro da mesma categoría.
_selection_has() {
  local expected_label="$1"
  shift
  local entry

  for entry in "$@"; do
    if [ "$(_app_label "$entry")" = "$expected_label" ]; then
      return 0
    fi
  done

  return 1
}

# Recibe as entradas seleccionadas, sepáraas en arrays locais por xestor e chama
# os instaladores públicos en modo directo. As colas desaparecen ao retornar e
# a seguinte categoría comeza sempre sen contexto herdado.
_install_selected_packages() {
  local entries=("$@")
  local yay_packages=()
  local flatpak_packages=()
  local pipx_packages=()
  local entry manager packages package_name

  for entry in "${entries[@]}"; do
    manager="$(_app_manager "$entry")"
    packages="$(_app_packages "$entry")"

    # A separación é deliberada: unha app pode necesitar varios paquetes.
    for package_name in $packages; do
      case "$manager" in
        pkg)
          yay_packages+=("$package_name")
          ;;
        flatpak)
          flatpak_packages+=("$package_name")
          ;;
        pipx)
          pipx_packages+=("$package_name")
          ;;
        *)
          error "Xestor descoñecido para $(_app_label "$entry"): $manager"
          return 1
          ;;
      esac
    done
  done

  if [ ${#yay_packages[@]} -gt 0 ]; then
    yay-install --packages "${yay_packages[@]}" || return 1
  fi
  if [ ${#flatpak_packages[@]} -gt 0 ]; then
    flatpak-install --packages "${flatpak_packages[@]}" || return 1
  fi
  if [ ${#pipx_packages[@]} -gt 0 ]; then
    pipx-install --packages "${pipx_packages[@]}" || return 1
  fi
}

# Imprime primeiro as aplicacións secundarias e por último a predeterminada.
# As funcións de categoría percorren esta orde ao escribir MIME: os exclusivos
# consérvanse e as coincidencias terminan asignadas á predeterminada.
_mime_application_order() {
  local default_entry="$1"
  shift
  local entry

  for entry in "$@"; do
    if [ "$entry" != "$default_entry" ]; then
      printf '%s\n' "$entry"
    fi
  done

  if [ -n "$default_entry" ]; then
    printf '%s\n' "$default_entry"
  fi
}

###############################################################################
# ESCRITURA DE MIME E HYPRLAND
###############################################################################

# Recibe un MIME e un ficheiro .desktop e actualiza só
# `[Default Applications]` de ~/.config/mimeapps.list. Conserva o resto das
# seccións e substitúe o destino unicamente despois de crear un temporal válido.
set_default_app() {
  local mime_type="$1"
  local desktop_file="$2"
  local mimeapps="$HOME/.config/mimeapps.list"
  local temporary_file

  mkdir -p "$HOME/.config"
  touch "$mimeapps"
  temporary_file="$(mktemp "$HOME/.config/.mimeapps.list.XXXXXX")" || return 1

  if ! awk -v mime_type="$mime_type" -v desktop_file="$desktop_file" '
    BEGIN {
      in_defaults = 0
      found_defaults = 0
      wrote_rule = 0
    }

    $0 == "[Default Applications]" {
      in_defaults = 1
      found_defaults = 1
      print
      next
    }

    /^\[/ {
      if (in_defaults && !wrote_rule) {
        print mime_type "=" desktop_file
        wrote_rule = 1
      }
      in_defaults = 0
    }

    in_defaults && index($0, mime_type "=") == 1 {
      if (!wrote_rule) {
        print mime_type "=" desktop_file
        wrote_rule = 1
      }
      next
    }

    {
      print
    }

    END {
      if (!found_defaults) {
        if (NR > 0) {
          print ""
        }
        print "[Default Applications]"
        print mime_type "=" desktop_file
      } else if (in_defaults && !wrote_rule) {
        print mime_type "=" desktop_file
      }
    }
  ' "$mimeapps" > "$temporary_file"; then
    rm -f "$temporary_file"
    return 1
  fi

  if ! chmod --reference="$mimeapps" "$temporary_file" ||
    ! mv -f "$temporary_file" "$mimeapps"; then
    rm -f "$temporary_file"
    return 1
  fi
}

# Recibe un ficheiro .desktop e todos os MIME que debe abrir.
# Detense no primeiro erro para non ocultar unha asociación incompleta.
set_default_apps() {
  local desktop_file="$1"
  shift
  local mime_type

  for mime_type in "$@"; do
    if ! set_default_app "$mime_type" "$desktop_file"; then
      return 1
    fi
  done
}

# Recibe directamente unha clave da táboa Lua `Gallaecia` e o seu comando.
# Actualiza a asignación existente ou créaa dentro da táboa; funciona tanto cos
# placeholders da instalación inicial como con valores xa configurados.
set_hyprland_default_app() {
  local config_key="$1"
  local command_value="$2"
  local hypr_config="${3:-$HOME/.config/hypr/hyprland.lua}"
  local escaped_value replacement temporary_file

  if [ ! -f "$hypr_config" ]; then
    error "Non se atopou a configuración de Hyprland en $hypr_config."
    return 1
  fi

  escaped_value="${command_value//\\/\\\\}"
  escaped_value="${escaped_value//\"/\\\"}"
  replacement="  $config_key = \"$escaped_value\","
  temporary_file="$(mktemp "${hypr_config}.XXXXXX")" || return 1

  if ! GALLAECIA_HYPR_REPLACEMENT="$replacement" \
    awk -v config_key="$config_key" '
    /^[[:space:]]*Gallaecia[[:space:]]*=[[:space:]]*{/ {
      in_gallaecia = 1
      found_gallaecia = 1
      print
      next
    }

    in_gallaecia && $0 ~ "^[[:space:]]*" config_key "[[:space:]]*=" {
      if (!wrote_value) {
        print ENVIRON["GALLAECIA_HYPR_REPLACEMENT"]
        wrote_value = 1
      }
      next
    }

    in_gallaecia && /^[[:space:]]*}[[:space:]]*,?[[:space:]]*$/ {
      if (!wrote_value) {
        print ENVIRON["GALLAECIA_HYPR_REPLACEMENT"]
        wrote_value = 1
      }
      in_gallaecia = 0
    }

    {
      print
    }

    END {
      if (!found_gallaecia) {
        exit 2
      }
    }
  ' "$hypr_config" > "$temporary_file"; then
    rm -f "$temporary_file"
    error "Non se atopou unha táboa Gallaecia válida en $hypr_config."
    return 1
  fi

  if ! chmod --reference="$hypr_config" "$temporary_file" ||
    ! mv -f "$temporary_file" "$hypr_config"; then
    rm -f "$temporary_file"
    return 1
  fi
}

###############################################################################
# CATEGORÍAS PRINCIPAIS
###############################################################################

# Todas as funcións `install-category-*` aceptan unicamente `--required`.
# Con esa opción, unha variante xa instalada satisfai a categoría; se non hai
# ningunha, cancelar ou confirmar unha selección baleira repite o selector. Sen
# ela, cancelar salta a categoría. Cada función conserva os arrays só durante a
# súa execución e remata todo o traballo antes de devolver o control.

# Instala terminais, copia a configuración de cada selección e escribe
# explicitamente o comando da predeterminada en `Gallaecia.terminal`.
install-category-terminal() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en terminal: $1"
    return 1
  fi

  local entries=(
    "pkg|Kitty|kitty|kitty"
    "pkg|Alacritty|alacritty|alacritty"
    "pkg|Foot|foot|foot"
    "pkg|Ghostty|ghostty|ghostty"
    "pkg|WezTerm|wezterm|wezterm"
  )
  local selected_entries=() active_entries=()
  local default_entry=""
  local default_label selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona terminal ou terminais:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0

  default_entry="$(_select_default_app "$required" \
    "Escolle o terminal predeterminado:" "${active_entries[@]}")"

  _install_selected_packages "${selected_entries[@]}" || return 1

  if _selection_has Kitty "${selected_entries[@]}"; then
    replace_path "$DOTFILES_DIR/optional/.config/kitty" "$HOME/.config/kitty" || return 1
  fi
  if _selection_has Alacritty "${selected_entries[@]}"; then
    replace_path "$DOTFILES_DIR/optional/.config/alacritty" "$HOME/.config/alacritty" || return 1
  fi
  if _selection_has Foot "${selected_entries[@]}"; then
    replace_path "$DOTFILES_DIR/optional/.config/foot" "$HOME/.config/foot" || return 1
  fi
  if _selection_has Ghostty "${selected_entries[@]}"; then
    replace_path "$DOTFILES_DIR/optional/.config/ghostty" "$HOME/.config/ghostty" || return 1
  fi
  if _selection_has WezTerm "${selected_entries[@]}"; then
    replace_path "$DOTFILES_DIR/optional/.config/wezterm" "$HOME/.config/wezterm" || return 1
  fi

  [ -n "$default_entry" ] || return 0
  default_label="$(_app_label "$default_entry")"
  case "$default_label" in
    Kitty) set_hyprland_default_app terminal "$(_app_command "$default_entry")" ;;
    Alacritty) set_hyprland_default_app terminal "$(_app_command "$default_entry")" ;;
    Foot) set_hyprland_default_app terminal "$(_app_command "$default_entry")" ;;
    Ghostty) set_hyprland_default_app terminal "$(_app_command "$default_entry")" ;;
    WezTerm) set_hyprland_default_app terminal "$(_app_command "$default_entry")" ;;
  esac
}

# Garante que Neovim cargue o módulo xerado polo template de Noctalia. Conserva
# calquera configuración existente e engade unicamente a chamada cando falta;
# se non existe init.lua, copia o ficheiro mínimo distribuído por Gallaecia.
_configure_neovim_matugen() {
  local source="$DOTFILES_DIR/optional/.config/nvim/init.lua"
  local target="$HOME/.config/nvim/init.lua"
  local setup_line="require('matugen').setup()"

  if path_exists -- "$target"; then
    if [ ! -f "$target" ]; then
      error "A configuración de Neovim existe pero non é un ficheiro: $target"
      return 1
    fi
    if grep -qxF "$setup_line" "$target"; then
      return 0
    fi

    # Engade primeiro un salto só cando o ficheiro non remata xa en nova liña.
    if [ -s "$target" ] && [ -n "$(tail -c 1 -- "$target")" ]; then
      printf '\n' >> "$target" || return 1
    fi
    printf '%s\n' "$setup_line" >> "$target"
    return
  fi

  copy_file "$source" "$target"
}

# Instala editores de terminal e asigna explicitamente o comando da elección
# predeterminada a `Gallaecia.editor`. Neovim incorpora o tema Base16 e a carga
# de Matugen; ningún editor desta categoría define MIME.
install-category-editor() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en editor: $1"
    return 1
  fi

  local entries=(
    "pkg|Neovim|neovim neovim-base16-git|nvim"
    "pkg|Helix|helix|hx"
    "pkg|Vim|vim|vim"
    "pkg|Nano|nano|nano"
    "pkg|Micro|micro|micro"
  )
  local selected_entries=() active_entries=()
  local default_entry=""
  local selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona editor ou editores de terminal:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  default_entry="$(_select_default_app "$required" \
    "Escolle o editor de terminal predeterminado:" "${active_entries[@]}")"

  _install_selected_packages "${selected_entries[@]}" || return 1

  if _selection_has "Neovim" "${active_entries[@]}"; then
    _configure_neovim_matugen || return 1
  fi

  [ -n "$default_entry" ] || return 0

  case "$(_app_label "$default_entry")" in
    Neovim) set_hyprland_default_app editor "$(_app_command "$default_entry")" ;;
    Helix) set_hyprland_default_app editor "$(_app_command "$default_entry")" ;;
    Vim) set_hyprland_default_app editor "$(_app_command "$default_entry")" ;;
    Nano) set_hyprland_default_app editor "$(_app_command "$default_entry")" ;;
    Micro) set_hyprland_default_app editor "$(_app_command "$default_entry")" ;;
  esac
}

# Instala IDEs e fusiona `text/plain` entre todas as eleccións. A predeterminada
# queda tamén en `Gallaecia.ide`. Se VS Code forma parte do conxunto activo,
# instala a súa flag controlada para usar GNOME Keyring mediante libsecret.
install-category-ide() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en ide: $1"
    return 1
  fi

  local entries=(
    "pkg|Visual Studio Code|visual-studio-code-bin|code"
    "pkg|Zed|zed|zed"
    "pkg|Obsidian|obsidian|obsidian"
    "pkg|Geany|geany|geany"
  )
  local selected_entries=() active_entries=()
  local mime_entries=()
  local default_entry="" entry selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona IDE ou editores con interface gráfica:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  default_entry="$(_select_default_app "$required" \
    "Escolle o IDE predeterminado:" "${active_entries[@]}")"

  _install_selected_packages "${selected_entries[@]}" || return 1

  if _selection_has "Visual Studio Code" "${active_entries[@]}"; then
    replace_file \
      "$DOTFILES_DIR/optional/.config/code-flags.conf" \
      "$HOME/.config/code-flags.conf" || return 1
  fi

  [ -n "$default_entry" ] || return 0

  case "$(_app_label "$default_entry")" in
    "Visual Studio Code") set_hyprland_default_app ide "$(_app_command "$default_entry")" ;;
    Zed) set_hyprland_default_app ide "$(_app_command "$default_entry")" ;;
    Obsidian) set_hyprland_default_app ide "$(_app_command "$default_entry")" ;;
    Geany) set_hyprland_default_app ide "$(_app_command "$default_entry")" ;;
  esac

  mapfile -t mime_entries < <(
    _mime_application_order "$default_entry" "${active_entries[@]}"
  )
  for entry in "${mime_entries[@]}"; do
    case "$(_app_label "$entry")" in
      "Visual Studio Code") set_default_apps visual-studio-code.desktop text/plain ;;
      Zed) set_default_apps dev.zed.Zed.desktop text/plain ;;
      Obsidian) set_default_apps obsidian.desktop text/plain ;;
      Geany) set_default_apps geany.desktop text/plain ;;
    esac || return 1
  done
}

# Instala navegadores, actualiza `Gallaecia.navegador` e repite explicitamente
# os MIME web por aplicación; a predeterminada aplícase por última.
install-category-browser() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en browser: $1"
    return 1
  fi

  local entries=(
    "pkg|Firefox|firefox|firefox"
    "pkg|LibreWolf|librewolf-bin|librewolf"
    "pkg|Zen Browser|zen-browser|zen-browser"
    "pkg|Tor Browser|tor-browser-bin|tor-browser"
  )
  local selected_entries=() active_entries=()
  local mime_entries=()
  local default_entry="" entry selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona navegador ou navegadores:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  default_entry="$(_select_default_app "$required" \
    "Escolle o navegador predeterminado:" "${active_entries[@]}")"

  _install_selected_packages "${selected_entries[@]}" || return 1
  [ -n "$default_entry" ] || return 0

  case "$(_app_label "$default_entry")" in
    Firefox) set_hyprland_default_app navegador "$(_app_command "$default_entry")" ;;
    LibreWolf) set_hyprland_default_app navegador "$(_app_command "$default_entry")" ;;
    "Zen Browser") set_hyprland_default_app navegador "$(_app_command "$default_entry")" ;;
    "Tor Browser") set_hyprland_default_app navegador "$(_app_command "$default_entry")" ;;
  esac

  mapfile -t mime_entries < <(
    _mime_application_order "$default_entry" "${active_entries[@]}"
  )
  for entry in "${mime_entries[@]}"; do
    case "$(_app_label "$entry")" in
      Firefox)
        set_default_apps firefox.desktop \
          text/html application/xhtml+xml \
          x-scheme-handler/http x-scheme-handler/https
        ;;
      LibreWolf)
        set_default_apps librewolf.desktop \
          text/html application/xhtml+xml \
          x-scheme-handler/http x-scheme-handler/https
        ;;
      "Zen Browser")
        set_default_apps zen.desktop \
          text/html application/xhtml+xml \
          x-scheme-handler/http x-scheme-handler/https
        ;;
      "Tor Browser")
        set_default_apps torbrowser.desktop \
          text/html application/xhtml+xml \
          x-scheme-handler/http x-scheme-handler/https
        ;;
    esac || return 1
  done
}

# Instala exploradores e as súas configuracións. Yazi usa o seu `yazi.desktop`
# para directorios e conserva literalmente `$TERMINAL -e yazi` en Hyprland.
install-category-file-explorer() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en file-explorer: $1"
    return 1
  fi

  local entries=(
    "pkg|Dolphin|dolphin ark|dolphin"
    "pkg|Nautilus|nautilus|nautilus"
    "pkg|Nemo|nemo|nemo"
    "pkg|Yazi|yazi|\$TERMINAL -e yazi"
  )
  local selected_entries=() active_entries=()
  local mime_entries=()
  local default_entry="" entry selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona explorador ou exploradores de arquivos:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  default_entry="$(_select_default_app "$required" \
    "Escolle o explorador predeterminado:" "${active_entries[@]}")"

  _install_selected_packages "${selected_entries[@]}" || return 1
  if _selection_has Dolphin "${selected_entries[@]}"; then
    replace_file \
      "$DOTFILES_DIR/optional/.config/dolphinrc" \
      "$HOME/.config/dolphinrc" || return 1
  fi
  if _selection_has Yazi "${selected_entries[@]}"; then
    replace_path "$DOTFILES_DIR/optional/.config/yazi" "$HOME/.config/yazi" || return 1
    ya pkg add yazi-rs/plugins:git || return 1
    ya pkg add yazi-rs/plugins:mount || return 1
    ya pkg add yazi-rs/plugins:chmod || return 1
    ya pkg add boydaihungst/mediainfo || return 1
  fi
  [ -n "$default_entry" ] || return 0

  case "$(_app_label "$default_entry")" in
    Dolphin) set_hyprland_default_app explorador_de_arquivos "$(_app_command "$default_entry")" ;;
    Nautilus) set_hyprland_default_app explorador_de_arquivos "$(_app_command "$default_entry")" ;;
    Nemo) set_hyprland_default_app explorador_de_arquivos "$(_app_command "$default_entry")" ;;
    Yazi) set_hyprland_default_app explorador_de_arquivos "$(_app_command "$default_entry")" ;;
  esac

  mapfile -t mime_entries < <(
    _mime_application_order "$default_entry" "${active_entries[@]}"
  )
  for entry in "${mime_entries[@]}"; do
    case "$(_app_label "$entry")" in
      Dolphin) set_default_apps org.kde.dolphin.desktop inode/directory ;;
      Nautilus) set_default_apps org.gnome.Nautilus.desktop inode/directory ;;
      Nemo) set_default_apps nemo.desktop inode/directory ;;
      Yazi) set_default_apps yazi.desktop inode/directory ;;
    esac || return 1
  done
}

###############################################################################
# CATEGORÍAS MULTIMEDIA E COMUNICACIÓN
###############################################################################

# Instala reprodutores de audio e combina os MIME completos de cada selección.
install-category-audio() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en audio: $1"
    return 1
  fi

  local entries=(
    "pkg|Amberol|amberol|amberol"
    "pkg|Tauon|tauon-music-box|tauon"
    "pkg|VLC|vlc vlc-plugins-all|vlc"
    "pkg|MPV|mpv|mpv"
  )
  local selected_entries=() active_entries=() mime_entries=()
  local default_entry="" entry selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona reprodutor ou reprodutores de audio:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  default_entry="$(_select_default_app "$required" \
    "Escolle o reprodutor de audio predeterminado:" "${active_entries[@]}")"
  _install_selected_packages "${selected_entries[@]}" || return 1
  [ -n "$default_entry" ] || return 0

  mapfile -t mime_entries < <(_mime_application_order "$default_entry" "${active_entries[@]}")
  for entry in "${mime_entries[@]}"; do
    case "$(_app_label "$entry")" in
      Amberol)
        set_default_apps io.bassi.Amberol.desktop \
          audio/aac audio/flac audio/mpeg audio/ogg audio/opus \
          audio/wav audio/x-wav audio/x-ms-wma
        ;;
      Tauon)
        set_default_apps com.github.taiko2k.tauonmb.desktop \
          audio/aac audio/flac audio/mpeg audio/ogg audio/opus \
          audio/wav audio/x-wav audio/x-ms-wma
        ;;
      VLC)
        set_default_apps vlc.desktop \
          audio/aac audio/flac audio/mpeg audio/ogg audio/opus \
          audio/wav audio/x-wav audio/x-ms-wma
        ;;
      MPV)
        set_default_apps mpv.desktop \
          audio/aac audio/flac audio/mpeg audio/ogg audio/opus \
          audio/wav audio/x-wav audio/x-ms-wma
        ;;
    esac || return 1
  done
}

# Instala reprodutores de vídeo e aplica a unión de MIME coa predeterminada ao
# final, incluso cando VLC ou MPV xa se instalaran na categoría de audio.
install-category-video() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en video: $1"
    return 1
  fi

  local entries=(
    "pkg|VLC|vlc vlc-plugins-all|vlc"
    "pkg|MPV|mpv|mpv"
    "pkg|Clapper|clapper|clapper"
  )
  local selected_entries=() active_entries=() mime_entries=()
  local default_entry="" entry selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona reprodutor ou reprodutores de vídeo:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  default_entry="$(_select_default_app "$required" \
    "Escolle o reprodutor de vídeo predeterminado:" "${active_entries[@]}")"
  _install_selected_packages "${selected_entries[@]}" || return 1
  [ -n "$default_entry" ] || return 0

  mapfile -t mime_entries < <(_mime_application_order "$default_entry" "${active_entries[@]}")
  for entry in "${mime_entries[@]}"; do
    case "$(_app_label "$entry")" in
      VLC)
        set_default_apps vlc.desktop \
          video/mp2t video/mp4 video/mpeg video/ogg video/quicktime video/webm \
          video/x-matroska video/x-msvideo video/x-ms-wmv
        ;;
      MPV)
        set_default_apps mpv.desktop \
          video/mp2t video/mp4 video/mpeg video/ogg video/quicktime video/webm \
          video/x-matroska video/x-msvideo video/x-ms-wmv
        ;;
      Clapper)
        set_default_apps com.github.rafostar.Clapper.desktop \
          video/mp2t video/mp4 video/mpeg video/ogg video/quicktime video/webm \
          video/x-matroska video/x-msvideo video/x-ms-wmv
        ;;
    esac || return 1
  done
}

# Instala visores de documentos e declara os mesmos formatos de lectura en cada
# opción para que a predeterminada resolva todas as coincidencias.
install-category-pdf() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en pdf: $1"
    return 1
  fi

  local entries=(
    "pkg|Okular|okular|okular"
    "pkg|Zathura|zathura zathura-pdf-mupdf|zathura"
    "pkg|Evince|evince|evince"
  )
  local selected_entries=() active_entries=() mime_entries=()
  local default_entry="" entry selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona visor ou visores de PDF:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  default_entry="$(_select_default_app "$required" \
    "Escolle o visor de documentos predeterminado:" "${active_entries[@]}")"
  _install_selected_packages "${selected_entries[@]}" || return 1
  [ -n "$default_entry" ] || return 0

  mapfile -t mime_entries < <(_mime_application_order "$default_entry" "${active_entries[@]}")
  for entry in "${mime_entries[@]}"; do
    case "$(_app_label "$entry")" in
      Okular)
        set_default_apps org.kde.okular.desktop \
          application/pdf application/epub+zip application/vnd.comicbook+zip \
          application/vnd.djvu image/vnd.djvu application/oxps application/vnd.ms-xpsdocument
        ;;
      Zathura)
        set_default_apps org.pwmt.zathura.desktop \
          application/pdf application/epub+zip application/vnd.comicbook+zip \
          application/vnd.djvu image/vnd.djvu application/oxps application/vnd.ms-xpsdocument
        ;;
      Evince)
        set_default_apps org.gnome.Evince.desktop \
          application/pdf application/epub+zip application/vnd.comicbook+zip \
          application/vnd.djvu image/vnd.djvu application/oxps application/vnd.ms-xpsdocument
        ;;
    esac || return 1
  done
}

# Instala visores/editores de imaxes e aplica por app todos os formatos comúns.
install-category-images() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en images: $1"
    return 1
  fi

  local entries=(
    "pkg|Loupe|loupe|loupe"
    "pkg|GIMP|gimp|gimp"
    "pkg|Krita|krita|krita"
  )
  local selected_entries=() active_entries=() mime_entries=()
  local default_entry="" entry selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona visor ou visores de imaxes:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  default_entry="$(_select_default_app "$required" \
    "Escolle o visor de imaxes predeterminado:" "${active_entries[@]}")"
  _install_selected_packages "${selected_entries[@]}" || return 1
  [ -n "$default_entry" ] || return 0

  mapfile -t mime_entries < <(_mime_application_order "$default_entry" "${active_entries[@]}")
  for entry in "${mime_entries[@]}"; do
    case "$(_app_label "$entry")" in
      Loupe)
        set_default_apps org.gnome.Loupe.desktop \
          image/avif image/bmp image/gif image/heif image/jpeg image/jxl \
          image/png image/tiff image/webp image/x-xcf image/vnd.adobe.photoshop
        ;;
      GIMP)
        set_default_apps org.gimp.GIMP.desktop \
          image/avif image/bmp image/gif image/heif image/jpeg image/jxl \
          image/png image/tiff image/webp image/x-xcf image/vnd.adobe.photoshop
        ;;
      Krita)
        set_default_apps org.kde.krita.desktop \
          image/avif image/bmp image/gif image/heif image/jpeg image/jxl \
          image/png image/tiff image/webp image/x-xcf image/vnd.adobe.photoshop
        ;;
    esac || return 1
  done
}

# Instala clientes de correo. Thunderbird é actualmente a única opción, pero a
# selección e os MIME quedan explícitos para ampliar a categoría facilmente.
install-category-mail() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en mail: $1"
    return 1
  fi

  local entries=("pkg|Thunderbird|thunderbird|thunderbird")
  local selected_entries=() active_entries=() mime_entries=()
  local default_entry="" entry selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona cliente ou clientes de correo:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  default_entry="$(_select_default_app "$required" \
    "Escolle o cliente de correo predeterminado:" "${active_entries[@]}")"
  _install_selected_packages "${selected_entries[@]}" || return 1
  [ -n "$default_entry" ] || return 0

  mapfile -t mime_entries < <(_mime_application_order "$default_entry" "${active_entries[@]}")
  for entry in "${mime_entries[@]}"; do
    case "$(_app_label "$entry")" in
      Thunderbird)
        set_default_apps thunderbird.desktop \
          message/rfc822 x-scheme-handler/mailto x-scheme-handler/mid
        ;;
    esac || return 1
  done
}

# Instala clientes de chat. Discord e Vesktop compiten por discord://; Telegram
# e Element figuran explicitamente cun bloque baleiro porque non usan ese MIME.
install-category-chat() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en chat: $1"
    return 1
  fi

  local entries=(
    "pkg|Discord|discord|discord"
    "pkg|Vesktop|vesktop|vesktop"
    "pkg|Telegram|telegram-desktop|telegram-desktop"
    "pkg|Element|element-desktop|element-desktop"
  )
  local selected_entries=() active_entries=() mime_entries=()
  local default_entry="" entry selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona apps de chat:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  default_entry="$(_select_default_app "$required" \
    "Escolle a app de chat predeterminada:" "${active_entries[@]}")"
  _install_selected_packages "${selected_entries[@]}" || return 1
  [ -n "$default_entry" ] || return 0

  mapfile -t mime_entries < <(_mime_application_order "$default_entry" "${active_entries[@]}")
  for entry in "${mime_entries[@]}"; do
    case "$(_app_label "$entry")" in
      Discord) set_default_apps discord.desktop x-scheme-handler/discord ;;
      Vesktop) set_default_apps vesktop.desktop x-scheme-handler/discord ;;
      Telegram) : ;;
      Element) : ;;
    esac || return 1
  done
}

###############################################################################
# CATEGORÍAS CREATIVAS, OFICINA, XOGOS E UTILIDADES
###############################################################################

# Instala ferramentas creativas heteroxéneas e rexistra os formatos nativos de
# cada unha sen pedir unha aplicación predeterminada común. As coincidencias
# resólvense pola orde estable das entradas; os casos baleiros fan visible que
# esas apps non teñen MIME propio nesta categoría.
install-category-creativity() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en creativity: $1"
    return 1
  fi

  local entries=(
    "pkg|OBS Studio|obs-studio|obs"
    "pkg|Krita|krita|krita"
    "pkg|GIMP|gimp|gimp"
    "pkg|Inkscape|inkscape|inkscape"
    "pkg|Blender|blender|blender"
    "pkg|Kdenlive|kdenlive|kdenlive"
    "pkg|Puddletag|puddletag|puddletag"
    "pkg|HandBrake|handbrake|handbrake"
  )
  local selected_entries=() active_entries=()
  local entry selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona apps creativas:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  _install_selected_packages "${selected_entries[@]}" || return 1

  for entry in "${active_entries[@]}"; do
    case "$(_app_label "$entry")" in
      "OBS Studio") : ;;
      Krita)
        set_default_apps org.kde.krita.desktop \
          application/x-krita image/openraster
        ;;
      GIMP) : ;;
      Inkscape)
        set_default_apps org.inkscape.Inkscape.desktop \
          image/svg+xml image/svg+xml-compressed application/postscript \
          application/illustrator application/eps
        ;;
      Blender) set_default_apps blender.desktop application/x-blender ;;
      Kdenlive)
        set_default_apps org.kde.kdenlive.desktop \
          application/x-kdenlive application/x-kdenlivetitle
        ;;
      Puddletag) : ;;
      HandBrake) : ;;
    esac || return 1
  done
}

# Instala aplicacións heteroxéneas de oficina e notas sen pedir unha
# predeterminada común. LibreOffice declara cada formato co executable
# especializado, mentres que ONLYOFFICE emprega un único lanzador para textos,
# follas de cálculo e presentacións. Obsidian queda sen MIME adicional.
install-category-office() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en office: $1"
    return 1
  fi

  local entries=(
    "pkg|LibreOffice|libreoffice-still libreoffice-still-gl libreoffice-still-es|libreoffice"
    "pkg|ONLYOFFICE|onlyoffice-bin|onlyoffice-desktopeditors"
    "pkg|Obsidian|obsidian|obsidian"
  )
  local selected_entries=() active_entries=()
  local entry selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona apps de oficina e notas:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  _install_selected_packages "${selected_entries[@]}" || return 1

  for entry in "${active_entries[@]}"; do
    case "$(_app_label "$entry")" in
      LibreOffice)
        set_default_apps libreoffice-writer.desktop \
          application/msword application/rtf application/vnd.oasis.opendocument.text \
          application/vnd.openxmlformats-officedocument.wordprocessingml.document text/rtf ||
          return 1
        set_default_apps libreoffice-calc.desktop \
          application/vnd.ms-excel application/vnd.oasis.opendocument.spreadsheet \
          application/vnd.openxmlformats-officedocument.spreadsheetml.sheet ||
          return 1
        set_default_apps libreoffice-impress.desktop \
          application/vnd.ms-powerpoint application/vnd.oasis.opendocument.presentation \
          application/vnd.openxmlformats-officedocument.presentationml.presentation ||
          return 1
        set_default_apps libreoffice-draw.desktop \
          application/vnd.oasis.opendocument.graphics
        ;;
      ONLYOFFICE)
        set_default_apps onlyoffice-desktopeditors.desktop \
          application/msword application/rtf application/vnd.oasis.opendocument.text \
          application/vnd.openxmlformats-officedocument.wordprocessingml.document text/rtf \
          application/vnd.ms-excel application/vnd.oasis.opendocument.spreadsheet \
          application/vnd.openxmlformats-officedocument.spreadsheetml.sheet \
          application/vnd.ms-powerpoint application/vnd.oasis.opendocument.presentation \
          application/vnd.openxmlformats-officedocument.presentationml.presentation
        ;;
      Obsidian) : ;;
    esac || return 1
  done
}

# Instala xogos e tendas sen pedir unha predeterminada común. Steam rexistra os
# seus protocolos; o resto das aplicacións aparecen con MIME baleiro para facer
# explícito o comportamento.
install-category-games() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en games: $1"
    return 1
  fi

  local entries=(
    "pkg|Steam|steam|steam"
    "pkg|Prism Launcher|prismlauncher|prismlauncher"
    "pkg|Lutris|lutris|lutris"
    "flatpak|Bottles|com.usebottles.bottles|flatpak run com.usebottles.bottles"
  )
  local selected_entries=() active_entries=()
  local entry selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona xogos e tendas:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  _install_selected_packages "${selected_entries[@]}" || return 1

  for entry in "${active_entries[@]}"; do
    case "$(_app_label "$entry")" in
      Steam)
        set_default_apps steam.desktop \
          x-scheme-handler/steam x-scheme-handler/steamlink
        ;;
      "Prism Launcher") : ;;
      Lutris) : ;;
      Bottles) : ;;
    esac || return 1
  done
}

# Instala utilidades heteroxéneas sen pedir unha predeterminada común.
# qBittorrent declara torrent/magnet e KeePassXC queda explicitamente sen
# asociacións novas controladas por esta categoría.
install-category-utilities() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en utilities: $1"
    return 1
  fi

  local entries=(
    "pkg|KeePassXC|keepassxc|keepassxc"
    "pkg|qBittorrent|qbittorrent|qbittorrent"
  )
  local selected_entries=() active_entries=()
  local entry selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona utilidades:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  _install_selected_packages "${selected_entries[@]}" || return 1

  for entry in "${active_entries[@]}"; do
    case "$(_app_label "$entry")" in
      KeePassXC) : ;;
      qBittorrent)
        set_default_apps org.qbittorrent.qBittorrent.desktop \
          application/x-bittorrent x-scheme-handler/magnet
        ;;
    esac || return 1
  done
}

###############################################################################
# CATEGORÍAS SEN APLICACIÓN PREDETERMINADA
###############################################################################

# Instala ferramentas de desenvolvemento e copia os módulos Bash opcionais.
# Docker habilita tamén o servizo e o grupo; non hai MIME nin clave Hyprland.
install-category-development() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en development: $1"
    return 1
  fi

  local entries=(
    "pkg|Git + GitHub CLI|git github-cli|git"
    "pkg|Docker + Compose|docker docker-compose docker-buildx|docker"
    "pkg|OpenCode|opencode|opencode"
    "flatpak|Bruno|com.usebruno.Bruno|bruno"
    "pkg|FileZilla|filezilla|filezilla"
  )
  local selected_entries=() active_entries=()
  local selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona apps de desenvolvemento:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  _install_selected_packages "${selected_entries[@]}" || return 1

  if _selection_has "Git + GitHub CLI" "${selected_entries[@]}"; then
    mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" || return 1
    replace_file \
      "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/203-git" \
      "$HOME/.local/share/gallaecia-dots/bashrc/203-git" || return 1
  fi

  if _selection_has "Docker + Compose" "${selected_entries[@]}"; then
    mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" || return 1
    replace_file \
      "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/204-docker" \
      "$HOME/.local/share/gallaecia-dots/bashrc/204-docker" || return 1
    sudo systemctl enable docker.service || return 1
    sudo usermod -aG docker "$USER" || return 1
  fi
}

# Instala aplicacións e ferramentas de rede e privacidade. A categoría non modifica
# Hyprland, MIME nin ficheiros opcionais.
install-category-network() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en network: $1"
    return 1
  fi

  local entries=(
    "flatpak|Proton VPN|com.protonvpn.www|protonvpn"
    "pkg|OpenSSH|openssh|ssh"
    "pkg|WireGuard|wireguard-tools|wg"
  )
  local selected_entries=() active_entries=()
  local selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona apps de rede e privacidade:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  _install_selected_packages "${selected_entries[@]}" || return 1

  if _selection_has OpenSSH "${selected_entries[@]}"; then
    sudo systemctl enable sshd.service || return 1
  fi
}

# Instala yt-dlp/SpotDL e as súas configuracións e módulos Bash opcionais.
# Non hai aplicación predeterminada nin asociacións MIME nesta categoría.
install-category-downloads() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en downloads: $1"
    return 1
  fi

  local entries=(
    "pkg|yt-dlp|yt-dlp|yt-dlp"
    "pipx|SpotDL|spotdl|spotdl"
  )
  local selected_entries=() active_entries=()
  local selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona ferramentas de descarga e personalización:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  _install_selected_packages "${selected_entries[@]}" || return 1

  if _selection_has yt-dlp "${selected_entries[@]}"; then
    mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" || return 1
    replace_path "$DOTFILES_DIR/optional/.config/yt-dlp" "$HOME/.config/yt-dlp" || return 1
    replace_file \
      "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/201-yt-dlp" \
      "$HOME/.local/share/gallaecia-dots/bashrc/201-yt-dlp" || return 1
  fi

  if _selection_has SpotDL "${selected_entries[@]}"; then
    mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" || return 1
    replace_path "$DOTFILES_DIR/optional/.config/spotdl" "$HOME/.config/spotdl" || return 1
    replace_file \
      "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/202-spotdl" \
      "$HOME/.local/share/gallaecia-dots/bashrc/202-spotdl" || return 1
  fi
}

###############################################################################
# CATEGORÍAS DE SERVIDOR
###############################################################################

# Instala editores de terminal no servidor sen configurar Hyprland nin o tema
# dinámico de Noctalia. A base chama esta categoría con `--required`.
install-category-server-editor() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en server-editor: $1"
    return 1
  fi

  local entries=(
    "pkg|Neovim|neovim neovim-base16-git|nvim"
    "pkg|Helix|helix|hx"
    "pkg|Vim|vim|vim"
    "pkg|Nano|nano|nano"
    "pkg|Micro|micro|micro"
  )
  local selected_entries=() active_entries=()
  local selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona editor ou editores de terminal:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  _install_selected_packages "${selected_entries[@]}"
}

# Instala ferramentas de administración e monitorización de terminal. A
# categoría é heteroxénea e non precisa unha aplicación predeterminada.
install-category-administration() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en administration: $1"
    return 1
  fi

  local entries=(
    "pkg|tmux|tmux|tmux"
    "pkg|btop|btop|btop"
    "pkg|htop|htop|htop"
  )
  local selected_entries=() active_entries=()
  local selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona ferramentas de administración:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  _install_selected_packages "${selected_entries[@]}"
}

# Instala Yazi e os ficheiros de terminal que non dependen do flavor xerado por
# Noctalia. `mediainfo` acompáñao porque un dos plugins usa ese executable.
install-category-server-files() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en server-files: $1"
    return 1
  fi

  local entries=("pkg|Yazi|yazi mediainfo|yazi")
  local selected_entries=() active_entries=()
  local selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona ferramentas de ficheiros:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  _install_selected_packages "${selected_entries[@]}" || return 1

  if _selection_has Yazi "${selected_entries[@]}"; then
    ensure_directory "$HOME/.config/yazi" || return 1
    replace_file \
      "$DOTFILES_DIR/optional/.config/yazi/init.lua" \
      "$HOME/.config/yazi/init.lua" || return 1
    replace_file \
      "$DOTFILES_DIR/optional/.config/yazi/keymap.toml" \
      "$HOME/.config/yazi/keymap.toml" || return 1
    replace_file \
      "$DOTFILES_DIR/optional/.config/yazi/yazi.toml" \
      "$HOME/.config/yazi/yazi.toml" || return 1
    ya pkg add yazi-rs/plugins:git || return 1
    ya pkg add yazi-rs/plugins:mount || return 1
    ya pkg add yazi-rs/plugins:chmod || return 1
    ya pkg add boydaihungst/mediainfo || return 1
  fi
}

# Instala ferramentas de despregamento. Git e Docker conservan os seus módulos
# Bash opcionais; Docker queda habilitado para o seguinte arranque e o usuario
# incorpórase ao grupo correspondente.
install-category-deployment() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en deployment: $1"
    return 1
  fi

  local entries=(
    "pkg|Git + GitHub CLI|git github-cli|git"
    "pkg|Docker + Compose|docker docker-compose docker-buildx|docker"
  )
  local selected_entries=() active_entries=()
  local selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona ferramentas de despregamento:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  _install_selected_packages "${selected_entries[@]}" || return 1

  if _selection_has "Git + GitHub CLI" "${selected_entries[@]}"; then
    mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" || return 1
    replace_file \
      "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/203-git" \
      "$HOME/.local/share/gallaecia-dots/bashrc/203-git" || return 1
  fi

  if _selection_has "Docker + Compose" "${selected_entries[@]}"; then
    mkdir -p "$HOME/.local/share/gallaecia-dots/bashrc" || return 1
    replace_file \
      "$DOTFILES_DIR/optional/.local/share/gallaecia-dots/bashrc/204-docker" \
      "$HOME/.local/share/gallaecia-dots/bashrc/204-docker" || return 1
    sudo systemctl enable docker.service || return 1
    sudo usermod -aG docker "$USER" || return 1
  fi
}

# Instala opcionalmente OpenSSH e WireGuard. OpenSSH queda habilitado para o
# seguinte arranque sen iniciar o daemon; NetworkManager xestiona nativamente
# os perfís de WireGuard e non precisa outro servizo.
install-category-server-network() {
  local required=false
  if [ "${1:-}" = "--required" ]; then required=true; shift; fi
  if [ $# -ne 0 ]; then
    error "Opción descoñecida en server-network: $1"
    return 1
  fi

  local entries=(
    "pkg|OpenSSH|openssh|ssh"
    "pkg|WireGuard|wireguard-tools|wg"
  )
  local selected_entries=() active_entries=()
  local selection_status

  _prepare_category_apps \
    selected_entries active_entries \
    "$required" "Selecciona ferramentas de rede:" "${entries[@]}"
  selection_status=$?
  case "$selection_status" in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  [ ${#active_entries[@]} -gt 0 ] || return 0
  _install_selected_packages "${selected_entries[@]}" || return 1

  if _selection_has OpenSSH "${selected_entries[@]}"; then
    sudo systemctl enable sshd.service || return 1
  fi
}
