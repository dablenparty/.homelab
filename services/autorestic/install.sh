#!/usr/bin/env bash

if ((UID != 0)); then
  echo "Please run this script as root!" 1>&2
  exit 1
fi

mkdir -vp /mnt/HomelabStorage/autorestic
unbox --if-exists ignore ./config/ ./systemd/
autorestic check
systemctl enable --now autorestic-cron.timer
