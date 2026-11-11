#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PYTHONPATH="$SCRIPT_DIR:$PYTHONPATH"

# Check dependencies
if ! python3 -c "import PyQt6.QtCore, PyQt6.QtGui, PyQt6.QtQml" 2>/dev/null; then
    ERR_MSG="PyQt6 components are missing. Please run ./install.sh or install python-pyqt6."
    echo "ERROR: $ERR_MSG" >&2
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u critical "CasterManager" "$ERR_MSG"
    fi
    exit 1
fi

# Ensure background HID drainer is running (restart ensures latest binary/script is active)
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user restart castermanager-drain.service 2>/dev/null || true
fi

cd "$SCRIPT_DIR"
exec python3 src/main.py "$@"

