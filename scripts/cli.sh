#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
scripts/moon-local.sh build --target js -j 1 -d
exec node _build/js/debug/build/cmd/main/main.js "$@"
