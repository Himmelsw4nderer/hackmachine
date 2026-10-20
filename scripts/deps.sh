#!/usr/bin/env bash
# Install the packages Nook uses. Needs sudo. Safe to re-run.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

fam=$(distro_family)
step "installing packages for: $fam"

case "$fam" in
  fedora)
    sudo dnf install -y --skip-unavailable \
      jetbrains-mono-fonts-all fastfetch fzf figlet lolcat toilet cava btop \
      librsvg2-tools curl konsole alacritty kde-cli-tools zsh git \
      zoxide eza bat git-delta fd-find ripgrep
    ;;
  debian)
    sudo apt-get update
    pkgs=(fonts-jetbrains-mono fzf figlet lolcat toilet cava btop librsvg2-bin curl konsole alacritty kde-cli-tools zsh git)
    # fastfetch is in Ubuntu 24.10+ / Debian 13+; older releases need ppa:zhangsongcui3371/fastfetch.
    if apt-cache show fastfetch >/dev/null 2>&1; then pkgs+=(fastfetch)
    else warn "fastfetch not in apt; add ppa:zhangsongcui3371/fastfetch to get it"; fi
    # shell tools: eza and git-delta are only in newer releases, so take what this one has
    for p in zoxide eza bat git-delta fd-find ripgrep; do
      if apt-cache show "$p" >/dev/null 2>&1; then pkgs+=("$p"); else warn "$p is not in apt; skipped"; fi
    done
    sudo apt-get install -y "${pkgs[@]}"
    ;;
  arch)
    sudo pacman -S --needed --noconfirm \
      ttf-jetbrains-mono fastfetch fzf figlet lolcat toilet cava btop librsvg curl konsole alacritty zsh git \
      zoxide eza bat git-delta fd ripgrep
    ;;
  suse)
    sudo zypper install -y jetbrains-mono-fonts fastfetch fzf figlet lolcat toilet cava btop rsvg-convert curl konsole alacritty zsh git \
      zoxide eza bat git-delta fd ripgrep
    ;;
  *)
    warn "unknown distro; install by hand: JetBrains Mono, fastfetch, fzf, figlet, lolcat, cava, btop, rsvg-convert, zoxide, eza, bat, delta, fd, ripgrep"
    ;;
esac

# VT323 pixel font (wallpaper headings) is not packaged anywhere; fetch it from Google Fonts.
fontdir="$XDG_DATA_HOME/fonts/nook"
if ! fc-list | grep -q VT323; then
  mkdir -p "$fontdir"
  if curl -fsSL -o "$fontdir/VT323-Regular.ttf" \
       https://raw.githubusercontent.com/google/fonts/main/ofl/vt323/VT323-Regular.ttf; then
    fc-cache -f "$fontdir" >/dev/null && ok "VT323 installed"
  else
    warn "could not download VT323; wallpaper headings fall back to JetBrains Mono"
  fi
fi
ok "packages done"
