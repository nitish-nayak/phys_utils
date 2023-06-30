#!/bin/bash

function sam_filepath {
  out=`samweb locate-file $1`
  d=`echo $out | grep 'dcache'`
  e=`echo $out | grep 'enstore'`
  # prefer dcache
  if [[ "$d" ]]; then
    loc=`echo $d | sed -e 's/dcache://g'`
  else
    loc=`echo $e | sed -e 's/enstore://g' | sed -e 's/\(.*\)(.*$/\1/g'`
  fi
  echo $loc"/"$1
}

# uboone doesn't have samweb2xrootd
function sam_xrootdpath {
  out=`samweb locate-file $1`
  d=`echo $out | grep 'dcache'`
  e=`echo $out | grep 'enstore'`
  # prefer dcache
  if [[ "$d" ]]; then
    loc=`echo $d | sed -e 's/dcache://g'`
  else
    loc=`echo $e | sed -e 's/enstore://g' | sed -e 's/\(.*\)(.*$/\1/g'`
  fi
  echo `pnfsToXRootD $loc"/"$1`
}

function set_proxy {
  t=$1
  kx509
  if [[ $t == "a" ]]; then
    voms-proxy-init -noregen -voms fermilab:/fermilab/uboone/Role=Analysis
  else
    voms-proxy-init -noregen -voms fermilab:/fermilab/uboone/Role=Production
  fi
}

function jump {
  exp=""
  if [[ `hostname` =~ "uboone" ]]; then
    exp="uboone"
  else
    exp="dune"
  fi
  pnfspath="/pnfs/"$exp"/scratch/users/"$USER
  apppath="/"$exp"/app/users/"$USER
  datapath="/"$exp"/data/users/"$USER
  
  opt=$1
  if [[ $opt == "data" ]]; then
    cd $datapath
  elif [[ $opt == "pnfs" ]]; then
    cd $pnfspath
  else
    cd $apppath
  fi
}
