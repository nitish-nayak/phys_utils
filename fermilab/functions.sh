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

# requires fd
function makeup_filelist () {

  if ! command -v fd &> /dev/null
  then
    echo "fd could not be found"
    exit
  fi

  output_pattern="$1"
  outputpath="$2"
  origdef="$3"

  if [[ x"$output_pattern" = x || x"$outputpath" = x || x"$origdef" = x ]]; then
    echo "Not enough arguments. Need 3 arguments : "
    echo "a glob pattern, directory where job files can be searched recursively and the original input samdef the jobs used"
  fi

  echo "First creating text file with the parents of the output files we have"
  fd -g "$output_pattern" "$outputpath" -x samweb list-files 'isparentof:(file_name '{/}')' >> tmp.txt
  cat tmp.txt | sort >> tmp_run.txt
  rm tmp.txt

  echo "Now creating text file with original set of files"
  samweb list-files 'defname: '"$origdef" | sort >> tmp_orig.txt

  echo "Finally, doing a diff and saving to makeup.txt"
  diff tmp_run.txt tmp_orig.txt | grep '^>' | sed 's/^>\ //' >> makeup.txt

  echo "Cleaning up"
  rm tmp_run.txt
  rm tmp_orig.txt

  echo "Number of makeup files : "`cat makeup.txt | wc -l`

}

function makeup_samdef () {
  filelist="$1"
  defn="$2"
  splitlen="$3"
  if [ x"$splitlen" = x ]; then
      splitlen=`cat "$filelist" | wc -l`
  fi

  echo "Creating makeup definition in chunks of "$splitlen
  i=0
  defs=""
  defs_arr=()
  while read chunks; do
      args=`echo $chunks | sed -e 's/ /,/g'`
      tmp_defn="$defn"_tmp"$i"
      echo "Creating defn for chunk "$i
      samweb create-definition $tmp_defn 'file_name '"$args"
      defs="defname: "$tmp_defn" or "$defs
      defs_arr+=("$tmp_defn")
      ((i++))
  done < <(cat $filelist | xargs -n "$splitlen")

  samweb create-definition "$defn" `echo "$defs" | sed -e 's/ or $//g'`
  samweb take-snapshot "$defn"

  echo "Created definition "$defn" with number of files "`samweb count-definition-files "$defn"`

}
