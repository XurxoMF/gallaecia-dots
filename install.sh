#!/usr/bin/env bash

set -u
set -o pipefail

DOTFILES_DIR="$HOME/.dotfiles"
REPO_URL="https://github.com/XurxoMF/gallaecia-dots.git"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
UPDATES_DIR="$DOTFILES_DIR/updates"
BASE_INSTALLER="$UPDATES_DIR/base.sh"
SKIP_CLONE="${GALLAECIA_SKIP_CLONE:-0}"
REPO_BRANCH="${GALLAECIA_REPO_BRANCH:-release}"

# Instala só o mínimo necesario para que o instalador poida continuar.
# Este ficheiro pode executarse con `bash <(curl ...)`, así que aquí non se
# poden importar módulos do repo: aínda non existe ata despois do `git clone`.
install_prerequisites() {
  if ! command -v gum &> /dev/null || ! command -v git &> /dev/null; then
    echo ":: Instalando programas requeridos para executar este script (gum e git)..."
    echo
    pacman -Sy --needed gum git
  fi
}

# Descarga o repo completo en ~/.dotfiles.
# Se o script xa se está executando desde ~/.dotfiles, non borra nin clona nada:
# isto permite probar o instalador desde unha copia local sen destruíla.
download_dotfiles() {
  if [ "$SKIP_CLONE" = "1" ]; then
    return 0
  fi

  if [ "$SCRIPT_DIR" = "$DOTFILES_DIR" ]; then
    return 0
  fi

  rm -rf "$DOTFILES_DIR" &&
  git clone --branch "$REPO_BRANCH" "$REPO_URL" "$DOTFILES_DIR"
}

# Executa primeiro a instalación base e despois só os updates versionados.
# A base non é unha migración: é o instalador inicial e pode cambiar no futuro
# para engadir novas opcións de apps. Os updates reais usan nomes 3_0_1.sh, etc.
run_updates() {
  local update_script

  if [ ! -d "$UPDATES_DIR" ]; then
    echo "Non se atopou o directorio de updates en $UPDATES_DIR."
    return 1
  fi

  if [ ! -f "$BASE_INSTALLER" ]; then
    echo "Non se atopou o instalador base en $BASE_INSTALLER."
    return 1
  fi

  if ! bash "$BASE_INSTALLER"; then
    echo "Algo fallou ao executar $BASE_INSTALLER. Abortando instalación..."
    return 1
  fi

  while IFS= read -r update_script; do
    [ -n "$update_script" ] || continue

    if ! bash "$update_script"; then
      echo "Algo fallou ao executar $update_script. Abortando instalación..."
      return 1
    fi
  done < <(find "$UPDATES_DIR" -maxdepth 1 -type f -name "[0-9]*_[0-9]*_[0-9]*.sh" | sort -V)
}

# Fluxo bootstrap completo:
# 1. instalar gum/git,
# 2. clonar repo,
# 3. delegar a instalación real aos scripts do repo clonado.
main() {
  install_prerequisites || exit 1

  if ! download_dotfiles; then
    echo "Algo fallou ao descargar Gallaecia Dots! Abortando instalación..."
    exit 1
  fi

  run_updates
}

main "$@"
