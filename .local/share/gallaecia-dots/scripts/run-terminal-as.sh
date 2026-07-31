#!/usr/bin/env bash

set -u
set -o pipefail

# Punto de entrada executable para interfaces gráficas que non cargan o
# `.bashrc`. Reutiliza a función pública do módulo para manter unha única
# implementación da detección e dos argumentos específicos de cada terminal.
COMMANDS_MODULE="$HOME/.local/share/gallaecia-dots/scripts/modules/commands.sh"

if [ ! -r "$COMMANDS_MODULE" ]; then
  echo "Non se atopou o módulo público de comandos en $COMMANDS_MODULE." >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$COMMANDS_MODULE"

run-terminal-as "$@"
