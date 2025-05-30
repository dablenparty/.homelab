#!/usr/bin/env sh

sed -i "s|ultrasecretkey|$(openssl rand -hex 32)|g" searxng/settings.yml
