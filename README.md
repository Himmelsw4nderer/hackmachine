# λ hackmachine — a KDE Plasma 6 rice

A cozy pastel hacker desktop: warm espresso-brown surfaces, cream text, nine pastels (one per
category), JetBrains Mono everywhere, and a Windows-style layout dressed as a terminal.
Built from the *Hackmachine* design system.

One repo, any machine: clone it and run `./install.sh`. Tested on Fedora/Nobara 44 with Plasma 6.6,
Wayland and two monitors (one rotated 90°). The scripts also handle Ubuntu/Kubuntu, Debian, Arch
and openSUSE.

```bash
git clone <this repo> ~/proj/kde-rice && cd ~/proj/kde-rice
./install.sh                  # packages (sudo) + theme
./install.sh --no-deps        # theme only, no sudo
./scripts/uninstall.sh        # back to how things were before the first install
```

Options (passed through to `scripts/apply.sh`): `--no-panel` keeps your panels, `--no-shell` leaves
`~/.bashrc` alone, `--no-shortcuts` skips the key bindings, `--no-icons` keeps your icon theme.

## What you get

| piece | details |
| --- | --- |
| **Colours** | `Hackmachine` Plasma colour scheme, used by the Breeze application style. |
| **Plasma style** | `hackmachine`, generated from the design tokens. Flat cocoa taskbar with a hairline on top. Task buttons: a short faint bar while running, a tile plus a lavender bar when focused, a coral bar when asking for attention. Popups are rounded with a lavender ring. Everything else falls back to Breeze. |
| **Icons** | `Hackmachine`: the BeautyLine line-icon theme (fetched at a pinned commit, GPL-3) repainted so each icon is **one pastel chosen by category**. Media is pink, security coral, time and transfers peach, files butter, dev mint, chat teal, web sky, system lavender and session lilac. App icons are categorised from their `.desktop` Categories, others by name. Underneath it, `Hackmachine-Breeze` repaints Breeze's small symbolic icons (tray, toolbars) the same way. |
| **Fonts** | JetBrains Mono for every UI font, with bold window titles. The Nerd Font build is used if that's the one installed. VT323 is fetched for pixel headings. |
| **Windows** | `Hackmachine` Aurorae decoration (generated SVG). Cocoa title bar with the title on the left and bracketed `[_] [□] [x]` buttons on the right; close turns coral on hover. The active window gets a 1px lavender ring and inactive ones a hairline. Blur is on. |
| **Taskbar** | Bottom of the primary screen, 44px, full width, not floating. Left to right: a `λ hackmachine` launcher, pinned terminal/files/browser/settings, the tray, a two-line clock (seconds, `dd.MM.yy`) and show-desktop. |
| **Wallpaper** | Rendered **per screen at its real size**, so rotated or portrait monitors get a stacked layout. It has a dot grid, a faint ASCII skull, a **key cheat-sheet**, a `whoami` card and the rainbow `HACKMACHINE` banner. The lock screen gets it too. |
| **Hack menu** | `Meta+Space` opens a borderless, centred fzf launcher. It shows a rainbow figlet banner, all apps, and lock, log out, reboot and shutdown. |
| **Terminal** | Konsole profile `Hackmachine`: pastel 16-colour palette, 92% opacity with blur, a `λ ~/path >` prompt and fastfetch with the candy logo. The prompt only applies inside this profile. |
| **Extras** | Themes for btop and cava (rainbow bars). |

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
scripts/icons.py        repaints an icon theme, one pastel per icon by category
scripts/themegen.py     generates the Plasma style and the Aurorae decoration
config/shortcuts.conf   key bindings + cheat-sheet rows
bin/hm-menu, hm-keys    the launcher and the cheat-sheet viewer (installed to ~/.local/bin)
theme/                  colour schemes, Konsole, fastfetch, btop, cava, icon, shell, KWin script
```

## Palette

```
bg-000 #1a1614  bg-100 #221d1a  bg-200 #2a2420  bg-300 #372f2a  line #4a3f38
ink    #f6ece4  muted  #bfae9f  faint  #7d6d62
pink   #f5a8c9  coral  #f7a59a  peach  #f9c49a  butter #f2e29b  mint #a6e6bf
teal   #94dcd6  sky    #a3cdf5  lavender #c4b2f5  lilac #e2b5f0
```
