# shellcheck shell=bash
#
# ⚠️ NON EDITAR ESTE ARQUIVO!
# 
# Se precisas configuracións personalizadas engádeas
# nun arquivo ~/.config/bashrc/* con nome 123-nome.
#

# Carga os helpers compartidos de Gallaecia antes da configuración interactiva.

for module in "$HOME"/.local/share/gallaecia-dots/scripts/modules/*.sh; do
  # shellcheck source=/dev/null
  [ -f "$module" ] && source "$module"
done

# Os seguintes Bashrc só teñen sentido nunha shell interactiva.
# `$-` contén as opcións activas da shell e inclúe `i` cando é interactiva.

[[ $- != *i* ]] && return

# Carga os módulos opcionais instalados por Gallaecia.
for f in ~/.local/share/gallaecia-dots/bashrc/*; do
  if [ ! -d "$f" ]; then
    # shellcheck source=/dev/null
    [ -f "$f" ] && source "$f"
  fi
done

# Carga os módulos persoais do usuario por orde alfabética.
for f in ~/.config/bashrc/*; do
  if [ ! -d "$f" ]; then
    # shellcheck source=/dev/null
    [ -f "$f" ] && source "$f"
  fi
done

##########################################################
#### TODO O QUE ESTÉ DEBAIXO DISTO DEBERÍASE DE MOVER ####
####     A UN ARQUIVO EN ~/.config/bashrc/123-xxx     ####
##########################################################
