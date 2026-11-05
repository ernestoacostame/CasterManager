# CasterManager

<p align="center">
  <img src="assets/app_icon.png" width="96" height="96" alt="CasterManager Logo" />
</p>

<p align="center">
  <strong>Native Linux Desktop Manager & SMART Pad Controller for RØDECaster Duo and Pro II</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Linux-orange.svg" alt="Platform Linux" />
  <img src="https://img.shields.io/badge/UI-Qt%206%20%7C%20QML-41cd52.svg" alt="Qt 6 / QML" />
  <img src="https://img.shields.io/badge/Language-Python%20%2F%20Rust-blue.svg" alt="Python / Rust" />
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License MIT" />
</p>

---

![CasterManager Screenshot](docs/screenshot.png)

## Overview

**CasterManager** is a modern, responsive Linux desktop application designed to control and configure **RØDECaster Duo** and **RØDECaster Pro II** audio production consoles. Built with Qt 6 (PyQt6 + QML) and backed by a high-performance Rust protocol engine, it brings full control over SMART pads, audio file transfers, playback settings, and show profiles to Linux users.

---

## Key Features

- **🎛️ SMART Pad Matrix Management:**
  - Visual 2x3 (Duo) and 2x4 (Pro II) interactive grid layout matching the physical hardware buttons.
  - Seamless bank navigation across all 8 pad banks (up to 48 / 64 pads).
  - One-click pad trigger and auditioning directly from the desktop.
  - Clear / delete pad sound assignments with instant hardware synchronization.

- **📁 Audio Import & Export:**
  - **Upload:** Select any audio file (`.wav`, `.mp3`, `.ogg`, `.flac`, `.aac`) or drag & drop. The application automatically triggers eMMC mass-storage transfer mode, converts/copies the file, and remounts storage.
  - **Export:** Save sound files assigned to any SMART pad directly to your computer.

- **⚙️ Real-Time Playback Parameter Customization:**
  - **Play Modes:** Toggle between `Toggle` (play/pause), `One Shot` (complete playback), and `Hold` (momentary press).
  - **Loop Control:** Switch loop mode on or off.
  - **Replay Option:** Instant restart on tap vs. ignore/pause.
  - **Gain Control:** Fine-tune audio playback volume in real time.
  - **Color Palette:** Customize each pad's LED backlight with 12 hardware-matched colors.

- **👤 Show & Profile Customizer:**
  - Change the active show name displayed on the console.
  - Customize the user avatar color.

- **🛡️ Integrated Anti-Freeze Background Daemon (`castermanager-drain`):**
  - Fixes the known Linux hardware lockup bug where the RØDECaster firmware blocks indefinitely on USB HID writes when no host process is reading the endpoint.
  - Includes a lightweight user systemd service (`castermanager-drain.service`) that uses virtually 0% CPU and keeps the console fully responsive 24/7, even when the GUI is closed.

---

## Requirements

- **Operating System:** Linux (Arch, Ubuntu, Debian, Fedora, openSUSE, etc.)
- **Python:** 3.10+
- **Qt 6:** `python-pyqt6`, `qt6-declarative` (QML)
- **System Tools:** `udev`, `udisksctl`, `lsblk`

### Package Installation

**Arch Linux / Manjaro:**
```bash
sudo pacman -S python python-pyqt6 qt6-declarative
```

**Ubuntu / Debian / Linux Mint:**
```bash
sudo apt install python3 python3-pyqt6 python3-pyqt6.qtquick
```

**Fedora:**
```bash
sudo dnf install python3 python3-pyqt6 qt6-qtdeclarative
```

---

## Installation

Clone the repository and run the automated installation script:

```bash
git clone https://github.com/your-username/castermanager.git
cd castermanager
./install.sh
```

### What `install.sh` does:
1. Verifies Python 3 and PyQt6 dependencies.
2. Installs `udev` rules (`/etc/udev/rules.d/99-castermanager.rules`) for non-root USB access.
3. Configures kernel module quirks (`/etc/modprobe.d/99-rodecaster-quirks.conf`) to avoid HID buffer blocking.
4. Sets up and enables the background drain daemon (`castermanager-drain.service`) via systemd user session.
5. Creates a native desktop shortcut in your application launcher (`CasterManager`).

---

## Running the Application

Launch CasterManager from your desktop application launcher or run:

```bash
./run.sh
```

---

## Hardware Compatibility

| Model | Supported | Physical Controls | SMART Pads |
| :--- | :---: | :---: | :---: |
| **RØDECaster Duo** |  Yes | 4 Faders, 2 Pots | 6 per bank (2x3) |
| **RØDECaster Pro II** | Yes | 6 Faders, 4 Pots | 8 per bank (2x4) |

---

## Preventing Console Freezes on Linux (The USB HID Quirk)

RØDECaster consoles communicate via USB HID packets. A firmware characteristic causes the device to block indefinitely if an input report write cannot complete when Linux closes the device handle.

CasterManager solves this with a two-layer approach:
1. **Systemd User Daemon (`castermanager-drain.service`):** Runs continuously in the background, consuming <5 MB of RAM and ~0% CPU, ensuring that incoming HID packets are drained at all times.
2. **Kernel Quirk (`usbhid.quirks`):** For complete kernel-level handling, `/etc/modprobe.d/99-rodecaster-quirks.conf` is installed by `install.sh`. You can also append `usbhid.quirks=0x19f7:0x0093:0x00000400` to your bootloader (e.g., GRUB `GRUB_CMDLINE_LINUX_DEFAULT`).

---

## Credits & Acknowledgements

This project was made possible thanks to the work and research of the open-source community:

- **[rcp2-cli](https://github.com/jnbr/rcp2-cli) by jnbr:** Incredible reverse engineering of the RØDECaster Pro II and Duo USB protocol (`rcp2-protocol`, `rcp2-core`), CLI, and mass-storage tooling.
- **The Linux Audio & RØDECaster Reverse Engineering Community:**
  - Community research on `rodecaster-utility` and protocol structures.
  - The [open-caster](https://github.com/) project and Linux driver experimentation.
  - Community work around [rodecaster-control](https://github.com/) and PipeWire routing profiles.

---

## Disclaimer

CasterManager is an independent open-source project and is not affiliated, associated, authorized, endorsed by, or in any way officially connected with RØDE Microphones or Freedman Electronics. All product and company names are trademarks™ or registered® trademarks of their respective holders.

---

## License

This project is licensed under the [MIT License](LICENSE).
