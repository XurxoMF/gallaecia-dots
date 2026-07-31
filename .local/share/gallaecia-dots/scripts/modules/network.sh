# shellcheck shell=bash

###############################################################################
# MÓDULO PÚBLICO DE REDE
#
# Noctalia cobre as operacións diarias de Wi-Fi e a activación das VPN. Este
# módulo completa a administración de perfís que non ofrece a súa interface:
#
#   vpn-list         -> mostra VPN e WireGuard gardadas.
#   vpn-import       -> importa un ficheiro compatible con NetworkManager.
#   vpn-rename       -> cambia o nome visible dun perfil.
#   vpn-clone        -> duplica un perfil cun UUID novo.
#   vpn-export       -> exporta unha VPN mediante o seu plugin.
#   vpn-autoconnect  -> asocia a VPN a unha conexión base para autoiniciala.
#   vpn-edit         -> abre o editor interactivo avanzado de nmcli.
#   vpn-delete       -> elimina un ou varios perfís tras confirmar.
#
# Todas as modificacións identifican o perfil polo UUID para evitar colisións
# entre nomes repetidos. Os selectores mostran nome, tipo, estado e UUID.
###############################################################################

# Centraliza a axuda dos comandos públicos sen ocultar o fluxo dos seus parsers.
_network_help() {
  case "$1" in
    vpn-list)
      cat <<'EOF'
USO
  vpn-list [OPCIÓNS]

DESCRICIÓN
  Lista os perfís VPN e WireGuard gardados en NetworkManager.

OPCIÓNS
  --active
      Mostra só os perfís activos.

  --plain
      Escribe unha táboa TSV sen formato de Gum.

  -h, --help
      Mostra esta axuda.

RESULTADO
  Mostra nome, tipo, estado e UUID. Devolve 0 tamén cando non hai ningún perfil.

EXEMPLOS
  vpn-list
  vpn-list --active --plain
EOF
      ;;
    vpn-import)
      cat <<'EOF'
USO
  vpn-import [OPCIÓNS] [FICHEIRO]

DESCRICIÓN
  Importa un ficheiro VPN mediante NetworkManager. Detecta OpenVPN para `.ovpn`
  e WireGuard para `.conf`; outros formatos requiren `--type`.

PARÁMETROS
  FICHEIRO
      Configuración que entende o plugin de NetworkManager correspondente.

OPCIÓNS
  --origin RUTA
      Ficheiro de configuración; se se omite, ábrese o selector.

  --type TIPO
      Tipo aceptado por `nmcli connection import`, por exemplo `openvpn`,
      `wireguard`, `vpnc` ou `openconnect`.

  --name NOME
      Nome que recibirá o perfil despois de importalo.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite unha ruta que comece por guión.

RESULTADO
  Crea un perfil persistente de NetworkManager e mostra o seu UUID. Devolve un
  código distinto de 0 se falta o plugin necesario ou a importación falla.

EXEMPLOS
  vpn-import
  vpn-import --origin ~/Descargas/traballo.ovpn
  vpn-import --origin ~/Descargas/wg0.conf --type wireguard --name Traballo
EOF
      ;;
    vpn-rename)
      cat <<'EOF'
USO
  vpn-rename [OPCIÓNS] [VPN] [NOVO_NOME]

DESCRICIÓN
  Cambia o nome visible dun perfil VPN ou WireGuard.

PARÁMETROS
  [VPN]
      Nome ou UUID. Se se omite, abre un selector.

  [NOVO_NOME]
      Nome novo. Se se omite, abre un input.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e trata os valores posteriores como parámetros.

RESULTADO
  Modifica `connection.id` conservando o UUID e o resto da configuración.

EXEMPLOS
  vpn-rename
  vpn-rename traballo "VPN da oficina"
EOF
      ;;
    vpn-clone)
      cat <<'EOF'
USO
  vpn-clone [OPCIÓNS] [VPN] [NOVO_NOME]

DESCRICIÓN
  Duplica un perfil VPN ou WireGuard cun nome e UUID novos.

PARÁMETROS
  [VPN]
      Nome ou UUID do perfil de orixe. Se se omite, abre un selector.

  [NOVO_NOME]
      Nome da copia. Se se omite, abre un input.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e trata os valores posteriores como parámetros.

RESULTADO
  Crea unha copia persistente sen modificar o perfil orixinal.

EXEMPLOS
  vpn-clone
  vpn-clone traballo "Traballo - probas"
EOF
      ;;
    vpn-export)
      cat <<'EOF'
USO
  vpn-export [OPCIÓNS] [VPN] [FICHEIRO]

DESCRICIÓN
  Exporta unha VPN mediante o plugin de NetworkManager que a xestiona.
  NetworkManager non ofrece esta exportación para perfís WireGuard.

PARÁMETROS
  [VPN]
      Nome ou UUID. Se se omite, abre un selector.

  [FICHEIRO]
      Ruta de saída. Se se omite, propón un ficheiro en `~/Descargas`.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e trata os valores posteriores como parámetros.

RESULTADO
  Crea o ficheiro exportado. Pide confirmación antes de sobrescribir unha ruta.

EXEMPLOS
  vpn-export
  vpn-export traballo ~/Descargas/traballo.ovpn
EOF
      ;;
    vpn-autoconnect)
      cat <<'EOF'
USO
  vpn-autoconnect [OPCIÓNS] [VPN] [CONEXIÓN_BASE]

DESCRICIÓN
  Asocia unha VPN a unha Wi-Fi, Ethernet ou outra conexión base para activala
  automaticamente con ela. `--disable` retira todas esas asociacións.

PARÁMETROS
  [VPN]
      Nome ou UUID. Se se omite, abre un selector.

  [CONEXIÓN_BASE]
      Nome ou UUID da conexión que debe iniciar a VPN. Se se omite, abre un
      selector. Non se usa con `--disable`.

OPCIÓNS
  --disable
      Desactiva a autoconexión retirando a VPN de todas as conexións base.

  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e trata os valores posteriores como parámetros.

RESULTADO
  Modifica `connection.secondaries` das conexións base. Esta é a vía que
  NetworkManager implementa para iniciar automaticamente VPNs clásicas.

EXEMPLOS
  vpn-autoconnect
  vpn-autoconnect traballo "Wi-Fi da casa"
  vpn-autoconnect --disable traballo
EOF
      ;;
    vpn-edit)
      cat <<'EOF'
USO
  vpn-edit [OPCIÓNS] [VPN]

DESCRICIÓN
  Abre o editor interactivo avanzado de NetworkManager para un perfil.

PARÁMETROS
  [VPN]
      Nome ou UUID. Se se omite, abre un selector.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e permite un identificador que comece por guión.

CONTROIS
  help
      Mostra os comandos e propiedades dispoñibles dentro do editor.

  save
      Garda os cambios.

  quit
      Pecha o editor.

RESULTADO
  Pode modificar calquera propiedade do perfil que se garde desde `nmcli`.

EXEMPLOS
  vpn-edit
  vpn-edit traballo
EOF
      ;;
    vpn-delete)
      cat <<'EOF'
USO
  vpn-delete [OPCIÓNS] [VPN...]

DESCRICIÓN
  Elimina un ou varios perfís VPN ou WireGuard de NetworkManager.

PARÁMETROS
  [VPN...]
      Nomes ou UUID. Se se omiten, abre un selector múltiple.

OPCIÓNS
  -h, --help
      Mostra esta axuda.

  --
      Remata as opcións e trata os valores posteriores como identificadores.

CONTROIS
  Tab ou Ctrl+Espazo
      Marca ou desmarca perfís no selector.

  Enter
      Confirma a selección.

  Esc
      Cancela sen eliminar nada.

RESULTADO
  Elimina os perfís só despois dunha confirmación explícita. Cancelar devolve 0
  e non modifica NetworkManager.

EXEMPLOS
  vpn-delete
  vpn-delete traballo persoal
EOF
      ;;
  esac
}

# Comproba a dependencia técnica e os wrappers visuais cargados pola shell.
_network_require_helpers() {
  local helper

  if ! command -v nmcli &> /dev/null; then
    printf 'NetworkManager non está dispoñible: falta o comando nmcli.\n' >&2
    return 1
  fi

  for helper in \
    choose confirm filter input table \
    error info success warning; do
    if ! declare -F "$helper" &> /dev/null; then
      printf 'Falta o helper público %s; carga todos os módulos de Gallaecia.\n' \
        "$helper" >&2
      return 1
    fi
  done
}

# Recibe un UUID e devolve 0 cando figura entre as conexións activas.
_network_uuid_is_active() {
  local expected_uuid="$1"
  local active_uuids
  local active_uuid

  active_uuids="$(nmcli --escape no --get-values UUID \
    connection show --active)" || return 1

  while IFS= read -r active_uuid; do
    if [ "$active_uuid" = "$expected_uuid" ]; then
      return 0
    fi
  done <<< "$active_uuids"

  return 1
}

# Imprime unha fila TSV por perfil VPN ou WireGuard. O último campo é sempre o
# UUID e úsase como identificador interno despois dos selectores.
_network_vpn_rows() {
  local only_active="${1:-false}"
  local profiles
  local uuid connection_type name vpn_service display_type state

  profiles="$(nmcli --escape no --terse --fields UUID,TYPE \
    connection show)" || return 1

  while IFS=: read -r uuid connection_type; do
    case "$connection_type" in
      vpn|wireguard) ;;
      *) continue ;;
    esac

    if $only_active && ! _network_uuid_is_active "$uuid"; then
      continue
    fi

    name="$(nmcli --escape no --get-values connection.id \
      connection show uuid "$uuid")" || return 1
    if [ "$connection_type" = "vpn" ]; then
      vpn_service="$(nmcli --escape no --get-values vpn.service-type \
        connection show uuid "$uuid")" || return 1
      display_type="${vpn_service##*.}"
      if [ -z "$display_type" ]; then
        display_type="vpn"
      fi
    else
      display_type="wireguard"
    fi

    if _network_uuid_is_active "$uuid"; then
      state="activa"
    else
      state="inactiva"
    fi

    printf '%s\t%s\t%s\t%s\n' "$name" "$display_type" "$state" "$uuid"
  done <<< "$profiles"
}

# Lista como filas TSV todas as conexións que poden actuar como base dunha VPN.
# Exclúe VPN e WireGuard porque `connection.secondaries` pertence á conexión
# primaria que proporciona o acceso real á rede.
_network_base_connection_rows() {
  local profiles
  local uuid connection_type name state

  profiles="$(nmcli --escape no --terse --fields UUID,TYPE \
    connection show)" || return 1

  while IFS=: read -r uuid connection_type; do
    case "$connection_type" in
      vpn|wireguard) continue ;;
    esac

    name="$(nmcli --escape no --get-values connection.id \
      connection show uuid "$uuid")" || return 1
    if _network_uuid_is_active "$uuid"; then
      state="activa"
    else
      state="inactiva"
    fi
    printf '%s\t%s\t%s\t%s\n' "$name" "$connection_type" "$state" "$uuid"
  done <<< "$profiles"
}

# Resolve un nome ou UUID e rexeita perfís VPN/WireGuard, pois aquí se necesita
# unha conexión primaria á que asociar a VPN como secundaria.
_network_resolve_base_uuid() {
  local identifier="$1"
  local uuid connection_type

  if ! uuid="$(nmcli --escape no --get-values connection.uuid \
    connection show "$identifier")"; then
    error "Non se atopou a conexión base: $identifier"
    return 1
  fi
  connection_type="$(nmcli --escape no --get-values connection.type \
    connection show uuid "$uuid")" || return 1

  case "$connection_type" in
    vpn|wireguard)
      error "A conexión base non pode ser outra VPN: $identifier"
      return 1
      ;;
  esac

  printf '%s\n' "$uuid"
}

# Resolve unha conexión base recibida ou mostra un selector filtrable. Imprime
# sempre o UUID gardado na última columna.
_network_choose_base_uuid() {
  local identifier="${1:-}"
  local rows selected_row

  if [ -n "$identifier" ]; then
    _network_resolve_base_uuid "$identifier"
    return
  fi

  rows="$(_network_base_connection_rows)" || return 1
  if [ -z "$rows" ]; then
    info "Non hai conexións base dispoñibles." >&2
    return 2
  fi
  selected_row="$(printf '%s\n' "$rows" |
    filter --header "Escolle a conexión que debe iniciar a VPN:")" ||
    return 2
  if [ -z "$selected_row" ]; then
    return 2
  fi

  printf '%s\n' "${selected_row##*$'\t'}"
}

# Devolve 0 se a lista `connection.secondaries` da conexión base contén o UUID
# recibido. NetworkManager imprime a propiedade como unha lista separada por
# comas; a separación en palabras posterior é deliberada.
_network_base_has_secondary() {
  local base_uuid="$1"
  local vpn_uuid="$2"
  local secondaries secondary_uuid

  secondaries="$(nmcli --escape no --get-values connection.secondaries \
    connection show uuid "$base_uuid")" || return 2
  secondaries="${secondaries//,/ }"

  for secondary_uuid in $secondaries; do
    if [ "$secondary_uuid" = "$vpn_uuid" ]; then
      return 0
    fi
  done

  return 1
}

# Recibe unha cabeceira e `single` ou `multiple`. Imprime as filas seleccionadas
# completas para que o chamador poida mostrar nomes e extraer os UUID finais.
_network_select_vpns() {
  local header="$1"
  local mode="$2"
  local rows selection

  rows="$(_network_vpn_rows false)" || return 1
  if [ -z "$rows" ]; then
    info "Non hai perfís VPN ou WireGuard gardados." >&2
    return 2
  fi

  if [ "$mode" = "multiple" ]; then
    selection="$(printf '%s\n' "$rows" |
      filter --header "$header" -- --no-limit)" || return 2
  else
    selection="$(printf '%s\n' "$rows" |
      filter --header "$header")" || return 2
  fi

  if [ -z "$selection" ]; then
    return 2
  fi

  printf '%s\n' "$selection"
}

# Resolve un nome ou UUID recibido polo usuario e comproba que o perfil sexa
# realmente VPN/WireGuard. Imprime un UUID inequívoco.
_network_resolve_vpn_uuid() {
  local identifier="$1"
  local uuid connection_type

  if ! uuid="$(nmcli --escape no --get-values connection.uuid \
    connection show "$identifier")"; then
    error "Non se atopou o perfil: $identifier"
    return 1
  fi
  connection_type="$(nmcli --escape no --get-values connection.type \
    connection show uuid "$uuid")" || return 1

  case "$connection_type" in
    vpn|wireguard)
      printf '%s\n' "$uuid"
      ;;
    *)
      error "O perfil non é unha VPN nin WireGuard: $identifier"
      return 1
      ;;
  esac
}

# Recibe un identificador opcional. Se está baleiro abre o selector e imprime o
# UUID gardado na última columna da fila.
_network_choose_vpn_uuid() {
  local identifier="${1:-}"
  local selected_row

  if [ -n "$identifier" ]; then
    _network_resolve_vpn_uuid "$identifier"
    return
  fi

  selected_row="$(_network_select_vpns "Escolle unha VPN:" single)"
  case $? in
    0) printf '%s\n' "${selected_row##*$'\t'}" ;;
    2) return 2 ;;
    *) return 1 ;;
  esac
}

# Imprime o nome actual dun perfil identificado polo UUID.
_network_vpn_name() {
  nmcli --escape no --get-values connection.id connection show uuid "$1"
}

# Lista os perfís en táboa estática de Gum ou TSV para consumo desde scripts.
vpn-list() {
  local only_active=false
  local plain=false
  local rows

  while (($#)); do
    case "$1" in
      --active)
        only_active=true
        ;;
      --plain)
        plain=true
        ;;
      -h|--help)
        _network_help vpn-list
        return 0
        ;;
      --)
        shift
        if [ $# -ne 0 ]; then
          printf 'vpn-list non admite parámetros. Usa vpn-list --help.\n' >&2
          return 1
        fi
        break
        ;;
      *)
        printf 'Opción descoñecida: %s. Usa vpn-list --help.\n' "$1" >&2
        return 1
        ;;
    esac
    shift
  done

  _network_require_helpers || return 1
  rows="$(_network_vpn_rows "$only_active")" || return 1
  if [ -z "$rows" ]; then
    info "Non hai perfís VPN que cumpran o filtro."
    return 0
  fi

  if $plain; then
    printf 'NOME\tTIPO\tESTADO\tUUID\n%s\n' "$rows"
  else
    printf '%s\n' "$rows" |
      table -- --separator $'\t' \
        --columns "Nome,Tipo,Estado,UUID" --print
  fi
}

# Importa unha configuración e renomea o UUID devolto cando se pediu `--name`.
vpn-import() {
  local vpn_type=""
  local requested_name=""
  local values=()
  local file_path=""
  local imported_uuid=""
  local uuids_before uuids_after candidate_uuid known_uuid known_uuid_value
  local new_profiles=0

  while (($#)); do
    case "$1" in
      --origin)
        if [ $# -lt 2 ]; then
          printf 'Falta RUTA para --origin. Usa vpn-import --help.\n' >&2
          return 1
        fi
        file_path="$2"
        shift
        ;;
      --type)
        if [ $# -lt 2 ]; then
          printf 'Falta TIPO para --type. Usa vpn-import --help.\n' >&2
          return 1
        fi
        vpn_type="$2"
        shift
        ;;
      --name)
        if [ $# -lt 2 ]; then
          printf 'Falta NOME para --name. Usa vpn-import --help.\n' >&2
          return 1
        fi
        requested_name="$2"
        shift
        ;;
      -h|--help)
        _network_help vpn-import
        return 0
        ;;
      --)
        shift
        values+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa vpn-import --help.\n' "$1" >&2
        return 1
        ;;
      *)
        values+=("$1")
        ;;
    esac
    shift
  done

  if [ -z "$file_path" ] && [ ${#values[@]} -gt 0 ]; then
    file_path="${values[0]}"
    values=("${values[@]:1}")
  fi
  if [ ${#values[@]} -gt 0 ]; then
    printf 'vpn-import recibiu demasiados ficheiros. Usa vpn-import --help.\n' >&2
    return 1
  fi

  _network_require_helpers || return 1
  if [ -z "$file_path" ]; then
    file_path="$(select_file --header "Selecciona a configuración da VPN" -- \
      "$HOME/Descargas")" || return 0
  fi
  if [ ! -f "$file_path" ]; then
    printf 'Non existe o ficheiro: %s\n' "$file_path" >&2
    return 1
  fi

  if [ -z "$vpn_type" ]; then
    case "${file_path,,}" in
      *.ovpn) vpn_type="openvpn" ;;
      *.conf) vpn_type="wireguard" ;;
      *)
        vpn_type="$(input --header "Tipo de VPN para NetworkManager:")" ||
          return 0
        ;;
    esac
  fi
  if [ -z "$vpn_type" ]; then
    warning "Importación cancelada."
    return 0
  fi

  uuids_before="$(nmcli --escape no --get-values UUID \
    connection show)" || return 1
  if ! nmcli connection import type "$vpn_type" file "$file_path"; then
    return 1
  fi
  uuids_after="$(nmcli --escape no --get-values UUID \
    connection show)" || return 1

  # `nmcli connection import` imprime unha mensaxe humana dependente do locale.
  # Comparar os UUID anteriores e posteriores evita analizar ese texto.
  while IFS= read -r candidate_uuid; do
    if [ -z "$candidate_uuid" ]; then
      continue
    fi

    known_uuid=false
    while IFS= read -r known_uuid_value; do
      if [ "$known_uuid_value" = "$candidate_uuid" ]; then
        known_uuid=true
        break
      fi
    done <<< "$uuids_before"

    if ! $known_uuid; then
      imported_uuid="$candidate_uuid"
      ((new_profiles += 1))
    fi
  done <<< "$uuids_after"

  if [ "$new_profiles" -ne 1 ]; then
    error "A VPN importouse, pero non se puido identificar un único UUID novo."
    return 1
  fi

  if [ -n "$requested_name" ]; then
    nmcli connection modify uuid "$imported_uuid" \
      connection.id "$requested_name" || return 1
  fi

  success "VPN importada co UUID $imported_uuid."
}

# Cambia `connection.id`; resolve ou selecciona primeiro o UUID para non depender
# de que o nome actual sexa único.
vpn-rename() {
  local values=()
  local identifier="" new_name="" uuid old_name

  while (($#)); do
    case "$1" in
      -h|--help)
        _network_help vpn-rename
        return 0
        ;;
      --)
        shift
        values+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa vpn-rename --help.\n' "$1" >&2
        return 1
        ;;
      *)
        values+=("$1")
        ;;
    esac
    shift
  done
  if [ ${#values[@]} -gt 2 ]; then
    printf 'vpn-rename admite [VPN] [NOVO_NOME]. Usa --help.\n' >&2
    return 1
  fi

  _network_require_helpers || return 1
  identifier="${values[0]:-}"
  new_name="${values[1]:-}"
  uuid="$(_network_choose_vpn_uuid "$identifier")"
  case $? in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  old_name="$(_network_vpn_name "$uuid")" || return 1

  if [ -z "$new_name" ]; then
    new_name="$(input --header "Novo nome da VPN:" -- --value "$old_name")" ||
      return 0
  fi
  if [ -z "$new_name" ]; then
    warning "O nome non pode quedar baleiro."
    return 1
  fi

  nmcli connection modify uuid "$uuid" connection.id "$new_name" || return 1
  success "VPN renomeada: $old_name → $new_name."
}

# Duplica o perfil seleccionado; NetworkManager conserva a configuración e crea
# automaticamente un UUID diferente.
vpn-clone() {
  local values=()
  local identifier="" new_name="" uuid old_name

  while (($#)); do
    case "$1" in
      -h|--help)
        _network_help vpn-clone
        return 0
        ;;
      --)
        shift
        values+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa vpn-clone --help.\n' "$1" >&2
        return 1
        ;;
      *)
        values+=("$1")
        ;;
    esac
    shift
  done
  if [ ${#values[@]} -gt 2 ]; then
    printf 'vpn-clone admite [VPN] [NOVO_NOME]. Usa --help.\n' >&2
    return 1
  fi

  _network_require_helpers || return 1
  identifier="${values[0]:-}"
  new_name="${values[1]:-}"
  uuid="$(_network_choose_vpn_uuid "$identifier")"
  case $? in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  old_name="$(_network_vpn_name "$uuid")" || return 1

  if [ -z "$new_name" ]; then
    new_name="$(input --header "Nome da copia:" -- \
      --value "$old_name - copia")" || return 0
  fi
  if [ -z "$new_name" ]; then
    warning "O nome non pode quedar baleiro."
    return 1
  fi

  nmcli connection clone uuid "$uuid" "$new_name" || return 1
  success "Creouse a copia $new_name."
}

# Exporta só perfís `vpn`, porque `nmcli connection export` non admite
# WireGuard. Confirma antes de substituír un ficheiro xa existente.
vpn-export() {
  local values=()
  local identifier="" output_file="" uuid name connection_type safe_name

  while (($#)); do
    case "$1" in
      -h|--help)
        _network_help vpn-export
        return 0
        ;;
      --)
        shift
        values+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa vpn-export --help.\n' "$1" >&2
        return 1
        ;;
      *)
        values+=("$1")
        ;;
    esac
    shift
  done
  if [ ${#values[@]} -gt 2 ]; then
    printf 'vpn-export admite [VPN] [FICHEIRO]. Usa --help.\n' >&2
    return 1
  fi

  _network_require_helpers || return 1
  identifier="${values[0]:-}"
  output_file="${values[1]:-}"
  uuid="$(_network_choose_vpn_uuid "$identifier")"
  case $? in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  name="$(_network_vpn_name "$uuid")" || return 1
  connection_type="$(nmcli --escape no --get-values connection.type \
    connection show uuid "$uuid")" || return 1
  if [ "$connection_type" != "vpn" ]; then
    error "NetworkManager non permite exportar WireGuard con nmcli."
    return 1
  fi

  if [ -z "$output_file" ]; then
    safe_name="${name// /-}"
    safe_name="${safe_name//\//-}"
    output_file="$(input --header "Ficheiro de saída:" -- \
      --value "$HOME/Descargas/$safe_name.conf")" || return 0
  fi
  if [ -z "$output_file" ]; then
    warning "Exportación cancelada."
    return 0
  fi
  if [ -e "$output_file" ] &&
    ! confirm "Sobrescribir $output_file?" -- --default=false; then
    info "Exportación cancelada."
    return 0
  fi

  nmcli connection export uuid "$uuid" "$output_file" || return 1
  success "VPN exportada en $output_file."
}

# Activa a autoconexión engadindo a VPN a `connection.secondaries` dunha
# conexión base. Con --disable percorre explicitamente todas as conexións base e
# retira o UUID da VPN onde apareza. NetworkManager non implementa
# `connection.autoconnect` para perfís VPN clásicos.
vpn-autoconnect() {
  local disable=false
  local values=()
  local identifier="" base_identifier=""
  local vpn_uuid vpn_name vpn_type base_uuid base_name
  local profiles profile_uuid profile_type secondary_status removed=0

  while (($#)); do
    case "$1" in
      --disable)
        disable=true
        ;;
      -h|--help)
        _network_help vpn-autoconnect
        return 0
        ;;
      --)
        shift
        values+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa vpn-autoconnect --help.\n' "$1" >&2
        return 1
        ;;
      *)
        values+=("$1")
        ;;
    esac
    shift
  done

  if $disable && [ ${#values[@]} -gt 1 ]; then
    printf 'Con --disable só se admite [VPN]. Usa vpn-autoconnect --help.\n' >&2
    return 1
  fi
  if ! $disable && [ ${#values[@]} -gt 2 ]; then
    printf 'vpn-autoconnect admite [VPN] [CONEXIÓN_BASE]. Usa --help.\n' >&2
    return 1
  fi

  _network_require_helpers || return 1
  identifier="${values[0]:-}"
  base_identifier="${values[1]:-}"
  vpn_uuid="$(_network_choose_vpn_uuid "$identifier")"
  case $? in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac

  vpn_name="$(_network_vpn_name "$vpn_uuid")" || return 1
  vpn_type="$(nmcli --escape no --get-values connection.type \
    connection show uuid "$vpn_uuid")" || return 1
  if [ "$vpn_type" != "vpn" ]; then
    error "A autoconexión mediante connection.secondaries só admite VPNs clásicas, non WireGuard."
    return 1
  fi

  if $disable; then
    profiles="$(nmcli --escape no --terse --fields UUID,TYPE \
      connection show)" || return 1

    while IFS=: read -r profile_uuid profile_type; do
      case "$profile_type" in
        vpn|wireguard) continue ;;
      esac

      _network_base_has_secondary "$profile_uuid" "$vpn_uuid"
      secondary_status=$?
      if [ "$secondary_status" -eq 2 ]; then
        return 1
      fi
      if [ "$secondary_status" -ne 0 ]; then
        continue
      fi

      nmcli connection modify uuid "$profile_uuid" \
        -connection.secondaries "$vpn_uuid" || return 1
      ((removed += 1))
    done <<< "$profiles"

    if [ "$removed" -eq 0 ]; then
      info "$vpn_name non tiña ningunha autoconexión configurada."
    else
      success "Autoconexión retirada de $removed conexión(s) base para $vpn_name."
    fi
    return 0
  fi

  base_uuid="$(_network_choose_base_uuid "$base_identifier")"
  case $? in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac
  base_name="$(nmcli --escape no --get-values connection.id \
    connection show uuid "$base_uuid")" || return 1

  _network_base_has_secondary "$base_uuid" "$vpn_uuid"
  secondary_status=$?
  if [ "$secondary_status" -eq 2 ]; then
    return 1
  fi
  if [ "$secondary_status" -eq 0 ]; then
    info "$vpn_name xa se inicia automaticamente con $base_name."
    return 0
  fi

  nmcli connection modify uuid "$base_uuid" \
    +connection.secondaries "$vpn_uuid" || return 1
  success "$vpn_name iniciarase automaticamente con $base_name."
}

# Abre o editor propio de nmcli despois de resolver o perfil seleccionado.
vpn-edit() {
  local values=()
  local identifier="" uuid

  while (($#)); do
    case "$1" in
      -h|--help)
        _network_help vpn-edit
        return 0
        ;;
      --)
        shift
        values+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa vpn-edit --help.\n' "$1" >&2
        return 1
        ;;
      *)
        values+=("$1")
        ;;
    esac
    shift
  done
  if [ ${#values[@]} -gt 1 ]; then
    printf 'vpn-edit admite unha única VPN. Usa vpn-edit --help.\n' >&2
    return 1
  fi

  _network_require_helpers || return 1
  identifier="${values[0]:-}"
  uuid="$(_network_choose_vpn_uuid "$identifier")"
  case $? in
    0) ;;
    2) return 0 ;;
    *) return 1 ;;
  esac

  nmcli connection edit uuid "$uuid"
}

# Resolve argumentos ou un selector múltiple e elimina todos os UUID nunha
# operación, pero unicamente despois de mostrar os nomes e obter confirmación.
vpn-delete() {
  local values=()
  local uuids=()
  local names=()
  local selected_rows="" row identifier uuid name

  while (($#)); do
    case "$1" in
      -h|--help)
        _network_help vpn-delete
        return 0
        ;;
      --)
        shift
        values+=("$@")
        break
        ;;
      -*)
        printf 'Opción descoñecida: %s. Usa vpn-delete --help.\n' "$1" >&2
        return 1
        ;;
      *)
        values+=("$1")
        ;;
    esac
    shift
  done

  _network_require_helpers || return 1
  if [ ${#values[@]} -eq 0 ]; then
    selected_rows="$(_network_select_vpns \
      "Selecciona as VPN que queres eliminar:" multiple)"
    case $? in
      0) ;;
      2) return 0 ;;
      *) return 1 ;;
    esac

    while IFS= read -r row; do
      if [ -z "$row" ]; then
        continue
      fi
      uuid="${row##*$'\t'}"
      name="$(_network_vpn_name "$uuid")" || return 1
      uuids+=("$uuid")
      names+=("$name")
    done <<< "$selected_rows"
  else
    for identifier in "${values[@]}"; do
      uuid="$(_network_resolve_vpn_uuid "$identifier")" || return 1
      name="$(_network_vpn_name "$uuid")" || return 1
      uuids+=("$uuid")
      names+=("$name")
    done
  fi

  if [ ${#uuids[@]} -eq 0 ]; then
    return 0
  fi
  if ! confirm \
    "Eliminar definitivamente estes perfís: ${names[*]}?" -- --default=false; then
    info "Eliminación cancelada."
    return 0
  fi

  for uuid in "${uuids[@]}"; do
    nmcli connection delete uuid "$uuid" || return 1
  done
  success "Perfís VPN eliminados: ${names[*]}."
}

# Completa nomes e UUID de VPN a partir das filas seguras do propio módulo.
# Non mostra segredos nin o contido dos perfís e queda baleiro se nmcli falla.
_network_completion_vpns() {
  local current="$1"
  local name type state uuid

  COMPREPLY=()
  while IFS=$'\t' read -r name type state uuid; do
    if [[ "$name" == "$current"* ]]; then
      COMPREPLY+=("$name")
    fi
    if [[ "$uuid" == "$current"* ]]; then
      COMPREPLY+=("$uuid")
    fi
  done < <(_network_vpn_rows false 2> /dev/null)
}

# Completa nomes e UUID de conexións base para a autoconexión dunha VPN.
_network_completion_base_connections() {
  local current="$1"
  local name type state uuid

  COMPREPLY=()
  while IFS=$'\t' read -r name type state uuid; do
    if [[ "$name" == "$current"* ]]; then
      COMPREPLY+=("$name")
    fi
    if [[ "$uuid" == "$current"* ]]; then
      COMPREPLY+=("$uuid")
    fi
  done < <(_network_base_connection_rows 2> /dev/null)
}

# Completa opcións, ficheiros e identificadores dos comandos públicos de VPN.
_network_completion() {
  local command_name="${COMP_WORDS[0]:-}"
  local current="${COMP_WORDS[COMP_CWORD]:-}"
  local previous=""
  local options=""

  COMPREPLY=()
  if ((COMP_CWORD > 0)); then
    previous="${COMP_WORDS[COMP_CWORD - 1]}"
  fi

  case "$previous" in
    --origin)
      compopt -o filenames
      mapfile -t COMPREPLY < <(compgen -f -- "$current")
      return
      ;;
    --type)
      mapfile -t COMPREPLY < <(
        compgen -W "openvpn wireguard vpnc openconnect" -- "$current"
      )
      return
      ;;
    --name)
      return
      ;;
  esac

  case "$command_name" in
    vpn-list)
      options="--active --plain -h --help"
      ;;
    vpn-import)
      options="--origin --type --name -h --help --"
      if [[ "$current" != -* ]]; then
        compopt -o filenames
        mapfile -t COMPREPLY < <(compgen -f -- "$current")
        return
      fi
      ;;
    vpn-rename|vpn-clone)
      options="-h --help --"
      if [[ "$current" != -* ]] && [ "$COMP_CWORD" -eq 1 ]; then
        _network_completion_vpns "$current"
        return
      fi
      ;;
    vpn-export)
      options="-h --help --"
      if [[ "$current" != -* ]]; then
        if [ "$COMP_CWORD" -eq 1 ]; then
          _network_completion_vpns "$current"
        else
          compopt -o filenames
          mapfile -t COMPREPLY < <(compgen -f -- "$current")
        fi
        return
      fi
      ;;
    vpn-autoconnect)
      options="--disable -h --help --"
      if [[ "$current" != -* ]]; then
        if [ "$COMP_CWORD" -eq 1 ]; then
          _network_completion_vpns "$current"
        else
          _network_completion_base_connections "$current"
        fi
        return
      fi
      ;;
    vpn-edit|vpn-delete)
      options="-h --help --"
      if [[ "$current" != -* ]]; then
        _network_completion_vpns "$current"
        return
      fi
      ;;
  esac

  mapfile -t COMPREPLY < <(compgen -W "$options" -- "$current")
}

# Rexistra os completados deste módulo unicamente nas shells interactivas.
if [[ $- == *i* ]]; then
  complete -F _network_completion \
    vpn-list vpn-import vpn-rename vpn-clone vpn-export \
    vpn-autoconnect vpn-edit vpn-delete
fi
