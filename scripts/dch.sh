#!/usr/bin/env bash

set -eo pipefail
shopt -s lastpipe

function print_usage() {
  printf 'usage: %s [options] <command> <service> [service...]\n' "$0"
  printf 'commands: restart, start, status, stop\n'
  printf 'service:  folder name under services/\n'
  printf 'options:\n'
  printf '  -h: show this help\n'
  # shellcheck disable=SC2016
  printf '  -s: overwrite $SERVICES_DIR\n'
}

function service_start() {
  echo "todo: service_start"
  exit 3
}

function service_stop() {
  echo "todo: service_stop"
  exit 3
}

if [[ -z "$OPTIND" ]]; then
  OPTIND=1
fi

services_dir="${SERVICES_DIR:-$PWD}"

while getopts 'hs:' opt; do
  case $opt in
  h)
    print_usage
    exit 0
    ;;
  s)
    services_dir="$OPTARG"
    ;;
  ?)
    printf 'Invalid option: -%s\n' "$OPTARG" 1>&2
    exit 2
    ;;
  esac
done

shift $((OPTIND - 1))

if (($# < 2)); then
  word='were'
  if (($# == 1)); then
    word='was'
  fi
  printf 'error: at least 2 args are required but %d %s given!\n' "$#" "$word" 1>&2
  print_usage 1>&2
  exit 2
fi

cmd="$1"
shift 1
services=("$@")

# dynamically creating the functions avoids running the case in every loop iteration
case "$cmd" in
restart)
  function opfunc() {
    service_stop "$@"
    service_start "$@"
  }
  ;;
start)
  function opfunc() {
    service_start "$@"
  }
  ;;
stop)
  function opfunc() {
    service_stop "$@"
  }
  ;;
*)
  printf 'invalid command: %s\n' "$cmd" 1>&2
  print_usage 1>&2
  exit 2
  ;;
esac

for service in "${services[@]}"; do
  service_dir="$services_dir/$service"
  if [[ ! -d "$service_dir" ]]; then
    printf "error: '%s' is not a valid service dir!\n" "$service_dir" 1>&2
    exit 1
  fi
  opfunc "$service_dir"
done
