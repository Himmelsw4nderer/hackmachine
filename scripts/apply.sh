#!/usr/bin/env bash
# Apply Hackmachine to the current user's Plasma 6 session. No sudo needed.
# Everything it overwrites is copied to ~/.local/state/hackmachine/backup-<time>/ first;
# uninstall.sh puts the oldest backup (your pre-Hackmachine setup) back.
#
# usage: apply.sh [--no-panel] [--no-shell] [--no-shortcuts] [--no-icons] [--no-widgets]
set -euo pipefail
source "$(dirname "$0")/lib.sh"

DO_PANEL=1 DO_SHELL=1 DO_KEYS=1 DO_ICONS=1 DO_WIDGETS=1
for a in "$@"; do
  case "$a" in
    --no-panel) DO_PANEL=0 ;; --no-shell) DO_SHELL=0 ;;
    --no-shortcuts) DO_KEYS=0 ;; --no-icons) DO_ICONS=0 ;; --no-widgets) DO_WIDGETS=0 ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    *) die "unknown option $a" ;;
  esac
done

have kwriteconfig6 || die "this needs KDE Plasma 6 (kwriteconfig6 not found)"
pgrep -x plasmashell >/dev/null || die "plasmashell is not running; log into a Plasma session first"

CFG=$XDG_CONFIG_HOME
BIN="$HOME/.local/bin"
FONT=$(mono_font)
SCREENS=$(screens)
[ -n "$SCREENS" ] || die "could not read the screen layout from plasmashell"
BACKUP_DIR="$HM_STATE/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR" "$HM_SHARE" "$BIN"

# ── 0 · backup ──────────────────────────────────────────────────────────────
step "backing up current settings → ${BACKUP_DIR/#$HOME/\~}"
backup "$CFG/kdeglobals" "$CFG/kwinrc" "$CFG/kwinrulesrc" "$CFG/plasmarc" \
       "$CFG/konsolerc" "$CFG/kscreenlockerrc" "$CFG/plasma-org.kde.plasma.desktop-appletsrc" \
       "$CFG/plasmashellrc" "$CFG/kglobalshortcutsrc" "$CFG/fastfetch/config.jsonc" \
       "$CFG/cava/config" "$CFG/btop/btop.conf" "$HOME/.bashrc"
# Names the uninstaller re-applies through Plasma's own tools.
{
  printf 'colorscheme=%q\n' "$(kread --file kdeglobals --group General --key ColorScheme)"
  printf 'icons=%q\n' "$(kread --file kdeglobals --group Icons --key Theme)"
  printf 'desktoptheme=%q\n' "$(kread --file plasmarc --group Theme --key name)"
} > "$BACKUP_DIR/previous.env"
ok "backup done"

# ── 1 · files ───────────────────────────────────────────────────────────────
step "installing theme files"
install -Dm644 "$REPO/theme/color-schemes/Hackmachine.colors" "$XDG_DATA_HOME/color-schemes/Hackmachine.colors"
install -Dm644 "$REPO/theme/konsole/Hackmachine.colorscheme" "$XDG_DATA_HOME/konsole/Hackmachine.colorscheme"
install -Dm644 "$REPO/theme/icons/hackmachine.svg" "$XDG_DATA_HOME/icons/hicolor/scalable/apps/hackmachine.svg"
install -Dm755 "$REPO/bin/hm-menu" "$BIN/hm-menu"
install -Dm755 "$REPO/bin/hm-keys" "$BIN/hm-keys"
install -Dm755 "$REPO/bin/hm-tray" "$BIN/hm-tray"
install -Dm644 "$REPO/scripts/shortcuts.py" "$HM_SHARE/shortcuts.py"
install -Dm644 "$REPO/config/shortcuts.conf" "$HM_SHARE/shortcuts.conf"
install -Dm644 "$REPO/theme/shell/bashrc" "$HM_SHARE/bashrc"
install -Dm644 "$REPO/theme/fastfetch/config.jsonc" "$CFG/fastfetch/config.jsonc"
install -Dm644 "$REPO/theme/fastfetch/candy-logo.txt" "$CFG/fastfetch/candy-logo.txt"
install -Dm644 "$REPO/theme/cava/config" "$CFG/cava/config"
install -Dm644 "$REPO/theme/btop/hackmachine.theme" "$CFG/btop/themes/hackmachine.theme"
if [ -f "$CFG/btop/btop.conf" ]; then
  sed -i -E 's|^color_theme *=.*|color_theme = "hackmachine"|' "$CFG/btop/btop.conf"
else
  printf 'color_theme = "hackmachine"\ntheme_background = True\n' > "$CFG/btop/btop.conf"
fi
gtk-update-icon-cache -q "$XDG_DATA_HOME/icons/hicolor" 2>/dev/null || true

cat > "$XDG_DATA_HOME/konsole/Hackmachine.profile" <<EOF
[Appearance]
ColorScheme=Hackmachine
Font=$FONT,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1

[Cursor Options]
CursorShape=0

[General]
Environment=TERM=xterm-256color,COLORTERM=truecolor,HACKMACHINE=1
Name=Hackmachine
Parent=FALLBACK/
TerminalCenter=true
TerminalMargin=12

[Scrolling]
ScrollBarPosition=2
EOF
kwrite --file konsolerc --group "Desktop Entry" --key DefaultProfile Hackmachine.profile
ok "konsole profile, fastfetch, btop, cava, hm-menu, hm-keys"

if [ "$DO_SHELL" = 1 ]; then
  hook='[ -f "$HOME/.local/share/hackmachine/bashrc" ] && . "$HOME/.local/share/hackmachine/bashrc"  # hackmachine'
  grep -qF '# hackmachine' "$HOME/.bashrc" 2>/dev/null || printf '\n%s\n' "$hook" >> "$HOME/.bashrc"
  ok "bash prompt + fastfetch (only inside the Hackmachine Konsole)"
fi

# ── 2 · colours, plasma style, icons ─────────────────────────────────────────
step "colours + plasma style"
plasma-apply-colorscheme Hackmachine >/dev/null 2>&1 || plasma-apply-colorscheme Hackmachine
kwrite --file kdeglobals --group KDE --key widgetStyle Breeze
pstyle="$XDG_DATA_HOME/plasma/desktoptheme/hackmachine"
rm -rf "$pstyle"
python3 "$REPO/scripts/themegen.py" plasma "$pstyle"
# Plasma caches theme SVGs; drop the cache so a regenerated style shows up at once.
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}"/plasma-svgelements* "${XDG_CACHE_HOME:-$HOME/.cache}"/plasma_theme_hackmachine*
plasma-apply-desktoptheme hackmachine >/dev/null 2>&1 || plasma-apply-desktoptheme hackmachine
ok "Hackmachine colours + Plasma style (cocoa panel, lavender focus bars, rounded popups)"

if [ "$DO_ICONS" = 1 ]; then
  step "icons: BeautyLine + Breeze symbolic, one pastel per category"
  # BeautyLine (GPL-3) is fetched at a fixed commit and repainted locally; it is not vendored here.
  BL_REV=07e3736f8be38f9f48cf015d992f56f06e455002
  bl_src="$HM_STATE/src/beautyline-$BL_REV"
  if [ ! -f "$bl_src/index.theme" ]; then
    mkdir -p "$HM_STATE/src"
    tmp=$(mktemp -d "$HM_STATE/src/dl.XXXXXX")
    curl -fsSL "https://gitlab.com/garuda-linux/themes-and-settings/artwork/beautyline/-/archive/$BL_REV/beautyline-$BL_REV.tar.gz" \
      | tar -xz -C "$tmp" || die "could not download BeautyLine"
    mv "$tmp"/beautyline-* "$bl_src" && rmdir "$tmp"
  fi
  breeze=$(ls -d /usr/share/icons/breeze-dark /usr/share/icons/breeze 2>/dev/null | head -1)
  icons="$XDG_DATA_HOME/icons"
  if [ -n "$breeze" ]; then
    python3 "$REPO/scripts/icons.py" "$breeze" "$icons/Hackmachine-Breeze" "Hackmachine-Breeze" \
      "breeze-dark,hicolor" --keep-semantic --symbolic-only
  fi
  python3 "$REPO/scripts/icons.py" "$bl_src" "$icons/Hackmachine" "Hackmachine" \
    "Hackmachine-Breeze,breeze-dark,hicolor"
  install -Dm644 "$REPO/theme/icons/hackmachine.svg" "$icons/Hackmachine/apps/scalable/hackmachine.svg"
  changeicons=$(ls /usr/libexec/plasma-changeicons /usr/lib/*/libexec/plasma-changeicons \
                   /usr/lib/libexec/plasma-changeicons 2>/dev/null | head -1 || true)
  if [ -n "$changeicons" ]; then "$changeicons" Hackmachine >/dev/null 2>&1 || true
  else kwrite --file kdeglobals --group Icons --key Theme Hackmachine; fi
  ok "icon theme Hackmachine"
fi

# ── 3 · fonts: monospace everywhere ──────────────────────────────────────────
step "fonts → $FONT"
f() { echo "$FONT,$1,-1,5,$2,0,0,0,0,0,0,0,0,0,0,1"; }
kwrite --file kdeglobals --group General --key font "$(f 10 400)"
kwrite --file kdeglobals --group General --key fixed "$(f 10 400)"
kwrite --file kdeglobals --group General --key menuFont "$(f 10 400)"
kwrite --file kdeglobals --group General --key toolBarFont "$(f 10 400)"
kwrite --file kdeglobals --group General --key smallestReadableFont "$(f 8 400)"
kwrite --file kdeglobals --group WM --key activeFont "$(f 10 700)"
ok "fonts set"

# ── 4 · windows ─────────────────────────────────────────────────────────────
step "window decoration + rules"
deco="$XDG_DATA_HOME/aurorae/themes/Hackmachine"
rm -rf "$deco"
python3 "$REPO/scripts/themegen.py" aurorae "$deco"
kwrite --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
kwrite --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__Hackmachine
kwrite --file kwinrc --group org.kde.kdecoration2 --key BorderSize Normal
kwrite --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft "M"
kwrite --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"
kwrite --file kwinrc --group Plugins --key blurEnabled true

# hm-menu: borderless, centred, on top, out of the taskbar
R=hackmachine-menu
kwrite --file kwinrulesrc --group $R --key Description "Hackmachine hack menu"
kwrite --file kwinrulesrc --group $R --key title "hm-menu"
kwrite --file kwinrulesrc --group $R --key titlematch 2
kwrite --file kwinrulesrc --group $R --key wmclass "konsole"
kwrite --file kwinrulesrc --group $R --key wmclassmatch 2
kwrite --file kwinrulesrc --group $R --key noborder true
kwrite --file kwinrulesrc --group $R --key noborderrule 2
kwrite --file kwinrulesrc --group $R --key above true
kwrite --file kwinrulesrc --group $R --key aboverule 2
kwrite --file kwinrulesrc --group $R --key skiptaskbar true
kwrite --file kwinrulesrc --group $R --key skiptaskbarrule 2
for k in size sizerule placement placementrule position positionrule; do   # placed by the KWin script
  kwrite --file kwinrulesrc --group $R --key $k --delete 2>/dev/null || true
done
script_dir="$XDG_DATA_HOME/kwin/scripts/hackmachine-menu"
rm -rf "$script_dir"; mkdir -p "$(dirname "$script_dir")"
cp -r "$REPO/theme/kwin/hackmachine-menu" "$script_dir"
kwrite --file kwinrc --group Plugins --key hackmachine-menuEnabled true
rules=$(kread --file kwinrulesrc --group General --key rules)
case ",$rules," in *",$R,"*) ;; *) rules=${rules:+$rules,}$R ;; esac
kwrite --file kwinrulesrc --group General --key rules "$rules"
kwrite --file kwinrulesrc --group General --key count "$(awk -F, '{print NF}' <<<"$rules")"
qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 \
  || gdbus call --session --dest org.kde.KWin --object-path /KWin --method org.kde.KWin.reconfigure >/dev/null
ok "Hackmachine decoration: lavender focus ring, [_] [□] [x], hm-menu placement"

# ── 5 · wallpaper with the key cheat-sheet, one per screen ──────────────────
step "wallpapers"
render() {  # svg png
  if have rsvg-convert; then rsvg-convert -o "$2" "$1"
  elif have inkscape; then inkscape "$1" --export-type=png --export-filename="$2" >/dev/null 2>&1
  elif have magick; then magick -background none "$1" "$2"
  else die "need rsvg-convert, inkscape or imagemagick to render the wallpaper (run ./install.sh)"; fi
}
js="" layout_in=""
while read -r id screen x y w h; do
  # the primary screen holds the taskbar, so the banner moves up there
  panel=0; [ "$screen" = 0 ] && panel=44
  png="$HM_SHARE/wallpaper-${w}x${h}-p$panel.png"
  # portrait screens hand the middle band to the desktop widgets, so the skull goes
  skull=""; [ "$DO_WIDGETS" = 1 ] && [ "$h" -gt "$w" ] && skull=--no-skull
  python3 "$REPO/scripts/wallpaper.py" "$REPO/config/shortcuts.conf" "${png%.png}.svg" "${w}x$h" "$FONT" "$panel" $skull
  layout_in+="$id $screen $w $h ${png%.png}.json"$'\n'
  render "${png%.png}.svg" "$png"
  js+="d = desktopById($id); d.wallpaperPlugin = 'org.kde.image';
       d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
       d.writeConfig('Image', 'file://$png'); d.writeConfig('FillMode', 2);"
  [ "$screen" = 0 ] && lock_png=$png
  ok "screen $screen: ${w}x$h$([ "$h" -gt "$w" ] && echo ' (portrait)')"
done <<<"$SCREENS"
plasma_eval "var d; $js" >/dev/null
kwrite --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$lock_png"
ok "lock screen uses the primary screen's wallpaper"

# ── 6 · taskbar ─────────────────────────────────────────────────────────────
if [ "$DO_PANEL" = 1 ]; then
  step "taskbar"
  launchers=$(python3 "$REPO/scripts/apps.py" "$REPO/config/apps.conf" launchers)
  plasma_eval "$(sed "s|__LAUNCHERS__|$launchers|" "$REPO/scripts/panel.js")" >/dev/null
  rm -f "$HM_STATE/tray-seen"   # new tray: hide everything again
  ok "three islands: λ + apps · clock · tray"
fi

# ── 6a · desktop widgets on every screen ────────────────────────────────────
if [ "$DO_WIDGETS" = 1 ]; then
  step "desktop widgets: clock, system, apps on every screen"
  for pl in apps clock sys; do
    dst="$XDG_DATA_HOME/plasma/plasmoids/org.hackmachine.$pl"
    rm -rf "$dst"; mkdir -p "$(dirname "$dst")"
    cp -r "$REPO/theme/plasmoids/org.hackmachine.$pl" "$dst"
  done
  apps_json=$(python3 "$REPO/scripts/apps.py" "$REPO/config/apps.conf" json)
  # 44px island + its float margin
  for mode in remove add; do
    plasma_eval "$(printf '%s' "$layout_in" | python3 "$REPO/scripts/layout.py" "$apps_json" "$BIN/hm-menu" 64 $mode)" >/dev/null
    [ $mode = remove ] && sleep 2
  done
  ok "$(printf '%s' "$layout_in" | grep -c .) screen(s) filled; apps from config/apps.conf"
fig/apps.conf" launchers | tr ',' '\n' | wc -l) apps from config/apps.conf)"
fi

# ── 6b · minimal tray ───────────────────────────────────────────────────────
step "tray: network, sound, microphone, battery; the rest in the ^ popup"
mkdir -p "$CFG/autostart"
cat > "$CFG/autostart/hackmachine-tray.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Hackmachine tray
Comment=Keeps the system tray down to network, sound, microphone and battery
Exec=$BIN/hm-tray
NoDisplay=true
X-KDE-autostart-phase=2
DESKTOP
pkill -f "$BIN/hm-tr[a]y" 2>/dev/null || true
(setsid -f "$BIN/hm-tray" >/dev/null 2>&1 &)
ok "hm-tray runs at login and hides new tray icons as apps start"

# ── 7 · shortcuts ───────────────────────────────────────────────────────────
if [ "$DO_KEYS" = 1 ]; then
  step "global shortcuts"
  python3 "$REPO/scripts/shortcuts.py" bind "$REPO/config/shortcuts.conf" "$BIN"
fi

# plasmashell only reads fonts and the icon theme at start-up, so restart it once.
step "restarting plasmashell"
if systemctl --user is-active -q plasma-plasmashell.service 2>/dev/null; then
  systemctl --user restart plasma-plasmashell.service
else
  kquitapp6 plasmashell >/dev/null 2>&1 || true; sleep 1; (setsid -f plasmashell >/dev/null 2>&1 &)
fi
ok "done"

printf '\n%sλ hackmachine applied.%s  %sMeta+/ shows every key · Meta+Space opens the hack menu%s\n' \
  "$c_lav" "$c_off" "$c_muted" "$c_off"
printf '%s  Log out and back in once so every app picks up the new fonts.%s\n' "$c_muted" "$c_off"
