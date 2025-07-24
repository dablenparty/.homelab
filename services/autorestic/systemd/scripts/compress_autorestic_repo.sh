#!/usr/bin/env bash

set -eo pipefail

repo_dir="${1:-${REPO_DIR:?REPO_DIR is not defined}}"
destination_dir="${2:-${DESTINATION_DIR:?DESTINATION_DIR is not defined}}"

if [[ ! -d "$repo_dir" ]]; then
  printf "%s is not a directory!" "$repo_dir" 1>&2
  exit 1
fi

# canonicalize path
repo_dir="${ realpath "$repo_dir"; }"

if [[ ! -d "$destination_dir" ]]; then
  printf "%s is not a directory!" "$destination_dir" 1>&2
  exit 1
fi

# canonicalize path
destination_dir="${ realpath "$destination_dir"; }"
printf -v date_str '%(%F-%H-%M-%S)T'

dest_file="$destination_dir/${repo_dir##*/}-backup-$date_str.zst"

printf "compressing %s to %s with zstd" "$repo_dir" "$dest_file"
# disable the service to prevent any writing mid-compress
systemctl disable --now autorestic-cron.timer
# re-enable service if something goes wrong
trap "systemctl enable --now autorestic-cron.timer" ERR
tar -cv -I "zstdmt -8" -f "$dest_file" "$repo_dir"
trap EXIT
systemctl enable --now autorestic-cron.timer
printf "success!"
