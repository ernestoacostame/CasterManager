# CasterManager

<p align="center">
  <img src="assets/app_icon.png" width="96" height="96" alt="CasterManager Logo" />
</p>

<p align="center">
  <strong>Native Linux Desktop Manager & SMART Pad Controller for RØDECaster Duo and Pro II</strong>
</p

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Linux-orange.svg" alt="Platform Linux" />
  <img src="https://img.shields.io/badge/UI-Qt%206%20%7C%20QML-41cd52.svg" alt="Qt 6 / QML" />
  <img src="https://img.shields.io/badge/Language-Python%20%2F%20Rust-blue.svg" alt="Python / Rust" />
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License MIT" />
</p>

---

<img width="1310" height="900" alt="castermanager_en" src="https://github.com/user-attachments/assets/5d63bcd0-7f43-493e-b1ec-24f439bdbd30" />

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
git clone https://github.com/ernestoacostame/CasterManager.git
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

# CasterManager

<p align="center">
  <img src="assets/app_icon.png" width="96" height="96" alt="Logo de CasterManager" />
</p>

<p align="center">
  <strong>Gestor de escritorio y controlador de SMART Pads para RØDECaster Duo y Pro II en Linux</strong>
</p>


<p align="center">
  <img src="https://img.shields.io/badge/Plataforma-Linux-orange.svg" alt="Plataforma Linux" />
  <img src="https://img.shields.io/badge/Interfaz-Qt%206%20%7C%20QML-41cd52.svg" alt="Qt 6 / QML" />
  <img src="https://img.shields.io/badge/Lenguajes-Python%20%2F%20Rust-blue.svg" alt="Python / Rust" />
  <img src="https://img.shields.io/badge/Licencia-MIT-yellow.svg" alt="Licencia MIT" />
</p>

---

<img width="1310" height="900" alt="castermanager_es" src="https://github.com/user-attachments/assets/6ea37280-6802-4626-8e2a-134a04e29913" />

## Descripción

**CasterManager** es una aplicación de escritorio nativa para Linux diseñada para controlar y configurar las consolas de producción de audio **RØDECaster Duo** y **RØDECaster Pro II**. Construida con Qt 6 (PyQt6 + QML) y respaldada por un motor de protocolo de alto rendimiento en Rust, ofrece control total de pads SMART, transferencia de archivos de audio, parámetros de reproducción y perfiles de show en Linux.

---

## Características Principales

- **🎛️ Gestión de Matriz de SMART Pads:**
  - Disposición visual interactiva 2x3 (Duo) y 2x4 (Pro II) idéntica a la botonera física del hardware.
  - Navegación fluida entre los 8 bancos de pads (hasta 48 o 64 pads en total).
  - Disparo y prueba de pads con un solo clic directamente desde el escritorio.
  - Borrado y limpieza de sonidos asignados con sincronización inmediata en la consola.

- **📁 Importación y Exportación de Audio:**
  - **Carga de sonido:** Selecciona cualquier archivo de audio (`.wav`, `.mp3`, `.ogg`, `.flac`, `.aac`) o arrástralo y suéltalo. La aplicación activa el modo de almacenamiento masivo eMMC, convierte/copia el archivo y remonta el almacenamiento de manera segura.
  - **Exportación de audio:** Guarda el audio asignado a cualquier SMART pad directamente en tu computadora.

- **⚙️ Configuración de Reproducción en Tiempo Real:**
  - **Modos de reproducción:** Alterna entre `Toggle` (reproducir/pausar), `One Shot` (reproducción completa) y `Hold` (mantener pulsado).
  - **Control de bucle:** Activa o desactiva la repetición continua (`Loop On / Off`).
  - **Función Replay:** Reinicio inmediato al pulsar vs. pausar/ignorar.
  - **Ganancia:** Ajusta el volumen de reproducción en tiempo real mediante slider de dB.
  - **Paleta de colores:** Personaliza la iluminación LED de cada pad con los 12 colores nativos del hardware.

- **👤 Personalización de Perfil y Show:**
  - Cambia el nombre del show mostrado en la pantalla de la consola.
  - Personaliza el color del avatar del usuario.

- **🛡️ Demonio Anti-Bloqueo de Hardware en Segundo Plano (`castermanager-drain`):**
  - Resuelve el bug del firmware de RØDE donde la consola se congela al pulsar botones si ningún proceso en Linux está leyendo el endpoint USB HID.
  - Se instala como servicio de usuario en systemd (`castermanager-drain.service`), consumiendo ~0% de CPU y <5 MB de RAM, manteniendo la consola desbloqueada las 24 horas del día.

---

## Requisitos del Sistema

- **Sistema Operativo:** Linux (Arch, Ubuntu, Debian, Fedora, openSUSE, etc.)
- **Python:** 3.10 o superior
- **Qt 6:** `python-pyqt6`, `qt6-declarative` (QML)
- **Herramientas de sistema:** `udev`, `udisksctl`, `lsblk`

### Instalación de Dependencias

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

## Instalación

Clona el repositorio y ejecuta el script de instalación automática:

```bash
git clone https://github.com/ernestoacostame/CasterManager.git
cd CasterManager
./install.sh
```

### Lo que realiza `install.sh`:
1. Verifica las dependencias de Python 3 y PyQt6.
2. Instala las reglas `udev` (`/etc/udev/rules.d/99-castermanager.rules`) para acceso USB HID sin privilegios de root.
3. Instala los quirks de kernel (`/etc/modprobe.d/99-rodecaster-quirks.conf`) para prevenir saturación de buffers.
4. Prepara el binario del backend CLI.
5. Registra, habilita e inicia el servicio en segundo plano (`castermanager-drain.service`) en systemd.
6. Instala los iconos de la aplicación en el tema estándar del sistema (`hicolor`) y crea el lanzador de escritorio (`CasterManager`).

---

## Ejecución

Puedes abrir CasterManager desde el menú de aplicaciones de tu entorno (KDE Plasma, GNOME, etc.) o por terminal con:

```bash
./run.sh
```

---

## Compatibilidad de Hardware

| Modelo | Soportado | Controles Físicos | SMART Pads |
| :--- | :---: | :---: | :---: |
| **RØDECaster Duo** | Sí | 4 Faders, 2 Pots | 6 por banco (2x3) |
| **RØDECaster Pro II** | Sí | 6 Faders, 4 Pots | 8 por banco (2x4) |

---

## Prevención de Bloqueos en Linux (USB HID Quirk)

Las consolas RØDECaster se comunican mediante paquetes USB HID. Una particularidad de su firmware hace que la consola se bloquee indefinidamente si intenta enviar reportes y el host cierra la lectura del dispositivo.

CasterManager soluciona este problema mediante dos capas:
1. **Servicio Systemd de Usuario (`castermanager-drain.service`):** Corre silenciosamente en segundo plano, asegurando que los reportes de progreso y estado sean consumidos en todo momento sin afectar el rendimiento.
2. **Quirk de Módulo de Kernel (`usbhid.quirks`):** Para soporte nativo a nivel de kernel, [`install.sh`](file:///home/elav/Developer/Rodecaster/install.sh) instala `/etc/modprobe.d/99-rodecaster-quirks.conf`. También puedes añadir `usbhid.quirks=0x19f7:0x0093:0x00000400` a la línea de comandos de GRUB (`GRUB_CMDLINE_LINUX_DEFAULT`).

---

## Créditos y Agradecimientos

Este proyecto es posible gracias al trabajo previo y a la investigación de la comunidad open-source:

- **[rcp2-cli](https://github.com/jnbr/rcp2-cli) por jnbr:** Extraordinaria ingeniería inversa del protocolo USB de RØDECaster Pro II y Duo (`rcp2-protocol`, `rcp2-core`), CLI y utilidades de almacenamiento eMMC.
- **Comunidad de Audio y Reverse Engineering de RØDECaster en Linux:**
  - Investigación de la comunidad en `rodecaster-utility`.
  - El proyecto [open-caster](https://github.com/) y experimentación con controladores Linux.
  - El trabajo comunitario en [rodecaster-control](https://github.com/) y perfiles de enrutamiento PipeWire.

---

## Descargo de Responsabilidad (Disclaimer)

CasterManager es un proyecto de código abierto independiente y no está afiliado, asociado, autorizado ni respaldado de ninguna manera por RØDE Microphones ni Freedman Electronics. Todos los nombres de productos y marcas comerciales pertenecen a sus respectivos propietarios.

---

## Licencia

Este proyecto está distribuido bajo la licencia [MIT](LICENSE).

