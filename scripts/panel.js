// Hackmachine taskbar: bottom, full width, 44px, not floating, Windows-style order.
// Run through org.kde.PlasmaShell.evaluateScript; apply.sh fills in __FONT__.
// Replaces every existing panel (apply.sh backs up the old layout first).

panels().forEach(function (p) { p.remove(); });

var panel = new Panel();
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

var sysmon = panel.addWidget("org.kde.plasma.systemmonitor.cpu");
sysmon.currentConfigGroup = ["Appearance"];
sysmon.writeConfig("chartFace", "org.kde.ksysguard.linechart");
sysmon.currentConfigGroup = ["SensorColors"];
sysmon.writeConfig("cpu/all/usage", "166,230,191");

panel.addWidget("org.kde.plasma.systemtray");

var clock = panel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showSeconds", 2);
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "dd.MM.yy");
clock.writeConfig("dateDisplayFormat", 2); // date below time
clock.writeConfig("autoFontAndSize", false);
clock.writeConfig("fontFamily", "__FONT__");
clock.writeConfig("boldText", true);
clock.writeConfig("fontSize", 10);
clock.writeConfig("use24hFormat", 2);

panel.addWidget("org.kde.plasma.showdesktop");
