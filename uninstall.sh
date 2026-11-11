#!/usr/bin/env bash
# ==============================================================================
# CasterManager - Automated Uninstallation Script
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UDEV_RULE_DST="/etc/udev/rules.d/99-castermanager.rules"
QUIRKS_DST="/etc/modprobe.d/99-rodecaster-quirks.conf"
DESKTOP_FILE="$HOME/.local/share/applications/castermanager.desktop"
SYSTEMD_SERVICE="$HOME/.config/systemd/user/castermanager-drain.service"

echo "=========================================="
echo "    CasterManager Uninstallation Script   "
echo "=========================================="
echo ""

# 1. Stop and disable systemd drain service
echo "[1/4] Stopping background drain service..."
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user stop castermanager-drain.service 2>/dev/null || true
    systemctl --user disable castermanager-drain.service 2>/dev/null || true
    systemctl --user stop castermanager-censor.service 2>/dev/null || true
    systemctl --user disable castermanager-censor.service 2>/dev/null || true
fi
rm -f "$SYSTEMD_SERVICE" "$HOME/.config/systemd/user/castermanager-censor.service"
rm -f "$HOME/.config/wireplumber/wireplumber.conf.d/51-castermanager-rodecaster.conf" "$HOME/.config/wireplumber/wireplumber.conf.d/51-castermanager-rodecaster-duo.conf"
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload || true
fi

# 2. Remove Desktop launcher & system icons
echo "[2/4] Removing application launcher and icons..."
rm -f "$DESKTOP_FILE"
rm -f "$HOME/.local/share/icons/hicolor/"*"/apps/castermanager."* 2>/dev/null || true
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi
if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 2>/dev/null || true
fi

# 3. Remove udev and modprobe rules
echo "[3/4] Removing system rules..."
if [ -f "$UDEV_RULE_DST" ] || [ -f "$QUIRKS_DST" ]; then
    echo "Requesting sudo permissions to remove udev and modprobe rules..."
    sudo rm -f "$UDEV_RULE_DST" "$QUIRKS_DST"
    sudo udevadm control --reload-rules || true
fi

echo ""
echo "=========================================="
echo "   Uninstallation Completed Successfully  "
echo "=========================================="

