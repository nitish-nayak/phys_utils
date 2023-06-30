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
