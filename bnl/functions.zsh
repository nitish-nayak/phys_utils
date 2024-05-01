#!/bin/zsh

function stage {
  echo "[Staging files]"
  time parallel -j 15 cp -rfvL {} "$1" ::: "${@:2}"
  echo "[Done]"
}
