// Hackmachine taskbar: three floating islands along the bottom of the primary screen.
//   left   λ launcher + pinned/running apps
//   centre clock
//   right  tray + show desktop
// Run through org.kde.PlasmaShell.evaluateScript; apply.sh fills in __LAUNCHERS__.
// Replaces every existing panel (apply.sh backs up the old layout first).

panels().forEach(function (p) { p.remove(); });

function island(alignment) {
    var p = new Panel();
    p.screen = 0;          // new panels open on the screen under the mouse; 0 is the primary one
    p.location = "bottom";
    p.height = 44;
    p.floating = true;
    p.lengthMode = "fit";  // only as wide as its content, so the islands sit apart
    p.alignment = alignment;
    p.hiding = "none";
    return p;
}

// ── left: start + apps ──
var left = island("left");
var kickoff = left.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("icon", "hackmachine");
kickoff.writeConfig("menuLabel", "");
kickoff.writeConfig("favoritesDisplay", 1); // list, not grid
kickoff.writeConfig("applicationsDisplay", 1);
kickoff.writeConfig("compactMode", true);

var tasks = left.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", "__LAUNCHERS__");
tasks.writeConfig("indicateAudioStreams", true);
tasks.writeConfig("iconSpacing", 1);
tasks.writeConfig("fill", false);

// ── centre: clock (the Hackmachine clock in its compact, colourful panel form) ──
var centre = island("center");
centre.addWidget("org.hackmachine.clock");

// ── right: tray ──
var right = island("right");
right.addWidget("org.kde.plasma.systemtray");
right.addWidget("org.kde.plasma.showdesktop");
