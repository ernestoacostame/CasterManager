#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PYTHONPATH="$SCRIPT_DIR:$PYTHONPATH"

# Ensure background HID drainer is running (restart ensures latest binary/script is active)
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user restart castermanager-drain.service 2>/dev/null || true
fi

cd "$SCRIPT_DIR"
exec python3 src/main.py "$@"

