#!/usr/bin/env zsh

# load .env
# set -a && source craftoria-server-restarter.env && set +a

# seconds (currently 2m)
timeout=120
((notify_interval = timeout / 4))

if command -v rcon-cli >/dev/null; then
  echo "found rcon-cli, using RCON to stop server"
  while [[ $timeout -gt 0 ]]; do
    msg="The server will restart in $timeout seconds."
    echo $msg
    rcon-cli --port $RCON_PORT --password $RCON_PASSWORD say $msg
    sleep $notify_interval
    ((timeout = timeout - notify_interval))
  done
fi

rcon-cli --port $RCON_PORT --password $RCON_PASSWORD say "Shutting down!"
sleep 2
env dch.sh restart craftoria-mc-server
