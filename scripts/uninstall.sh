#!/usr/bin/env bash
# Undo Hackmachine: restore the settings saved by the first apply.sh run and remove our files.
# usage: uninstall.sh [backup-dir]   (default: the oldest backup, i.e. your pre-Hackmachine setup)
set -euo pipefail
source "$(dirname "$0")/lib.sh"

src=${1:-$(ls -d "$HM_STATE"/backup-* 2>/dev/null | sort | head -1 || true)}
[ -n "$src" ] && [ -d "$src" ] || die "no backup found in ${HM_STATE/#$HOME/\~}"
step "restoring from ${src/#$HOME/\~}"

python3 "$REPO/scripts/shortcuts.py" unbind || true

# kwinrulesrc / breezerc / btop.conf etc. that did not exist before get removed, the rest restored.
for f in kdeglobals kwinrc kwinrulesrc plasmarc konsolerc kscreenlockerrc plasmashellrc \
         fastfetch/config.jsonc cava/config btop/btop.conf; do
  rel=".config/$f"
  if [ -e "$src/$rel" ]; then cp -a "$src/$rel" "$HOME/$rel"
  else rm -f "$HOME/$rel"; fi
done
[ -e "$src/.bashrc" ] && cp -a "$src/.bashrc" "$HOME/.bashrc" || sed -i '/# hackmachine$/d' "$HOME/.bashrc"

pkill -f "hm-tr[a]y" 2>/dev/null || true
rm -f "$HOME/.local/bin/hm-menu" "$HOME/.local/bin/hm-keys" "$HOME/.local/bin/hm-tray" \
      "$XDG_CONFIG_HOME/autostart/hackmachine-tray.desktop" "$HM_STATE/tray-seen" \
      "$XDG_DATA_HOME/konsole/Hackmachine.profile" "$XDG_DATA_HOME/konsole/Hackmachine.colorscheme" \
      "$XDG_DATA_HOME/icons/hicolor/scalable/apps/hackmachine.svg" \
      "$XDG_CONFIG_HOME/fastfetch/candy-logo.txt" \
      "$XDG_STATE_HOME/hackmachine/menu-config/konsolerc" "$XDG_CONFIG_HOME/btop/themes/hackmachine.theme"

# shellcheck disable=SC1091
source "$src/previous.env"
[ -n "${colorscheme:-}" ] && plasma-apply-colorscheme "$colorscheme" >/dev/null 2>&1 || true
[ -n "${desktoptheme:-}" ] && plasma-apply-desktoptheme "$desktoptheme" >/dev/null 2>&1 || true
changeicons=$(ls /usr/libexec/plasma-changeicons /usr/lib/*/libexec/plasma-changeicons 2>/dev/null | head -1 || true)
[ -n "${icons:-}" ] && [ -n "$changeicons" ] && "$changeicons" "$icons" >/dev/null 2>&1 || true
rm -f "$XDG_DATA_HOME/color-schemes/Hackmachine.colors"
rm -rf "$XDG_DATA_HOME/kwin/scripts/hackmachine-menu" "$XDG_DATA_HOME/aurorae/themes/Hackmachine" \
       "$XDG_DATA_HOME/plasma/desktoptheme/hackmachine" "$XDG_DATA_HOME/icons/Hackmachine" \
       "$XDG_DATA_HOME/icons/Hackmachine-Breeze"
qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

# The panel layout lives in plasmashell's own config: restart it to load the restored file.
kquitapp6 plasmashell >/dev/null 2>&1 || true
sleep 2
if [ -e "$src/.config/plasma-org.kde.plasma.desktop-appletsrc" ]; then
  cp -a "$src/.config/plasma-org.kde.plasma.desktop-appletsrc" "$XDG_CONFIG_HOME/"
fi
(setsid -f plasmashell >/dev/null 2>&1 &)
ok "restored. Log out and back in to reset fonts in running apps."
