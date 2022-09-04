#!/usr/bin/env bash

CWD=$(pwd)
VERSION=1.0.2

function show_help {
  echo "DoDo $VERSION"
  echo "Author: Pavel Kilin <pavel@borodyadka.wtf>"
  echo ""
  echo "Bugs and suggestions https://github.com/borodyadka/dodo/issues"
  echo ""
  echo "Usage: $0 [<flags>...] <image or path> <command>"
  echo ""
  echo "Flags:"
  echo ""
  echo "  -h --help       — this help"
  echo "  -V --version    — version info"
  echo "  -e --env        — set env var: '-e FOO=BAR'"
  echo "  -p --publish    — publish container port: '-p 80:80'"
  echo "  -v --volume     — mount volume: '-v /tmp:/var/lib/data'"
  echo "  -w --workdir    — set current workdir: '-w /opt/app', default is '/home/dodo'"
  echo "  -u --user       — set user, '-u 1000:1000', default is '$(id -u):$(id -g)'"
  echo ""
  echo "  All listed flags passing directly to 'docker run' command. Any other flags causes an error"
  echo ""
  echo "Example:"
  echo ""
  echo "  This command will install 'some-package' to /tmp dir:"
  echo "  $ dodo -w /app -v /tmp:/app node:latest npm install some-package --save"
}

function show_version {
  echo "$VERSION"
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
    fi

    _debug_log "    unable to find Dockerfile in '${BASH_REMATCH[1]}'"
  fi

  # try to find pattern `[namespace/]image[:tag]`
  if [[ "$value" =~ ^([a-zA-Z0-9\._-]+\/)?([a-zA-Z0-9\._-]+)(:[a-zA-Z0-9\._-]+)?$ ]]; then
    _debug_log "    specified image $value"
    echo "${BASH_REMATCH[0]}"
    return
  fi
}

function run {
  ENV_ARGS=""
  PORT_ARGS=""
  NETWORK_VALUE=""
  VOLUME_ARGS=""
  WORKDIR_VALUE="/home/dodo"
  USER_VALUE="$(id -u):$(id -g)"
  IMAGE=""

  _debug_log "parse arguments"

  while true ; do
    case "$1" in
      -h | --help )
        _debug_log "    show help"
        show_help
        return 1
        shift
      ;;
      -V | --version )
        _debug_log "    show version"
        show_version
        return 1
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
      -n | --network )
        _debug_log "    network: $2"
        NETWORK_VALUE="--network $2"
        shift 2
        ;;
      -- )
        _debug_log "    done"
        shift
        break
        ;;
      *)
        _debug_log "    done"
        IMAGE=$(get_current_image $1); shift
        break
        ;;
    esac
  done

  if [[ "$IMAGE" == "" ]]; then
    _fatal "no image or Dockerfile specified"
  fi

  VOLUME_ARGS="$VOLUME_ARGS -v $CWD:$WORKDIR_VALUE"
  local CLI_ARGS="$ENV_ARGS $PORT_ARGS $VOLUME_ARGS -w $WORKDIR_VALUE -u $USER_VALUE $NETWORK_VALUE"

  exec docker run --rm -it $CLI_ARGS $IMAGE $@
}

if [[ "$DODO_TEST" == "" ]]; then
  run $@
fi
