// Hackmachine taskbar: bottom, full width, 44px, not floating, Windows-style order.
// Run through org.kde.PlasmaShell.evaluateScript.
// Replaces every existing panel (apply.sh backs up the old layout first).

panels().forEach(function (p) { p.remove(); });

var panel = new Panel();
panel.screen = 0; // new panels open on the screen under the mouse; 0 is the primary one
panel.location = "bottom";
panel.height = 44;
panel.floating = false;
panel.lengthMode = "fill";
panel.hiding = "none";

// λ hackmachine start button
var kickoff = panel.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("icon", "hackmachine");
kickoff.writeConfig("menuLabel", "hackmachine");
kickoff.writeConfig("favoritesDisplay", 1); // list, not grid
kickoff.writeConfig("applicationsDisplay", 1);
kickoff.writeConfig("compactMode", true);

// pinned apps: terminal, files, browser, settings
var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
  "applications:org.kde.konsole.desktop",
  "applications:org.kde.dolphin.desktop",
  "preferred://browser",
  "applications:systemsettings.desktop"
].join(","));
tasks.writeConfig("indicateAudioStreams", true);
tasks.writeConfig("iconSpacing", 1);

panel.addWidget("org.kde.plasma.panelspacer");

panel.addWidget("org.kde.plasma.systemtray");

var clock = panel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showSeconds", 2);
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "dd.MM.yy");
clock.writeConfig("dateDisplayFormat", 2); // date below time
clock.writeConfig("autoFontAndSize", true); // sized to the panel, in the (monospace) UI font
clock.writeConfig("use24hFormat", 2);

panel.addWidget("org.kde.plasma.showdesktop");
