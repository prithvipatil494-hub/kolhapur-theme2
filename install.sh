#!/usr/bin/env bash
# ----------------------------------------------------------------------------
# install.sh — Konkan Coast Waybar package
#
# Usage:
#   cd <this-folder>
#   chmod +x install.sh
#   ./install.sh
#
# What this does:
#   1. Checks that waybar is actually installed (installs it via pacman if
#      it's missing and pacman is available).
#   2. Creates ~/.config/waybar/ if it doesn't exist.
#   3. Backs up any existing config.jsonc / style.css (timestamped).
#   4. Installs this package's config.jsonc and style.css as a full,
#      self-contained config (not a patch) — workspaces, clock/date,
#      wifi/network, volume, battery, tray.
#   5. Restarts waybar.
#
# Safe to re-run.
# ----------------------------------------------------------------------------

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAYBAR_DIR="$HOME/.config/waybar"
CONFIG_FILE="$WAYBAR_DIR/config.jsonc"
STYLE_FILE="$WAYBAR_DIR/style.css"
STAMP="$(date +%Y%m%d%H%M%S)"

log()  { echo -e "\033[1;36m[konkan-waybar]\033[0m $1"; }
ok()   { echo -e "\033[1;32m[ok]\033[0m $1"; }
warn() { echo -e "\033[1;31m[warn]\033[0m $1"; }

# ---------------------------------------------------------------------------
# 1. Make sure waybar is actually installed
# ---------------------------------------------------------------------------
log "Checking for waybar..."
if command -v waybar >/dev/null 2>&1; then
    ok "waybar is installed."
else
    warn "waybar not found on this system."
    if command -v pacman >/dev/null 2>&1; then
        log "Attempting to install waybar via pacman (needs sudo)..."
        sudo pacman -S --needed --noconfirm waybar || {
            warn "pacman install failed. Install waybar manually, then re-run this script."
            exit 1
        }
    elif command -v apt >/dev/null 2>&1; then
        log "Attempting to install waybar via apt (needs sudo)..."
        sudo apt install -y waybar || {
            warn "apt install failed. Install waybar manually, then re-run this script."
            exit 1
        }
    else
        warn "Unknown package manager — install waybar manually, then re-run this script."
        exit 1
    fi
fi

# ---------------------------------------------------------------------------
# 2. Ensure config directory exists
# ---------------------------------------------------------------------------
mkdir -p "$WAYBAR_DIR"

# ---------------------------------------------------------------------------
# 3. Back up anything already there
# ---------------------------------------------------------------------------
if [ -e "$CONFIG_FILE" ] && [ ! -L "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak.$STAMP"
    log "Backed up existing config.jsonc to config.jsonc.bak.$STAMP"
elif [ -L "$CONFIG_FILE" ]; then
    warn "config.jsonc is a symlink — leaving it alone and writing into its target."
fi

if [ -e "$STYLE_FILE" ] && [ ! -L "$STYLE_FILE" ]; then
    cp "$STYLE_FILE" "$STYLE_FILE.bak.$STAMP"
    log "Backed up existing style.css to style.css.bak.$STAMP"
elif [ -L "$STYLE_FILE" ]; then
    warn "style.css is a symlink — leaving it alone and writing into its target."
fi

# ---------------------------------------------------------------------------
# 4. Install the new config + style (writing into symlink targets if present)
# ---------------------------------------------------------------------------
log "Installing config.jsonc..."
if [ -L "$CONFIG_FILE" ]; then
    cp "$SCRIPT_DIR/config.jsonc" "$(readlink -f "$CONFIG_FILE")"
else
    cp "$SCRIPT_DIR/config.jsonc" "$CONFIG_FILE"
fi
ok "config.jsonc installed."

log "Installing style.css..."
if [ -L "$STYLE_FILE" ]; then
    cp "$SCRIPT_DIR/style.css" "$(readlink -f "$STYLE_FILE")"
else
    cp "$SCRIPT_DIR/style.css" "$STYLE_FILE"
fi
ok "style.css installed."

# ---------------------------------------------------------------------------
# 5. Restart waybar
# ---------------------------------------------------------------------------
log "Restarting waybar..."
if command -v omarchy-restart-waybar >/dev/null 2>&1; then
    omarchy-restart-waybar
else
    pkill waybar 2>/dev/null
    sleep 0.5
    (setsid waybar >/dev/null 2>&1 &) 2>/dev/null || (waybar >/dev/null 2>&1 & disown)
fi

ok "Done! You should now see workspaces, clock/date, wifi, volume, battery and tray in the new colors."
echo
echo "If anything looks wrong, your old files are saved as:"
echo "  $CONFIG_FILE.bak.$STAMP"
echo "  $STYLE_FILE.bak.$STAMP"
