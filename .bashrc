# shellcheck shell=bash
#
# ⚠️ NON EDITAR ESTE ARQUIVO!
# 
# Se precisas configuracións personalizadas engádeas
# nun arquivo ~/.config/bashrc/* con nome 123-nome.
#

# Carga de módulos de gallaecia de ~/.local/share/gallaecia-dots/modules/*.sh

for module in "$HOME"/.local/share/gallaecia-dots/scripts/modules/*.sh; do
  # shellcheck source=/dev/null
  [ -f "$module" ] && source "$module"
done

# Carga dos modulos de Gallaecia ~/.local/share/gallaecia-dots/bashrc/*

[[ $- != *i* ]] && return

for f in ~/.local/share/gallaecia-dots/bashrc/*; do
  if [ ! -d "$f" ]; then
    # shellcheck source=/dev/null
    [ -f "$f" ] && source "$f"
  fi
done

# Carga dos modulos de usuario ~/.config/bashrc/*

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
