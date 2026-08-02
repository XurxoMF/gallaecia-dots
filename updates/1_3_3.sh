#!/usr/bin/env bash

set -u
set -o pipefail

VERSION="1.3.3"
DOTFILES_DIR="$HOME/.dotfiles"
MODULES_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/modules"
INTERNAL_DIR="$DOTFILES_DIR/.local/share/gallaecia-dots/scripts/internal"

# Todos os updates cargan sempre a API pública e as librarías internas completas.
if [ ! -r "$MODULES_DIR/apps.sh" ] ||
  [ ! -r "$MODULES_DIR/commands.sh" ] ||
  [ ! -r "$MODULES_DIR/files.sh" ] ||
  [ ! -r "$MODULES_DIR/gallaecia.sh" ] ||
  [ ! -r "$MODULES_DIR/network.sh" ] ||
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
source "$MODULES_DIR/network.sh"
# shellcheck source=/dev/null
source "$MODULES_DIR/ui.sh"
# shellcheck source=/dev/null
source "$INTERNAL_DIR/apps.sh"
# shellcheck source=/dev/null
source "$INTERNAL_DIR/versions.sh"

# Actualiza unicamente as rutas defectuosas distribuídas nos dous ficheiros de
# yt-dlp. Se o usuario xa escolleu outra ruta, tamén conserva esa personalización.
update_yt_dlp_configs() {
  local video_config="$HOME/.config/yt-dlp/youtube-com.conf"
  local music_config="$HOME/.config/yt-dlp/music-youtube-com.conf"

  if ! has_command yt-dlp; then
    return 0
  fi

  if [ -f "$video_config" ]; then
    # Os grupos conservan o espazado e calquera comentario posterior da liña.
    if ! sed -i \
      's|^\([[:space:]]*--output[[:space:]]\+\)"[$]HOME/Vídeos/yt-dlp/%(title)s[.]%(ext)s"\(.*\)$|\1"%(title)s.%(ext)s"\2|' \
      "$video_config"; then
      return 1
    fi
  fi

  if [ -f "$music_config" ]; then
    # A ruta segue sendo relativa; artista e álbum créanse baixo a carpeta actual.
    if ! sed -i \
      's|^\([[:space:]]*--output[[:space:]]\+\)"[$]HOME/Música/yt-dlp/%(artists[.]0)s/%(album)s/%(playlist_index)s[.] %(title)s[.]%(ext)s"\(.*\)$|\1"%(artists.0)s/%(album)s/%(playlist_index)s. %(title)s.%(ext)s"\2|' \
      "$music_config"; then
      return 1
    fi
  fi
}

# Actualiza só o valor defectuoso de `output` na configuración existente de
# SpotDL. Un valor distinto escollido polo usuario non se modifica.
update_spotdl_config() {
  local spotdl_config="$HOME/.config/spotdl/config.json"

  if ! has_command spotdl; then
    return 0
  fi
  if [ ! -f "$spotdl_config" ]; then
    return 0
  fi

  # Conserva o espazado e a coma; só recoñece a ruta anterior de Gallaecia.
  sed -i \
    's|^\([[:space:]]*"output"[[:space:]]*:[[:space:]]*\)"Música/SpotDL/{album-artist}/{album}/{track-number}[.] {title}[.]{output-ext}"\([[:space:]]*,[[:space:]]*\)$|\1"{album-artist}/{album}/{track-number}. {title}.{output-ext}"\2|' \
    "$spotdl_config"
}

# Resume os cambios antes de modificar as instalacións existentes.
show_changelog() {
  title "Update $VERSION"
  info "Cambios que se van aplicar:"
  info "· yt-dlp descargará na carpeta desde a que se execute o comando."
  info "· SpotDL descargará na carpeta actual sen crear Música/SpotDL dentro dela."
}

# Aplica por separado as configuracións das dúas aplicacións opcionais.
apply_update() {
  if ! update_yt_dlp_configs; then
    return 1
  fi
  if ! update_spotdl_config; then
    return 1
  fi
}

# Presenta o changelog, confirma e executa o orquestrador.
# Só un éxito completo permite ao instalador marcar a versión como aplicada.
main() {
  show_changelog

  if ! confirm "Instalar update $VERSION?"; then
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
