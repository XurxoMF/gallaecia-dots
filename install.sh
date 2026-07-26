#!/usr/bin/env bash

set -u
set -o pipefail

###############################################################################
# BOOTSTRAP E SELECTOR DO MODO DE INSTALACIÓN
#
# Este é o único script que pode comezar sen que ~/.dotfiles exista. Por iso a
# primeira parte non usa módulos: instala Gum/Git e clona o repo. Unha vez
# dispoñible o repo, carga todas as librarías e escolle un destes fluxos:
#
#   install    -> updates/base.sh e marca todas as migracións actuais.
#   update     -> só updates/X_Y_Z.sh aínda non rexistrados.
#   reinstall  -> limpa o estado de versións e volve executar a base.
#
# SKIP_CLONE e INSTALL_MODE son a interface usada por `gallaecia` e
# system-update.sh para evitar descargar o repo dúas veces ou volver preguntar
# polo modo.
###############################################################################

# Rutas do repo.
DOTFILES_DIR="$HOME/.dotfiles"
MODULES_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules"
INTERNAL_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/internal"
UPDATES_DIR="$DOTFILES_DIR/updates"
BASE_INSTALLER="$UPDATES_DIR/base.sh"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Estado da instalación.
STATE_DIR="$HOME/.local/share/gallaecia-dots"
INSTALLED_VERSIONS_FILE="$STATE_DIR/versions-instaladas"
CURRENT_VERSION_FILE="$STATE_DIR/version"
INSTALLED_MARK_FILE="$STATE_DIR/instalado"

# Repo remoto. As instalacións usan sempre a versión publicada en `release`;
# non se admite seleccionar outra rama desde variables nin argumentos.
REPO_URL="https://github.com/XurxoMF/gallaecia-dots.git"

# Opcións do bootstrap.
SKIP_CLONE="${SKIP_CLONE:-0}"
INSTALL_MODE="${INSTALL_MODE:-auto}"

# Instala só o mínimo necesario para que o instalador poida continuar.
# Este ficheiro pode executarse con `bash <(curl ...)`, así que aquí non se
# poden importar módulos do repo: aínda non existe ata despois do `git clone`.
install_prerequisites() {
  if ! command -v gum &> /dev/null || ! command -v git &> /dev/null; then
    echo ":: Instalando programas requeridos para executar este script (gum e git)..."
    echo
    sudo pacman -Sy --needed gum git
  fi
}

# Descarga o repo completo en ~/.dotfiles.
# Se o script xa se está executando desde ~/.dotfiles, non borra nin clona nada:
# isto permite probar o instalador desde unha copia local sen destruíla.
# Os fluxos que xa sincronizaron o repo pasan SKIP_CLONE=1.
download_dotfiles() {
  if [ "$SKIP_CLONE" = "1" ]; then
    return 0
  fi

  if [ "$SCRIPT_DIR" = "$DOTFILES_DIR" ]; then
    return 0
  fi

  rm -rf "$DOTFILES_DIR" &&
  git clone -b release "$REPO_URL" "$DOTFILES_DIR"
}

# Busca updates X_Y_Z.sh, convérteos a X.Y.Z e execútaos por orde.
# Consulta versions-instaladas antes de cada un e só o marca tras un código 0.
run_versioned_updates() {
  local update_script
  local version_name
  local update_scripts=()

  if [ ! -d "$UPDATES_DIR" ]; then
    echo "Non se atopou o directorio de updates en $UPDATES_DIR."
    return 1
  fi

  # Carga primeiro os nomes para que os scripts conserven o stdin da terminal.
  # Se o bucle lese directamente do find, yay e gum recibirían esa entrada e
  # poderían atopar un EOF en lugar de poder preguntar ao usuario.
  mapfile -t update_scripts < <(
    find "$UPDATES_DIR" -maxdepth 1 -type f \
      -name "[0-9]*_[0-9]*_[0-9]*.sh" |
      sort -V
  )

  for update_script in "${update_scripts[@]}"; do
    version_name="${update_script##*/}"
    version_name="${version_name%.sh}"
    version_name="${version_name//_/.}"

    if is_version_installed "$version_name"; then
      continue
    fi

    if ! bash "$update_script"; then
      echo "Algo fallou ao executar $update_script. Abortando instalación..."
      return 1
    fi

    mark_version_from_script "$update_script" || return 1
  done
}

# Executa updates/base.sh e, só se remata correctamente, marca `base` e todas as
# migracións actuais. Unha instalación nova non reproduce updates históricos.
run_base_install() {
  if [ ! -f "$BASE_INSTALLER" ]; then
    echo "Non se atopou o instalador base en $BASE_INSTALLER."
    return 1
  fi

  if ! bash "$BASE_INSTALLER"; then
    echo "Algo fallou ao executar $BASE_INSTALLER. Abortando instalación..."
    return 1
  fi

  mark_base_as_installed
}

# Recibe a ruta dun updater xa executado correctamente, extrae do nome
# `X_Y_Z.sh` a versión `X.Y.Z` e actualiza os dous rexistros internos.
mark_version_from_script() {
  local script_path="$1"
  local version_name

  version_name="${script_path##*/}"
  version_name="${version_name%.sh}"
  version_name="${version_name//_/.}"

  mark_version_installed "$version_name" &&
  set_gallaecia_current_version "$version_name"
}

# Rexistra todas as migracións dispoñibles e fixa a máis recente como versión
# actual, evitando que unha instalación nova reproduza actualizacións históricas.
mark_base_as_installed() {
  mark_all_available_versions &&
  set_gallaecia_current_version "$(latest_available_version)"
}

# Decide o modo efectivo. Un INSTALL_MODE explícito úsase sen preguntar.
# En `auto`, o estado local decide entre instalación nova ou un menú
# update/reinstall para unha instalación existente.
resolve_install_mode() {
  case "$INSTALL_MODE" in
    install|update|reinstall)
      printf '%s\n' "$INSTALL_MODE"
      return 0
      ;;
    auto)
      if [ -s "$INSTALLED_VERSIONS_FILE" ]; then
        local install_mode
        install_mode=$(gum_choose \
          --header "Xa hai unha instalación de Gallaecia Dots. Que queres facer?" \
          "Actualizar" \
          "Reinstalar")

        if [ "$install_mode" = "Reinstalar" ]; then
          printf '%s\n' "reinstall"
        else
          printf '%s\n' "update"
        fi
      else
        printf '%s\n' "install"
      fi
      return 0
      ;;
  esac

  echo "Modo de instalación non válido: $INSTALL_MODE" >&2
  return 1
}

# Recibe o modo xa resolto e chama exactamente un fluxo. Reinstall borra só os
# ficheiros de estado de versións; a base decide que configuración substituír.
run_install_flow() {
  local effective_mode="$1"

  case "$effective_mode" in
    install)
      run_base_install
      ;;
    update)
      run_versioned_updates
      ;;
    reinstall)
      rm -f "$INSTALLED_VERSIONS_FILE" "$CURRENT_VERSION_FILE" "$INSTALLED_MARK_FILE"
      run_base_install
      ;;
    *)
      echo "Modo de instalación non soportado: $effective_mode" >&2
      return 1
      ;;
  esac
}

# Fluxo bootstrap completo:
# 1. instalar gum/git,
# 2. clonar repo,
# 3. cargar as sete librarías estándar desde o repo,
# 4. resolver o modo,
# 5. delegar a instalación real á base ou ás migracións.
main() {
  install_prerequisites || exit 1

  if ! download_dotfiles; then
    echo "Algo fallou ao descargar Gallaecia Dots! Abortando instalación..."
    exit 1
  fi

  if [ ! -r "$MODULES_DIR/apps.sh" ] ||
    [ ! -r "$MODULES_DIR/commands.sh" ] ||
    [ ! -r "$MODULES_DIR/files.sh" ] ||
    [ ! -r "$MODULES_DIR/gallaecia.sh" ] ||
    [ ! -r "$MODULES_DIR/ui.sh" ] ||
    [ ! -r "$INTERNAL_DIR/apps.sh" ] ||
    [ ! -r "$INTERNAL_DIR/versions.sh" ]; then
    echo "Non se atoparon as librarías de Gallaecia Dots en $DOTFILES_DIR." >&2
    exit 1
  fi

  # shellcheck source=/dev/null
  source "$MODULES_DIR/apps.sh"
  # shellcheck source=/dev/null
  source "$MODULES_DIR/commands.sh"
  # shellcheck source=/dev/null
  source "$MODULES_DIR/files.sh"
  # shellcheck source=/dev/null
  source "$MODULES_DIR/gallaecia.sh"
  # shellcheck source=/dev/null
  source "$MODULES_DIR/ui.sh"
  # shellcheck source=/dev/null
  source "$INTERNAL_DIR/apps.sh"
  # shellcheck source=/dev/null
  source "$INTERNAL_DIR/versions.sh"

  local effective_mode

  effective_mode=$(resolve_install_mode) || exit 1

  run_install_flow "$effective_mode"
}

main "$@"
