#!/usr/bin/env bash
# Nook for KDE Plasma 6: install packages (sudo), theme the current user, then the login
# screen (sudo).
# usage: ./install.sh [--no-deps] [--no-sddm] [apply.sh options: --no-panel --no-shell --no-shortcuts --no-icons --no-cursor]
#   --no-deps skips everything that needs sudo, the login screen too
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
deps=1 sddm=1 args=()
for a in "$@"; do
  case "$a" in --no-deps) deps=0 ;; --no-sddm) sddm=0 ;; *) args+=("$a") ;; esac
done
[ "$deps" = 1 ] && "$here/scripts/deps.sh"
"$here/scripts/apply.sh" "${args[@]}"
if [ "$deps" = 1 ] && [ "$sddm" = 1 ]; then "$here/scripts/sddm.sh"; fi
