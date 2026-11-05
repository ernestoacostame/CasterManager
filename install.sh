#!/usr/bin/env bash
# ==============================================================================
# CasterManager - Automated Installation Script
# Supports: RØDECaster Duo and RØDECaster Pro II on Linux
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UDEV_RULE_SRC="$SCRIPT_DIR/udev/99-castermanager.rules"
UDEV_RULE_DST="/etc/udev/rules.d/99-castermanager.rules"
QUIRKS_SRC="$SCRIPT_DIR/udev/99-rodecaster-quirks.conf"
QUIRKS_DST="/etc/modprobe.d/99-rodecaster-quirks.conf"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/castermanager.desktop"

echo "=========================================="
echo "    CasterManager Installation Script     "
echo "=========================================="
echo ""

# 1. Check Python and PyQt6
echo "[1/5] Checking prerequisites..."
if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 is not installed."
    exit 1
fi

if ! python3 -c "import PyQt6.QtQml, PyQt6.QtQuick" 2>/dev/null; then
    echo "WARNING: PyQt6 (with QtQml / QtQuick) is missing."
    echo "On Arch Linux run: sudo pacman -S python-pyqt6 qt6-declarative"
    echo "On Ubuntu/Debian:  sudo apt install python3-pyqt6 python3-pyqt6.qtquick"
fi

# 2. Install udev rules and kernel quirks
echo "[2/5] Installing udev rules and kernel quirks for RØDECaster devices..."
if [ "$EUID" -ne 0 ]; then
    echo "Requesting sudo permissions to install udev rules and modprobe quirks..."
    sudo cp "$UDEV_RULE_SRC" "$UDEV_RULE_DST"
    sudo cp "$QUIRKS_SRC" "$QUIRKS_DST"
    sudo udevadm control --reload-rules
    sudo udevadm trigger --subsystem-match=hidraw || true
    # Fix permissions immediately on any currently active node
    for h in /sys/class/hidraw/hidraw*; do
        if [ -d "$h/device" ]; then
            devpath=$(readlink -f "$h/device")
            if echo "$devpath" | grep -qi "19f7"; then
                nodename=$(basename "$h")
                echo "Applying permissions to /dev/$nodename"
                sudo chmod 666 "/dev/$nodename" || true
            fi
        fi
    done
else
    cp "$UDEV_RULE_SRC" "$UDEV_RULE_DST"
    cp "$QUIRKS_SRC" "$QUIRKS_DST"
    udevadm control --reload-rules
    udevadm trigger --subsystem-match=hidraw || true
    for h in /sys/class/hidraw/hidraw*; do
        if [ -d "$h/device" ]; then
            devpath=$(readlink -f "$h/device")
            if echo "$devpath" | grep -qi "19f7"; then
                nodename=$(basename "$h")
                chmod 666 "/dev/$nodename" || true
            fi
        fi
    done
fi

# 3. Compile or copy Rust backend binary if needed
echo "[3/5] Checking CasterManager backend engine..."
if [ -f "$SCRIPT_DIR/Resources/rcp2-cli-main/target/release/rcp2-cli" ]; then
    cp "$SCRIPT_DIR/Resources/rcp2-cli-main/target/release/rcp2-cli" "$SCRIPT_DIR/bin/rcp2-cli"
    chmod +x "$SCRIPT_DIR/bin/rcp2-cli"
elif [ -f "$SCRIPT_DIR/Resources/rcp2-cli-main/target/debug/rcp2-cli" ]; then
    cp "$SCRIPT_DIR/Resources/rcp2-cli-main/target/debug/rcp2-cli" "$SCRIPT_DIR/bin/rcp2-cli"
    chmod +x "$SCRIPT_DIR/bin/rcp2-cli"
fi

# 4. Install Background Drain Service (Prevents hardware freezes)
echo "[4/5] Installing background HID drain service..."
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"
cat > "$SYSTEMD_USER_DIR/castermanager-drain.service" << EOF
[Unit]
Description=CasterManager RØDECaster HID Drain Service (Prevents Hardware Freeze)
After=graphical-session.target

[Service]
Type=simple
ExecStart=$SCRIPT_DIR/bin/castermanager-drain
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF

chmod +x "$SCRIPT_DIR/bin/castermanager-drain"
systemctl --user daemon-reload || true
systemctl --user enable --now castermanager-drain.service || true

# 5. Install Desktop & System Icons (XDG Icon Theme Specification)
echo "[5/6] Installing application icons to system icon theme..."
python3 -c "
import os, sys, shutil
from PyQt6.QtGui import QImage, QGuiApplication

app = QGuiApplication(sys.argv)
src_png = '$SCRIPT_DIR/assets/app_icon.png'
src_svg = '$SCRIPT_DIR/assets/app_icon.svg'
icon_base = os.path.expanduser('~/.local/share/icons/hicolor')

if os.path.exists(src_png):
    img = QImage(src_png)
    for s in [256, 128, 64, 48, 32, 16]:
        dir_path = os.path.join(icon_base, f'{s}x{s}', 'apps')
        os.makedirs(dir_path, exist_ok=True)
        img.scaled(s, s).save(os.path.join(dir_path, 'castermanager.png'))

if os.path.exists(src_svg):
    scalable_dir = os.path.join(icon_base, 'scalable', 'apps')
    os.makedirs(scalable_dir, exist_ok=True)
    shutil.copyfile(src_svg, os.path.join(scalable_dir, 'castermanager.svg'))
" || true

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi
if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 2>/dev/null || true
fi

# 6. Create Desktop shortcut
echo "[6/6] Creating application menu launcher..."
mkdir -p "$DESKTOP_DIR"
chmod +x "$SCRIPT_DIR/run.sh"

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=CasterManager
Comment=Manage RØDECaster Duo & Pro II SMART Pads and audio on Linux
Exec=$SCRIPT_DIR/run.sh
Icon=castermanager
Terminal=false
Type=Application
Categories=AudioVideo;Audio;Mixer;Qt;
StartupWMClass=castermanager
StartupNotify=true
EOF

chmod +x "$DESKTOP_FILE"
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
fi
echo "Launcher installed at: $DESKTOP_FILE"

echo ""
echo "=========================================="
echo "   Installation Completed Successfully!   "
echo "=========================================="
echo "You can now launch CasterManager by running:"
echo "   $SCRIPT_DIR/run.sh"
echo "Or from your application launcher (CasterManager)."

