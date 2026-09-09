#!/usr/bin/env bash
# ----------------------------------------------------------------------------
# install.sh — Kolhapur Theme: Marathi Waybar setup
#
# Usage (after cloning the repo):
#   cd kolhapur-theme2
#   chmod +x install.sh
#   ./install.sh
#
# What this does, in order:
#   1. Installs a Devanagari-capable font (needed to render Marathi text)
#   2. Copies scripts/marathi-date.sh into ~/.config/waybar/scripts/
#   3. Patches ~/.config/waybar/config.jsonc to:
#        - add a "custom/marathi-date" module
#        - update the "network" module's wifi/ethernet/disconnected labels
#          to Marathi
#        - swap "clock" for "custom/marathi-date" in your modules arrays
#        - make sure "network" is present in those arrays
#      (a timestamped backup of config.jsonc is always made first)
#   4. Installs this theme's waybar.css as your Waybar stylesheet
#      (symlink-aware — won't break an existing Omarchy theme symlink)
#   5. Restarts Waybar
#
# Safe to re-run — it detects work that's already done and skips it.
# ----------------------------------------------------------------------------

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAYBAR_DIR="$HOME/.config/waybar"
CONFIG_FILE="$WAYBAR_DIR/config.jsonc"
STYLE_FILE="$WAYBAR_DIR/style.css"
SCRIPTS_DIR="$WAYBAR_DIR/scripts"

log()  { echo -e "\033[1;33m[kolhapur-theme]\033[0m $1"; }
ok()   { echo -e "\033[1;32m[ok]\033[0m $1"; }
warn() { echo -e "\033[1;31m[warn]\033[0m $1"; }

# ---------------------------------------------------------------------------
# 1. Devanagari font
# ---------------------------------------------------------------------------
log "Checking for a Devanagari-capable font..."
if fc-list | grep -qi "Noto Sans Devanagari"; then
    ok "Noto Sans Devanagari already installed."
else
    if command -v pacman >/dev/null 2>&1; then
        log "Installing noto-fonts-extra via pacman (needs sudo)..."
        sudo pacman -S --needed --noconfirm noto-fonts-extra || \
            warn "pacman install failed — install a Devanagari font manually (e.g. noto-fonts-extra)."
    elif command -v apt >/dev/null 2>&1; then
        log "Installing fonts-noto-devanagari via apt (needs sudo)..."
        sudo apt install -y fonts-noto-devanagari || \
            warn "apt install failed — install a Devanagari font manually."
    else
        warn "Unknown package manager. Please install a Devanagari font (e.g. Noto Sans Devanagari) manually."
    fi
    fc-cache -f >/dev/null 2>&1
fi

# ---------------------------------------------------------------------------
# 2. Copy the Marathi date script
# ---------------------------------------------------------------------------
log "Installing marathi-date.sh..."
mkdir -p "$SCRIPTS_DIR"
if [ -f "$SCRIPT_DIR/scripts/marathi-date.sh" ]; then
    cp "$SCRIPT_DIR/scripts/marathi-date.sh" "$SCRIPTS_DIR/marathi-date.sh"
elif [ -f "$SCRIPT_DIR/marathi-date.sh" ]; then
    cp "$SCRIPT_DIR/marathi-date.sh" "$SCRIPTS_DIR/marathi-date.sh"
else
    warn "marathi-date.sh not found next to install.sh — skipping this step."
fi
chmod +x "$SCRIPTS_DIR/marathi-date.sh" 2>/dev/null
ok "Script placed at $SCRIPTS_DIR/marathi-date.sh"

# ---------------------------------------------------------------------------
# 3. Patch config.jsonc
# ---------------------------------------------------------------------------
if [ ! -f "$CONFIG_FILE" ]; then
    warn "$CONFIG_FILE not found — skipping config patch. Set up Waybar first, then re-run this script."
else
    BACKUP="$CONFIG_FILE.bak.$(date +%Y%m%d%H%M%S)"
    cp "$CONFIG_FILE" "$BACKUP"
    log "Backed up existing config to $BACKUP"

    python3 - "$CONFIG_FILE" <<'PYEOF'
import re, sys, pathlib

path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
original = text

def upsert_block(text, key, body):
    """Replace the object value of `key` if it exists (brace-matched),
    otherwise insert a new top-level `key: body` right after the file's
    opening brace."""
    m = re.search(r'"' + re.escape(key) + r'"\s*:\s*\{', text)
    if m:
        start = m.end() - 1  # index of the opening '{'
        depth = 0
        i = start
        while i < len(text):
            if text[i] == '{':
                depth += 1
            elif text[i] == '}':
                depth -= 1
                if depth == 0:
                    end = i
                    break
            i += 1
        else:
            return text  # unbalanced braces, bail out safely
        return text[:m.start()] + f'"{key}": {body}' + text[end + 1:]
    else:
        idx = text.find('{')
        if idx == -1:
            return text
        insertion = f'\n  "{key}": {body},\n'
        return text[:idx + 1] + insertion + text[idx + 1:]

network_body = '''{
    "format-wifi": "  जोडलेले ({signalStrength}%)",
    "format-ethernet": "  तारेने जोडलेले",
    "format-disconnected": "  जोडलेले नाही",
    "tooltip-format": "{ifname}: {ipaddr}",
    "on-click": "nm-connection-editor"
  }'''

marathi_date_body = '''{
    "exec": "~/.config/waybar/scripts/marathi-date.sh",
    "interval": 30,
    "tooltip": false
  }'''

text = upsert_block(text, "network", network_body)
text = upsert_block(text, "custom/marathi-date", marathi_date_body)

# Swap "clock" for "custom/marathi-date" wherever it appears as an array
# item (i.e. not immediately followed by a colon, which would mean it's
# an object key definition like "clock": {...}).
text = re.sub(r'"clock"(?!\s*:)', '"custom/marathi-date"', text)

# Make sure "network" appears somewhere in a modules array. If it's
# missing entirely as an array item, add it right before our new
# custom/marathi-date entry in modules-right (falling back to
# modules-left) so it actually gets displayed.
if not re.search(r'"network"(?!\s*:)', text):
    for arr_key in ("modules-right", "modules-left"):
        pattern = re.compile(r'("' + arr_key + r'"\s*:\s*\[)')
        if pattern.search(text):
            text = pattern.sub(r'\1\n    "network",', text, count=1)
            break

if text != original:
    path.write_text(text, encoding="utf-8")
    print("PATCHED")
else:
    print("NOCHANGE")
PYEOF

    ok "config.jsonc patched (diff against backup with: diff $BACKUP $CONFIG_FILE)"
fi

# ---------------------------------------------------------------------------
# 4. Install waybar.css (symlink-aware)
# ---------------------------------------------------------------------------
if [ -f "$SCRIPT_DIR/waybar.css" ]; then
    log "Installing waybar.css..."
    mkdir -p "$WAYBAR_DIR"
    if [ -L "$STYLE_FILE" ]; then
        TARGET="$(readlink -f "$STYLE_FILE")"
        log "style.css is a symlink (likely managed by Omarchy's theme system)."
        log "Writing into the linked file instead of breaking the symlink: $TARGET"
        cp "$SCRIPT_DIR/waybar.css" "$TARGET"
    else
        [ -f "$STYLE_FILE" ] && cp "$STYLE_FILE" "$STYLE_FILE.bak.$(date +%Y%m%d%H%M%S)"
        cp "$SCRIPT_DIR/waybar.css" "$STYLE_FILE"
    fi
    ok "waybar.css installed."
else
    warn "waybar.css not found next to install.sh — skipping."
fi

# ---------------------------------------------------------------------------
# 5. Restart Waybar
# ---------------------------------------------------------------------------
log "Restarting Waybar..."
if command -v omarchy-restart-waybar >/dev/null 2>&1; then
    omarchy-restart-waybar
else
    pkill waybar 2>/dev/null
    sleep 0.5
    (setsid waybar >/dev/null 2>&1 &) 2>/dev/null || (waybar >/dev/null 2>&1 & disown)
fi

ok "Done! Check your bar — wifi and date should now be in Marathi."
echo
echo "If something looks wrong, your original config is safe at:"
echo "  $CONFIG_FILE.bak.* (in $WAYBAR_DIR)"
