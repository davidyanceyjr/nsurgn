#!/usr/bin/env bash

# shellcheck disable=SC2034

NSURGN_GROUP='profile'
NSURGN_FORMAT='raw'
NSURGN_VERBOSE=0
NSURGN_QUIET=0
NSURGN_NO_COLOR=0
NSURGN_HOST_PID='1'
NSURGN_INCLUDE_HOST=0
NSURGN_COMMAND=''
NSURGN_ARGS=()

nsurgn_cli_parse() {
  NSURGN_ARGS=()

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --group)
        [ "$#" -ge 2 ] || nsurgn_usage_error 'missing value for --group' || return "$?"
        NSURGN_GROUP="$2"
        shift 2
        ;;
      --format)
        [ "$#" -ge 2 ] || nsurgn_usage_error 'missing value for --format' || return "$?"
        NSURGN_FORMAT="$2"
        shift 2
        ;;
      --verbose)
        NSURGN_VERBOSE=1
        shift
        ;;
      --quiet)
        NSURGN_QUIET=1
        shift
        ;;
      --no-color)
        NSURGN_NO_COLOR=1
        shift
        ;;
      --host-pid)
        [ "$#" -ge 2 ] || nsurgn_usage_error 'missing value for --host-pid' || return "$?"
        nsurgn_is_uint "$2" || nsurgn_usage_error 'invalid --host-pid value' || return "$?"
        NSURGN_HOST_PID="$2"
        shift 2
        ;;
      --include-host)
        NSURGN_INCLUDE_HOST=1
        shift
        ;;
      --version)
        NSURGN_COMMAND='version'
        shift
        break
        ;;
      --help)
        NSURGN_COMMAND='help'
        shift
        break
        ;;
      --)
        shift
        break
        ;;
      -*)
        nsurgn_usage_error "invalid option: $1"
        return "$?"
        ;;
      *)
        break
        ;;
    esac
  done

  nsurgn_cli_validate_group "$NSURGN_GROUP" || return "$?"
  nsurgn_cli_validate_format "$NSURGN_FORMAT" || return "$?"

  if [ -z "$NSURGN_COMMAND" ]; then
    if [ "$#" -eq 0 ]; then
      NSURGN_COMMAND='help'
    else
      NSURGN_COMMAND="$1"
      shift
    fi
  fi

  NSURGN_ARGS=("$@")
}

nsurgn_cli_validate_group() {
  case "$1" in
    profile|strict|pid|mnt|net|cgroup) return 0 ;;
    *) nsurgn_usage_error "unsupported --group value: $1" ;;
  esac
}

nsurgn_cli_validate_format() {
  case "$1" in
    raw|table|text|json|ndjson) return 0 ;;
    *) nsurgn_usage_error "unsupported --format value: $1" ;;
  esac
}
