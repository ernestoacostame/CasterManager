import os
import subprocess
import json
import logging
import threading
import time

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
        self.target_pid = None
        self.target_serial = None
        self._lock = threading.Lock()
        self._known_pads = set()
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

    # ------------------------------------------------------------------
    # Pad node bookkeeping
    #
    # `rcp2-cli pad set-prop` creates a brand-new PAD node when it cannot find
    # one for the target slot. Every CLI call is a separate process with its own
    # snapshot, so a burst of set-prop calls on an empty slot (FX assignment,
    # copy/paste...) used to create one duplicate node per call before the device
    # reported the first one. `pad clear` then only removed one node per click and
    # the pad "came back" again and again.
    # ------------------------------------------------------------------
    def invalidate_pad_cache(self):
        self._known_pads.clear()

    def pad_exists(self, bank, pad):
        """Read-only check (dry-run) whether a PAD node exists for bank/pad."""
        out, err = self.run_cmd(["--dry-run", "pad", "clear", str(bank), str(pad)], timeout=8)
        return bool(out) and "deleting pad idx" in out

    def _set_pad_prop(self, args, timeout):
        bank, pad = args[2], args[3]
        key = (self.target_pid, str(bank), str(pad))
        if key in self._known_pads:
            return self.run_cmd(args, timeout=timeout, _raw=True)

        if self.pad_exists(bank, pad):
            self._known_pads.add(key)
            return self.run_cmd(args, timeout=timeout, _raw=True)

        # Slot is empty: this call creates the node. Wait until the device
        # reports it before letting any further set-prop through.
        result = self.run_cmd(args, timeout=timeout, _raw=True)
        for _ in range(12):
            time.sleep(0.35)
            if self.pad_exists(bank, pad):
                break
        else:
            logger.warning(f"Pad node for bank {bank} pad {pad} not confirmed after creation")
        self._known_pads.add(key)
        return result

    def clear_pad(self, bank, pad, max_passes=16):
        """Delete every PAD node for bank/pad (also removes leftover duplicates)."""
        self._known_pads.discard((self.target_pid, str(bank), str(pad)))
        removed = 0
        last_err = None
        for _ in range(max_passes):
            out, err = self.run_cmd(["pad", "clear", str(bank), str(pad)], timeout=10)
            if err:
                last_err = err
                break
            if not out or "already empty" in out:
                break
            removed += 1
            time.sleep(0.3)
        if removed > 1:
            logger.info(f"Removed {removed} duplicated nodes for bank {bank} pad {pad}")
        return removed, last_err

    def run_cmd(self, args, timeout=5, _raw=False):
        if not _raw and len(args) >= 4 and args[0] == "pad" and args[1] == "set-prop":
            return self._set_pad_prop(args, timeout)
        if not self.is_available():
            logger.warning(f"CLI binary not found at {self.cli_path}")
            return None, "Binary not found"

        cmd = [self.cli_path, "--i-know-what-i-do"] + args
        env = os.environ.copy()
        if self.target_pid:
            env["RCP_DEVICE_PID"] = str(self.target_pid)
        if self.target_serial:
            env["RCP_DEVICE_SERIAL"] = str(self.target_serial)

        with self._lock:
            try:
                res = subprocess.run(
                    cmd,
                    capture_output=True,
                    text=True,
                    timeout=timeout,
                    env=env
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
        out, err = self.run_cmd(["pad", "trigger", str(bank), str(pad), "--hold", str(hold_ms)], timeout=6)
        if err:
            logger.error(f"Error triggering pad {bank}:{pad} -> {err}")
            return False, err
        return True, "Triggered"

    def set_bank(self, bank):
        out, err = self.run_cmd(["pad", "bank", str(bank)], timeout=8)
        if err:
            logger.error(f"Error switching to bank {bank} -> {err}")
            return False, err
        return True, "Switched"

    def dump_state(self):
        out, err = self.run_cmd(["dump"], timeout=16)
        if err or not out:
            logger.warning(f"Could not dump device state: {err}")
            return None
        try:
            return json.loads(out)
        except Exception as e:
            logger.error(f"Failed to parse JSON state dump: {e}")
            return None


