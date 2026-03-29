#!/usr/bin/env bash

# Obter os novos MIME types dispoñibles e os engade a "~/.config/mimeapps.list"
# sin sobreescribir os que xa están.

MIMEINFO="/usr/share/applications/mimeinfo.cache"
MIMEAPPS="${1:-$HOME/.config/mimeapps.list}"

# Crea o ficheiro mimeapps.list se non existe
if [[ ! -f "$MIMEAPPS" ]]; then
    touch "$MIMEAPPS"
fi

# Obter os novos MIME types
NEW=$(comm -23 \
    <(awk -F'=' '/^[^[]/ {print $1}' "$MIMEINFO" | sort -u) \
    <(awk -F'=' '/^[^[]/ {print $1}' "$MIMEAPPS" | sort -u))

# Contar os novos MIME types
COUNT=$(echo "$NEW" | grep -c .)

# Se non hai MIME types novos terminamos
if [[ $COUNT -eq 0 ]]; then
    printf "Non hai MIME types novos"
    exit 0
fi

# Engadir os novos MIME types a mimeapps.list
PROCESSED="${NEW//$'\n'/$'=\n'}="
echo "$PROCESSED" >> "$MIMEAPPS"

# Gardar os MIME types como lista e mostralos ao usuario
LIST="- ${NEW//$'\n'/$'\n- '}"
printf "Engadidos %s novos MIME types a %s:\n\n%s" "$COUNT" "$MIMEAPPS" "$LIST"