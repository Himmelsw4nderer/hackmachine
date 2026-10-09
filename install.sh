#!/usr/bin/env bash
# Hackmachine for KDE Plasma 6: install packages (sudo), then theme the current user.
# usage: ./install.sh [--no-deps] [apply.sh options: --no-panel --no-shell --no-shortcuts --no-icons]
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
deps=1 args=()
for a in "$@"; do [ "$a" = --no-deps ] && deps=0 || args+=("$a"); done
[ "$deps" = 1 ] && "$here/scripts/deps.sh"
exec "$here/scripts/apply.sh" "${args[@]}"
