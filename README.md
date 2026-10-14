# λ hackmachine — a KDE Plasma 6 rice

A cozy pastel hacker desktop: warm espresso-brown surfaces, cream text, nine pastels (one per
category), JetBrains Mono everywhere, and a Windows-style layout dressed as a terminal.
Built from the *Hackmachine* design system.

One repo, any machine: clone it and run `./install.sh`. Tested on Fedora/Nobara 44 with Plasma 6.6,
Wayland and two monitors (one rotated 90°). The scripts also handle Ubuntu/Kubuntu, Debian, Arch
and openSUSE.

```bash
git clone https://github.com/Himmelsw4nderer/hackmachine.git && cd hackmachine
./install.sh                  # packages (sudo) + theme
./install.sh --no-deps        # theme only, no sudo
./scripts/uninstall.sh        # back to how things were before the first install
```

Options (passed through to `scripts/apply.sh`): `--no-panel` keeps your panels, `--no-widgets` skips the desktop widgets, `--no-shell` leaves
`~/.bashrc` alone, `--no-shortcuts` skips the key bindings, `--no-icons` keeps your icon theme.

## What you get

| piece | details |
| --- | --- |
| **Colours** | `Hackmachine` Plasma colour scheme, used by the Breeze application style. |
| **Plasma style** | `hackmachine`, generated from the design tokens. Flat cocoa taskbar with a hairline on top. Task buttons: a short faint bar while running, a tile plus a lavender bar when focused, a coral bar when asking for attention. Popups are rounded with a lavender ring. Everything else falls back to Breeze. |
| **Icons** | `Hackmachine`: the BeautyLine line-icon theme (fetched at a pinned commit, GPL-3) repainted so each icon is **one pastel chosen by category**. Media is pink, security coral, time and transfers peach, files butter, dev mint, chat teal, web sky, system lavender and session lilac. App icons are categorised from their `.desktop` Categories, others by name. The arrows (the tray's `^` too) are thin line chevrons instead of BeautyLine's filled ones. Underneath it, `Hackmachine-Breeze` repaints Breeze's small symbolic icons (tray, toolbars) the same way. |
| **Fonts** | JetBrains Mono for every UI font, with bold window titles. The Nerd Font build is used if that's the one installed. VT323 is fetched for pixel headings. |
| **Windows** | `Hackmachine` Aurorae decoration (generated SVG). Cocoa title bar with the title on the left and bracketed `[_] [□] [x]` buttons on the right; close turns coral on hover. Square corners; the active window gets a 1px lavender ring and inactive ones a hairline. Blur is on. |
| **Tiling** | **Krohnkite** (MIT, a dynamic tiling KWin script, fetched at a pinned release and checksum-verified): every new window is tiled automatically, master on the left and the stack on the right, with 8px gaps. Each screen and virtual desktop keeps its own layout. Dialogs, plasmashell and the hack menu float. `Meta+F` floats or tiles a single window, and dragging a tile onto another swaps them. Keys below; Krohnkite's own defaults that clash with Plasma's (`Meta+L`, `Meta+I`, `Meta+D`, `Meta+.`) are cleared, and KWin's quick-tile keys go to Krohnkite. The arrow keys cross screens: at the edge of a screen, focus jumps to the next screen and a moved window is sent there (`theme/kwin/hackmachine-tiling`). On the portrait screen, `Meta+Ctrl+Space` turns the split into top/bottom. Settings: System Settings → Window Management → KWin Scripts → Krohnkite. |
| **Taskbar** | One floating bar along the bottom of the primary screen that **auto-hides**: push the mouse against the bottom edge anywhere to bring it back. Left: the filled rainbow hexagon-λ start button (set apart from the single-pastel line icons of the apps) and pinned apps. Centre: a colourful clock (a big rainbow `16:34` as tall as the app icons, with `fri 09.10` over `wk41 :47` beside it; click for a calendar). Right: the tray, its icons scaled to the same size as the apps. It's one bar rather than separate islands because Plasma only reveals an auto-hidden panel from the stretch of screen edge right under it. |
| **Desktop widgets** | Three custom Plasma widgets are placed on **every connected screen**, in the space the wallpaper leaves free. Everything sits on Plasma's 16px widget grid, and the wallpaper's cards are snapped to the same grid, so the widget frames line up exactly with the cheat-sheet and whoami cards, with the same 32px gaps. On landscape screens: clock and apps level with the cheat-sheet, the system card below them from the whoami card's top to above the banner. On portrait screens: stacked between the cards and the banner, as wide as the cards. `TIME // LOCAL` is a big clock drawn with `#` in monospace, one pastel per digit, with date, ISO week and day of month. `SYS // LIVE` shows CPU/GPU/RAM/disk as `[████░░]` bars with temperatures, network up/down as sparklines, and uptime. `APPS // PINNED` has numbered app tiles that scale with the card; its footer opens the hack menu. |
| **Tray** | Only network, sound, microphone and battery stay visible. Everything else, Plasma's own entries and app icons alike, goes into the `^` popup. `hm-tray` runs at login and hides tray icons from apps that start later. Each entry is hidden only the first time it appears, so anything you set to "Always shown" stays. Edit `SHOW` in `bin/hm-tray` to change the list. |
| **Wallpaper** | Rendered **per screen at its real size**, so rotated or portrait monitors get a stacked layout. It has a dot grid, a faint ASCII skull (only without the desktop widgets), a **key cheat-sheet**, a `whoami` card and the rainbow `HACKMACHINE` banner. The lock screen gets it too. |
| **Hack menu** | `Meta+Space` opens a borderless, centred fzf launcher. It shows a rainbow figlet banner, all apps, and lock, log out, reboot and shutdown. |
| **Terminal** | Konsole profile `Hackmachine` runs **zsh with oh-my-zsh** and the `hackmachine` theme: a two-line prompt (`╭─λ user@host ─ ~/path ─  branch ✓` / `╰─❯`). The right side shows the conda/venv env, how long the last command took, a failed command's exit code, and the time. Autosuggestions and syntax highlighting are in the pastels. Your own `~/.zshrc` is kept; one line is added at its top. Pastel 16-colour palette, 92% opacity with blur, fastfetch with the candy logo. **No toolbars**: only the window decoration and the terminal (Konsole's own layout files with the toolbars stripped; menus via Ctrl+Shift+M or right-click). |
| **Brave** | `theme/brave/hackmachine`: a browser theme in the same cocoa and lavender palette. Chromium only installs local themes through its own UI, so run `hm-brave` once: it opens the extensions page, copies the theme's path to the clipboard and tells you the two clicks (Developer mode → Load unpacked). |
| **Zed** | `theme/zed/hackmachine.json`: a Zed theme in the same cocoa and pastel palette (lavender keywords and focus, mint strings, sky functions, butter types). It goes into the native (`~/.config/zed`) and the Flatpak (`~/.var/app/dev.zed.Zed/config/zed`) config, whichever is there. `settings.json` gets `theme` and JetBrains Mono as buffer and UI font; the file's other settings and comments stay as they are. Zed picks it up live. |
| **Extras** | Themes for btop and cava (rainbow bars). |

## Pinned apps

`config/apps.conf` lists the pinned apps, used by both the taskbar and the desktop card. Each line
has a label, a category colour and the `.desktop` ids to try, so one line covers the native,
Flatpak and Snap builds of an app. If a pinned app isn't installed, its slot goes to the first
installed app from the `[fill]` list below it (Zed, VS Code, Firefox, Zen, Spotify, Signal,
Obsidian, Kate, System Monitor), so the card is always full. Edit it and run `./install.sh --no-deps`.

## Shortcuts

`config/shortcuts.conf` is the **single source** for the key bindings *and* the wallpaper
cheat-sheet. A row with a command gets bound as a global shortcut, live over D-Bus, with no
logout needed. A row without one is a Plasma default and only shows on the wallpaper. Edit it,
then re-run `./install.sh --no-deps`.

| keys | does |
| --- | --- |
| `Meta+Return` | terminal (Hackmachine profile) |
| `Meta+Space` | hack menu |
| `Meta+/` | show every shortcut in a terminal (`hm-keys`) |
| `Meta+B` | browser |
| `Meta+Shift+Return` | btop |
| `Meta+Alt+V` | cava |
| `Meta+←↑→↓` | focus the tile in that direction, or the next screen at the edge |
| `Meta+Alt+←↑→↓` | swap with the tile on that side, or send the window to the next screen |
| `Meta+Ctrl+Return` | make the window the master |
| `Meta+T` / `Meta+M` | tile / monocle layout (`Meta+Shift+Space` cycles all layouts, `Meta+Ctrl+Space` rotates) |

## Multi-monitor and rotation

Screen sizes come from plasmashell's own `screenGeometry()`. Rotation is already applied there,
so a 90° monitor reports e.g. 1440×2560 and gets a portrait wallpaper. The taskbar goes on the
primary screen. The hack menu opens centred on whichever screen is active, through a tiny KWin
script (`theme/kwin/hackmachine-menu`). Plug in or rotate a monitor? Run `./install.sh --no-deps`
again.

## Layout

```
install.sh              entry point: deps.sh, then apply.sh
scripts/deps.sh         packages per distro (dnf / apt / pacman / zypper) + VT323
scripts/apply.sh        everything per-user; backs up first to ~/.local/state/hackmachine/
scripts/uninstall.sh    restores the oldest backup, removes our files
scripts/wallpaper.py    SVG wallpaper generator (stdlib only), rendered with rsvg-convert/inkscape/magick
scripts/shortcuts.py    binds/unbinds global shortcuts, prints the cheat-sheet
scripts/panel.js        Plasma scripting for the taskbar
scripts/apps.py         resolves config/apps.conf to installed .desktop files
scripts/layout.py       places the desktop widgets on each screen around the wallpaper
scripts/icons.py        repaints an icon theme, one pastel per icon by category
scripts/themegen.py     generates the Plasma style and the Aurorae decoration
scripts/zed.py          sets the theme and font in Zed's settings.json (JSONC, edited in place)
config/shortcuts.conf   key bindings + cheat-sheet rows
config/apps.conf        pinned apps (taskbar + desktop card)
bin/hm-menu, hm-keys    the launcher and the cheat-sheet viewer (installed to ~/.local/bin)
bin/hm-tray             keeps the tray minimal (autostarted)
bin/hm-brave            loads the Brave theme
theme/                  colour schemes, Konsole, fastfetch, btop, cava, Zed, icon, shell, KWin script
```

## Palette

```
bg-000 #1a1614  bg-100 #221d1a  bg-200 #2a2420  bg-300 #372f2a  line #4a3f38
ink    #f6ece4  muted  #bfae9f  faint  #7d6d62
pink   #f5a8c9  coral  #f7a59a  peach  #f9c49a  butter #f2e29b  mint #a6e6bf
teal   #94dcd6  sky    #a3cdf5  lavender #c4b2f5  lilac #e2b5f0
```
