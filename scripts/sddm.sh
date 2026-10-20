#!/usr/bin/env bash
# Theme the login screen (SDDM): the Nook greeter and cursor. Needs sudo, since SDDM runs
# as its own user and only reads system-wide themes. Run apply.sh first: the cursor comes from it.
#
# usage: sddm.sh            install, and make it the current SDDM theme
#        sddm.sh --remove   take it out again; SDDM falls back to the distro's theme
set -euo pipefail
source "$(dirname "$0")/lib.sh"

THEME=/usr/share/sddm/themes/nook
CURSOR=/usr/share/icons/Nook-Cursors
# sorts after the distro's and System Settings' files (kde_settings.conf), so it wins
CONF=/etc/sddm.conf.d/zz-nook.conf

if [ "${1:-}" = --remove ]; then
  step "login screen: removing the Nook theme"
  sudo rm -rf "$THEME" "$CURSOR" "$CONF"
  ok "SDDM is back on the distro's theme"
  exit 0
fi

[ -d /etc/sddm.conf.d ] || have sddm || { warn "SDDM is not installed; the login screen stays as it is"; exit 0; }
step "login screen: SDDM theme + cursor"
FONT=$(mono_font)
tmp=$(mktemp -d)
cp -r "$REPO/theme/sddm/nook" "$tmp/nook"
sed -i "s|^font=.*|font=$FONT|" "$tmp/nook/theme.conf"
# and the files from before the rename, if any
sudo rm -rf "$THEME" /usr/share/sddm/themes/hackmachine /usr/share/icons/Hackmachine-Cursors /etc/sddm.conf.d/zz-hackmachine.conf
sudo install -d "$(dirname "$THEME")"
sudo cp -r "$tmp/nook" "$THEME"
sudo chmod -R a+rX "$THEME"
rm -rf "$tmp"

cursor_conf=""
src_cursor="$XDG_DATA_HOME/icons/Nook-Cursors"
if [ -d "$src_cursor/cursors" ]; then
  sudo rm -rf "$CURSOR"
  sudo cp -r "$src_cursor" "$CURSOR"
  sudo chmod -R a+rX "$CURSOR"
  cursor_conf=$'CursorTheme=Nook-Cursors\nCursorSize=32'
else
  warn "no Nook cursor yet (run apply.sh first); the login screen keeps its cursor"
fi

sudo install -d /etc/sddm.conf.d
printf '%s\n' "# Written by Nook's scripts/sddm.sh; 'scripts/sddm.sh --remove' takes it out." \
  "[Theme]" "Current=nook" "Font=$FONT,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1" ${cursor_conf:+"$cursor_conf"} \
  | sudo tee "$CONF" >/dev/null
ok "SDDM theme nook (shows at the next login; preview: sddm-greeter-qt6 --test-mode --theme $THEME)"
