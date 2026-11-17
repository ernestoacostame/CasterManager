"""
Native USB HID controller for RØDE PodMic USB (VID 19f7, PID 004a).

Protocol summary:
- Report ID 0x08 (Output, 28 bytes) -> Report ID 0x07 (Input, 28 bytes)
- Report ID 0x04 (Output, 29 bytes) -> Report ID 0x03 (Input, 29 bytes)
Each transaction sends one report and waits for the matching reply under a lock.
"""

import os
import select
import threading
import time
from typing import Dict, Optional, Sequence


_HID_LOCK = threading.Lock()

REPORT_OUT_GLOBAL = 0x08
REPORT_IN_GLOBAL = 0x07
LEN_GLOBAL = 28

REPORT_OUT_PROC = 0x04
REPORT_IN_PROC = 0x03
LEN_PROC = 29

VOXLAB_SUB_MAP = {
    "depth": 0x00,
    "sparkle": 0x01,
    "punch": 0x02,
}

# Processor category IDs for Report 0x04 / 0x03
PROC_COMP = 0x00
PROC_GATE = 0x01
PROC_EXCITER = 0x02
PROC_BIG_BOTTOM = 0x03


class PodMicHidController:
    """Thread-safe HID helper for reading and writing RØDE PodMic USB DSP/gain state."""

    @staticmethod
    def _build_report(report_id: int, total_len: int, payload: Sequence[int]) -> bytes:
        buf = bytearray(total_len)
        buf[0] = report_id & 0xFF
        for idx, val in enumerate(payload, start=1):
            if idx >= total_len:
                break
            buf[idx] = val & 0xFF
        return bytes(buf)

    @staticmethod
    def _drain_fd(fd: int) -> None:
        while True:
            r, _, _ = select.select([fd], [], [], 0.0)
            if not r:
                break
            try:
                os.read(fd, 128)
            except (BlockingIOError, OSError):
                break

    @classmethod
    def _query_fd(
        cls,
        fd: int,
        report_id: int,
        total_len: int,
        expected_reply_id: int,
        payload: Sequence[int],
        expected_cmd: int,
        expected_sub: Optional[int] = None,
        timeout: float = 0.12,
    ) -> Optional[bytes]:
        cls._drain_fd(fd)
        packet = cls._build_report(report_id, total_len, payload)
        os.write(fd, packet)

        deadline = time.monotonic() + timeout
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                return None
            r, _, _ = select.select([fd], [], [], remaining)
            if not r:
                return None
            try:
                data = os.read(fd, 128)
            except (BlockingIOError, OSError):
                continue
            if not data or len(data) < 4:
                continue
            if data[0] != expected_reply_id or data[1] != expected_cmd:
                continue
            if expected_sub is not None and data[3] != expected_sub:
                continue
            return data

    @classmethod
    def _write_report(
        cls,
        hidraw_path: str,
        report_id: int,
        total_len: int,
        payload: Sequence[int],
    ) -> bool:
        if not hidraw_path or not os.path.exists(hidraw_path):
            return False
        packet = cls._build_report(report_id, total_len, payload)
        with _HID_LOCK:
            fd = None
            try:
                fd = os.open(hidraw_path, os.O_RDWR | os.O_NONBLOCK)
                os.write(fd, packet)
                # Brief pause so consecutive writes are not dropped by the USB MCU
                time.sleep(0.008)
                cls._drain_fd(fd)
                return True
            except OSError:
                return False
            finally:
                if fd is not None:
                    try:
                        os.close(fd)
                    except OSError:
                        pass

    @classmethod
    def read_full_state(cls, hidraw_path: str) -> Optional[Dict[str, object]]:
        """Query all live DSP, VoxLab, gain, and mute parameters from PodMic USB."""
        if not hidraw_path or not os.path.exists(hidraw_path):
            return None

        with _HID_LOCK:
            fd = None
            try:
                fd = os.open(hidraw_path, os.O_RDWR | os.O_NONBLOCK)

                def q8(cmd: int, sub: Optional[int] = None) -> Optional[bytes]:
                    pl = [cmd, 0x01] if sub is None else [cmd, 0x01, sub]
                    return cls._query_fd(
                        fd,
                        REPORT_OUT_GLOBAL,
                        LEN_GLOBAL,
                        REPORT_IN_GLOBAL,
                        pl,
                        expected_cmd=cmd,
                        expected_sub=sub,
                    )

                def q4(cat: int, param_idx: int = 0x00) -> Optional[bytes]:
                    return cls._query_fd(
                        fd,
                        REPORT_OUT_PROC,
                        LEN_PROC,
                        REPORT_IN_PROC,
                        [cat, 0x03, param_idx],
                        expected_cmd=cat,
                    )

                r_proc = q8(0x0D)
                r_adv = q8(0x0B)
                r_hpf = q8(0x01)
                r_hf = q8(0x02)
                r_mute = q8(0x03)
                r_gain = q8(0x04)
                r_depth = q8(0x0C, 0x00)
                r_sparkle = q8(0x0C, 0x01)
                r_punch = q8(0x0C, 0x02)

                r_comp = q4(PROC_COMP, 0x00)
                r_gate = q4(PROC_GATE, 0x00)
                r_exciter = q4(PROC_EXCITER, 0x00)
                r_big = q4(PROC_BIG_BOTTOM, 0x00)

                if r_gain is None and r_mute is None and r_proc is None:
                    return None

                gain_pct = max(0, min(100, int(r_gain[3]))) if r_gain else 75
                # Hardware byte 3: 1 = unmuted (active), 0 = muted
                muted = (int(r_mute[3]) == 0) if r_mute else False
                processing_on = bool(r_proc[3]) if r_proc else True
                advanced_mode = bool(r_adv[3]) if r_adv else False
                hpf_mode = max(0, min(2, int(r_hpf[3]))) if r_hpf else 0
                hf_boost = bool(r_hf[3]) if r_hf else False

                depth = max(0, min(100, int(r_depth[4]))) if (r_depth and len(r_depth) > 4) else 50
                sparkle = max(0, min(100, int(r_sparkle[4]))) if (r_sparkle and len(r_sparkle) > 4) else 50
                punch = max(0, min(100, int(r_punch[4]))) if (r_punch and len(r_punch) > 4) else 50

                # Report 0x03 reply format for param_idx 0x00: [0x03, cat, 0x41, <enable_0_or_1>, ...]
                def proc_bool(rep: Optional[bytes]) -> bool:
                    return bool(rep[3]) if (rep and len(rep) >= 4 and rep[2] == 0x41) else False

                return {
                    "processing_on": processing_on,
                    "advanced_mode": advanced_mode,
                    "hpf_mode": hpf_mode,
                    "hf_boost": hf_boost,
                    "muted": muted,
                    "gain_pct": gain_pct,
                    "depth": depth,
                    "sparkle": sparkle,
                    "punch": punch,
                    "comp_on": proc_bool(r_comp),
                    "gate_on": proc_bool(r_gate),
                    "exciter_on": proc_bool(r_exciter),
                    "big_bottom_on": proc_bool(r_big),
                }
            except OSError:
                return None
            finally:
                if fd is not None:
                    try:
                        os.close(fd)
                    except OSError:
                        pass

    @classmethod
    def set_gain(cls, hidraw_path: str, pct_0_100: int) -> bool:
        pct = max(0, min(100, int(round(pct_0_100))))
        ok4 = cls._write_report(hidraw_path, REPORT_OUT_PROC, LEN_PROC, [0x04, 0x00, pct])
        ok8 = cls._write_report(hidraw_path, REPORT_OUT_GLOBAL, LEN_GLOBAL, [0x04, 0x00, pct])
        return ok4 or ok8

    @classmethod
    def set_mute(cls, hidraw_path: str, muted: bool) -> bool:
        # Hardware byte 3: 0 = muted, 1 = unmuted
        hw_val = 0 if muted else 1
        return cls._write_report(hidraw_path, REPORT_OUT_GLOBAL, LEN_GLOBAL, [0x03, 0x00, hw_val])

    @classmethod
    def set_processing_enabled(cls, hidraw_path: str, enabled: bool) -> bool:
        return cls._write_report(
            hidraw_path, REPORT_OUT_GLOBAL, LEN_GLOBAL, [0x0D, 0x00, 1 if enabled else 0]
        )

    @classmethod
    def set_advanced_mode(cls, hidraw_path: str, advanced: bool) -> bool:
        return cls._write_report(
            hidraw_path, REPORT_OUT_GLOBAL, LEN_GLOBAL, [0x0B, 0x00, 1 if advanced else 0]
        )

    @classmethod
    def set_voxlab(cls, hidraw_path: str, macro_key: str, val_0_100: int) -> bool:
        sub = VOXLAB_SUB_MAP.get(macro_key)
        if sub is None:
            return False
        val = max(0, min(100, int(round(val_0_100))))
        cls.set_processing_enabled(hidraw_path, True)
        cls.set_advanced_mode(hidraw_path, False)
        return cls._write_report(hidraw_path, REPORT_OUT_GLOBAL, LEN_GLOBAL, [0x0C, 0x00, sub, val])

    @classmethod
    def set_hpf(cls, hidraw_path: str, enabled: bool, freq_norm: float = 0.5) -> bool:
        if not enabled:
            mode = 0
        elif freq_norm < 0.5:
            mode = 1  # 75 Hz
        else:
            mode = 2  # 150 Hz
        return cls._write_report(hidraw_path, REPORT_OUT_GLOBAL, LEN_GLOBAL, [0x01, 0x00, mode])

    @classmethod
    def set_hf_boost(cls, hidraw_path: str, enabled: bool) -> bool:
        return cls._write_report(
            hidraw_path, REPORT_OUT_GLOBAL, LEN_GLOBAL, [0x02, 0x00, 1 if enabled else 0]
        )

    @classmethod
    def set_processor_enable(cls, hidraw_path: str, cat: int, enabled: bool) -> bool:
        return cls._write_report(
            hidraw_path, REPORT_OUT_PROC, LEN_PROC, [cat, 0x02, 0x00, 1 if enabled else 0]
        )
