# Shared helpers for the Hackmachine scripts. Source, don't execute.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
HM_STATE="$XDG_STATE_HOME/hackmachine"
HM_SHARE="$XDG_DATA_HOME/hackmachine"

c_lav=$'\e[38;2;196;178;245m' c_mint=$'\e[38;2;166;230;191m'
c_coral=$'\e[38;2;247;165;154m' c_butter=$'\e[38;2;242;226;155m'
c_muted=$'\e[38;2;191;174;159m' c_off=$'\e[0m'

step() { printf '%sλ%s %s\n' "$c_mint" "$c_off" "$*"; }
ok()   { printf '  %s[OK]%s %s\n' "$c_mint" "$c_off" "$*"; }
warn() { printf '  %s[!!]%s %s\n' "$c_butter" "$c_off" "$*" >&2; }
die()  { printf '  %s[xx]%s %s\n' "$c_coral" "$c_off" "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# Distro family: fedora | debian | arch | suse | unknown
distro_family() {
  local id like
  id=$(. /etc/os-release; echo "${ID:-}")
  like=$(. /etc/os-release; echo "${ID_LIKE:-}")
  case " $id $like " in
    *" fedora "*|*" rhel "*|*" nobara "*) echo fedora ;;
    *" debian "*|*" ubuntu "*)            echo debian ;;
    *" arch "*)                           echo arch ;;
    *" suse "*|*" opensuse "*)            echo suse ;;
    *)                                    echo unknown ;;
  esac
}

# Krohnkite, the KWin tiling script (Plasma 6 fork), pinned to a release.
KK_VER=0.9.9.2
KK_URL="https://github.com/anametologin/krohnkite/releases/download/$KK_VER/krohnkite-${KK_VER}_1d7fd74.kwinscript"
KK_SHA256=42f7f66531d366c74b5fc860381da3517ccb4cdccd1f80c122fcab6e9a8fcf7e

kwrite() { kwriteconfig6 "$@" 2>/dev/null || kwriteconfig5 "$@"; }
kread()  { kreadconfig6 "$@" 2>/dev/null || kreadconfig5 "$@"; }

# (Re)load a KWin script after its files or its [Plugins] entry changed: unload it, then let
# reconfigure load whatever is enabled.
kwin_reload_script() {
  gdbus call --session --dest org.kde.KWin --object-path /Scripting \
    --method org.kde.kwin.Scripting.unloadScript "$1" >/dev/null 2>&1 || true
  gdbus call --session --dest org.kde.KWin --object-path /KWin --method org.kde.KWin.reconfigure >/dev/null
  gdbus call --session --dest org.kde.KWin --object-path /Scripting --method org.kde.kwin.Scripting.start >/dev/null 2>&1 || true
}

# A QML script (Krohnkite): KWin keeps its QML and JS in memory per file name for the whole
# session, so a reload by name runs the old code. Load fresh copies of main.qml and
# code/script.js under new names instead; the next login loads the real files as usual.
kwin_reload_qml_script() {  # plugin-id
  local c="$XDG_DATA_HOME/kwin/scripts/$1/contents" s id
  s="live-$(date +%s%N)"
  rm -f "$c"/ui/hm-live-*.qml "$c"/code/hm-live-*.js
  cp "$c/code/script.js" "$c/code/hm-$s.js"
  sed "s|\"../code/script.js\"|\"../code/hm-$s.js\"|" "$c/ui/main.qml" > "$c/ui/hm-$s.qml"
  gdbus call --session --dest org.kde.KWin --object-path /Scripting \
    --method org.kde.kwin.Scripting.unloadScript "$1" >/dev/null 2>&1 || true
  gdbus call --session --dest org.kde.KWin --object-path /KWin --method org.kde.KWin.reconfigure >/dev/null
  id=$(gdbus call --session --dest org.kde.KWin --object-path /Scripting \
    --method org.kde.kwin.Scripting.loadDeclarativeScript "$c/ui/hm-$s.qml" "$1" | grep -o -- '-\?[0-9]\+' | head -1)
  [ "${id:--1}" -ge 0 ] || return 1
  gdbus call --session --dest org.kde.KWin --object-path "/Scripting/Script$id" \
    --method org.kde.kwin.Script.run >/dev/null
}

plasma_eval() {
  local js=$1
  if have qdbus6; then qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$js"
  elif have qdbus; then qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$js"
  else
    # gdbus parses each argument as GVariant text, which mangles JavaScript, so hand it a quoted
    # string literal. It prints a GVariant tuple, ('…',), and nothing when plasmashell isn't
    # answering (e.g. mid-restart), so fail like qdbus would instead of handing Python "".
    local out
    out=$(gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell \
            --method org.kde.PlasmaShell.evaluateScript \
            "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1], ensure_ascii=False))' "$js")") || return 1
    [ -n "$out" ] || return 1
    python3 -c 'import ast,sys; print(ast.literal_eval(sys.argv[1])[0], end="")' "$out"
  fi
}

# Best installed monospace family: plain JetBrains Mono, then the Nerd Font build.
mono_font() {
  local fams
  fams=$(fc-list : family | tr ',' '\n')
  if grep -qx 'JetBrains Mono' <<<"$fams"; then echo 'JetBrains Mono'
  elif grep -qx 'JetBrainsMono Nerd Font' <<<"$fams"; then echo 'JetBrainsMono Nerd Font'
  elif grep -qx 'JetBrainsMono Nerd Font Mono' <<<"$fams"; then echo 'JetBrainsMono Nerd Font Mono'
  else echo 'Monospace'; fi
}

# One line per Plasma desktop: "<containment id> <screen> <x> <y> <width> <height>".
# Plasma reports logical geometry with rotation applied, so a 90° monitor comes out as 1440x2560.
# Screen 0 is the primary one (it gets the taskbar).
screens() {
  plasma_eval 'desktops().forEach(function (d) { var g = screenGeometry(d.screen);
    print(d.id + " " + d.screen + " " + g.x + " " + g.y + " " + g.width + " " + g.height + "\n"); });' |
    awk 'NF == 6 && $2 >= 0' | sort -k2,2n
}

# Copy a file into the current backup dir (once per run), keeping its path under $HOME.
backup() {
  local f
  for f in "$@"; do
    [ -e "$f" ] || continue
    local rel=${f#"$HOME"/}
    [ -e "$BACKUP_DIR/$rel" ] && continue
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    cp -a "$f" "$BACKUP_DIR/$rel"
  done
}
