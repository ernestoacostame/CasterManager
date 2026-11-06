import os
import logging
from concurrent.futures import ThreadPoolExecutor
from PyQt6.QtCore import QObject, pyqtSignal, pyqtProperty, pyqtSlot, QVariant, QSettings, QTimer

from .device_monitor import DeviceMonitor
from .rcp_bridge import RcpBridge, PAD_COLORS

logger = logging.getLogger("CasterManager.state")

DUO_PHYSICAL_ORDER = [0, 3, 1, 4, 2, 5]
PRO_II_PHYSICAL_ORDER = [0, 4, 1, 5, 2, 6, 3, 7]

FACTORY_SOUNDS = [
    {"id": "applause", "name": "Applause", "filename": "Applause.wav"},
    {"id": "airhorn", "name": "Airhorn", "filename": "Airhorn.wav"},
    {"id": "crickets", "name": "Crickets", "filename": "Crickets.wav"},
    {"id": "rim_shot", "name": "Rim Shot", "filename": "Rim_Shot.wav"},
    {"id": "trombone", "name": "Trombone", "filename": "Trombone.wav"},
    {"id": "music_bed", "name": "Music Bed", "filename": "Music_Bed.wav"},
    {"id": "chimes", "name": "Chimes", "filename": "Chimes.wav"},
    {"id": "record_scratch", "name": "Record Scratch", "filename": "Record_Scratch.wav"},
]

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
        "tab_sound": "Sonido",
        "tab_fx": "Efectos FX",
        "tab_mixer": "Mezclador",
        "tab_midi": "MIDI",
        "tab_callme": "CallMe",
        "tab_video": "Vídeo",
        "customize_smart_pads": "Personalizar SMART Pads",
        "scan_device": "Buscar dispositivo ahora",
        "pad_placeholder": "Nombre del Pad...",
        "usb_permission_required": "⚠️ Permiso USB requerido",
        "usb_permission_hint": "Para interactuar con el dispositivo, ejecuta:\n./install.sh en la carpeta del programa",
        "hub_audio_setup": "Configuración de Audio",
        "hub_audio_setup_desc": "Faders, canales, enrutamiento y vúmetros en vivo",
        "hub_device_config": "Configuración del Dispositivo",
        "hub_device_config_desc": "Salidas, pantalla, brillo, vúmetros y sistema",
        "hub_smart_pads": "Personalizar SMART Pads",
        "hub_smart_pads_desc": "Sonidos, efectos de voz, censura y comandos MIDI",
        "hub_recordings": "Transferir Grabaciones",
        "hub_recordings_desc": "Gestiona podcasts y tomas grabadas en la MicroSD",
        "tab_output": "Salida",
        "tab_display": "Pantalla",
        "tab_system": "Sistema",
        "headphones": "Auriculares",
        "monitor": "Monitores",
        "routing": "Enrutamiento",
        "listen": "Escucha (Solo)",
        "multitrack": "Multipista",
        "processing": "Procesamiento",
        "brightness": "Brillo",
        "metering": "Vúmetros",
        "haptics": "Respuesta Háptica",
        "rec_button": "Botón REC",
        "display_brightness": "Pantalla",
        "buttons_brightness": "Botones",
        "auto_brightness": "Brillo Automático",
        "dim_after": "Atenuar tras",
        "auto_mute_output": "Silenciar monitores al subir fader de micrófono",
        "auto_mute_bt": "Silenciar Bluetooth al subir micrófono",
        "fixed_output_level": "Nivel de salida fijo (Línea)",
        "pre_fader_listen": "Escucha Pre-Fader (PFL)",
        "after_fader_listen": "Escucha Post-Fader (AFL)",
        "midi_control": "Control MIDI",
        "midi_control_desc": "Permitir comunicación MIDI bidireccional por USB",
        "information": "Información",
        "serial_number": "Número de Serie",
        "reset_device": "Restablecer Consola",
        "factory_sounds": "Sonidos de Fábrica",
        "load_factory_sound": "Cargar sonido oficial RØDE",
        "rec_start": "Grabar",
        "rec_pause": "Pausar",
        "rec_stop": "Detener",
        "drop_marker": "Poner Marca",
        "faders_title": "Mezclador de Faders en Vivo",
        "input_sources_pool": "Fuentes de Entrada Disponibles",
        "latching": "Latching (Fijo)",
        "momentary": "Momentary (Pulsar)",
        "target_channels": "Canales Destino",
        "censor_bleep": "Censura (Bleep)",
        "trash_talk": "Trash Talk",
        "ducking": "Ducking",
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
        "hub_audio_setup": "Audio Setup",
        "hub_audio_setup_desc": "Live fader strips, channel routing and VU meters",
        "hub_device_config": "Device Configuration",
        "hub_device_config_desc": "Outputs, display, brightness, metering and system",
        "hub_smart_pads": "Customize SMART Pads",
        "hub_smart_pads_desc": "Sounds, voice effects, censor bleep and MIDI commands",
        "hub_recordings": "Transfer Recordings",
        "hub_recordings_desc": "Manage podcast takes recorded on the MicroSD card",
        "tab_output": "Output",
        "tab_display": "Display",
        "tab_system": "System",
        "headphones": "Headphones",
        "monitor": "Monitor",
        "routing": "Routing",
        "listen": "Listen (Solo)",
        "multitrack": "Multitrack",
        "processing": "Processing",
        "brightness": "Brightness",
        "metering": "Metering",
        "haptics": "Haptics",
        "rec_button": "REC Button",
        "display_brightness": "Display",
        "buttons_brightness": "Buttons",
        "auto_brightness": "Automatic Brightness",
        "dim_after": "Dim After",
        "auto_mute_output": "Auto-mute monitor output when fader is raised",
        "auto_mute_bt": "Auto-mute Bluetooth when microphone is live",
        "fixed_output_level": "Fixed Output Level (Line)",
        "pre_fader_listen": "Pre-fader Listen (PFL)",
        "after_fader_listen": "After-fader Listen (AFL)",
        "midi_control": "MIDI Control",
        "midi_control_desc": "Allow bi-directional MIDI communication over USB",
        "information": "Information",
        "serial_number": "Serial Number",
        "reset_device": "Reset Device",
        "factory_sounds": "Factory Sounds",
        "load_factory_sound": "Load official RØDE sound",
        "rec_start": "Record",
        "rec_pause": "Pause",
        "rec_stop": "Stop",
        "drop_marker": "Drop Marker",
        "faders_title": "Live Fader Mixer",
        "input_sources_pool": "Available Input Sources",
        "latching": "Latching",
        "momentary": "Momentary",
        "target_channels": "Target Channels",
        "censor_bleep": "Censor (Bleep)",
        "trash_talk": "Trash Talk",
        "ducking": "Ducking",
    }
}

class StateManager(QObject):
    stateChanged = pyqtSignal()
    padsChanged = pyqtSignal()
    selectedPadChanged = pyqtSignal()
    transferStateChanged = pyqtSignal()
    toastMessage = pyqtSignal(str)
    languageChanged = pyqtSignal()
    viewChanged = pyqtSignal()
    fadersChanged = pyqtSignal()
    recordingChanged = pyqtSignal()
    deviceConfigChanged = pyqtSignal()
    recordingsChanged = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.settings = QSettings("CasterManager", "CasterManager")
        self._language = self.settings.value("language", "es")
        self._current_view = "home"
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
        self._mount_point = ""
        self._recordings = []

        # Live Recording State
        self._is_recording = False
        self._record_time_ms = 0

        # Device Configuration State (Display, Outputs, System)
        self._screen_brightness = 250
        self._button_brightness = 255
        self._auto_brightness = False
        self._dim_after_sec = 0
        self._broadcast_meters = False
        self._haptic_feedback = 1
        self._headphone1_type = 0
        self._headphone2_type = 0
        self._monitor_auto_mute = True
        self._bt_auto_mute = False
        self._monitor_fixed_level = False
        self._listen_prefader = False
        self._multitrack_mode = 2
        self._midi_control = False

        self.bridge = RcpBridge()
        self.executor = ThreadPoolExecutor(max_workers=2)

        # Debounced brightness timer
        self._brightness_timer = QTimer(self)
        self._brightness_timer.setSingleShot(True)
        self._brightness_timer.setInterval(180)
        self._brightness_timer.timeout.connect(self._flush_brightness_hardware)
        self._pending_screen_brightness = None
        self._pending_button_brightness = None

        # Debounced fader levels timer
        self._fader_timer = QTimer(self)
        self._fader_timer.setSingleShot(True)
        self._fader_timer.setInterval(120)
        self._fader_timer.timeout.connect(self._flush_faders_hardware)
        self._pending_fader_levels = {}

        # Faders state
        self._faders = self._init_default_faders()

        # Polling timer for live fader & recording status
        self._live_poll_timer = QTimer(self)
        self._live_poll_timer.setInterval(3000)
        self._live_poll_timer.timeout.connect(self._poll_live_hardware)
        self._live_poll_timer.start()

        self.monitor = DeviceMonitor(self)
        self.monitor.device_changed.connect(self._on_device_changed)
        self.monitor.device_disconnected.connect(self._on_device_disconnected)
        self.monitor.permission_issue.connect(self._on_permission_issue)

        # Initialize banks
        self._banks = self._init_empty_banks()

        # Start monitoring
        self.monitor.start()

    def _init_default_faders(self):
        phys_limit = 4 if self._is_duo else 6
        return [
            {"index": 0, "name": "Mic 1", "color": "#FF3C3C", "icon": "mic", "level": 70, "mute": False, "listen": False, "is_virtual": False},
            {"index": 1, "name": "Mic 2 / Chat", "color": "#28C850", "icon": "chat", "level": 70, "mute": False, "listen": False, "is_virtual": False},
            {"index": 2, "name": "USB 1", "color": "#FF8C28", "icon": "usb", "level": 70, "mute": False, "listen": False, "is_virtual": False},
            {"index": 3, "name": "USB 2", "color": "#A050E6", "icon": "usb", "level": 70, "mute": False, "listen": False, "is_virtual": False},
            {"index": 4, "name": "SMART Pads", "color": "#FF3C3C", "icon": "pads", "level": 70, "mute": False, "listen": False, "is_virtual": True},
            {"index": 5, "name": "Bluetooth", "color": "#3C96FF", "icon": "bluetooth", "level": 70, "mute": False, "listen": False, "is_virtual": True},
        ]

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

                # Storage Volumes (MicroSD card, external USB, internal eMMC)
                sd_volume = None
                internal_volume = None

                for c in sys_node.get("children", []):
                    if c.get("name") == "STORAGEVOLUME":
                        vprops = {k: list(v.values())[0] for k, v in c.get("properties", {}).items()}
                        state_str = str(vprops.get("storageVolumeState", ""))
                        if "|" in state_str:
                            parts = state_str.split("|")
                            if len(parts) >= 3 and parts[0].isdigit() and parts[1].isdigit():
                                cap = int(parts[0])
                                free = int(parts[1])
                                removable = (parts[2] == "1")
                                vol_info = {
                                    "cap": cap,
                                    "free": free,
                                    "removable": removable,
                                    "rec_dest": vprops.get("storageVolumeRecDestination", False)
                                }
                                if removable and cap > 0:
                                    sd_volume = vol_info
                                elif not removable and cap > 0:
                                    internal_volume = vol_info

                # Prioritize MicroSD card when inserted; otherwise fallback to internal memory
                active_vol = sd_volume if sd_volume else internal_volume
                if active_vol:
                    cap = active_vol["cap"]
                    free = active_vol["free"]
                    used = max(0, cap - free)
                    cap_gb = cap / (1024 ** 3)
                    used_gb = used / (1024 ** 3)
                    self._sd_total = f"{cap_gb:.0f} GB"
                    if used_gb >= 10:
                        self._sd_used = f"{used_gb:.0f} GB"
                    elif used_gb >= 0.1:
                        self._sd_used = f"{used_gb:.1f} GB"
                    else:
                        self._sd_used = "0 GB"
                    self._sd_percent = (used / cap) * 100.0 if cap > 0 else 0.0

            # GUI Settings (Brightness, Meters)
            gui_node = find_node(dump, "GUI")
            if gui_node:
                gprops = {k: list(v.values())[0] for k, v in gui_node.get("properties", {}).items()}
                if "screenBrightness" in gprops:
                    self._screen_brightness = int(gprops["screenBrightness"])
                if "activeButtonsBrightness" in gprops:
                    self._button_brightness = int(gprops["activeButtonsBrightness"])
                if "autoBrightness" in gprops:
                    self._auto_brightness = bool(gprops["autoBrightness"])
                if "metering" in gprops:
                    self._broadcast_meters = (int(gprops["metering"]) == 1)
                elif "broadcastMeters" in gprops:
                    self._broadcast_meters = bool(gprops["broadcastMeters"])
                if "screenDimAfterSeconds" in gprops:
                    try:
                        self._dim_after_sec = int(gprops["screenDimAfterSeconds"])
                    except (ValueError, TypeError):
                        self._dim_after_sec = 0

            # Recorder state
            rec_node = find_node(dump, "RECORDER")
            if rec_node:
                rprops = {k: list(v.values())[0] for k, v in rec_node.get("properties", {}).items()}
                self._is_recording = (rprops.get("recordState", 0) == 2)
                self._record_time_ms = int(rprops.get("recordTimeMs", 0))

            # Outputs and Headphones
            out_node = find_node(dump, "OUTPUT")
            if out_node:
                oprops = {k: list(v.values())[0] for k, v in out_node.get("properties", {}).items()}
                if "outputMonAutoMute" in oprops:
                    self._monitor_auto_mute = bool(oprops["outputMonAutoMute"])
                if "outputBTAutoMute" in oprops:
                    self._bt_auto_mute = bool(oprops["outputBTAutoMute"])
                if "outputMonFixed" in oprops:
                    self._monitor_fixed_level = bool(oprops["outputMonFixed"])
                if "outputPrefader" in oprops:
                    self._listen_prefader = bool(oprops["outputPrefader"])
                if "recordingMultitrackMode" in oprops:
                    self._multitrack_mode = int(oprops["recordingMultitrackMode"])

            # System settings (Haptics, MIDI)
            if sys_node:
                sprops = {k: list(v.values())[0] for k, v in sys_node.get("properties", {}).items()}
                if "systemHapticSetting" in sprops:
                    self._haptic_feedback = int(sprops["systemHapticSetting"])
                if "systemMidiControl" in sprops:
                    self._midi_control = bool(sprops["systemMidiControl"])
                if "systemSerialNumber" in sprops and sprops["systemSerialNumber"] != "REDACTED":
                    self._serial = sprops["systemSerialNumber"]

            # Headphone nodes (children 9 and 10)
            children = dump.get("children", [])
            hp_nodes = [c for c in children if c.get("name") == "HEADPHONE"]
            if len(hp_nodes) >= 1:
                hp1_props = {k: list(v.values())[0] for k, v in hp_nodes[0].get("properties", {}).items()}
                self._headphone1_type = int(hp1_props.get("headphoneType", 0))
            if len(hp_nodes) >= 2:
                hp2_props = {k: list(v.values())[0] for k, v in hp_nodes[1].get("properties", {}).items()}
                self._headphone2_type = int(hp2_props.get("headphoneType", 0))

            # Live Faders
            fout, _ = self.bridge.run_cmd(["fader", "list", "--json"])
            if fout:
                import json
                try:
                    f_list = json.loads(fout)
                    for item in f_list:
                        idx = item.get("index", 0)
                        if 0 <= idx < len(self._faders):
                            self._faders[idx]["mute"] = bool(item.get("mute", False))
                            self._faders[idx]["listen"] = bool(item.get("listen", False))
                            self._faders[idx]["level"] = int(round(float(item.get("level", 0.7)) * 100))
                except Exception as e:
                    logger.debug(f"Error parsing fader list: {e}")

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
                            "file": p.get("padFilePath", ""),
                            "fx_id": int(p.get("padTriggerControl", 8)),
                            "fx_channel": int(p.get("padEffectInput", 0)),
                            "fx_mode": int(p.get("padEffectTriggerMode", 1))
                        }
                        self._banks[bank][pos] = pad_entry

            logger.info("Successfully synced hardware state!")
            self.stateChanged.emit()
            self.padsChanged.emit()
            self.selectedPadChanged.emit()
            self.fadersChanged.emit()
            self.recordingChanged.emit()
            self.deviceConfigChanged.emit()
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

    @pyqtProperty(QVariant, notify=recordingsChanged)
    def recordings(self):
        return self._recordings

    @pyqtProperty(str, notify=transferStateChanged)
    def mountPoint(self):
        return self._mount_point

    def _scan_recordings(self, mount_point=None):
        import glob
        import xml.etree.ElementTree as ET
        from datetime import datetime

        recordings = []
        candidates = []
        if mount_point and os.path.isdir(mount_point):
            candidates.append(mount_point)

        candidates.extend(glob.glob("/run/media/*/RodeCaster"))
        candidates.extend(glob.glob("/media/*/RodeCaster"))

        found_dir = None
        for c in candidates:
            rode_dir = os.path.join(c, "RODECaster")
            if os.path.isdir(rode_dir):
                found_dir = rode_dir
                break
            elif os.path.isdir(c):
                found_dir = c
                break

        if not found_dir or not os.path.isdir(found_dir):
            self._recordings = []
            self.recordingsChanged.emit()
            return

        try:
            for entry in sorted(os.listdir(found_dir), reverse=True):
                entry_path = os.path.join(found_dir, entry)
                if not os.path.isdir(entry_path):
                    continue
                meta_path = os.path.join(entry_path, "Meta.xml")
                if os.path.isfile(meta_path):
                    try:
                        tree = ET.parse(meta_path)
                        root = tree.getroot()
                        val = root.find("value0")
                        name = val.findtext("name", entry) if val is not None else entry
                        duration_s = float(val.findtext("duration", "0")) if val is not None else 0.0
                        multichannel = (val.findtext("multichannel", "false").lower() == "true") if val is not None else False
                        creation_ms = int(val.findtext("creation", "0")) if val is not None else 0

                        if creation_ms > 0:
                            dt = datetime.fromtimestamp(creation_ms / 1000.0)
                            date_str = dt.strftime("%d %b %Y, %H:%M")
                        else:
                            mtime = os.path.getmtime(entry_path)
                            date_str = datetime.fromtimestamp(mtime).strftime("%d %b %Y, %H:%M")

                        mins = int(duration_s) // 60
                        secs = int(duration_s) % 60
                        duration_str = f"{mins:02d}:{secs:02d}"

                        # Calculate total take size
                        total_bytes = sum(os.path.getsize(os.path.join(entry_path, f)) for f in os.listdir(entry_path) if os.path.isfile(os.path.join(entry_path, f)))
                        size_mb = total_bytes / (1024 * 1024)
                        size_str = f"{size_mb:.1f} MB" if size_mb < 1000 else f"{(size_mb/1024):.2f} GB"

                        stereo_wav = os.path.join(entry_path, "Stereo Mix.wav")
                        if not os.path.isfile(stereo_wav):
                            wavs = [f for f in os.listdir(entry_path) if f.endswith(".wav")]
                            stereo_wav = os.path.join(entry_path, wavs[0]) if wavs else ""

                        recordings.append({
                            "name": name,
                            "folder": entry,
                            "path": entry_path,
                            "date": date_str,
                            "duration": duration_str,
                            "multitrack": multichannel,
                            "size": size_str,
                            "stereo_wav": stereo_wav
                        })
                    except Exception as e:
                        logger.debug(f"Error parsing {meta_path}: {e}")
        except Exception as e:
            logger.error(f"Error reading recordings directory: {e}")

        self._recordings = recordings
        self.recordingsChanged.emit()

    @pyqtSlot()
    def enterTransferMode(self):
        self._transfer_mode = True
        self._transfer_status = "Activando modo transferencia..."
        self.transferStateChanged.emit()
        self.toastMessage.emit("Activando transferencia USB en la consola...")

        def do_enter():
            import time
            import subprocess
            self.bridge.run_cmd(["set-property", "15", "transferModeType", "u32:1"])
            time.sleep(2)

            mount_path = ""
            for dev in ["/dev/sda1", "/dev/sdb1", "/dev/sdc1"]:
                if os.path.exists(dev):
                    out = subprocess.run(["udisksctl", "mount", "-b", dev], capture_output=True, text=True)
                    if "Mounted" in out.stdout:
                        parts = out.stdout.split(" at ")
                        if len(parts) > 1:
                            mount_path = parts[1].strip().rstrip(".")
                            break

            if not mount_path:
                import glob
                matches = glob.glob("/run/media/*/RodeCaster") + glob.glob("/media/*/RodeCaster")
                if matches:
                    mount_path = matches[0]

            self._mount_point = mount_path
            self._transfer_status = f"MicroSD montada en {mount_path}" if mount_path else "Modo Transferencia Activo"
            self._scan_recordings(mount_path)
            self.transferStateChanged.emit()
            msg = "¡MicroSD montada en tu sistema!" if mount_path else "Modo Transferencia Activo"
            self.toastMessage.emit(msg)

        self.executor.submit(do_enter)

    @pyqtSlot()
    def exitTransferMode(self):
        self._transfer_status = "Desmontando..."
        self.transferStateChanged.emit()
        self.toastMessage.emit("Desmontando MicroSD...")

        def do_exit():
            import subprocess
            for dev in ["/dev/sda1", "/dev/sdb1", "/dev/sdc1"]:
                if os.path.exists(dev):
                    subprocess.run(["udisksctl", "unmount", "-b", dev], capture_output=True, text=True)

            self.bridge.run_cmd(["set-property", "15", "transferModeType", "u32:0"])
            self.bridge.run_cmd(["set-property", "15", "remountPadStorage", "bool:true"])
            self._transfer_mode = False
            self._mount_point = ""
            self._transfer_status = ""
            self.transferStateChanged.emit()
            self.toastMessage.emit("MicroSD desmontada de forma segura")

        self.executor.submit(do_exit)

    @pyqtSlot(str)
    def openRecordingFolder(self, path):
        if not path or not os.path.exists(path):
            self.toastMessage.emit("Carpeta no encontrada o MicroSD desmontada")
            return
        import subprocess
        subprocess.Popen(["xdg-open", path])

    # Navigation & Views
    @pyqtProperty(str, notify=viewChanged)
    def currentView(self):
        return self._current_view

    @pyqtSlot(str)
    def navigateTo(self, view):
        if self._current_view != view:
            self._current_view = view
            self.viewChanged.emit()

    @pyqtSlot()
    def navigateHome(self):
        if self._current_view != "home":
            self._current_view = "home"
            self.viewChanged.emit()

    # Factory Sounds
    @pyqtProperty(QVariant, notify=stateChanged)
    def factorySounds(self):
        return FACTORY_SOUNDS

    @pyqtSlot(str)
    def loadFactorySound(self, sound_id):
        sound = next((s for s in FACTORY_SOUNDS if s["id"] == sound_id), None)
        if not sound:
            return
        filename = sound["filename"]
        base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        path1 = os.path.join(base_dir, "assets", "sounds", filename)
        if os.path.exists(path1):
            self.uploadSoundFile(path1, sound["name"])
            return

        import glob
        pattern = os.path.join(base_dir, "Resources", "rode", "**", filename)
        matches = glob.glob(pattern, recursive=True)
        if matches:
            self.uploadSoundFile(matches[0], sound["name"])
        else:
            self.toastMessage.emit(f"Sonido {filename} no encontrado")

    # Faders & Mixer
    @pyqtProperty(QVariant, notify=fadersChanged)
    def faders(self):
        return self._faders

    @pyqtSlot(int)
    def toggleFaderMute(self, index):
        if 0 <= index < len(self._faders):
            new_mute = not self._faders[index]["mute"]
            self._faders[index]["mute"] = new_mute
            self.fadersChanged.emit()
            if self._connected and not self._permission_error:
                action = "on" if new_mute else "off"
                self.executor.submit(self.bridge.run_cmd, ["fader", "mute", str(index), action])
            msg = f"{self._faders[index]['name']}: " + ("Mute" if new_mute else "Unmute")
            self.toastMessage.emit(msg)

    @pyqtSlot(int)
    def toggleFaderListen(self, index):
        if 0 <= index < len(self._faders):
            new_listen = not self._faders[index]["listen"]
            self._faders[index]["listen"] = new_listen
            self.fadersChanged.emit()
            if self._connected and not self._permission_error:
                action = "on" if new_listen else "off"
                self.executor.submit(self.bridge.run_cmd, ["fader", "listen", str(index), action])
            msg = f"{self._faders[index]['name']}: Listen " + ("Activado" if new_listen else "Desactivado")
            self.toastMessage.emit(msg)

    @pyqtSlot(int, int)
    def setFaderLevel(self, index, level):
        if 0 <= index < len(self._faders):
            clamped = max(0, min(100, level))
            self._faders[index]["level"] = clamped
            self.fadersChanged.emit()
            self._pending_fader_levels[index] = clamped
            self._fader_timer.start()

    def _flush_faders_hardware(self):
        if not self._connected or self._permission_error or not self._pending_fader_levels:
            return
        to_send = dict(self._pending_fader_levels)
        self._pending_fader_levels.clear()
        for idx, lvl in to_send.items():
            raw_val = int(round(lvl * 127.0 / 100.0))
            # On Duo: node [0, 4..7] are physical faders, [0, 8..9] are virtual faders
            # Setting virtual faders [0, 8] (SMART Pads) and [0, 9] (Bluetooth) directly updates hardware audio level!
            target_node = f"0,{4 + idx}"
            self.executor.submit(self.bridge.run_cmd, ["set-property", target_node, "faderLevel", f"u32:{raw_val}"])

    # Live Recording
    @pyqtProperty(bool, notify=recordingChanged)
    def isRecording(self):
        return self._is_recording

    @pyqtProperty(str, notify=recordingChanged)
    def recordTimeString(self):
        total_sec = self._record_time_ms // 1000
        mins = total_sec // 60
        secs = total_sec % 60
        if mins >= 60:
            hrs = mins // 60
            mins = mins % 60
            return f"{hrs:02d}:{mins:02d}:{secs:02d}"
        return f"{mins:02d}:{secs:02d}"

    @pyqtSlot()
    def toggleRecord(self):
        new_state = not self._is_recording
        self._is_recording = new_state
        self.recordingChanged.emit()
        target_val = "u32:2" if new_state else "u32:0"
        if self._connected and not self._permission_error:
            self.executor.submit(
                self.bridge.run_cmd,
                ["set-property", "3", "requestRecordState", target_val]
            )
        msg = "Grabación iniciada" if new_state else "Grabación detenida"
        self.toastMessage.emit(msg)

    @pyqtSlot()
    def dropMarker(self):
        if self._connected and not self._permission_error:
            self.executor.submit(
                self.bridge.run_cmd,
                ["set-property", "3", "requestDropMarker", "f64:1.0"]
            )
        self.toastMessage.emit("Marca colocada en la grabación")

    # Device Configuration
    @pyqtProperty(int, notify=deviceConfigChanged)
    def screenBrightness(self):
        return self._screen_brightness

    @pyqtSlot(int)
    def setScreenBrightness(self, val):
        val = max(0, min(255, val))
        self._screen_brightness = val
        self._pending_screen_brightness = val
        self.deviceConfigChanged.emit()
        self._brightness_timer.start()

    @pyqtProperty(int, notify=deviceConfigChanged)
    def buttonBrightness(self):
        return self._button_brightness

    @pyqtSlot(int)
    def setButtonBrightness(self, val):
        val = max(0, min(255, val))
        self._button_brightness = val
        self._pending_button_brightness = val
        self.deviceConfigChanged.emit()
        self._brightness_timer.start()

    def _flush_brightness_hardware(self):
        if not self._connected or self._permission_error:
            return
        if self._pending_screen_brightness is not None:
            sb = self._pending_screen_brightness
            self._pending_screen_brightness = None
            self.executor.submit(self.bridge.run_cmd, ["set-property", "7", "screenBrightness", f"u32:{sb}"])
        if self._pending_button_brightness is not None:
            bb = self._pending_button_brightness
            self._pending_button_brightness = None
            # Update BOTH active buttons (rotary dials, encoders) and inactive buttons (Mute, Listen, Rec, Pads)
            # Default ratio on hardware is 4:1 (active 254 / inactive 64)
            inactive_bb = max(0, min(255, int(round(bb * 64.0 / 255.0))))
            self.executor.submit(self.bridge.run_cmd, ["set-property", "7", "activeButtonsBrightness", f"u32:{bb}"])
            self.executor.submit(self.bridge.run_cmd, ["set-property", "7", "inactiveButtonsBrightness", f"u32:{inactive_bb}"])

    @pyqtProperty(bool, notify=deviceConfigChanged)
    def autoBrightness(self):
        return self._auto_brightness

    @pyqtSlot(bool)
    def setAutoBrightness(self, val):
        self._auto_brightness = val
        self.deviceConfigChanged.emit()
        if self._connected and not self._permission_error:
            self.executor.submit(self.bridge.run_cmd, ["set-property", "7", "autoBrightness", f"u32:{1 if val else 0}"])

    @pyqtProperty(int, notify=deviceConfigChanged)
    def dimAfterSeconds(self):
        return self._dim_after_sec

    @pyqtSlot(int)
    def setDimAfterSeconds(self, sec):
        self._dim_after_sec = sec
        self.deviceConfigChanged.emit()
        if self._connected and not self._permission_error:
            self.executor.submit(self.bridge.run_cmd, ["set-property", "7", "screenDimAfterSeconds", f"u32:{sec}"])

    @pyqtProperty(bool, notify=deviceConfigChanged)
    def broadcastMeters(self):
        return self._broadcast_meters

    @pyqtSlot(bool)
    def setBroadcastMeters(self, val):
        self._broadcast_meters = val
        self.deviceConfigChanged.emit()
        if self._connected and not self._permission_error:
            def do_set():
                self.bridge.run_cmd(["set-property", "7", "metering", f"u32:{1 if val else 0}"])
                self.bridge.run_cmd(["set-property", "7", "broadcastMeters", f"bool:{str(val).lower()}"])
            self.executor.submit(do_set)

    @pyqtSlot(int, int)
    def assignChannelInputSource(self, fader_idx, input_source_id):
        if 0 <= fader_idx < 6:
            channel_node_idx = 28 + fader_idx
            if self._connected and not self._permission_error:
                def do_assign():
                    self.bridge.run_cmd(["set-property", str(channel_node_idx), "channelInputSource", f"u32:{input_source_id}"])
                    self._sync_hardware_state()
                self.executor.submit(do_assign)
            self.toastMessage.emit(f"Canal {fader_idx + 1} asignado")

    def _poll_live_hardware(self):
        if not self._connected or self._permission_error or self._transfer_mode:
            return

        def do_poll():
            fout, _ = self.bridge.run_cmd(["fader", "list", "--json"], timeout=2)
            if fout:
                import json
                try:
                    f_list = json.loads(fout)
                    changed = False
                    for item in f_list:
                        idx = item.get("index", 0)
                        if 0 <= idx < len(self._faders):
                            new_mute = bool(item.get("mute", False))
                            new_listen = bool(item.get("listen", False))
                            new_lvl = int(round(float(item.get("level", 0.7)) * 100))
                            if (self._faders[idx]["mute"] != new_mute or 
                                self._faders[idx]["listen"] != new_listen or 
                                abs(self._faders[idx]["level"] - new_lvl) > 1):
                                self._faders[idx]["mute"] = new_mute
                                self._faders[idx]["listen"] = new_listen
                                self._faders[idx]["level"] = new_lvl
                                changed = True
                    if changed:
                        self.fadersChanged.emit()
                except Exception:
                    pass

            rout, _ = self.bridge.run_cmd(["record", "status"], timeout=2)
            if rout:
                rec_now = "RECORDING" in rout.upper()
                if rec_now != self._is_recording:
                    self._is_recording = rec_now
                    self.recordingChanged.emit()

        self.executor.submit(do_poll)

    @pyqtProperty(int, notify=deviceConfigChanged)
    def headphone1Type(self):
        return self._headphone1_type

    @pyqtSlot(int)
    def setHeadphone1Type(self, val):
        self._headphone1_type = val
        self.deviceConfigChanged.emit()
        if self._connected and not self._permission_error:
            self.executor.submit(self.bridge.run_cmd, ["set-property", "9", "headphoneType", f"u32:{val}"])

    @pyqtProperty(int, notify=deviceConfigChanged)
    def headphone2Type(self):
        return self._headphone2_type

    @pyqtSlot(int)
    def setHeadphone2Type(self, val):
        self._headphone2_type = val
        self.deviceConfigChanged.emit()
        if self._connected and not self._permission_error:
            self.executor.submit(self.bridge.run_cmd, ["set-property", "10", "headphoneType", f"u32:{val}"])

    @pyqtProperty(bool, notify=deviceConfigChanged)
    def monitorAutoMute(self):
        return self._monitor_auto_mute

    @pyqtSlot(bool)
    def setMonitorAutoMute(self, val):
        self._monitor_auto_mute = val
        self.deviceConfigChanged.emit()
        if self._connected and not self._permission_error:
            self.executor.submit(self.bridge.run_cmd, ["set-property", "13", "outputMonAutoMute", f"bool:{str(val).lower()}"])

    @pyqtProperty(bool, notify=deviceConfigChanged)
    def btAutoMute(self):
        return self._bt_auto_mute

    @pyqtSlot(bool)
    def setBtAutoMute(self, val):
        self._bt_auto_mute = val
        self.deviceConfigChanged.emit()
        if self._connected and not self._permission_error:
            self.executor.submit(self.bridge.run_cmd, ["set-property", "13", "outputBTAutoMute", f"bool:{str(val).lower()}"])

    @pyqtProperty(bool, notify=deviceConfigChanged)
    def monitorFixedLevel(self):
        return self._monitor_fixed_level

    @pyqtSlot(bool)
    def setMonitorFixedLevel(self, val):
        self._monitor_fixed_level = val
        self.deviceConfigChanged.emit()
        if self._connected and not self._permission_error:
            self.executor.submit(self.bridge.run_cmd, ["set-property", "13", "outputMonFixed", f"bool:{str(val).lower()}"])

    @pyqtProperty(bool, notify=deviceConfigChanged)
    def listenPrefader(self):
        return self._listen_prefader

    @pyqtSlot(bool)
    def setListenPrefader(self, val):
        self._listen_prefader = val
        self.deviceConfigChanged.emit()
        if self._connected and not self._permission_error:
            self.executor.submit(self.bridge.run_cmd, ["set-property", "13", "outputPrefader", f"bool:{str(val).lower()}"])

    @pyqtProperty(int, notify=deviceConfigChanged)
    def multitrackMode(self):
        return self._multitrack_mode

    @pyqtSlot(int)
    def setMultitrackMode(self, val):
        self._multitrack_mode = val
        self.deviceConfigChanged.emit()
        if self._connected and not self._permission_error:
            self.executor.submit(self.bridge.run_cmd, ["set-property", "13", "recordingMultitrackMode", f"u32:{val}"])

    @pyqtProperty(int, notify=deviceConfigChanged)
    def hapticFeedback(self):
        return self._haptic_feedback

    @pyqtSlot(int)
    def setHapticFeedback(self, val):
        self._haptic_feedback = val
        self.deviceConfigChanged.emit()
        if self._connected and not self._permission_error:
            self.executor.submit(self.bridge.run_cmd, ["set-property", "15", "systemHapticSetting", f"u32:{val}"])

    @pyqtProperty(bool, notify=deviceConfigChanged)
    def midiControl(self):
        return self._midi_control

    @pyqtSlot(bool)
    def setMidiControl(self, val):
        self._midi_control = val
        self.deviceConfigChanged.emit()
        if self._connected and not self._permission_error:
            self.executor.submit(self.bridge.run_cmd, ["set-property", "15", "systemMidiControl", f"bool:{str(val).lower()}"])

    @pyqtSlot(int, str, int, int)
    def assignPadEffect(self, fx_id, fx_name, input_ch=0, trigger_mode=1):
        """
        Assigns a hardware Voice FX preset to the current pad with proper properties.
        fx_id: 8=Voice Disguise, 9=Megaphone, 10=Large Robot, 12=Pitch Shift, 13=Monster, 14=Small Robot
        input_ch: 0=Mic 1, 1=Mic 2
        trigger_mode: 1=Latching, 0=Momentary
        """
        order = DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER
        logical_pos = order[self._selected_pad_index] if self._selected_pad_index < len(order) else self._selected_pad_index
        pad = self._banks[self._current_bank][logical_pos]

        pad["type"] = "fx"
        pad["name"] = fx_name
        pad["file"] = ""
        pad["fx_id"] = fx_id
        pad["fx_channel"] = input_ch
        pad["fx_mode"] = trigger_mode

        fx_colors = {8: 8, 9: 9, 10: 10, 12: 0, 13: 1, 14: 2}
        col = fx_colors.get(fx_id, 8)
        pad["color_idx"] = col
        pad["color_hex"] = PAD_COLORS[col]["hex"]

        self.padsChanged.emit()
        self.selectedPadChanged.emit()

        if self._connected and not self._permission_error:
            def do_assign():
                b_str = str(self._current_bank)
                p_str = str(self._selected_pad_index)
                # Set proper hardware properties to prevent audio engine lockup
                self.bridge.run_cmd(["pad", "set-prop", b_str, p_str, "padType", "u32:2"])
                self.bridge.run_cmd(["pad", "set-prop", b_str, p_str, "padFilePath", "str:"])
                self.bridge.run_cmd(["pad", "set-prop", b_str, p_str, "padName", f"str:{fx_name}"])
                self.bridge.run_cmd(["pad", "set-prop", b_str, p_str, "padColourIndex", f"u32:{col}"])
                self.bridge.run_cmd(["pad", "set-prop", b_str, p_str, "padEffectTriggerMode", f"u32:{trigger_mode}"])
                self.bridge.run_cmd(["pad", "set-prop", b_str, p_str, "padEffectInput", f"u32:{input_ch}"])
                self.bridge.run_cmd(["pad", "set-prop", b_str, p_str, "padTriggerControl", f"u32:{fx_id}"])
                self.bridge.run_cmd(["pad", "set-prop", b_str, p_str, "padTriggerSend", "u32:2"])
                self.bridge.run_cmd(["pad", "set-prop", b_str, p_str, "padTriggerChannel", "u32:1"])
                self.bridge.run_cmd(["pad", "set-prop", b_str, p_str, "padTriggerMode", "u32:1"])
                self.bridge.run_cmd(["pad", "set-prop", b_str, p_str, "padTriggerOn", "u32:127"])
                self.bridge.run_cmd(["pad", "set-prop", b_str, p_str, "padTriggerOff", "u32:0"])
                self.bridge.run_cmd(["pad", "set-prop", b_str, p_str, "padActive", "bool:false"])
            self.executor.submit(do_assign)
        self.toastMessage.emit(f"Efecto '{fx_name}' configurado")

    @pyqtSlot(str)
    def updatePadType(self, ptype):
        order = DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER
        logical_pos = order[self._selected_pad_index] if self._selected_pad_index < len(order) else self._selected_pad_index
        pad = self._banks[self._current_bank][logical_pos]
        pad["type"] = ptype
        if ptype == "fx":
            if not pad.get("name"):
                pad["name"] = "Reverb FX"
        elif ptype == "mixer":
            if not pad.get("name"):
                pad["name"] = "Censor Bleep"
        elif ptype == "midi":
            if not pad.get("name"):
                pad["name"] = "MIDI CC#1"
        self.padsChanged.emit()
        self.selectedPadChanged.emit()
        self.toastMessage.emit(f"Tipo: {ptype.upper()}")

    @pyqtSlot()
    def refresh(self):
        self.monitor.scan_devices()
        if self._connected and not self._permission_error:
            self.executor.submit(self._sync_hardware_state)
        self.toastMessage.emit("Sincronizando...")
