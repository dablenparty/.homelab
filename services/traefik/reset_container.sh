#!/usr/bin/env bash

set -eo pipefail

if ((UID != 0)); then
  echo "you must run this script as root!" 1>&2
  exit 2
fi

docker compose down
rm -rvf ./{config/acme.json,logs}
touch ./config/acme.json
chmod 600 ./config/acme.json
docker compose up -d
