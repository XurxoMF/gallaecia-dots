# shellcheck shell=bash
#
# ⚠️ NON EDITAR ESTE ARQUIVO!
# 
# Se precisas configuracións personalizadas engádeas
# nun arquivo ~/.config/bashrc/* con nome 123-nome.
#

# Carga de módulos de gallaecia usados en todos os scripts e demáis

for module in "$HOME"/.local/share/gallaecia-dots/scripts/modules/*.sh; do
  # shellcheck source=/dev/null
  [ -f "$module" ] && source "$module"
done

# Carga dos modulos de usuario ~/.config/bashrc/*

[[ $- != *i* ]] && return

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
