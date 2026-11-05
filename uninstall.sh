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
echo "[1/3] Stopping background drain service..."
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user stop castermanager-drain.service 2>/dev/null || true
    systemctl --user disable castermanager-drain.service 2>/dev/null || true
fi
rm -f "$SYSTEMD_SERVICE"
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload || true
fi

# 2. Remove Desktop launcher
echo "[2/3] Removing application launcher..."
rm -f "$DESKTOP_FILE"

# 3. Remove udev and modprobe rules
echo "[3/3] Removing system rules..."
if [ -f "$UDEV_RULE_DST" ] || [ -f "$QUIRKS_DST" ]; then
    echo "Requesting sudo permissions to remove udev and modprobe rules..."
    sudo rm -f "$UDEV_RULE_DST" "$QUIRKS_DST"
    sudo udevadm control --reload-rules || true
fi

echo ""
echo "=========================================="
echo "   Uninstallation Completed Successfully  "
echo "=========================================="

