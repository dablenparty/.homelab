#!/usr/bin/env bash

function print_usage() {
  printf 'usage: %s [options] <command> <service> [service...]\n' "$0"
  printf 'command:  docker compose command\n'
  printf 'service:  folder name under services/\n'
  printf 'options:\n'
  printf '  -h: show this help\n'
  # shellcheck disable=SC2016
  printf '  -s: overwrite $SERVICES_DIR for debugging\n'
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

for service in "${services[@]}"; do
  service_dir="$services_dir/$service"
  if [[ ! -d "$service_dir" ]]; then
    printf "error: '%s' is not a valid service dir!\n" "$service_dir" 1>&2
    exit 1
  fi
  # validate docker compose config
  if ! docker compose --project-directory "$service_dir" config -q; then
    printf "warn: skipping '%s': invalid config\n" "$service"
  else
    suffix='ing'
    if [[ "$cmd" == "stop" ]]; then
      suffix='ping'
    fi
    printf "%s%s '%s'\n" "$cmd" "$suffix" "$service"
    docker compose --project-directory "$service_dir" "$cmd"
  fi
done

printf 'done!\n'
