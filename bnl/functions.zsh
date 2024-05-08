#!/bin/zsh

function stage {
  echo "[Staging files]"
  time parallel -j 15 cp -rfvL {} "$1" ::: "${@:2}"
  echo "[Done]"
}

function fix_zshrc {
  orig=`pwd`
  cd ~
  mv .zsh_history .zsh_history_bad
  strings .zsh_history_bad > .zsh_history
  fc -R .zsh_history
  rm ~/.zsh_history_bad
  echo "[Fixed!]"
  cd "$orig"
}
