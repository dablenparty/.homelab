#!/usr/bin/env bash

set -eo pipefail

# export and source all vars in .env
set -a && source .env && set +a

forgejo-runner create-runner-file --connect --instance http://forgejo-server:3000 --name runner --secret "${SHARED_SECRET}"
# add 'docker' label
sed -i -e "s|\"labels\": null|\"labels\": [\"docker:docker://code.forgejo.org/oci/node:20-bookworm\"]|" .runner
forgejo-runner generate-config >config.yml
# set runner config vars
sed -i -e "s|^  envs:$$|  envs:\n    DOCKER_HOST: $DOCKER_HOST|" -e "s|network: .*|network: forgejo-net|" -e "s|  valid_volumes: \[\]$$|  valid_volumes:\n    - \"**\"|" -e "s|  docker_host: .*|  docker_host: \"$DOCKER_HOST\"|" config.yml
chown -R "${RUNNER_UID}":"${RUNNER_GID}" /data
