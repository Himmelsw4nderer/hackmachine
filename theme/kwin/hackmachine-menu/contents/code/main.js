// Konsole sets the "hm-menu" title only after its window is mapped, too late for a KWin
// placement rule, so centre it here once the title shows up (on whatever screen is active,
// rotated or not).
const W = 780, H = 560;

function place(win) {
    if (win.hmPlaced || !win.caption || win.caption.indexOf("hm-menu") === -1) return;
    win.hmPlaced = true;
    const a = workspace.clientArea(KWin.PlacementArea, workspace.activeScreen, workspace.currentDesktop);
    win.frameGeometry = {
        x: Math.round(a.x + (a.width - W) / 2),
        y: Math.round(a.y + (a.height - H) / 2),
        width: W, height: H
    };
    workspace.activeWindow = win;
}

workspace.windowAdded.connect(function (win) {
    place(win);
    win.captionChanged.connect(function () { place(win); });
});
