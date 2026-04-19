#!/bin/bash

VERSION_BIN="260419"

SN="${0##*/}"
ID="[$SN]"

INSTALL_RSYNC=0
INSTALL_ANPB=0
INSTALL_ANPB_HP="hdev"
VERSION=0
EVAL=0
HELP=0

declare -a ARGS1
ARGS2=""

s=0

while [ $# -gt 0 ]; do
  case $1 in
    --vers*|-vers*)
      VERSION=1
      shift
      ;;
    --inst*|-inst*)
      INSTALL_RSYNC=1
      shift
      ;;
    --anpb|-anpb)
      INSTALL_ANPB=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && INSTALL_ANPB_HP="$2" && shift
      shift
      ;;
    -x)
      EVAL=1
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
  echo "$SN -version                  # version"
  echo "$SN -install                  # install with rsync"
  echo "$SN -anpb [host_pattern] [-x] # install with ansible"
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
# stage: INSTALL-RSYNC
#
if [ $INSTALL_RSYNC -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: INSTALL-RSYNC"

  if [ -f hdev.env ]; then
    for d in /usr/local/etc /pub/pkb/kb/data/999220-hdev/999220-000020_hdev_script /pub/pkb/pb/playbooks/999220-hdev/files; do
      if [ -d $d ]; then
        set -ex
        rsync -ai hdev.env $d
        { set +ex; } 2>/dev/null
      fi
    done
  fi
  if [ -f hdev.sh ]; then
    for d in /usr/local/bin /pub/pkb/kb/data/999220-hdev/999220-000020_hdev_script /pub/pkb/pb/playbooks/999220-hdev/files; do
      if [ -d $d ]; then
        set -ex
        rsync -ai hdev.sh $d
        { set +ex; } 2>/dev/null
      fi
    done
  fi

  exit 0
fi

#
# stage: INSTALL-ANPB
#
if [ $INSTALL_ANPB -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: INSTALL-ANPB (EVAL=$EVAL)"

  if [ ! $(type -t anpb) ]; then
    echo "$ID: error: command not found: anpb"
    exit 1
  fi

  if [ $EVAL -eq 0 ]; then
    set -ex
    anpb hdev_install.yml -e h=$INSTALL_ANPB_HP --check --diff
    { set +ex; } 2>/dev/null
  else
    set -ex
    anpb hdev_install.yml -e h=$INSTALL_ANPB_HP
    { set +ex; } 2>/dev/null
  fi

  exit 0
fi
