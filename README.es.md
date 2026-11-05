# CasterManager

<p align="center">
  <img src="assets/app_icon.png" width="96" height="96" alt="Logo de CasterManager" />
</p>

<p align="center">
  <strong>Gestor de escritorio y controlador de SMART Pads para RØDECaster Duo y Pro II en Linux</strong>
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README.es.md"><strong>Español</strong></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Plataforma-Linux-orange.svg" alt="Plataforma Linux" />
  <img src="https://img.shields.io/badge/Interfaz-Qt%206%20%7C%20QML-41cd52.svg" alt="Qt 6 / QML" />
  <img src="https://img.shields.io/badge/Lenguajes-Python%20%2F%20Rust-blue.svg" alt="Python / Rust" />
  <img src="https://img.shields.io/badge/Licencia-MIT-yellow.svg" alt="Licencia MIT" />
</p>

---

![Captura de pantalla de CasterManager](docs/screenshot.png)

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
git clone https://github.com/TU_USUARIO/CasterManager.git
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

## Apoyo y Donaciones

Si encuentras útil **CasterManager** y te gustaría apoyar su desarrollo continuo, mantenimiento y soporte de hardware de audio en Linux, puedes considerar hacer una donación:

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/ernestoacostame)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/ernestoacostame)
[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://www.paypal.com/paypalme/elav)

- ☕ **Buy Me a Coffee:** [buymeacoffee.com/ernestoacostame](https://www.buymeacoffee.com/ernestoacostame)
- 💖 **Ko-fi:** [ko-fi.com/ernestoacostame](https://ko-fi.com/ernestoacostame)
- 🅿️ **PayPal:** [paypal.com/paypalme/elav](https://www.paypal.com/paypalme/elav)

¡Muchas gracias por tu apoyo!

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
