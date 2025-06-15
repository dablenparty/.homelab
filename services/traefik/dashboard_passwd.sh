#!/usr/bin/env bash

set -eo pipefail

htpasswd -nB admin | sed -e s/\\$/\\$\\$/g
