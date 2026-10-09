#!/usr/bin/env python3
"""Resolve config/apps.conf against the installed .desktop files.

usage: apps.py CONF json       → [{"name","hue","id","icon","path"}] for the desktop card
       apps.py CONF launchers  → "applications:x.desktop,…" for the taskbar
"""
import json
import os
import re
import sys
from pathlib import Path

HUE = {"pink": "#f5a8c9", "coral": "#f7a59a", "peach": "#f9c49a", "butter": "#f2e29b", "mint": "#a6e6bf",
       "teal": "#94dcd6", "sky": "#a3cdf5", "lavender": "#c4b2f5", "lilac": "#e2b5f0"}
DATA = os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share"))
DIRS = [Path(DATA) / "applications", Path(DATA) / "flatpak/exports/share/applications",
        Path("/var/lib/flatpak/exports/share/applications"), Path("/var/lib/snapd/desktop/applications"),
        Path("/usr/local/share/applications"), Path("/usr/share/applications")]


def find(desktop_id):
    for d in DIRS:
        f = d / f"{desktop_id}.desktop"
        if f.is_file():
            return f
    return None


def entry_icon(path):
    # first Icon= inside [Desktop Entry], not one of the actions below it
    text = path.read_text(errors="ignore").split("\n[Desktop Action", 1)[0]
    m = re.search(r"^Icon=(.+)$", text, re.M)
    return m.group(1).strip() if m else "application-x-executable"


def resolve(conf):
    apps = []
    for line in Path(conf).read_text().splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        name, hue, ids = (p.strip() for p in line.split("|", 2))
        for i in ids.split():
            path = find(i)
            if path:
                apps.append({"name": name, "hue": HUE.get(hue, hue), "id": i,
                             "icon": entry_icon(path), "path": str(path)})
                break
        else:
            print(f"  [!!] {name}: none of {ids} is installed, skipped", file=sys.stderr)
    return apps


if __name__ == "__main__":
    apps = resolve(sys.argv[1])
    if sys.argv[2] == "json":
        print(json.dumps(apps))
    else:
        print(",".join(f"applications:{a['id']}.desktop" for a in apps))
