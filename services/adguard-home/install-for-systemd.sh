#!/usr/bin/env bash

set -eo pipefail

if ((UID != 0)); then
  echo "please run this script as root!" 1>&2
  exit 2
fi

# link adguardhome.conf
system_resolved_d=/etc/systemd/resolved.conf.d
conf_name=adguardhome.conf
conf_path="${ realpath -e "${0%/*}/$conf_name"; }"
if [[ ! -d "$system_resolved_d" ]]; then
  mkdir -v "$system_resolved_d"
fi
# hard link
ln -v "$conf_path" "$system_resolved_d/$conf_name"

# link systemd resolv.conf
mv -v /etc/resolv.conf /etc/resolv.conf.bak
ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl reload-or-restart systemd-resolved
