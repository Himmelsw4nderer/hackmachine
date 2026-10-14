#!/usr/bin/env python3
"""Patch the installed Krohnkite script.js for the rice (it is pinned, so the anchors are stable).

- Tile layout follows the screen: side by side on landscape, master on top on portrait, so
  Meta+Alt+↑↓ moves a window between the halves there. Meta+R still rotates by hand.
- Meta+Alt+←→ past the last tile (or a floating window at the screen edge) sends the window
  to the next screen in that direction.
- Meta+←→ past the last tile focuses the nearest window on the next screen.

Usage: krohnkite_patch.py path/to/contents/code/script.js   (idempotent)
"""
import sys

MARK = "// hackmachine-patched\n"

PATCHES = [
    # The workspace, reachable from the engine.
    ("var KWIN;\n",
     "var KWIN;\nvar HMWS;\n"),
    ("        KWIN = api.kwin;\n        this.workspace = api.workspace;\n",
     "        KWIN = api.kwin;\n        HMWS = api.workspace;\n        this.workspace = api.workspace;\n"),
    # Focus: no neighbour left/right → nearest window on the next screen.
    ("        const neighbor = this.getNeighborByDirection(ctx, window, dir);\n"
     "        if (neighbor)\n            ctx.currentWindow = neighbor;\n    }\n",
     "        const neighbor = this.getNeighborByDirection(ctx, window, dir);\n"
     "        if (neighbor)\n            ctx.currentWindow = neighbor;\n"
     "        else\n            hmFocusScreen(window, dir);\n    }\n"),
    # Tiled: no neighbour left/right → next screen.
    ("        const neighbor = this.getNeighborByDirection(ctx, window, dir);\n"
     "        if (neighbor)\n            this.windows.swap(window, neighbor);\n    }\n    moveFloat(",
     "        const neighbor = this.getNeighborByDirection(ctx, window, dir);\n"
     "        if (neighbor)\n            this.windows.swap(window, neighbor);\n"
     "        else\n            hmSendToScreen(window, dir);\n    }\n    moveFloat("),
    # Floating: already at the edge → next screen.
    ("        if (WindowClass.isFloatingState(state))\n            this.moveFloat(window, dir);\n",
     "        if (WindowClass.isFloatingState(state)) {\n"
     "            if (!hmAtEdge(window, dir) || !hmSendToScreen(window, dir))\n"
     "                this.moveFloat(window, dir);\n        }\n"),
    # Tile layout orientation follows the screen until rotated by hand.
    ("    apply(ctx, tileables, area, gap) {\n"
     "        tileables.forEach((tileable) => (tileable.state = WindowState.Tiled));\n"
     "        this.parts.apply(area, tileables, gap)",
     "    apply(ctx, tileables, area, gap) {\n"
     "        if (!this.hmRotated)\n            this.parts.angle = area.height > area.width ? 90 : 0;\n"
     "        tileables.forEach((tileable) => (tileable.state = WindowState.Tiled));\n"
     "        this.parts.apply(area, tileables, gap)"),
    ("            case Shortcut.Rotate:\n                this.parts.rotate(90);\n                break;\n"
     "            case Shortcut.RotatePart:\n                this.parts.inner.primary.rotate(90);\n",
     "            case Shortcut.Rotate:\n                this.hmRotated = true;\n                this.parts.rotate(90);\n                break;\n"
     "            case Shortcut.RotatePart:\n                this.parts.inner.primary.rotate(90);\n"),
]

HELPERS = """
function hmScreenTowards(client, dir) {
    if (!HMWS || (dir !== "left" && dir !== "right"))
        return null;
    const cur = client.output.geometry;
    let best = null, bestDist = Infinity;
    HMWS.screens.forEach((s) => {
        const g = s.geometry;
        if (s === client.output || !overlap(cur.y, cur.y + cur.height, g.y, g.y + g.height))
            return;
        const dist = dir === "right" ? g.x - (cur.x + cur.width) : cur.x - (g.x + g.width);
        if (dist >= 0 && dist < bestDist)
            (best = s), (bestDist = dist);
    });
    return best;
}
function hmSendToScreen(window, dir) {
    const client = window.window.window;
    const target = hmScreenTowards(client, dir);
    if (!target)
        return false;
    HMWS.sendClientToScreen(client, target);
    HMWS.activeWindow = client;
    return true;
}
function hmFocusScreen(window, dir) {
    const client = window.window.window;
    const target = hmScreenTowards(client, dir);
    if (!target)
        return false;
    const shown = HMWS.stackingOrder.filter((c) => c.output === target && c.normalWindow &&
        !c.minimized && !c.skipTaskbar &&
        (c.onAllDesktops || c.desktops.indexOf(HMWS.currentDesktop) >= 0));
    if (shown.length === 0)
        return false;
    // Closest to the shared edge, then level with the current window, then topmost.
    const edge = (c) => dir === "right" ? c.frameGeometry.x : -(c.frameGeometry.x + c.frameGeometry.width);
    const nearest = Math.min(...shown.map(edge));
    const near = shown.filter((c) => edge(c) - nearest < 32);
    const cy = client.frameGeometry.y + client.frameGeometry.height / 2;
    const level = near.filter((c) => c.frameGeometry.y <= cy && cy < c.frameGeometry.y + c.frameGeometry.height);
    const pick = level.length > 0 ? level : near;
    HMWS.activeWindow = pick[pick.length - 1];
    return true;
}
function hmAtEdge(window, dir) {
    const client = window.window.window;
    const o = client.output.geometry, g = client.frameGeometry;
    return dir === "left" ? g.x <= o.x + 1 : dir === "right" ? g.x + g.width >= o.x + o.width - 1 : false;
}
"""


def main(path):
    src = open(path, encoding="utf-8").read()
    if src.startswith(MARK):
        return
    for old, new in PATCHES:
        if src.count(old) != 1:
            sys.exit(f"krohnkite_patch: anchor not found once in {path}:\n{old}")
        src = src.replace(old, new)
    open(path, "w", encoding="utf-8").write(MARK + src + HELPERS)


if __name__ == "__main__":
    main(sys.argv[1])
