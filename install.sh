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
echo "[1/6] Checking prerequisites..."
if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 is not installed. Please install Python 3."
    exit 1
fi

PYQT_MISSING=0
if ! python3 -c "import PyQt6.QtCore, PyQt6.QtGui, PyQt6.QtQml, PyQt6.QtQuick" 2>/dev/null; then
    PYQT_MISSING=1
fi

if [ "$PYQT_MISSING" -eq 1 ]; then
    echo ""
    echo "==> PyQt6 (QtQml / QtQuick) components are missing."
    DISTRO_CMD=""
    if command -v pacman >/dev/null 2>&1; then
        DISTRO_CMD="sudo pacman -S --needed python-pyqt6 qt6-declarative qt6-multimedia qt6-svg"
    elif command -v apt-get >/dev/null 2>&1; then
        DISTRO_CMD="sudo apt update && sudo apt install -y python3-pyqt6 python3-pyqt6.qtquick python3-pyqt6.qtmultimedia qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts qml6-module-qtquick-shapes qml6-module-qtquick-dialogs qml6-module-qtmultimedia libqt6svg6"
    elif command -v dnf >/dev/null 2>&1; then
        DISTRO_CMD="sudo dnf install -y python3-pyqt6 qt6-qtdeclarative qt6-qtmultimedia qt6-qtsvg"
    elif command -v zypper >/dev/null 2>&1; then
        DISTRO_CMD="sudo zypper in python3-PyQt6 qt6-declarative qt6-multimedia"
    fi

    if [ -n "$DISTRO_CMD" ]; then
        echo "Detected package manager command to install dependencies:"
        echo "  $DISTRO_CMD"
        if [ -t 0 ]; then
            read -r -p "Would you like to run this command now? [y/N] " reply
            case "$reply" in
                [yY][eE][sS]|[yY])
                    eval "$DISTRO_CMD" || true
                    ;;
                *)
                    echo "Continuing installation. Remember to install dependencies before launching CasterManager."
                    ;;
            esac
        fi
    else
        echo "Please install PyQt6, Qt6 Declarative (QML), and Qt6 Multimedia using your package manager."
    fi
    echo ""
fi

# 2. Install udev rules and kernel quirks
echo "[2/6] Installing udev rules and kernel quirks for RØDECaster devices..."
if [ "$EUID" -ne 0 ]; then
    echo "Requesting sudo permissions to install udev rules and modprobe quirks..."
    sudo cp --remove-destination "$UDEV_RULE_SRC" "$UDEV_RULE_DST"
    sudo cp --remove-destination "$QUIRKS_SRC" "$QUIRKS_DST"
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
    cp --remove-destination "$UDEV_RULE_SRC" "$UDEV_RULE_DST"
    cp --remove-destination "$QUIRKS_SRC" "$QUIRKS_DST"
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
echo "[3/6] Checking CasterManager backend engine..."
# The bundled bin/rcp2-cli is authoritative (it carries Streamer X multitrack PID 0x0055
# support); only fall back to a local build when it is missing, never overwrite it.
if [ -x "$SCRIPT_DIR/bin/rcp2-cli" ]; then
    echo "      Using bundled bin/rcp2-cli"
elif [ -f "$SCRIPT_DIR/Resources/rcp2-cli-main/target/release/rcp2-cli" ]; then
    cp --remove-destination "$SCRIPT_DIR/Resources/rcp2-cli-main/target/release/rcp2-cli" "$SCRIPT_DIR/bin/rcp2-cli"
    chmod +x "$SCRIPT_DIR/bin/rcp2-cli"
elif [ -f "$SCRIPT_DIR/Resources/rcp2-cli-main/target/debug/rcp2-cli" ]; then
    cp --remove-destination "$SCRIPT_DIR/Resources/rcp2-cli-main/target/debug/rcp2-cli" "$SCRIPT_DIR/bin/rcp2-cli"
    chmod +x "$SCRIPT_DIR/bin/rcp2-cli"
fi

# 4. Install Background Drain Service (Prevents hardware freezes)
echo "[4/6] Installing background HID drain service..."
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

# Streamer X: applies the Censor pad to UNIFY-Mic in USB multitrack mode (the unit sends
# its multitrack channels before the Censor). Runs without the CasterManager window.
cat > "$SYSTEMD_USER_DIR/castermanager-censor.service" << EOF
[Unit]
Description=CasterManager Streamer X Censor Service (UNIFY-Mic)
After=pipewire-pulse.service graphical-session.target

[Service]
Type=simple
ExecStart=$SCRIPT_DIR/bin/castermanager-censor
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF

chmod +x "$SCRIPT_DIR/bin/castermanager-drain" "$SCRIPT_DIR/bin/castermanager-censor"
systemctl --user daemon-reload || true
systemctl --user enable --now castermanager-drain.service || true
systemctl --user enable --now castermanager-censor.service || true

# RØDECaster Duo / Pro II / Streamer X: friendly PipeWire names (Chat / Multitrack) for the Pro Audio nodes
WP_DIR="$HOME/.config/wireplumber/wireplumber.conf.d"
mkdir -p "$WP_DIR"
rm -f "$WP_DIR/51-castermanager-rodecaster-duo.conf"
cp "$SCRIPT_DIR/assets/wireplumber/51-castermanager-rodecaster.conf" "$WP_DIR/"
systemctl --user restart wireplumber.service 2>/dev/null || true

# 5. Install Desktop & System Icons (XDG Icon Theme Specification)
echo "[5/6] Installing application icons to system icon theme..."
ICON_BASE="$HOME/.local/share/icons/hicolor"
mkdir -p "$ICON_BASE"

if [ -d "$SCRIPT_DIR/assets/icons/hicolor" ]; then
    cp -r "$SCRIPT_DIR/assets/icons/hicolor/"* "$ICON_BASE/"
fi

# Fallback: copy standard icon to ~/.local/share/pixmaps
mkdir -p "$HOME/.local/share/pixmaps"
if [ -f "$SCRIPT_DIR/assets/app_icon.png" ]; then
    cp --remove-destination "$SCRIPT_DIR/assets/app_icon.png" "$HOME/.local/share/pixmaps/castermanager.png"
fi

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

