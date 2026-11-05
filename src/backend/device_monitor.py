import os
import glob
import select
import threading
from PyQt6.QtCore import QObject, pyqtSignal, QTimer

RODE_VENDOR_ID = "19f7"

DUO_PRODUCT_IDS = {
    "0050": "RØDECaster Duo",
    "0079": "RØDECaster Duo",
    "0093": "RØDECaster Duo",
    "0095": "RØDECaster Duo",
    "004e": "RØDECaster Duo (Secondary)",
}

PRO_II_PRODUCT_IDS = {
    "0030": "RØDECaster Pro II",
    "0037": "RØDECaster Pro II",
    "0072": "RØDECaster Pro II",
    "0078": "RØDECaster Pro II",
    "0092": "RØDECaster Pro II",
    "0094": "RØDECaster Pro II",
    "0026": "RØDECaster Pro II (Secondary)",
}

class HidDrainer(threading.Thread):
    """
    Prevents hardware lockup on Linux: continuously drains reports from
    the RØDECaster's HID endpoint so that button/pad presses never block the firmware.
    """
    def __init__(self, hidraw_path):
        super().__init__(daemon=True)
        self.hidraw_path = hidraw_path
        self._running = True
        self._fd = None

    def run(self):
        try:
            self._fd = os.open(self.hidraw_path, os.O_RDONLY | os.O_NONBLOCK)
            while self._running:
                r, _, _ = select.select([self._fd], [], [], 0.5)
                if r and self._running:
                    try:
                        _ = os.read(self._fd, 1024)
                    except (BlockingIOError, OSError):
                        pass
        except Exception:
            pass
        finally:
            if self._fd is not None:
                try:
                    os.close(self._fd)
                except Exception:
                    pass
                self._fd = None

    def stop(self):
        self._running = False

class DeviceMonitor(QObject):
    """
    Actively monitors USB and hidraw devices to dynamically detect
    when a RØDECaster Duo or Pro II is connected or disconnected.
    """
    device_changed = pyqtSignal(dict)  # Emits device info dict when connected/changed
    device_disconnected = pyqtSignal()
    permission_issue = pyqtSignal(str) # Emits hidraw path when permission is denied

    def __init__(self, parent=None, poll_interval_ms=1500):
        super().__init__(parent)
        self._current_device = None
        self._drainer = None
        self._timer = QTimer(self)
        self._timer.timeout.connect(self.scan_devices)
        self._poll_interval = poll_interval_ms

    def start(self):
        self.scan_devices()
        self._timer.start(self._poll_interval)

    def stop(self):
        self._timer.stop()
        if self._drainer:
            self._drainer.stop()
            self._drainer = None

    def scan_devices(self):
        found = None

        # 1. Scan sysfs for USB devices with vendor 19f7
        for dev_path in glob.glob("/sys/bus/usb/devices/*"):
            vendor_file = os.path.join(dev_path, "idVendor")
            if os.path.isfile(vendor_file):
                try:
                    with open(vendor_file, "r") as f:
                        vid = f.read().strip().lower()
                    if vid == RODE_VENDOR_ID:
                        prod_file = os.path.join(dev_path, "idProduct")
                        with open(prod_file, "r") as f:
                            pid = f.read().strip().lower()

                        manufacturer_file = os.path.join(dev_path, "manufacturer")
                        product_file = os.path.join(dev_path, "product")
                        serial_file = os.path.join(dev_path, "serial")

                        manufacturer = self._read_text(manufacturer_file, "RØDE")
                        product_name = self._read_text(product_file, "RØDECaster")
                        serial = self._read_text(serial_file, "")

                        # Determine Model profile
                        if pid in DUO_PRODUCT_IDS:
                            model_type = "Duo"
                            display_name = "RØDECaster Duo"
                            pads_per_bank = 6
                            pad_cols = 2
                            pad_rows = 3
                            physical_faders = 4
                            virtual_faders = 5
                            pots = 2
                            physical_order = [0, 3, 1, 4, 2, 5]
                        elif pid in PRO_II_PRODUCT_IDS:
                            model_type = "ProII"
                            display_name = "RØDECaster Pro II"
                            pads_per_bank = 8
                            pad_cols = 2
                            pad_rows = 4
                            physical_faders = 6
                            virtual_faders = 3
                            pots = 4
                            physical_order = [0, 4, 1, 5, 2, 6, 3, 7]
                        else:
                            # Default fallback based on product name
                            if "duo" in product_name.lower():
                                model_type = "Duo"
                                display_name = "RØDECaster Duo"
                                pads_per_bank = 6
                                pad_cols = 2
                                pad_rows = 3
                                physical_faders = 4
                                virtual_faders = 5
                                pots = 2
                                physical_order = [0, 3, 1, 4, 2, 5]
                            else:
                                model_type = "ProII"
                                display_name = "RØDECaster Pro II"
                                pads_per_bank = 8
                                pad_cols = 2
                                pad_rows = 4
                                physical_faders = 6
                                virtual_faders = 3
                                pots = 4
                                physical_order = [0, 4, 1, 5, 2, 6, 3, 7]

                        # Find corresponding hidraw node
                        hidraw_node = self._find_hidraw_for_device(dev_path)
                        has_permission = False
                        if hidraw_node and os.path.exists(hidraw_node):
                            has_permission = os.access(hidraw_node, os.R_OK | os.W_OK)

                        found = {
                            "vendor_id": vid,
                            "product_id": pid,
                            "model_type": model_type,
                            "display_name": display_name,
                            "product_name": product_name,
                            "manufacturer": manufacturer,
                            "serial": serial,
                            "sysfs_path": dev_path,
                            "hidraw_node": hidraw_node,
                            "has_permission": has_permission,
                            "pads_per_bank": pads_per_bank,
                            "pad_cols": pad_cols,
                            "pad_rows": pad_rows,
                            "physical_faders": physical_faders,
                            "virtual_faders": virtual_faders,
                            "pots": pots,
                            "physical_order": physical_order,
                            "max_banks": 8
                        }
                        break
                except Exception:
                    continue

        if found:
            if not found["has_permission"] and found.get("hidraw_node"):
                self.permission_issue.emit(found["hidraw_node"])
            elif found["has_permission"] and found.get("hidraw_node"):
                # Start or update background drainer to prevent hardware button freeze
                if not self._drainer or self._drainer.hidraw_path != found["hidraw_node"]:
                    if self._drainer:
                        self._drainer.stop()
                    self._drainer = HidDrainer(found["hidraw_node"])
                    self._drainer.start()

            if not self._current_device or self._current_device.get("product_id") != found["product_id"] or self._current_device.get("has_permission") != found["has_permission"]:
                self._current_device = found
                self.device_changed.emit(found)
        else:
            if self._drainer:
                self._drainer.stop()
                self._drainer = None
            if self._current_device is not None:
                self._current_device = None
                self.device_disconnected.emit()

    def _read_text(self, path, fallback=""):
        if os.path.isfile(path):
            try:
                with open(path, "r", encoding="utf-8", errors="ignore") as f:
                    return f.read().strip()
            except Exception:
                pass
        return fallback

    def _find_hidraw_for_device(self, usb_dev_path):
        # Look for interface 9 (hidraw) inside the usb device path
        for root, dirs, files in os.walk(usb_dev_path):
            if "hidraw" in dirs:
                hidraw_dir = os.path.join(root, "hidraw")
                for item in os.listdir(hidraw_dir):
                    if item.startswith("hidraw"):
                        return f"/dev/{item}"
            for item in dirs:
                if item.startswith("hidraw"):
                    return f"/dev/{item}"
        # Fallback check via /sys/class/hidraw
        for h in glob.glob("/sys/class/hidraw/hidraw*"):
            try:
                target = os.path.realpath(h)
                if RODE_VENDOR_ID.upper() in target or RODE_VENDOR_ID.lower() in target:
                    return f"/dev/{os.path.basename(h)}"
            except Exception:
                continue
        return None

