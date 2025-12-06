#!/bin/bash

VERSION_BIN="202512070061"

SN="${0##*/}"
ID="[$SN]"

INSTALL=0
VERSION=0
HELP=0

declare -a ARGS1
ARGS2=""

while [ $# -gt 0 ]; do
  case $1 in
    --inst*|-inst*)
      INSTALL=1
      shift
      ;;
    --vers*|-vers*)
      VERSION=1
      shift
      ;;
    -h|-help|--help)
      HELP=1
      shift
      ;;
    --)
      shift
      ARGS2=$*
      break
      ;;
    *)
      ARGS1+=("$1")
      shift
      ;;
  esac
done

#
# stage: HELP
#
if [ $HELP -eq 1 ]; then
  echo "$SN -install   # install"
  echo "$SN -version   # version"
  exit 0
fi

#
# stage: VERSION
#
if [ $VERSION -eq 1 ]; then
  echo "${0##*/}  $VERSION_BIN"
  [[ "$VERSION_ENV" != "" ]] && echo "cdev.env $VERSION_ENV"
  if [ $(type -t helm) ]; then
    set -ex
    helm version
    { set +ex; } 2>/dev/null
  fi
  exit 0
fi

#
# stage: INSTALL
#
if [ $INSTALL -eq 1 ]; then
  if [ -f hdev.env ]; then
    for d in /usr/local/etc; do
      if [ -d $d ]; then
        set -ex
        rsync -ai hdev.env $d
        { set +ex; } 2>/dev/null
      fi
    done
  fi
  if [ -f hdev.sh ]; then
    for d in /usr/local/bin; do
      if [ -d $d ]; then
        set -ex
        rsync -ai hdev.sh $d
        { set +ex; } 2>/dev/null
      fi
    done
  fi
  exit 0
fi
