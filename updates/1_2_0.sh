#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.2.0"
DOTFILES_DIR="$HOME/.dotfiles"
MODULES_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules"
INTERNAL_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/internal"
INSTALLED_VERSIONS_FILE="$HOME/.local/share/gallaecia-dots/versions-instaladas"

if [ ! -r "$MODULES_DIR/apps.sh" ] ||
  [ ! -r "$MODULES_DIR/commands.sh" ] ||
  [ ! -r "$MODULES_DIR/files.sh" ] ||
  [ ! -r "$MODULES_DIR/gallaecia.sh" ] ||
  [ ! -r "$MODULES_DIR/ui.sh" ] ||
  [ ! -r "$INTERNAL_DIR/apps.sh" ] ||
  [ ! -r "$INTERNAL_DIR/versions.sh" ]; then
  echo "Non se atoparon os módulos ou librarías internas en $DOTFILES_DIR." >&2
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

# Substitúe a API pública de resolución, validación e reintento de comandos.
# Non executa nin instala paquetes durante a copia.
update_commands_module() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/commands.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/modules/commands.sh"
}

# Substitúe o módulo público de ficheiros que incorpora copias seguras, backups,
# enlaces e lixo recuperable.
update_files_module() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/files.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/modules/files.sh"
}

# Substitúe a capa pública de Gum coa paleta semántica e os novos wrappers.
# Os consumidores poden usala inmediatamente ao abrir unha shell nova.
update_ui_module() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/ui.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/modules/ui.sh"
}

# Substitúe o template controlado que Noctalia usa para exportar cores de Gum.
# Non sobrescribe unha personalización allea ao template do proxecto.
update_ui_colors_template() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/noctalia/ui-colors.sh.template" \
    "$HOME/.local/share/gallaecia-dots/noctalia/ui-colors.sh.template"
}

# Substitúe `apps.sh`, que expón comprobación e instaladores Yay/Flatpak/Pipx.
# O catálogo de categorías permanece na libraría interna separada.
update_apps_module() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/apps.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/modules/apps.sh"
}

# Substitúe o dispatcher público `gallaecia` cos subcomandos de mantemento,
# categorías e importación de fondos.
update_gallaecia_module() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules/gallaecia.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/modules/gallaecia.sh"
}

# Substitúe o actualizador invocado por Noctalia para que reutilice `_sync-repo`.
# Esta función só instala o script; non lanza unha actualización.
update_system_update_script() {
  replace_file \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/system-update.sh" \
    "$HOME/.local/share/gallaecia-dots/scripts/system-update.sh"
}

# Substitúe a árbore `internal` completa co catálogo e versións exclusivas dos
# instaladores. Deliberadamente deixa de expoñelas na shell diaria.
update_internal_modules() {
  replace_path \
    "$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/internal" \
    "$HOME/.local/share/gallaecia-dots/scripts/internal"
}

# Elimina o antigo `modules/versions.sh`, xa substituído por `internal/versions.sh`.
# A eliminación evita expoñer accidentalmente a API interna na shell do usuario.
remove_legacy_versions_module() {
  rm -f "$HOME/.local/share/gallaecia-dots/scripts/modules/versions.sh"
}

# Se existe o rexistro, elimina exactamente 1.2.3, 1.2.4 e 1.2.5.
# Esas etiquetas reutilizaranse no futuro e deben volver aparecer como pendentes.
remove_legacy_installed_versions() {
  if [ ! -f "$INSTALLED_VERSIONS_FILE" ]; then
    return 0
  fi

  # Cada expresión elimina só unha liña completa co número de versión indicado.
  sed -i \
    -e '/^1[.]2[.]3$/d' \
    -e '/^1[.]2[.]4$/d' \
    -e '/^1[.]2[.]5$/d' \
    "$INSTALLED_VERSIONS_FILE"
}

# Presenta o amplo cambio de APIs, CLI, categorías e estrutura interna.
# Non copia nin elimina ficheiros antes da confirmación do usuario.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· Engadidas consultas de comandos e paquetes oficiais ou AUR con Yay."
  info "· Engadidos reintentos seguros e helpers para validar e resolver comandos."
  info "· Retirado o antigo helper automático: cada script escolle agora o xestor adecuado."
  info "· Engadidas copias, backups, enlaces, comprobacións e envío ao lixo."
  info "· Engadidos máis wrappers de Gum para ficheiros, progreso, táboas e logs."
  info "· Unificadas as cores de Gum nunha paleta semántica reutilizable."
  info "· Engadidos instaladores interactivos para Yay, Flatpak e Pipx."
  info "· Engadido o comando gallaecia para mantemento, categorías e fondos."
  info "· Centralizado o catálogo de aplicacións e a sincronización do repo."
  info "· Unificada a aplicación predeterminada de MIME e Hyprland por categoría."
  info "· Separadas as librarías internas dos módulos públicos do Bashrc."
  info "· Corrixido o rexistro das updates renomeadas para futuras migracións."
}

# Aplica cada módulo e limpeza nun paso explícito e na orde de dependencias.
# Detense ao primeiro erro para que a versión poida reintentarse completa.
apply_update() {
  if ! update_commands_module; then
    return 1
  fi
  if ! update_files_module; then
    return 1
  fi
  if ! update_ui_module; then
    return 1
  fi
  if ! update_ui_colors_template; then
    return 1
  fi
  if ! update_apps_module; then
    return 1
  fi
  if ! update_gallaecia_module; then
    return 1
  fi
  if ! update_system_update_script; then
    return 1
  fi
  if ! update_internal_modules; then
    return 1
  fi
  if ! remove_legacy_versions_module; then
    return 1
  fi
  if ! remove_legacy_installed_versions; then
    return 1
  fi
}

# Mostra o changelog, pide confirmación e comunica o resultado.
# Cancelar ou fallar impide que o instalador rexistre esta versión.
main() {
  show_changelog

  if ! gum_confirm "Instalar update $VERSION?"; then
    warning "Update $VERSION cancelada."
    exit 1
  fi

  if apply_update; then
    success "Update $VERSION instalada con éxito!"
  else
    fail "Algo fallou ao instalar a update $VERSION."
  fi
}

main "$@"
