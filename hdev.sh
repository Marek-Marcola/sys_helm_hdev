#!/bin/bash

VERSION_BIN="260831"

SN="${0##*/}"
ID="[$SN]"

SDIR="/dep/c"

INSTALL_RSYNC=0
INSTALL_RSYNC_HL="$(hostname -s)"
INSTALL_ANPB=0
INSTALL_ANPB_HP="hdev"
VERSION=0
STAGE_LIST=0
CHART_PACKAGE=0
CHART_UPLOAD=0
CHART_VERS=""
SLIST=0
SLOAD=0
ARCH=0
EVAL=0
HELP=0

declare -a ARGS1
ARGS2=""

s=0

: ${COMM:=$(readlink -f ${BASH_SOURCE})}

while [ $# -gt 0 ]; do
  case $1 in
    --ver*|-ver*)
      VERSION=1
      shift
      ;;
    --inst*|-inst*)
      INSTALL_RSYNC=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && INSTALL_RSYNC_HL="$2" && shift
      shift
      ;;
    --anpb|-anpb)
      INSTALL_ANPB=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && INSTALL_ANPB_HP="$2" && shift
      shift
      ;;
    --stage|-stage)
      STAGE_LIST=1
      shift
      ;;
    -x)
      EVAL=1
      shift
      ;;
    -cp)
      CHART_PACKAGE=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && CHART_VERS="$2" && shift
      shift
      ;;
    -cu)
      CHART_UPLOAD=1
      shift
      ;;
    -cpu)
      CHART_PACKAGE=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && CHART_VERS="$2" && shift
      CHART_UPLOAD=1
      shift
      ;;
    -cl)
      SLOAD=1
      SDIR="$2"
      shift; shift
      ;;
    -ls)
      QUIET=1
      SLIST=1
      shift
      ;;
    -la)
      QUIET=1
      SLOAD=1
      ARCH=1
      shift
      ;;
    -A)
      ARCH=1
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
  echo "Helm chart development tools."
  echo ""
  echo "$SN -ver                      # version"
  echo "$SN -inst [host_list]    [-x] # install with rsync"
  echo "$SN -anpb [host_pattern] [-x] # install with ansible"
  echo "$SN -stage                    # stage list"
  echo ""
  echo "$SN -cp [ver,...|all]         # chart package"
  echo "$SN -cu                       # chart upload"
  echo "$SN -cl dir [-A]              # chart load (all from dir), archive"
  echo ""
  echo "$SN -cpu [ver,...|all]        # alias: -cp [ver,...|all] -cu"
  echo ""
  echo "$SN -ls                       # spooler list"
  echo "$SN -la                       # spooler load/archive"
  echo ""
  echo "$SN                           # info"
  exit 0
fi

#
# stage: VERSION
#
if [ $VERSION -eq 1 ]; then
  echo "${0##*/}  $VERSION_BIN"
  [[ "$VERSION_ENV" != "" ]] && echo "hdev.env $VERSION_ENV"
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
  echo "$ID: stage: INSTALL-RSYNC (EVAL=$EVAL HL=$INSTALL_RSYNC_HL)"

  [[ $EVAL -ne 1 ]] && EVAL_OPT="-n" || EVAL_OPT=""

  if [ -f hdev.sh ]; then
    for d in /usr/local/etc /pub/pkb/kb/data/999220-hdev/999220-000020_hdev_script /pub/pkb/pb/playbooks/999220-hdev/files; do
      if [ -d $d ]; then
        set -ex
        rsync -ai $EVAL_OPT hdev.env $d
        { set +ex; } 2>/dev/null
      fi
    done
    for d in /usr/local/bin /pub/pkb/kb/data/999220-hdev/999220-000020_hdev_script /pub/pkb/pb/playbooks/999220-hdev/files; do
      if [ -d $d ]; then
        set -ex
        rsync -ai $EVAL_OPT hdev.sh $d
        { set +ex; } 2>/dev/null
      fi
    done
  elif [ -f /pub/pkb/pb/playbooks/999220-hdev/files/hdev.sh ]; then
    for h in $(echo $INSTALL_RSYNC_HL|sed 's/,/ /g'); do
      set -ex
      rsync -ai $EVAL_OPT /pub/pkb/pb/playbooks/999220-hdev/files/hdev.sh $h:/usr/local/bin/
      rsync -ai $EVAL_OPT /pub/pkb/pb/playbooks/999220-hdev/files/hdev.env $h:/usr/local/etc/
      { set +ex; } 2>/dev/null
    done
  fi

  exit 0
fi

#
# stage: INSTALL-ANPB
#
if [ $INSTALL_ANPB -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: INSTALL-ANPB (EVAL=$EVAL HP=$INSTALL_ANPB_HP)"

  if [ ! $(type -t anpb) ]; then
    echo "$ID: error: command not found: anpb"
    exit 1
  fi

  [[ $EVAL -ne 1 ]] && EVAL_OPT="--check --diff" || EVAL_OPT=""

  set -ex
  anpb hdev_install.yml -e h=$INSTALL_ANPB_HP $EVAL_OPT
  { set +ex; } 2>/dev/null

  exit 0
fi

#
# stage: STAGE-LIST
#
if [ $STAGE_LIST -eq 1 ]; then
  cat $COMM | grep '^#' | grep 'stage:'
  exit 0
fi

#
# stage: CHART-PACKAGE
#
if [ $CHART_PACKAGE -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: CHART-PACKAGE"

  C=$(cat Chart.yaml 2>/dev/null|col -b|grep name:|awk '{print $2}')

  if [ -f .hdev.env ]; then
    E=.hdev.env
  elif [ -f $HOME/.hdev.env ]; then
    E=$HOME/.hdev.env
  else
    E=/usr/local/etc/hdev.env
  fi

  if [ "$CHART_VERS" = "" ]; then
    V=$(cat $E 2>/dev/null|sed -e :a -e '$!N;s/\n  */ /;ta' -e 'P;D'|grep ^${C}:|sed 's/^.*://'|awk '{print $1}')
  elif [ "$CHART_VERS" = "all" ]; then
    V=$(cat $E 2>/dev/null|sed -e :a -e '$!N;s/\n  */ /;ta' -e 'P;D'|grep ^${C}:|sed 's/^.*://')
  else
    V=$(echo $CHART_VERS|sed 's/,/ /g')
  fi

  for i in $V; do
    echo
    set -ex
    helm package . -d ../zout --version $i --app-version $i
    { set +ex; } 2>/dev/null

    if [ $CHART_UPLOAD -ne 0 ]; then
      echo
      for r in $CM_HOST; do
        set -ex
        curl -sk --netrc-file $CM_AUTH --data-binary "@../zout/$C-$i.tgz" $r/api/charts?force | jq
        { set +ex; } 2>/dev/null
      done
    fi
  done
fi

#
# stage: SPOOLER-LIST
#
if [ $SLIST -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: SPOOLER-LIST"

  if [ ! -d "$SDIR" ]; then
    echo "$ID: error: no spooler dir: $SDIR"
    exit 1
  fi

  set -ex
  cd $SDIR
  tree --noreport -F -C -L 1 -f $SDIR
  { set +ex; } 2>/dev/null
fi

#
# stage: SPOOLER-LOAD
#
if [ $SLOAD -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: SPOOLER-LOAD"

  if [ ! -f "$SDIR" -a ! -d "$SDIR" ]; then
    echo "$ID: error: access: $SDIR"
    exit 1
  fi

  if [ -z "$CM_HOST" ]; then
    echo error: require CM_HOST
    exit 1
  fi

  set -ex
  cd $SDIR
  tree --noreport -F -h -C -L 1 -f $SDIR
  { set +ex; } 2>/dev/null
  echo

  ls *.tgz 2>/dev/null | sort | \
  while read C; do
    for r in $CM_HOST; do
      set -ex
      curl -sk --netrc-file $CM_AUTH --data-binary "@$C" $r/api/charts?force | jq
      { set +ex; } 2>/dev/null
    done
    if [ $ARCH -ne 0 ]; then
      if [ -d archive ]; then
        set -ex
        mv -fv $C archive/
        { set +ex; } 2>/dev/null
      fi
    fi
    echo
  done
fi
