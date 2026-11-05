import os
import subprocess
import json
import logging

logger = logging.getLogger("CasterManager.rcp_bridge")

PAD_COLORS = [
    {"name": "Red",        "hex": "#FF3C3C", "idx": 0},
    {"name": "Orange",     "hex": "#FF8C28", "idx": 1},
    {"name": "Yellow",     "hex": "#FFDC28", "idx": 2},
    {"name": "LightGreen", "hex": "#8CE63C", "idx": 3},
    {"name": "Green",      "hex": "#28C850", "idx": 4},
    {"name": "Mint",       "hex": "#28D2AA", "idx": 5},
    {"name": "Cyan",       "hex": "#28C8DC", "idx": 6},
    {"name": "LightBlue",  "hex": "#3C96FF", "idx": 7},
    {"name": "Blue",       "hex": "#5050FF", "idx": 8},
    {"name": "Purple",     "hex": "#A050E6", "idx": 9},
    {"name": "Pink",       "hex": "#E650B4", "idx": 10},
    {"name": "Magenta",    "hex": "#E63C78", "idx": 11},
]

class RcpBridge:
    def __init__(self, cli_path=None):
        base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        if not cli_path:
            # Check local bin/ first, then Resources target
            candidate = os.path.join(base_dir, "bin", "rcp2-cli")
            if not os.path.exists(candidate):
                candidate = os.path.join(base_dir, "Resources", "rcp2-cli-main", "target", "release", "rcp2-cli")
            self.cli_path = candidate
        else:
            self.cli_path = cli_path

    def is_available(self):
        return os.path.isfile(self.cli_path) and os.access(self.cli_path, os.X_OK)

    def run_cmd(self, args, timeout=5):
        if not self.is_available():
            logger.warning(f"CLI binary not found at {self.cli_path}")
            return None, "Binary not found"

        cmd = [self.cli_path, "--i-know-what-i-do"] + args
        try:
            res = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            if res.returncode == 0:
                return res.stdout, None
            else:
                return None, res.stderr or res.stdout
        except subprocess.TimeoutExpired:
            return None, "Command timed out"
        except Exception as e:
            return None, str(e)

    def trigger_pad(self, bank, pad, hold_ms=50):
        out, err = self.run_cmd(["pad", "trigger", str(bank), str(pad), "--hold", str(hold_ms)])
        if err:
            logger.error(f"Error triggering pad {bank}:{pad} -> {err}")
            return False, err
        return True, "Triggered"

    def set_bank(self, bank):
        out, err = self.run_cmd(["pad", "bank", str(bank)])
        if err:
            logger.error(f"Error switching to bank {bank} -> {err}")
            return False, err
        return True, "Switched"

    def dump_state(self):
        out, err = self.run_cmd(["dump"], timeout=8)
        if err or not out:
            logger.warning(f"Could not dump device state: {err}")
            return None
        try:
            return json.loads(out)
        except Exception as e:
            logger.error(f"Failed to parse JSON state dump: {e}")
            return None

