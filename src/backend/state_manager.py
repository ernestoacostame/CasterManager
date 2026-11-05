import os
import logging
from concurrent.futures import ThreadPoolExecutor
from PyQt6.QtCore import QObject, pyqtSignal, pyqtProperty, pyqtSlot, QVariant, QSettings

from .device_monitor import DeviceMonitor
from .rcp_bridge import RcpBridge, PAD_COLORS

logger = logging.getLogger("CasterManager.state")

DUO_PHYSICAL_ORDER = [0, 3, 1, 4, 2, 5]
PRO_II_PHYSICAL_ORDER = [0, 4, 1, 5, 2, 6, 3, 7]

TRANSLATIONS = {
    "es": {
        "settings": "Configuración",
        "app_language": "Idioma de la aplicación",
        "language_desc": "Selecciona el idioma de la interfaz:",
        "spanish": "Español",
        "english": "English",
        "close": "Cerrar",
        "save": "Guardar",
        "cancel": "Cancelar",
        "home": "Inicio",
        "connected": "Conectada",
        "disconnected": "Desconectada",
        "firmware": "Firmware",
        "microsd": "MicroSD",
        "device_settings": "Configuración",
        "device_disconnected_title": "RØDECaster Desconectada",
        "device_disconnected_desc": "Conecta tu RØDECaster Duo o Pro II por cable USB a tu computadora para comenzar.",
        "permission_notice_title": "Permisos de Dispositivo Requeridos",
        "permission_notice_desc": "Para acceder a la consola sin permisos de root en Linux, ejecuta install.sh.",
        "edit_profile": "Editar Perfil del Show",
        "show_name": "Nombre del Show:",
        "show_placeholder": "Nombre del show...",
        "avatar_color": "Icono/Color:",
        "choose_file": "Elegir Archivo",
        "drag_drop": "Arrastrar y Soltar",
        "export_audio": "Exportar Audio",
        "mode_toggle": "Toggle",
        "mode_oneshot": "One Shot",
        "mode_hold": "Hold",
        "loop_on": "Loop On",
        "loop_off": "Loop Off",
        "replay": "Replay",
        "gain": "Ganancia:",
        "transfer_mode_btn": "Activar Modo Transferencia (Cargar Audios a la Duo)",
        "transfer_mode_title": "Tu RØDECaster está en Modo Transferencia",
        "transfer_mode_desc": "La memoria interna o tarjeta SD está accesible en Linux como almacenamiento masivo USB.",
        "transfer_mode_exit": "Finalizar y Salir del Modo Transferencia",
        "trigger_selected": "▶ Disparar Pad Seleccionado",
        "bank": "Banco",
        "of": "de",
        "pad": "Pad",
        "no_audio_export": "El pad seleccionado no tiene ningún archivo para exportar.",
        "sound_dialog_title": "Seleccionar archivo de sonido para el Pad",
        "export_dialog_title": "Guardar Audio Exportado",
        "audio_files_filter": "Archivos de audio (*.wav *.mp3 *.ogg *.flac *.aac)",
        "all_files_filter": "Todos los archivos (*)",
        "tab_sound": "Sound",
        "tab_fx": "FX Effects",
        "tab_mixer": "Mixer",
        "tab_midi": "MIDI",
        "tab_callme": "CallMe",
        "tab_video": "Video",
        "customize_smart_pads": "Personalizar SMART Pads",
        "scan_device": "Buscar dispositivo ahora",
        "pad_placeholder": "Nombre del Pad...",
        "usb_permission_required": "⚠️ Permiso USB requerido",
        "usb_permission_hint": "Para interactuar con el dispositivo, ejecuta:\n./install.sh en la carpeta del programa",
    },
    "en": {
        "settings": "Settings",
        "app_language": "Application Language",
        "language_desc": "Select the interface language:",
        "spanish": "Español",
        "english": "English",
        "close": "Close",
        "save": "Save",
        "cancel": "Cancel",
        "home": "Home",
        "connected": "Connected",
        "disconnected": "Disconnected",
        "firmware": "Firmware",
        "microsd": "MicroSD",
        "device_settings": "Settings",
        "device_disconnected_title": "RØDECaster Disconnected",
        "device_disconnected_desc": "Connect your RØDECaster Duo or Pro II via USB cable to get started.",
        "permission_notice_title": "Device Permissions Required",
        "permission_notice_desc": "To access the console without root permissions on Linux, run install.sh.",
        "edit_profile": "Edit Show Profile",
        "show_name": "Show Name:",
        "show_placeholder": "Show name...",
        "avatar_color": "Icon/Color:",
        "choose_file": "Choose File",
        "drag_drop": "Drag & Drop",
        "export_audio": "Export Audio",
        "mode_toggle": "Toggle",
        "mode_oneshot": "One Shot",
        "mode_hold": "Hold",
        "loop_on": "Loop On",
        "loop_off": "Loop Off",
        "replay": "Replay",
        "gain": "Gain:",
        "transfer_mode_btn": "Activate Transfer Mode (Upload Audio to Duo)",
        "transfer_mode_title": "Your RØDECaster is in Transfer Mode",
        "transfer_mode_desc": "Internal memory or SD card is accessible in Linux as USB mass storage.",
        "transfer_mode_exit": "Finish and Exit Transfer Mode",
        "trigger_selected": "▶ Trigger Selected Pad",
        "bank": "Bank",
        "of": "of",
        "pad": "Pad",
        "no_audio_export": "The selected pad has no audio assigned to export.",
        "sound_dialog_title": "Select Sound File for Pad",
        "export_dialog_title": "Save Exported Audio",
        "audio_files_filter": "Audio files (*.wav *.mp3 *.ogg *.flac *.aac)",
        "all_files_filter": "All files (*)",
        "tab_sound": "Sound",
        "tab_fx": "FX Effects",
        "tab_mixer": "Mixer",
        "tab_midi": "MIDI",
        "tab_callme": "CallMe",
        "tab_video": "Video",
        "customize_smart_pads": "Customize SMART Pads",
        "scan_device": "Scan for device now",
        "pad_placeholder": "Pad name...",
        "usb_permission_required": "⚠️ USB permission required",
        "usb_permission_hint": "To interact with the device, run:\n./install.sh in the program folder",
    }
}

class StateManager(QObject):
    stateChanged = pyqtSignal()
    padsChanged = pyqtSignal()
    selectedPadChanged = pyqtSignal()
    transferStateChanged = pyqtSignal()
    toastMessage = pyqtSignal(str)
    languageChanged = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.settings = QSettings("CasterManager", "CasterManager")
        self._language = self.settings.value("language", "es")
        self._connected = False
        self._permission_error = False
        self._permission_path = ""
        self._model_name = "RØDECaster Duo"
        self._is_duo = True
        self._firmware = "1.7.7"
        self._serial = ""
        self._show_name = "TuPodcast"
        self._show_icon = 5
        self._sd_used = "0 GB"
        self._sd_total = "119 GB"
        self._sd_percent = 0.0

        self._pad_cols = 2
        self._pad_rows = 3
        self._pads_per_bank = 6
        self._current_bank = 3  # 0-indexed (Bank 4)
        self._selected_pad_index = 0

        self._transfer_mode = False
        self._transfer_status = ""

        self.bridge = RcpBridge()
        self.executor = ThreadPoolExecutor(max_workers=2)

        self.monitor = DeviceMonitor(self)
        self.monitor.device_changed.connect(self._on_device_changed)
        self.monitor.device_disconnected.connect(self._on_device_disconnected)
        self.monitor.permission_issue.connect(self._on_permission_issue)

        # Initialize banks
        self._banks = self._init_empty_banks()

        # Start monitoring
        self.monitor.start()

    def _init_empty_banks(self):
        banks = []
        ppb = self._pads_per_bank
        for b in range(8):
            bank_pads = []
            for p in range(ppb):
                pad = {
                    "idx": b * ppb + p,
                    "pos": p,
                    "name": "",
                    "color_idx": (b * 2 + p) % 12,
                    "color_hex": PAD_COLORS[(b * 2 + p) % 12]["hex"],
                    "type": "empty",
                    "mode": "toggle",
                    "loop": False,
                    "replay": False,
                    "gain": 0.0,
                    "file": ""
                }
                bank_pads.append(pad)
            banks.append(bank_pads)
        return banks

    def _on_device_changed(self, info):
        logger.info(f"RØDECaster connected: {info['display_name']} ({info['product_id']})")
        self._connected = True
        self._model_name = info["display_name"]
        self._is_duo = (info["model_type"] == "Duo")
        self._pads_per_bank = info["pads_per_bank"]
        self._pad_cols = info["pad_cols"]
        self._pad_rows = info["pad_rows"]
        self._serial = info.get("serial", "")
        self._permission_error = not info.get("has_permission", False)
        self._permission_path = info.get("hidraw_node", "")

        self.stateChanged.emit()
        self.padsChanged.emit()
        self.selectedPadChanged.emit()

        if info.get("has_permission"):
            self.executor.submit(self._sync_hardware_state)

    def _on_device_disconnected(self):
        logger.info("RØDECaster disconnected")
        self._connected = False
        self._permission_error = False
        self.stateChanged.emit()

    def _on_permission_issue(self, hidpath):
        self._permission_error = True
        self._permission_path = hidpath
        self.stateChanged.emit()

    def _sync_hardware_state(self):
        # 1. Query device full dump
        dump = self.bridge.dump_state()
        if not dump:
            logger.warning("Could not dump hardware state")
            return

        try:
            def find_node(node, name):
                if node.get("name") == name:
                    return node
                for child in node.get("children", []):
                    res = find_node(child, name)
                    if res:
                        return res
                return None

            # Show Name & Icon
            show_node = find_node(dump, "CURRENTSHOW")
            if show_node:
                props = {k: list(v.values())[0] for k, v in show_node.get("properties", {}).items()}
                if "currentShowName" in props:
                    self._show_name = props["currentShowName"]
                if "currentShowIcon" in props:
                    self._show_icon = int(props["currentShowIcon"])

            # System & Firmware & SD Card
            sys_node = find_node(dump, "SYSTEM")
            if sys_node:
                props = {k: list(v.values())[0] for k, v in sys_node.get("properties", {}).items()}
                if "systemFirmwareVersion" in props:
                    self._firmware = props["systemFirmwareVersion"]
                if "systemName" in props and props["systemName"]:
                    self._model_name = props["systemName"]

                # SD Card volume state
                for c in sys_node.get("children", []):
                    if c.get("name") == "STORAGEVOLUME":
                        vprops = {k: list(v.values())[0] for k, v in c.get("properties", {}).items()}
                        state_str = str(vprops.get("storageVolumeState", ""))
                        if "|" in state_str:
                            parts = state_str.split("|")
                            if len(parts) >= 2 and parts[0].isdigit() and parts[1].isdigit():
                                cap = int(parts[0])
                                free = int(parts[1])
                                if cap > 0:
                                    used = cap - free
                                    cap_gb = cap / (1024 ** 3)
                                    used_gb = used / (1024 ** 3)
                                    self._sd_total = f"{cap_gb:.0f} GB"
                                    self._sd_used = f"{used_gb:.0f} GB"
                                    self._sd_percent = (used / cap) * 100.0

            # Get current active bank from hardware
            out, _ = self.bridge.run_cmd(["pad", "bank", "--json"])
            if out:
                import json
                try:
                    bank_info = json.loads(out)
                    if "selected" in bank_info:
                        self._current_bank = bank_info["selected"]
                except Exception:
                    pass

            # Populate Pads from SOUNDPADS
            soundpads_node = find_node(dump, "SOUNDPADS")
            if soundpads_node:
                pads_per_bank = 6 if self._is_duo else 8
                self._banks = self._init_empty_banks()

                for c in soundpads_node.get("children", []):
                    p = {k: list(v.values())[0] for k, v in c.get("properties", {}).items()}
                    idx = p.get("padIdx")
                    if idx is None:
                        continue
                    idx = int(idx)
                    bank = idx // pads_per_bank
                    pos = idx % pads_per_bank

                    if bank < 8:
                        color_idx = int(p.get("padColourIndex", 0)) % 12
                        pad_type_raw = p.get("padType", 0)
                        if pad_type_raw in (0, 1):
                            ptype = "sound" if p.get("padName") or p.get("padFilePath") else "empty"
                        elif pad_type_raw == 2:
                            ptype = "fx"
                        else:
                            ptype = "mixer"

                        play_mode_val = p.get("padPlayMode", 0)
                        if play_mode_val == 0:
                            mode = "toggle"
                        elif play_mode_val == 1:
                            mode = "oneshot"
                        else:
                            mode = "hold"

                        pad_entry = {
                            "idx": idx,
                            "pos": pos,
                            "name": p.get("padName", "").replace("_", " "),
                            "color_idx": color_idx,
                            "color_hex": PAD_COLORS[color_idx]["hex"],
                            "type": ptype,
                            "mode": mode,
                            "loop": bool(p.get("padLoop", False)),
                            "replay": bool(p.get("padReplay", False)),
                            "gain": float(p.get("padGain", 0.0)),
                            "file": p.get("padFilePath", "")
                        }
                        self._banks[bank][pos] = pad_entry

            logger.info("Successfully synced hardware state!")
            self.stateChanged.emit()
            self.padsChanged.emit()
            self.selectedPadChanged.emit()
            self.toastMessage.emit(f"Sincronizado con {self._model_name}")

        except Exception as e:
            logger.error(f"Error parsing hardware state: {e}")

    # Properties
    @pyqtProperty(bool, notify=stateChanged)
    def connected(self):
        return self._connected

    @pyqtProperty(bool, notify=stateChanged)
    def permissionError(self):
        return self._permission_error

    @pyqtProperty(str, notify=stateChanged)
    def permissionPath(self):
        return self._permission_path

    @pyqtProperty(str, notify=languageChanged)
    def language(self):
        return self._language

    @pyqtProperty(QVariant, notify=languageChanged)
    def strings(self):
        return TRANSLATIONS.get(self._language, TRANSLATIONS["es"])

    @pyqtSlot(str)
    def setLanguage(self, lang):
        if lang in ("es", "en") and lang != self._language:
            self._language = lang
            self.settings.setValue("language", lang)
            self.languageChanged.emit()
            msg = "Idioma cambiado a Español" if lang == "es" else "Language changed to English"
            self.toastMessage.emit(msg)

    @pyqtProperty(str, notify=stateChanged)
    def modelName(self):
        return self._model_name

    @pyqtProperty(bool, notify=stateChanged)
    def isDuo(self):
        return self._is_duo

    @pyqtProperty(str, notify=stateChanged)
    def firmwareVersion(self):
        return self._firmware

    @pyqtProperty(str, notify=stateChanged)
    def serialNumber(self):
        return self._serial

    @pyqtProperty(str, notify=stateChanged)
    def showName(self):
        return self._show_name

    @pyqtProperty(int, notify=stateChanged)
    def showIcon(self):
        return self._show_icon

    @pyqtProperty(str, notify=stateChanged)
    def sdCardUsed(self):
        return self._sd_used

    @pyqtProperty(str, notify=stateChanged)
    def sdCardTotal(self):
        return self._sd_total

    @pyqtProperty(float, notify=stateChanged)
    def sdCardPercent(self):
        return self._sd_percent

    @pyqtProperty(int, notify=stateChanged)
    def padCols(self):
        return self._pad_cols

    @pyqtProperty(int, notify=stateChanged)
    def padRows(self):
        return self._pad_rows

    @pyqtProperty(int, notify=stateChanged)
    def padsPerBank(self):
        return self._pads_per_bank

    @pyqtProperty(int, notify=stateChanged)
    def currentBank(self):
        return self._current_bank

    @pyqtProperty(int, notify=stateChanged)
    def currentBankDisplay(self):
        return self._current_bank + 1

    @pyqtProperty(int, notify=selectedPadChanged)
    def selectedPadIndex(self):
        return self._selected_pad_index

    @pyqtProperty(QVariant, notify=padsChanged)
    def currentPads(self):
        order = DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER
        bank = self._banks[self._current_bank]

        ordered_pads = []
        for display_idx in range(self._pads_per_bank):
            logical_pos = order[display_idx] if display_idx < len(order) else display_idx
            ordered_pads.append(dict(bank[logical_pos]))
        return ordered_pads

    @pyqtProperty(QVariant, notify=selectedPadChanged)
    def selectedPad(self):
        order = DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER
        logical_pos = order[self._selected_pad_index] if self._selected_pad_index < len(order) else self._selected_pad_index
        return dict(self._banks[self._current_bank][logical_pos])

    @pyqtProperty(bool, notify=transferStateChanged)
    def transferModeActive(self):
        return self._transfer_mode

    @pyqtProperty(str, notify=transferStateChanged)
    def transferStatusText(self):
        return self._transfer_status

    # Slots
    @pyqtSlot(int)
    def selectBank(self, bank):
        if 0 <= bank < 8:
            self._current_bank = bank
            if self._connected and not self._permission_error:
                self.executor.submit(self.bridge.set_bank, bank)
            self.stateChanged.emit()
            self.padsChanged.emit()
            self.selectedPadChanged.emit()

    @pyqtSlot()
    def nextBank(self):
        self.selectBank((self._current_bank + 1) % 8)

    @pyqtSlot()
    def prevBank(self):
        self.selectBank((self._current_bank - 1 + 8) % 8)

    @pyqtSlot(int)
    def selectPad(self, display_index):
        if 0 <= display_index < self._pads_per_bank:
            self._selected_pad_index = display_index
            self.selectedPadChanged.emit()

    @pyqtSlot(int)
    def triggerPad(self, display_index):
        if 0 <= display_index < self._pads_per_bank:
            self.selectPad(display_index)
            order = DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER
            logical_pos = order[display_index] if display_index < len(order) else display_index
            pad = self._banks[self._current_bank][logical_pos]

            logger.info(f"Triggering Pad {display_index} (name: '{pad.get('name')}') on Bank {self._current_bank + 1}")
            if self._connected and not self._permission_error:
                self.executor.submit(self.bridge.trigger_pad, self._current_bank, display_index)
            self.toastMessage.emit(f"Pulsado: {pad.get('name') or f'Pad {display_index+1}'}")

    @pyqtSlot(str)
    def updatePadName(self, name):
        order = DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER
        logical_pos = order[self._selected_pad_index] if self._selected_pad_index < len(order) else self._selected_pad_index
        pad = self._banks[self._current_bank][logical_pos]
        pad["name"] = name
        if pad["type"] == "empty" and name:
            pad["type"] = "sound"
        self.padsChanged.emit()
        self.selectedPadChanged.emit()

        if self._connected and not self._permission_error:
            self.executor.submit(
                self.bridge.run_cmd,
                ["pad", "set-prop", str(self._current_bank), str(self._selected_pad_index), "padName", f"str:{name}"]
            )
            self.toastMessage.emit(f"Nombre guardado: {name}")

    @pyqtSlot(int)
    def updatePadColor(self, color_idx):
        if 0 <= color_idx < len(PAD_COLORS):
            order = DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER
            logical_pos = order[self._selected_pad_index] if self._selected_pad_index < len(order) else self._selected_pad_index
            pad = self._banks[self._current_bank][logical_pos]
            pad["color_idx"] = color_idx
            pad["color_hex"] = PAD_COLORS[color_idx]["hex"]
            self.padsChanged.emit()
            self.selectedPadChanged.emit()

            if self._connected and not self._permission_error:
                self.executor.submit(
                    self.bridge.run_cmd,
                    ["pad", "set-prop", str(self._current_bank), str(self._selected_pad_index), "padColourIndex", f"u32:{color_idx}"]
                )

    @pyqtSlot(str)
    def updatePadPlayMode(self, mode):
        order = DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER
        logical_pos = order[self._selected_pad_index] if self._selected_pad_index < len(order) else self._selected_pad_index
        pad = self._banks[self._current_bank][logical_pos]
        pad["mode"] = mode
        self.padsChanged.emit()
        self.selectedPadChanged.emit()

        mode_name = "Toggle (Reproducir/Pausar)" if mode == "toggle" else ("One Shot (Completo)" if mode == "oneshot" else "Hold (Mantener)")
        self.toastMessage.emit(f"Modo: {mode_name}")

        mode_val = 0 if mode == "toggle" else (1 if mode == "oneshot" else 2)
        if self._connected and not self._permission_error:
            def do_update():
                self.bridge.run_cmd(
                    ["pad", "set-prop", str(self._current_bank), str(self._selected_pad_index), "padPlayMode", f"u32:{mode_val}"]
                )
                self._sync_hardware_state()
            self.executor.submit(do_update)

    @pyqtSlot(bool)
    def updatePadLoop(self, loop):
        order = DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER
        logical_pos = order[self._selected_pad_index] if self._selected_pad_index < len(order) else self._selected_pad_index
        pad = self._banks[self._current_bank][logical_pos]
        pad["loop"] = loop
        self.padsChanged.emit()
        self.selectedPadChanged.emit()

        self.toastMessage.emit("Bucle: " + ("Activado (Loop On)" if loop else "Desactivado (Loop Off)"))

        val_str = "bool:true" if loop else "bool:false"
        if self._connected and not self._permission_error:
            def do_update():
                self.bridge.run_cmd(
                    ["pad", "set-prop", str(self._current_bank), str(self._selected_pad_index), "padLoop", val_str]
                )
                self._sync_hardware_state()
            self.executor.submit(do_update)

    @pyqtSlot(bool)
    def updatePadReplay(self, replay):
        order = DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER
        logical_pos = order[self._selected_pad_index] if self._selected_pad_index < len(order) else self._selected_pad_index
        pad = self._banks[self._current_bank][logical_pos]
        pad["replay"] = replay
        self.padsChanged.emit()
        self.selectedPadChanged.emit()

        self.toastMessage.emit("Replay: " + ("Activado (Reiniciar al pulsar)" if replay else "Desactivado (Pausar al pulsar)"))

        val_str = "bool:true" if replay else "bool:false"
        if self._connected and not self._permission_error:
            def do_update():
                self.bridge.run_cmd(
                    ["pad", "set-prop", str(self._current_bank), str(self._selected_pad_index), "padReplay", val_str]
                )
                self._sync_hardware_state()
            self.executor.submit(do_update)

    @pyqtSlot(float)
    def updatePadGain(self, gain):
        order = DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER
        logical_pos = order[self._selected_pad_index] if self._selected_pad_index < len(order) else self._selected_pad_index
        pad = self._banks[self._current_bank][logical_pos]
        pad["gain"] = gain
        self.padsChanged.emit()
        self.selectedPadChanged.emit()

        if self._connected and not self._permission_error:
            def do_update():
                self.bridge.run_cmd(
                    ["pad", "set-prop", str(self._current_bank), str(self._selected_pad_index), "padGain", f"f64:{gain}"]
                )
            self.executor.submit(do_update)

    @pyqtSlot(str, str)
    def uploadSoundFile(self, file_path, pad_name):
        clean_path = file_path.replace("file://", "")
        if not os.path.isfile(clean_path):
            self.toastMessage.emit("Archivo no encontrado")
            return

        order = DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER
        logical_pos = order[self._selected_pad_index] if self._selected_pad_index < len(order) else self._selected_pad_index
        pad = self._banks[self._current_bank][logical_pos]

        name = pad_name or os.path.splitext(os.path.basename(clean_path))[0]
        pad["name"] = name
        pad["file"] = os.path.basename(clean_path)
        pad["type"] = "sound"

        self.padsChanged.emit()
        self.selectedPadChanged.emit()
        self.toastMessage.emit(f"Subiendo a la Duo: {name}...")

        def do_upload():
            out, err = self.bridge.run_cmd([
                "pad", "upload",
                str(self._current_bank),
                str(self._selected_pad_index),
                clean_path,
                "--name", name
            ], timeout=45)
            if err:
                logger.error(f"Upload error: {err}")
                self.toastMessage.emit(f"Error al subir: {err}")
            else:
                logger.info(f"Upload finished: {out}")
                self.toastMessage.emit(f"Audio cargado con éxito en Pad {self._selected_pad_index + 1}!")
                self._sync_hardware_state()

        self.executor.submit(do_upload)

    @pyqtSlot()
    def clearCurrentPad(self):
        order = DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER
        logical_pos = order[self._selected_pad_index] if self._selected_pad_index < len(order) else self._selected_pad_index
        pad = self._banks[self._current_bank][logical_pos]
        pad["name"] = ""
        pad["file"] = ""
        pad["type"] = "empty"
        self.padsChanged.emit()
        self.selectedPadChanged.emit()

        if self._connected and not self._permission_error:
            def do_clear():
                out, err = self.bridge.run_cmd(
                    ["pad", "clear", str(self._current_bank), str(self._selected_pad_index)]
                )
                if err:
                    logger.error(f"Error clearing pad: {err}")
                    self.toastMessage.emit(f"Error al limpiar: {err}")
                else:
                    logger.info("Pad cleared successfully on hardware")
                    self.toastMessage.emit("Pad limpiado en la Rodecaster")
                    self._sync_hardware_state()

            self.executor.submit(do_clear)

    @pyqtSlot(str)
    def exportCurrentPad(self, target_filepath):
        order = DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER
        logical_pos = order[self._selected_pad_index] if self._selected_pad_index < len(order) else self._selected_pad_index
        pad = self._banks[self._current_bank][logical_pos]

        if not pad.get("file") or pad.get("type") == "empty":
            self.toastMessage.emit("El pad seleccionado no tiene ningún archivo asignado para exportar.")
            return

        clean_path = target_filepath
        if clean_path.startswith("file://"):
            clean_path = clean_path[7:]

        pad_name = pad.get("name") or "Pad"
        self.toastMessage.emit(f"Exportando audio '{pad_name}'...")
        self._transfer_mode = True
        self._transfer_status = f"Exportando audio de '{pad_name}'..."
        self.transferStateChanged.emit()

        if self._connected and not self._permission_error:
            def do_export():
                try:
                    out, err = self.bridge.run_cmd(
                        ["pad", "export", str(self._current_bank), str(self._selected_pad_index), clean_path],
                        timeout=90
                    )
                    if err:
                        logger.error(f"Error exporting pad: {err}")
                        self.toastMessage.emit(f"Error al exportar: {err}")
                    else:
                        filename = os.path.basename(clean_path)
                        logger.info(f"Export finished successfully: {out}")
                        self.toastMessage.emit(f"¡Audio guardado exitosamente como {filename}!")
                except Exception as e:
                    logger.error(f"Export exception: {e}")
                    self.toastMessage.emit(f"Error al exportar: {e}")
                finally:
                    self._transfer_mode = False
                    self._transfer_status = ""
                    self.transferStateChanged.emit()

            self.executor.submit(do_export)
        else:
            self._transfer_mode = False
            self.transferStateChanged.emit()
            self.toastMessage.emit("No hay conexión con la Rodecaster.")

    @pyqtSlot(str)
    def updateShowName(self, name):
        self._show_name = name
        self.stateChanged.emit()
        if self._connected and not self._permission_error:
            self.executor.submit(
                self.bridge.run_cmd,
                ["show", "set-name", name]
            )
            self.toastMessage.emit(f"Nombre de show actualizado: {name}")

    @pyqtSlot(int)
    def updateShowIcon(self, icon_idx):
        self._show_icon = icon_idx
        self.stateChanged.emit()
        if self._connected and not self._permission_error:
            self.executor.submit(
                self.bridge.run_cmd,
                ["show", "set-icon", str(icon_idx)]
            )
            self.toastMessage.emit(f"Icono de show actualizado")

    @pyqtSlot()
    def enterTransferMode(self):
        self._transfer_mode = True
        self._transfer_status = "RØDECaster en Modo Transferencia (Almacenamiento masivo USB activo)"
        self.transferStateChanged.emit()

    @pyqtSlot()
    def exitTransferMode(self):
        self._transfer_mode = False
        self._transfer_status = ""
        self.transferStateChanged.emit()

    @pyqtSlot()
    def refresh(self):
        self.monitor.scan_devices()
        if self._connected and not self._permission_error:
            self.executor.submit(self._sync_hardware_state)
        self.toastMessage.emit("Sincronizando...")
