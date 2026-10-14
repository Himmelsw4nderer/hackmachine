#!/usr/bin/env python3
"""Bind / unbind the Hackmachine global shortcuts from config/shortcuts.conf.

Each row with a command becomes ~/.local/share/applications/hackmachine-<slug>.desktop
plus a kglobalaccel "_launch" shortcut, registered live over D-Bus (and persisted by
kglobalaccel in kglobalshortcutsrc), so no logout is needed.

A command "kwin:ActionA,ActionB" binds existing KWin actions (Krohnkite's, for one) instead.
With several actions the keys split up: "Meta+←↑→↓" is Left, Up, Right, Down and
"Meta+Ctrl+H/L" is H, L. Every Krohnkite action not listed is unbound, as are the KWin actions
on "!free" lines; the previous keys are saved so unbind can put them back.

usage: shortcuts.py bind CONF BIN_DIR | unbind | list CONF
"""
import json
import os
import re
import subprocess
import sys
from pathlib import Path

APPS = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "applications"
PREFIX = "hackmachine-"
STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "hackmachine"
KWIN_SAVED = STATE / "kwin-shortcuts.json"
ARROWS = {"←": "Left", "↑": "Up", "→": "Right", "↓": "Down"}

MODS = {"meta": 0x10000000, "alt": 0x08000000, "ctrl": 0x04000000, "shift": 0x02000000}
KEYS = {
    "return": 0x01000004, "enter": 0x01000005, "space": 0x20, "esc": 0x01000000,
    "escape": 0x01000000, "tab": 0x01000001, "backspace": 0x01000003, "del": 0x01000007,
    "delete": 0x01000007, "print": 0x01000009, "home": 0x01000010, "end": 0x01000011,
    "left": 0x01000012, "up": 0x01000013, "right": 0x01000014, "down": 0x01000015,
    "pgup": 0x01000016, "pgdown": 0x01000017,
}


def parse(conf):
    rows = []
    for line in Path(conf).read_text().splitlines():
        if not line.strip() or line.lstrip().startswith(("#", "!")):
            continue
        parts = [p.strip() for p in line.split("|")]
        parts += [""] * (4 - len(parts))
        group, keys, label, cmd = parts[:4]
        rows.append({"group": group, "keys": keys, "label": label, "cmd": cmd})
    return rows


def freed(conf):
    """KWin actions named on '!free |' lines: Plasma defaults the rice's keys replace."""
    return [a.strip() for line in Path(conf).read_text().splitlines()
            if line.startswith("!free") for a in line.split("|", 1)[1].split(",") if a.strip()]


def qt_key(seq):
    """'Meta+Shift+Return' -> Qt int key code. The key part may itself be '+' or '/'."""
    m = re.fullmatch(r"((?:(?:Meta|Alt|Ctrl|Shift)\+)*)(.+)", seq, re.I)
    mods, key = m.group(1), m.group(2)
    code = 0
    for mod in filter(None, mods.split("+")):
        code |= MODS[mod.lower()]
    k = key.lower()
    if k in KEYS:
        code |= KEYS[k]
    elif re.fullmatch(r"f([1-9]|[12][0-9]|3[0-5])", k):
        code |= 0x01000030 + int(k[1:]) - 1
    elif len(key) == 1:  # letters, digits and ASCII punctuation are their own Qt key codes
        code |= ord(key.upper())
    else:
        raise ValueError(f"unknown key '{key}' in '{seq}'")
    return code


def slug(label):
    return re.sub(r"[^a-z0-9]+", "-", label.lower()).strip("-")


def accel(method, *args):
    return subprocess.run(
        ["gdbus", "call", "--session", "--dest", "org.kde.kglobalaccel",
         "--object-path", "/kglobalaccel", "--method", f"org.kde.KGlobalAccel.{method}", *args],
        capture_output=True, text=True)


def action_id(desktop, label):
    return f"['{desktop}','_launch','{label}','{label}']"


def split_keys(seq, n):
    """'Meta+←↑→↓' -> 4 keys, 'Meta+Ctrl+H/L' -> 2 keys; a single action keeps the sequence."""
    if n == 1:
        return [seq]
    mods, _, last = seq.rpartition("+")
    keys = [ARROWS[c] for c in last] if all(c in ARROWS for c in last) else last.split("/")
    if len(keys) != n:
        raise ValueError(f"'{seq}' gives {len(keys)} keys for {n} actions")
    return [f"{mods}+{k}" if mods else k for k in keys]


def kwin_id(action):
    return f"['kwin','{action}','KWin','']"


def kwin_keys(action):
    r = accel("shortcut", kwin_id(action))
    return [int(x) for x in re.findall(r"-?\d+", r.stdout)] if r.returncode == 0 else []


def kwin_set(action, keys):
    return accel("setForeignShortcut", kwin_id(action), f"@ai {keys}")


def bind_kwin(conf, rows):
    actions = [a for r in rows for a in r["cmd"][5:].split(",")]
    present = accel("allActionsForComponent", "['kwin']").stdout
    missing = [a for a in actions if f"'{a}'" not in present]
    if missing:
        print(f"  KWin actions not loaded, skipped: {', '.join(missing)}")
        return
    saved = json.loads(KWIN_SAVED.read_text()) if KWIN_SAVED.exists() else {}
    # Krohnkite's own defaults (Meta+Return, Meta+L, Meta+D …) would shadow the rice's keys, so
    # every Krohnkite action starts unbound, along with the Plasma defaults listed in "!free".
    krohnkite = sorted(set(re.findall(r"'(Krohnkite\w+)'", present)))
    for a in krohnkite + freed(conf):
        if a not in saved:
            saved[a] = kwin_keys(a)
        kwin_set(a, [])
    for row in rows:
        acts = row["cmd"][5:].split(",")
        ok = True
        for key, act in zip(split_keys(row["keys"], len(acts)), acts):
            if act not in saved:
                saved[act] = kwin_keys(act)
            ok &= kwin_set(act, [qt_key(key)]).returncode == 0
        print(f"  {row['keys']:<18} {row['label']:<16} {'bound' if ok else 'FAILED'}")
    STATE.mkdir(parents=True, exist_ok=True)
    KWIN_SAVED.write_text(json.dumps(saved, indent=1))


def unbind_kwin():
    if not KWIN_SAVED.exists():
        return
    saved = json.loads(KWIN_SAVED.read_text())
    for a in saved:  # free everything first, then hand the keys back
        kwin_set(a, [])
    for a, keys in saved.items():
        if keys:
            kwin_set(a, keys)
    KWIN_SAVED.unlink()
    print(f"  restored {len(saved)} KWin shortcuts")


def bind(conf, bin_dir):
    APPS.mkdir(parents=True, exist_ok=True)
    rows = parse(conf)
    bind_kwin(conf, [r for r in rows if r["cmd"].startswith("kwin:")])
    for row in rows:
        if not row["cmd"] or row["cmd"].startswith("kwin:"):
            continue
        cmd = re.sub(r"(^|\s)(hm-[\w-]+)", lambda m: m.group(1) + str(Path(bin_dir) / m.group(2)), row["cmd"])
        desktop = f"{PREFIX}{slug(row['label'])}.desktop"
        label = f"Hackmachine: {row['label']}"
        (APPS / desktop).write_text(
            "[Desktop Entry]\nType=Application\n"
            f"Name={label}\nExec={cmd}\nIcon=hackmachine\nNoDisplay=true\n"
            f"X-KDE-Shortcuts={row['keys']}\n")
        aid = action_id(desktop, label)
        accel("doRegister", aid)
        r = accel("setForeignShortcut", aid, f"[{qt_key(row['keys'])}]")
        status = "bound" if r.returncode == 0 else f"FAILED ({r.stderr.strip()})"
        print(f"  {row['keys']:<18} {row['label']:<16} {status}")
    subprocess.run(["kbuildsycoca6"], capture_output=True)


def unbind():
    unbind_kwin()
    for f in sorted(APPS.glob(f"{PREFIX}*.desktop")):
        accel("unregister", f.name, "_launch")
        f.unlink()
        print(f"  removed {f.name}")
    subprocess.run(["kbuildsycoca6"], capture_output=True)


COLORS = {"apps": (166, 230, 191), "session": (226, 181, 240), "windows": (163, 205, 245),
          "tiling": (148, 220, 214), "desktop": (196, 178, 245), "tools": (249, 196, 154)}


def show(conf):
    """Pretty cheat-sheet for the terminal (hm-keys)."""
    rows = parse(conf)
    muted = "\x1b[38;2;191;174;159m"
    off = "\x1b[0m"
    last = None
    for r in rows:
        rgb = COLORS.get(r["group"], (246, 236, 228))
        hue = "\x1b[38;2;%d;%d;%dm" % rgb
        if r["group"] != last:
            print(f"\n {hue}\x1b[1m{r['group'].upper()} //{off}")
            last = r["group"]
        print(f"   {hue}{r['keys']:<20}{off}{muted}{'.' * 3}{off} {r['label']}")
    print()


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "bind":
        bind(sys.argv[2], sys.argv[3])
    elif cmd == "unbind":
        unbind()
    elif cmd == "list":
        show(sys.argv[2])
    else:
        sys.exit(__doc__)
