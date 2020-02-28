#!/usr/bin/env bash

CWD=$(pwd)
VERSION=1.0

function show_help {
  echo "DoDo $VERSION"
  echo "Author: Pavel Kilin <pavel@borodyadka.wtf>"
  echo "Bugs and suggestions https://github.com/borodyadka/dodo/issues"
  echo ""
  echo "Usage: $0 [<flags>...] <image or path> <command>"
  echo ""
  echo "Flags"
  echo "  -h --help — this help"
  echo "  -V --version — version info"
  echo ""
  echo "All listed flags passing directly to `docker run` command. Any other flags causes an error"
  exit 0
}

function show_version {
  echo "$VERSION"
  exit 0
}

function _error_log {
  echo "Error:" "$@" 1>&2;
}

function _debug_log {
  if [[ "$DODO_DEBUG" != "" ]]; then
    echo "DEBUG:" "$@" 1>&2;
  fi
}

function _fatal {
  _error_log $@
  exit 1
}

function _grep_from {
  grep --color=never -ioP '^FROM\s+\K([\w\d\.:_-]+)'
}

function get_current_image {
  local value="$1";
  _debug_log "get_current_image($value)"

  if [[ "$value" =~ ^(\.(/.+)?) ]]; then
    local file="${BASH_REMATCH[1]}"
    if [[ -d "$file" ]]; then file=$(realpath "$CWD/$file/Dockerfile"); fi
    if [[ -f "$file" ]]; then
      local dockerfile=$(cat "$file")
      _debug_log "    read from file $file"


      local image=$(echo "$dockerfile" | _grep_from | head -n 1)
      _debug_log "    parsed: $image"

      echo "$image"
      return
    else
      _fatal "unable to find Dockerfile in '${BASH_REMATCH[1]}'"
    fi
  elif [[ "$value" =~ ^([^\.][^/]+)$ ]]; then
    _debug_log "    specified image $value"
    echo ${BASH_REMATCH[1]}
    return
  fi
  _fatal "no image or Dockerfile specified"
}

function run {
  local SHORT=e:p:v:w:u:hV
  local LONG=env:,publish:,volume:,workdir:,user:,help,version
  local OPTS=$(getopt -o $SHORT -l $LONG --name "dodo" -- "$@")

  if [[ $? != 0 ]]; then
    _fatal "failed to parse options"
  fi

  eval set -- "$OPTS"

  ENV_ARGS=""
  PORT_ARGS=""
  VOLUME_ARGS=""
  WORKDIR_VALUE="/home/dodo"
  USER_VALUE="$(id -u):$(id -g)"

  _debug_log "parse arguments"

  while true ; do
    case "$1" in
      -h | --help )
        _debug_log "    show help"
        show_help
        shift
      ;;
      -V | --version )
        _debug_log "    show version"
        show_version
        shift
      ;;
      -e | --env )
        _debug_log "    env: $2"
        ENV_ARGS="$ENV_ARGS -e '$2'"
        shift 2
        ;;
      -p | --publish )
        _debug_log "    port: $2"
        PORT_ARGS="$PORT_ARGS -p '$2'"
        shift 2
        ;;
      -v | --volume )
        _debug_log "    volume: $2"
        VOLUME_ARGS="$VOLUME_ARGS -v '$2'"
        shift 2
        ;;
      -w | --workdir )
        _debug_log "    workdir: $2"
        WORKDIR_VALUE="$2"
        shift 2
        ;;
      -u | --user )
        _debug_log "    user: $2"
        USER_VALUE="$2"
        shift 2
        ;;
      -- )
        _debug_log "    done"
        shift
        break
        ;;
      *)
        _fatal "unrecognized option '$1'"
        ;;
    esac
  done

  VOLUME_ARGS="$VOLUME_ARGS -v $CWD:$WORKDIR_VALUE"
  local CLI_ARGS="$ENV_ARGS $PORT_ARGS $VOLUME_ARGS -w $WORKDIR_VALUE -u $USER_VALUE"

  local image=$(get_current_image $1); shift
  exec docker run --rm -it $CLI_ARGS $image $@
}

if [[ "$DODO_TEST" != "true" ]]; then
  run $@
fi
