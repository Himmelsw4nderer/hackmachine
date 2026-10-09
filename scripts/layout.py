#!/usr/bin/env python3
"""Lay out the Hackmachine desktop widgets on every screen, around what the wallpaper draws.

Reads one line per screen on stdin:  <containment id> <screen> <width> <height> <wallpaper.json>
and prints a Plasma script that (re)places the clock, system and apps cards on each desktop.

Landscape: the wallpaper owns the right-hand column (cheat-sheet) and the banner bottom-right,
           so the widgets fill the left: clock top-left, apps + system side by side at the bottom.
Portrait:  the wallpaper owns the top (cheat-sheet) and the bottom (banner), so the widgets
           stack in the band between them: clock, apps, system.

usage: layout.py APPS_JSON MENU_COMMAND PANEL_RESERVE remove|add < screens

Run "remove" first and "add" a moment later: widgets removed in the same script still hold their
spot while they fade out, and Plasma would shove the new ones aside.
"""
import json
import sys

WIDGETS = ("org.hackmachine.clock", "org.hackmachine.sys", "org.hackmachine.apps")


def landscape(w, h, box, s, bottom_reserve):
    m, gap = 48 * s, 24 * s
    cards_x = box["cards"][0]
    banner_x, banner_y = box["banner"][0], box["banner"][1]
    left, right = m, cards_x - m
    bottom = h - bottom_reserve - m
    # the bottom row must stay left of the banner (or end above it)
    row_right = min(right, banner_x - m) if bottom > banner_y - m else right
    row_h = min(520 * s, (bottom - m) * 0.45)
    row_w = row_right - left
    apps_w = min(560 * s, row_w * 0.44)
    clock_w = min(760 * s, right - left)
    return [
        ("org.hackmachine.clock", left, m, clock_w, 300 * s),
        ("org.hackmachine.apps", left, bottom - row_h, apps_w, row_h),
        ("org.hackmachine.sys", left + apps_w + gap, bottom - row_h, row_w - apps_w - gap, row_h),
    ]


def portrait(w, h, box, s, bottom_reserve):
    m, gap = 48 * s, 24 * s
    cx, cy, cw, ch = box["cards"]
    top = cy + ch + m
    bottom = min(box["banner"][1], h - bottom_reserve) - m
    avail = bottom - top - 2 * gap
    parts = {"clock": 0.25, "apps": 0.43, "sys": 0.32}
    y, out = top, []
    for name in ("clock", "apps", "sys"):
        hh = avail * parts[name]
        out.append((f"org.hackmachine.{name}", cx, y, cw, hh))
        y += hh + gap
    return out


def main():
    apps_json, menu_cmd, reserve, mode = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4]
    js = ["var d, w;"]
    for line in sys.stdin:
        if not line.strip():
            continue
        cid, screen, w, h, box_file = line.split(maxsplit=4)
        w, h = int(w), int(h)
        box = json.load(open(box_file.strip()))
        s = box["scale"]
        res = reserve * s if screen == "0" else 0
        place = portrait(w, h, box, s, res) if box["portrait"] else landscape(w, h, box, s, res)
        js.append(f"d = desktopById({cid});")
        if mode == "remove":
            js.append("d.widgets().forEach(function (x) { if (%s.indexOf(x.type) >= 0) x.remove(); });"
                      % json.dumps(list(WIDGETS)))
            continue
        for plugin, x, y, ww, hh in place:
            js.append(f"w = d.addWidget('{plugin}', {round(x)}, {round(y)}, {round(ww)}, {round(hh)});")
            if plugin.endswith(".apps"):
                js.append("w.currentConfigGroup = ['General'];")
                js.append(f"w.writeConfig('apps', {json.dumps(apps_json)});")
                js.append(f"w.writeConfig('menuCommand', {json.dumps(menu_cmd)});")
    print("\n".join(js))


if __name__ == "__main__":
    main()
