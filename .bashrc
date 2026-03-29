# shellcheck shell=bash
#
# ⚠️ DON'T EDIT THIS FILE, IT'S A SIMPLE LOADER
# 
# If you need custom configs add them to
# ~/.config/bashrc/custom/* or to the
# ~/.bashrc-custom file.
#
# If you use the ~/.config/bashrc/custom/* folder
# I recommend you to use the 00-name to 100-name
# file names.
#

[[ $- != *i* ]] && return

for f in ~/.config/bashrc/*; do
  if [ ! -d "$f" ]; then
    # shellcheck source=/dev/null
    [ -f "$f" ] && source "$f"
  fi
done
