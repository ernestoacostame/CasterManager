import os
import tempfile
import threading
import json
import logging
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor
from PyQt6.QtCore import QObject, pyqtSignal, pyqtProperty, pyqtSlot, QVariant, QSettings, QTimer

from .device_monitor import DeviceMonitor
from .rcp_bridge import RcpBridge, PAD_COLORS
from .streamerx_audio import StreamerXAudioRouter

logger = logging.getLogger("CasterManager.state")

DUO_PHYSICAL_ORDER = [0, 3, 1, 4, 2, 5]
PRO_II_PHYSICAL_ORDER = [0, 4, 1, 5, 2, 6, 3, 7]
STREAMER_X_PHYSICAL_ORDER = [0, 2, 1, 3]

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
        "show_profiles": "Gestión de Perfiles de Show",
        "show_profiles_desc": "Guarda o carga configuraciones completas de Pads, Faders y ajustes para distintos podcasts o directos.",
        "export_profile": "Exportar Perfil...",
        "load_profile": "Cargar Perfil...",
        "save_to_microsd": "Guardar en MicroSD",
        "load_from_microsd": "Cargar de MicroSD",
        "export_profile_title": "Exportar Perfil de Show",
        "load_profile_title": "Cargar Perfil de Show",
        "profile_filter": "Perfiles CasterManager (*.castershow *.json)",
        "microsd_detected": "MicroSD detectada",
        "microsd_not_mounted": "MicroSD no montada (activa Modo Transferencia en Grabaciones)",
        "profile_exported": "Perfil guardado con éxito",
        "profile_loaded": "Perfil cargado con éxito",
        "profile_invalid": "El archivo seleccionado no es un perfil de show válido",
        "removable_storage": "Almacenamiento Extraíble",
        "recordings_in_card": "Grabaciones en Tarjeta",
        "new_takes": "Nuevas",
        "all": "Todas",
        "none": "Ninguna",
        "latest": "Más recientes",
        "oldest": "Más antiguas",
        "multitrack": "Multipista",
        "stereo": "Estéreo",
        "custom_preset": "Personalizado",
        "format": "Formato",
        "sample_rate": "Frecuencia",
        "bit_rate": "Profundidad / Tasa",
        "loudness": "Sonoridad (Loudness)",
        "delete_take": "Eliminar",
        "export_take": "Exportar",
        "color": "Color",
        "no_microsd_title": "No hay tarjeta MicroSD instalada",
        "no_microsd_desc": "La ranura de tarjeta MicroSD de tu RØDECaster está vacía. Inserta una tarjeta MicroSD para grabar tomas y transferirlas a tu PC.",
        "no_recordings_title": "No hay grabaciones en la tarjeta",
        "no_recordings_desc": "Las grabaciones realizadas con el botón REC en tu RØDECaster aparecerán aquí.",
        "submixes": "Submezclas",
        "main_mix": "Mezcla Principal (Stream)",
        "headphones_submix": "Mis Auriculares (Submezcla)",
        "submix_banner_main": "🔴 Mezcla de Transmisión en Vivo: Ajustando el audio que escucha la audiencia y graba el master.",
        "submix_banner_hp": "🎧 Submezcla de Auriculares: Ajusta tu volumen personal de monitoreo sin alterar la transmisión en vivo.",
        "linked_to_main": "Vinculado al Stream",
        "independent_mix": "Monitoreo Personalizado",
        "reset_submix": "Restablecer a Principal",
        "dual_mix_title": "Modo Submezclas / Dual Mix",
        "hub_audio_processing": "Procesamiento de Audio",
        "hub_audio_processing_desc": "Efectos APHEX®, Puerta de Ruido, Compresor, HPF, De-Esser y EQ",
        "audio_processing": "Procesamiento",
        "audio_processing_title": "Procesamiento de Audio en Vivo",
        "voxlab_mode": "VoxLab™",
        "advanced_mode": "Canal Avanzado",
        "voxlab_subtitle": "Controles macro intuitivos y perfiles de voz para una calidad de estudio instantánea",
        "depth": "Depth (Profundidad)",
        "depth_desc": "Graves cálidos y ricos del APHEX Big Bottom",
        "sparkle": "Sparkle (Brillo)",
        "sparkle_desc": "Claridad, presencia y aire del APHEX Aural Exciter",
        "punch": "Punch (Pegada)",
        "punch_desc": "Consistencia dinámica e impacto con el Compresor",
        "voice_presets": "Perfiles de Voz",
        "preset_broadcast": "Broadcast",
        "preset_broadcast_desc": "Presencia clásica de radio y estudio con graves profundos",
        "preset_podcast": "Podcast Studio",
        "preset_podcast_desc": "Tono vocal cálido, natural y equilibrado",
        "preset_gaming": "Streaming / Gaming",
        "preset_gaming_desc": "Voz nítida con supresión agresiva de teclado y clic",
        "preset_neutral": "Neutro / Plano",
        "preset_neutral_desc": "Señal pura sin procesamiento dinámico adicional",
        "signal_chain": "Cadena de Señal de Audio",
        "voxlab_macros": "Controles Maestros VoxLab™",
        "advanced_subtitle": "Control completo de cada procesador de la cadena",
        "processing_subtitle": "APHEX®, procesamiento dinámico, filtros y VoxLab™ por canal",
        "macro_studio": "Estudio",
        "macro_max": "Máx",
        "aphex_title": "Procesamiento APHEX®",
        "aphex_desc": "Mejora psicoacústica profesional para dar brillo y presencia a la voz.",
        "aural_exciter": "Aural Exciter™",
        "big_bottom": "Big Bottom™",
        "noise_gate": "Puerta de Ruido",
        "noise_gate_desc": "Elimina ruidos de fondo no deseados cuando no estás hablando.",
        "compressor": "Compresor",
        "compressor_desc": "Controla la dinámica vocal para un sonido consistente y profesional.",
        "hpf": "Filtro Paso Alto (HPF)",
        "hpf_desc": "Corta frecuencias graves bajas para eliminar retumbos y vibraciones.",
        "deesser": "De-Esser",
        "deesser_desc": "Atenúa frecuencias sibilantes agudas estridentes ('S').",
        "equalizer": "Ecualizador (EQ)",
        "equalizer_desc": "Modela el perfil tonal en frecuencias graves, medias y agudas.",
        "preamp": "Preamplificador / Entrada",
        "preamp_desc": "Revolution Preamp™ de ultra-bajo ruido",
        "preamp_gain": "Ganancia de Entrada",
        "phantom_power": "Phantom (+48V)",
        "phase_invert": "Invertir Fase (Ø)",
        "threshold": "Umbral",
        "range": "Rango",
        "attack": "Ataque",
        "release": "Liberación",
        "hold": "Retención (Hold)",
        "ratio": "Relación",
        "makeup_gain": "Ganancia Compensación",
        "frequency": "Frecuencia",
        "slope": "Pendiente",
        "tune": "Sintonía (Tune)",
        "mix": "Mezcla (Mix)",
        "drive": "Empuje (Drive)",
        "low": "Graves",
        "mid": "Medios",
        "high": "Agudos",
        "tab_audio_unify": "Audio & UNIFY",
        "unify_title": "RØDE UNIFY (PipeWire Linux)",
        "unify_desc": "Crea dispositivos virtuales independientes en PipeWire (Game, Chat, Music, System y Stream Mix) con enrutamiento automático hacia auriculares y OBS Studio.",
        "unify_active_mt": "● MULTIPISTA ACTIVA",
        "unify_active_stereo": "○ STEREO ESTÁNDAR",
        "unify_btn_deactivate": "Desactivar UNIFY",
        "unify_btn_activate": "Activar UNIFY en Linux",
        "unify_mt_active_desc": "Multipista USB activa: Micrófono, Headset, Wireless, SMART Pads y canales 6-9 como entradas separadas para tu DAW",
        "unify_mt_inactive_desc": "Multipista USB (9 canales): graba cada entrada de la Streamer X en su propia pista",
        "unify_game_desc": "Juegos / Steam",
        "unify_chat_desc": "Discord / Teams",
        "unify_music_desc": "Spotify / Media",
        "unify_system_desc": "Alertas del SO",
        "unify_stream_mix_desc": "Mezcla Maestra OBS",
        "unify_tip_badge": "OBS & DAWs",
        "unify_tip_text": "Los 5 canales virtuales aparecen de inmediato en PipeWire para capturar en pistas independientes (1-6) sin solapamiento.",
        "hp_front_output": "Salida de Auriculares (Frontal TRRS 3.5mm)",
        "headphone": "Auricular",
        "headphone_1": "Auricular 1",
        "headphone_2": "Auricular 2",
        "auto_mute_output_desc": "Evita retroalimentación acústica al hablar por los micrófonos",
        "auto_mute_bt_desc": "Atenúa la salida bluetooth mientras hablas",
        "listen_desc": "Pre-fader (PFL) o After-fader (AFL) para los botones Listen",
        "metering_standard_desc": "Los vúmetros incluyen marcadores a intervalos regulares e indican el nivel de ganancia unitario estándar.",
        "metering_broadcast_desc": "Los vúmetros incluyen marcadores precisos de escala dBFS en cada canal y medidores de reducción de ganancia (compresor).",
        "multitrack_desc": "Graba canales individuales independientes en la tarjeta MicroSD",
        "auto_brightness_desc": "Ajustar el sensor de luz ambiental automáticamente",
        "haptics_desc": "Vibración al tocar los pads y controles táctiles",
        "device_label": "Dispositivo",
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
        "show_profiles": "Show Profiles Management",
        "show_profiles_desc": "Save or load complete configurations of Pads, Faders, and settings for different podcasts or live streams.",
        "export_profile": "Export Profile...",
        "load_profile": "Load Profile...",
        "save_to_microsd": "Save to MicroSD",
        "load_from_microsd": "Load from MicroSD",
        "export_profile_title": "Export Show Profile",
        "load_profile_title": "Load Show Profile",
        "profile_filter": "CasterManager Profiles (*.castershow *.json)",
        "microsd_detected": "MicroSD detected",
        "microsd_not_mounted": "MicroSD not mounted (enable Transfer Mode in Recordings)",
        "profile_exported": "Profile saved successfully",
        "profile_loaded": "Profile loaded successfully",
        "profile_invalid": "The selected file is not a valid show profile",
        "removable_storage": "Removable Storage",
        "recordings_in_card": "Card Recordings",
        "new_takes": "New",
        "all": "All",
        "none": "None",
        "latest": "Latest",
        "oldest": "Oldest",
        "multitrack": "Multitrack",
        "stereo": "Stereo",
        "custom_preset": "Custom",
        "format": "Format",
        "sample_rate": "Sample Rate",
        "bit_rate": "Bit Rate",
        "loudness": "Loudness",
        "delete_take": "Delete",
        "export_take": "Export",
        "color": "Color",
        "no_microsd_title": "No MicroSD Card Installed",
        "no_microsd_desc": "The MicroSD card slot on your RØDECaster is empty. Insert a MicroSD card to record takes and transfer them to your PC.",
        "no_recordings_title": "No recordings on card",
        "no_recordings_desc": "Recordings made with the REC button on your RØDECaster will appear here.",
        "submixes": "Submixes",
        "main_mix": "Main Mix (Stream)",
        "headphones_submix": "My Headphones (Submix)",
        "submix_banner_main": "🔴 Live Broadcast Mix: Adjusting volume heard by your stream audience and master recording.",
        "submix_banner_hp": "🎧 Headphones Submix: Adjust your personal listening volume without altering the live stream.",
        "linked_to_main": "Linked to Stream",
        "independent_mix": "Custom Monitor Mix",
        "reset_submix": "Reset to Main",
        "dual_mix_title": "Dual Mix / Submix Mode",
        "hub_audio_processing": "Audio Processing",
        "hub_audio_processing_desc": "APHEX® effects, Noise Gate, Compressor, HPF, De-Esser and EQ",
        "audio_processing": "Processing",
        "audio_processing_title": "Live Audio Processing",
        "voxlab_mode": "VoxLab™",
        "advanced_mode": "Advanced Channel",
        "voxlab_subtitle": "Intuitive macro controls and voice profiles for instant broadcast quality",
        "depth": "Depth",
        "depth_desc": "Warm low-end richness powered by APHEX Big Bottom",
        "sparkle": "Sparkle",
        "sparkle_desc": "High-end presence and vocal air from APHEX Aural Exciter",
        "punch": "Punch",
        "punch_desc": "Dynamic consistency and vocal punch from Compressor",
        "voice_presets": "Voice Profiles",
        "preset_broadcast": "Broadcast",
        "preset_broadcast_desc": "Classic radio studio presence with rich proximity",
        "preset_podcast": "Podcast Studio",
        "preset_podcast_desc": "Warm, balanced, and natural spoken-word delivery",
        "preset_gaming": "Streaming / Gaming",
        "preset_gaming_desc": "Crisp voice cut with aggressive keyboard noise rejection",
        "preset_neutral": "Neutral / Flat",
        "preset_neutral_desc": "Clean, uncolored preamp signal with zero dynamic processing",
        "signal_chain": "Audio Signal Chain",
        "voxlab_macros": "VoxLab™ Master Controls",
        "advanced_subtitle": "Full control over every processor in the chain",
        "processing_subtitle": "APHEX®, dynamics, filters and VoxLab™ per channel",
        "macro_studio": "Studio",
        "macro_max": "Max",
        "aphex_title": "APHEX® Processing",
        "aphex_desc": "Professional psychoacoustic enhancement for clarity and presence.",
        "aural_exciter": "Aural Exciter™",
        "big_bottom": "Big Bottom™",
        "noise_gate": "Noise Gate",
        "noise_gate_desc": "Eliminates unwanted ambient background noise when silent.",
        "compressor": "Compressor",
        "compressor_desc": "Levels out vocal dynamics for punchy and consistent tone.",
        "hpf": "High Pass Filter (HPF)",
        "hpf_desc": "Cuts ultra-low frequencies to remove desk rumbles and handling noise.",
        "deesser": "De-Esser",
        "deesser_desc": "Tames harsh sibilance and whistling high frequencies ('S' sounds).",
        "equalizer": "Equalizer (EQ)",
        "equalizer_desc": "Sculpts vocal tone by adjusting low, mid and high frequencies.",
        "preamp": "Preamplifier / Input",
        "preamp_desc": "Revolution Preamp™ ultra-low noise",
        "preamp_gain": "Input Gain",
        "phantom_power": "Phantom (+48V)",
        "phase_invert": "Phase Invert (Ø)",
        "threshold": "Threshold",
        "range": "Range",
        "attack": "Attack",
        "release": "Release",
        "hold": "Hold",
        "ratio": "Ratio",
        "makeup_gain": "Makeup Gain",
        "frequency": "Frequency",
        "slope": "Slope",
        "tune": "Tune",
        "mix": "Mix",
        "drive": "Drive",
        "low": "Low",
        "mid": "Mid",
        "high": "High",
        "tab_audio_unify": "Audio & UNIFY",
        "unify_title": "RØDE UNIFY (PipeWire Linux)",
        "unify_desc": "Creates independent virtual devices in PipeWire (Game, Chat, Music, System and Stream Mix) with automated routing to headphones and OBS Studio.",
        "unify_active_mt": "● MULTITRACK ACTIVE",
        "unify_active_stereo": "○ STANDARD STEREO",
        "unify_btn_deactivate": "Disable UNIFY",
        "unify_btn_activate": "Enable UNIFY in Linux",
        "unify_mt_active_desc": "USB Multitrack active: Microphone, Headset, Wireless, SMART Pads and channels 6-9 as isolated tracks for your DAW",
        "unify_mt_inactive_desc": "USB Multitrack (9 channels): records each Streamer X input on its own isolated DAW track",
        "unify_game_desc": "Games / Steam",
        "unify_chat_desc": "Discord / Teams",
        "unify_music_desc": "Spotify / Media",
        "unify_system_desc": "OS Alerts / Desktop",
        "unify_stream_mix_desc": "OBS Master Mix",
        "unify_tip_badge": "OBS & DAWs",
        "unify_tip_text": "The 5 virtual channels appear immediately in PipeWire to capture separate audio tracks (1-6) with zero crosstalk.",
        "hp_front_output": "Headphones Output (Front TRRS 3.5mm)",
        "headphone": "Headphones",
        "headphone_1": "Headphone 1",
        "headphone_2": "Headphone 2",
        "auto_mute_output_desc": "Prevents acoustic feedback when speaking into microphones",
        "auto_mute_bt_desc": "Ducks Bluetooth output while speaking into microphones",
        "listen_desc": "Pre-fader (PFL) or After-fader (AFL) for Listen buttons",
        "metering_standard_desc": "Meters include regular intervals and indicate standard unity gain level.",
        "metering_broadcast_desc": "Meters include precise dBFS scale markers on each channel and gain reduction (compressor) meters.",
        "multitrack_desc": "Record separate individual channels to MicroSD card",
        "auto_brightness_desc": "Automatically adjust to ambient light sensor",
        "haptics_desc": "Vibration feedback when tapping pads and touch controls",
        "device_label": "Device",
    }
}


DSP_PRESETS = {
    "broadcast": {
        "hpf_on": True, "hpf_frequency": 0.4,
        "noise_gate_on": True, "noise_gate_threshold": 0.35, "noise_gate_range": 0.75,
        "noise_gate_attack": 0.4, "noise_gate_release": 0.45, "noise_gate_hold": 0.1,
        "deesser_on": True, "deesser_threshold": 0.6, "deesser_ratio": 0.5,
        "compressor_on": True, "compressor_threshold": 0.6, "compressor_ratio": 0.5, "compressor_gain": 0.25,
        "eq_on": True, "eq_low": 0.65, "eq_mid": 0.45, "eq_high": 0.65,
        "aphex_on": True, "aphex_ae_mix": 0.55, "aphex_ae_tune": 0.5, "aphex_bb_drive": 0.6, "aphex_bb_tune": 0.4,
        "voxlab_depth": 60, "voxlab_sparkle": 55, "voxlab_punch": 55
    },
    "podcast": {
        "hpf_on": True, "hpf_frequency": 0.35,
        "noise_gate_on": True, "noise_gate_threshold": 0.4, "noise_gate_range": 0.6,
        "noise_gate_attack": 0.5, "noise_gate_release": 0.5, "noise_gate_hold": 0.15,
        "deesser_on": True, "deesser_threshold": 0.65, "deesser_ratio": 0.45,
        "compressor_on": True, "compressor_threshold": 0.7, "compressor_ratio": 0.38, "compressor_gain": 0.15,
        "eq_on": True, "eq_low": 0.55, "eq_mid": 0.5, "eq_high": 0.55,
        "aphex_on": True, "aphex_ae_mix": 0.4, "aphex_ae_tune": 0.5, "aphex_bb_drive": 0.45, "aphex_bb_tune": 0.35,
        "voxlab_depth": 45, "voxlab_sparkle": 40, "voxlab_punch": 40
    },
    "gaming": {
        "hpf_on": True, "hpf_frequency": 0.5,
        "noise_gate_on": True, "noise_gate_threshold": 0.48, "noise_gate_range": 0.85,
        "noise_gate_attack": 0.3, "noise_gate_release": 0.35, "noise_gate_hold": 0.05,
        "deesser_on": True, "deesser_threshold": 0.55, "deesser_ratio": 0.55,
        "compressor_on": True, "compressor_threshold": 0.52, "compressor_ratio": 0.65, "compressor_gain": 0.32,
        "eq_on": True, "eq_low": 0.45, "eq_mid": 0.55, "eq_high": 0.7,
        "aphex_on": True, "aphex_ae_mix": 0.7, "aphex_ae_tune": 0.6, "aphex_bb_drive": 0.35, "aphex_bb_tune": 0.3,
        "voxlab_depth": 35, "voxlab_sparkle": 70, "voxlab_punch": 65
    },
    "neutral": {
        "hpf_on": False,
        "noise_gate_on": False,
        "deesser_on": False,
        "compressor_on": False,
        "eq_on": False,
        "aphex_on": False,
        "voxlab_depth": 0, "voxlab_sparkle": 0, "voxlab_punch": 0
    }
}


def detect_dsp_preset(ch):
    """Return the preset id whose hardware values match channel `ch`, or "custom"."""
    for pid, values in DSP_PRESETS.items():
        match = True
        for k, v in values.items():
            if k.startswith("voxlab_"):
                continue
            cur = ch.get(k)
            if isinstance(v, bool):
                if bool(cur) != v:
                    match = False
                    break
            else:
                if cur is None or abs(float(cur) - float(v)) > 0.01:
                    match = False
                    break
        if match:
            return pid
    return "custom"

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
    devicesChanged = pyqtSignal()
    activeMixTargetChanged = pyqtSignal()
    padClipboardChanged = pyqtSignal()
    dspChanged = pyqtSignal()
    activeDspChannelChanged = pyqtSignal()
    headphoneVolumeChanged = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.settings = QSettings("CasterManager", "CasterManager")
        self._language = self.settings.value("language", "es")
        self._current_view = "home"
        self._active_mix_target = "main"
        self._devices = []
        self._selected_device_index = 0
        self._copied_pad = None
        self._connected = False
        self._permission_error = False
        self._permission_path = ""
        self._headphone_volume = 25
        self._headphone_mute = False
        self._model_name = "RØDECaster Duo"
        self._is_duo = True
        self._is_streamer_x = False
        self._model_type = "Duo"
        self._firmware = "1.7.7"
        self._serial = ""
        self._show_name = self.settings.value("show_name", "TuPodcast")
        try:
            self._show_icon = int(self.settings.value("show_icon", 5))
        except (TypeError, ValueError):
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
        self._has_sd_card = False
        self._storage_label = "Memoria Interna"

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
        # DUCKER.duckerDepth (dB, 0 = off). Used by SMART Pads in Ducking mode.
        self._ducker_depth = -9.0
        try:
            self._ducker_last_depth = float(self.settings.value("ducker_last_depth", -9.0))
        except (TypeError, ValueError):
            self._ducker_last_depth = -9.0

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
        self._poll_in_flight = False
        self._device_generation = 0
        self._mix_layout = None
        self._submix_bus = 0
        self._submix_custom = {}

        # Faders state
        self._faders = self._init_default_faders()

        # Polling timer for live fader & recording status
        self._live_poll_timer = QTimer(self)
        self._live_poll_timer.setInterval(1000)
        self._live_poll_timer.timeout.connect(self._poll_live_hardware)
        self._live_poll_timer.start()

        # DSP Audio Processing State
        self._active_dsp_channel = 0
        self._dsp_channels = self._init_default_dsp_channels()
        self._pending_dsp_updates = {}
        self._dsp_timer = QTimer(self)
        self._dsp_timer.setSingleShot(True)
        self._dsp_timer.setInterval(120)
        self._dsp_timer.timeout.connect(self._flush_dsp_hardware)
        self._is_syncing = False
        self._resync_requested = False
        self._sync_guard = threading.Lock()

        self.monitor = DeviceMonitor(self)
        self.monitor.devices_changed.connect(self._on_devices_changed)
        self.monitor.device_disconnected.connect(self._on_device_disconnected)
        self.monitor.permission_issue.connect(self._on_permission_issue)

        # Initialize banks
        self._banks = self._init_empty_banks(use_cache=True)

        # Start monitoring
        self.monitor.start()

    def _localized_dsp_channel_name(self, idx):
        is_en = (getattr(self, "_language", "es") == "en")
        if getattr(self, "_is_streamer_x", False):
            names = ["XLR Microphone", "TRRS Headset", "Wireless"] if is_en else ["Micrófono XLR", "Auriculares TRRS", "Inalámbrico"]
        elif getattr(self, "_is_duo", True):
            names = ["Microphone 1", "Microphone 2", "Wireless 1", "Wireless 2"] if is_en else ["Micrófono 1", "Micrófono 2", "Inalámbrico 1", "Inalámbrico 2"]
        else:
            names = ["Microphone 1", "Microphone 2", "Microphone 3", "Microphone 4"] if is_en else ["Micrófono 1", "Micrófono 2", "Micrófono 3", "Micrófono 4"]
        return names[idx] if idx < len(names) else f"Mic {idx + 1}"

    def _init_default_dsp_channels(self):
        count = 3 if getattr(self, "_is_streamer_x", False) else 4
        channels = []
        for i in range(count):
            channels.append({
                "id": i,
                "name": self._localized_dsp_channel_name(i),
                "channel_idx": 28 + i,
                "input_idx": 191 + i,
                "preamp_gain": 45,
                "phantom_power": False,
                "phase_flip": False,
                "aphex_on": True,
                "aphex_ae_mix": 0.5,
                "aphex_ae_tune": 0.5,
                "aphex_bb_drive": 0.5,
                "aphex_bb_tune": 0.35,
                "noise_gate_on": True,
                "noise_gate_threshold": 0.28,
                "noise_gate_range": 0.7,
                "noise_gate_attack": 0.5,
                "noise_gate_release": 0.4,
                "noise_gate_hold": 0.0,
                "compressor_on": True,
                "compressor_threshold": 0.65,
                "compressor_ratio": 0.4,
                "compressor_gain": 0.2,
                "compressor_attack": 0.4,
                "compressor_release": 0.4,
                "hpf_on": True,
                "hpf_frequency": 0.5,
                "deesser_on": True,
                "deesser_threshold": 0.65,
                "deesser_ratio": 0.5,
                "eq_on": True,
                "eq_low": 0.5,
                "eq_mid": 0.5,
                "eq_high": 0.5,
                "voxlab_depth": 50,
                "voxlab_sparkle": 50,
                "voxlab_punch": 50,
                "active_preset": "",
            })
        return channels

    def _init_default_faders(self):
        if getattr(self, "_is_streamer_x", False):
            raw = [
                {"index": 0, "name": "Mic / Line", "color": "#FF3C3C", "icon": "mic", "level": 70, "mute": False, "listen": False, "is_virtual": False},
                {"index": 1, "name": "Headset", "color": "#28C850", "icon": "mic", "level": 70, "mute": False, "listen": False, "is_virtual": False},
                {"index": 2, "name": "USB 1", "color": "#FF8C28", "icon": "usb", "level": 70, "mute": False, "listen": False, "is_virtual": False},
                {"index": 3, "name": "USB 2 / Chat", "color": "#00C8C8", "icon": "chat", "level": 70, "mute": False, "listen": False, "is_virtual": False},
                {"index": 4, "name": "SMART Pads", "color": "#E63C78", "icon": "pads", "level": 70, "mute": False, "listen": False, "is_virtual": True},
                {"index": 5, "name": "HDMI Audio", "color": "#3C96FF", "icon": "usb", "level": 70, "mute": False, "listen": False, "is_virtual": True},
            ]
        elif self._is_duo:
            raw = [
                {"index": 0, "name": "Mic 1", "color": "#FF3C3C", "icon": "mic", "level": 70, "mute": False, "listen": False, "is_virtual": False},
                {"index": 1, "name": "Mic 2 / Chat", "color": "#28C850", "icon": "chat", "level": 70, "mute": False, "listen": False, "is_virtual": False},
                {"index": 2, "name": "USB 1", "color": "#FF8C28", "icon": "usb", "level": 70, "mute": False, "listen": False, "is_virtual": False},
                {"index": 3, "name": "USB 2", "color": "#A050E6", "icon": "usb", "level": 70, "mute": False, "listen": False, "is_virtual": False},
                {"index": 4, "name": "SMART Pads", "color": "#FF3C3C", "icon": "pads", "level": 70, "mute": False, "listen": False, "is_virtual": True},
                {"index": 5, "name": "Bluetooth", "color": "#3C96FF", "icon": "bluetooth", "level": 70, "mute": False, "listen": False, "is_virtual": True},
            ]
        else:
            raw = [
                {"index": 0, "name": "Mic 1", "color": "#FF3C3C", "icon": "mic", "level": 70, "mute": False, "listen": False, "is_virtual": False},
                {"index": 1, "name": "Mic 2", "color": "#28C850", "icon": "mic", "level": 70, "mute": False, "listen": False, "is_virtual": False},
                {"index": 2, "name": "Mic 3", "color": "#FF9600", "icon": "mic", "level": 70, "mute": False, "listen": False, "is_virtual": False},
                {"index": 3, "name": "Mic 4", "color": "#E6DC00", "icon": "mic", "level": 70, "mute": False, "listen": False, "is_virtual": False},
                {"index": 4, "name": "USB 1", "color": "#FF8C28", "icon": "usb", "level": 70, "mute": False, "listen": False, "is_virtual": False},
                {"index": 5, "name": "USB 2", "color": "#00C8C8", "icon": "chat", "level": 70, "mute": False, "listen": False, "is_virtual": False},
                {"index": 6, "name": "Pads", "color": "#FF3C3C", "icon": "pads", "level": 70, "mute": False, "listen": False, "is_virtual": True},
                {"index": 7, "name": "Bluetooth", "color": "#3C96FF", "icon": "bluetooth", "level": 70, "mute": False, "listen": False, "is_virtual": True},
                {"index": 8, "name": "Virtual", "color": "#A050E6", "icon": "usb", "level": 70, "mute": False, "listen": False, "is_virtual": True},
            ]
        for f in raw:
            f.setdefault("submix_level", f["level"])
            f.setdefault("submix_linked", True)
            f.setdefault("submix_mute", False)
        return raw

    def _init_empty_banks(self, use_cache=False):
        # The cache is only a placeholder for instant display at startup / device
        # switch. A hardware sync must start from truly empty banks, otherwise
        # pads deleted on the device are resurrected from the cache.
        saved = self.settings.value(f"cached_banks_{self._model_type}", None) if use_cache else None
        if saved:
            try:
                cached = json.loads(saved)
                if isinstance(cached, list) and len(cached) == 8 and len(cached[0]) == self._pads_per_bank:
                    return cached
            except Exception:
                pass

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

    def _on_devices_changed(self, device_list):
        self._devices = device_list
        if not device_list:
            self._connected = False
            self._selected_device_index = 0
            self.stateChanged.emit()
            self.devicesChanged.emit()
            return

        current_serial = self._serial
        matching_idx = next((i for i, d in enumerate(device_list) if d.get("serial") and d.get("serial") == current_serial), None)
        if matching_idx is not None:
            self._selected_device_index = matching_idx
        elif self._selected_device_index >= len(device_list):
            self._selected_device_index = 0

        target_dev = device_list[self._selected_device_index]
        if (self._connected and 
            self._model_type == target_dev.get("model_type") and 
            self.bridge.target_serial == target_dev.get("serial") and 
            self.bridge.target_pid == target_dev.get("product_id") and
            self._permission_error == (not target_dev.get("has_permission", False))):
            self.devicesChanged.emit()
            return

        self._apply_device_config(target_dev)
        self.devicesChanged.emit()

    def _apply_device_config(self, info):
        logger.info(f"Applying config for active device: {info['display_name']} ({info['product_id']})")
        self._connected = True
        self._model_name = info["display_name"]
        self._model_type = info.get("model_type", "Duo")
        self._is_duo = (self._model_type == "Duo")
        self._is_streamer_x = (self._model_type == "StreamerX")
        if self._is_streamer_x:
            self._has_sd_card = False
        self._pads_per_bank = info["pads_per_bank"]
        self._pad_cols = info["pad_cols"]
        self._pad_rows = info["pad_rows"]
        self._serial = info.get("serial", "")
        if info.get("firmware_version"):
            self._firmware = info["firmware_version"]
        self._permission_error = not info.get("has_permission", False)
        self._permission_path = info.get("hidraw_node", "")

        # Load profile name & icon persisted for this specific device model
        saved_name = self.settings.value(f"show_name_{self._model_type}", self.settings.value("show_name", None))
        if saved_name:
            self._show_name = str(saved_name)
        saved_icon = self.settings.value(f"show_icon_{self._model_type}", self.settings.value("show_icon", None))
        if saved_icon is not None:
            try:
                self._show_icon = int(saved_icon)
            except (TypeError, ValueError):
                pass

        # Direct bridge to target this specific device
        self.bridge.target_pid = info.get("product_id")
        self.bridge.target_serial = info.get("serial")

        # Re-initialize banks and faders for the active model geometry
        self._current_bank = int(self.settings.value(f"current_bank_{self._model_type}", 0))
        self._banks = self._init_empty_banks(use_cache=True)
        self._faders = self._init_default_faders()
        self._dsp_channels = self._init_default_dsp_channels()
        self._active_dsp_channel = 0
        # Never carry queued writes from the previous device over to the new one
        self._device_generation += 1
        self._mix_layout = None
        self._submix_bus = 0
        self._submix_custom = {}
        self._pending_fader_levels.clear()
        self._pending_dsp_updates.clear()
        self._copied_pad = None
        if self._selected_pad_index >= self._pads_per_bank:
            self._selected_pad_index = 0

        self.stateChanged.emit()
        self.padsChanged.emit()
        self.selectedPadChanged.emit()
        self.fadersChanged.emit()
        self.dspChanged.emit()
        self.activeDspChannelChanged.emit()

        if info.get("has_permission"):
            self.executor.submit(self._sync_hardware_state)


    def _on_device_changed(self, info):
        # Fallback single device handler
        if not self._devices:
            self._devices = [info]
            self._selected_device_index = 0
            self.devicesChanged.emit()
        self._apply_device_config(info)

    def _on_device_disconnected(self):
        logger.info("RØDECaster disconnected")
        self._connected = False
        self._permission_error = False
        self._devices = []
        self.stateChanged.emit()
        self.devicesChanged.emit()
        self.stateChanged.emit()

    def _on_permission_issue(self, hidpath):
        # Only the active device's permission matters: a second unit without access
        # must not block writes to the one currently selected.
        active_dev = None
        if 0 <= self._selected_device_index < len(self._devices):
            active_dev = self._devices[self._selected_device_index]
        if active_dev and active_dev.get("hidraw_node") and active_dev.get("hidraw_node") != hidpath:
            return
        self._permission_error = True
        self._permission_path = hidpath
        self.stateChanged.emit()

    def _sync_hardware_state(self):
        self.bridge.invalidate_pad_cache()
        with self._sync_guard:
            if self._is_syncing:
                # A sync is already running, but its dump may predate the change
                # that triggered this call (e.g. a pad clear). Queue one more pass.
                self._resync_requested = True
                logger.info("Hardware sync in progress, queued another pass")
                return
            self._is_syncing = True
        try:
            while True:
                self._resync_requested = False
                self._sync_hardware_state_once()
                if not self._resync_requested:
                    break
                logger.info("Running queued hardware sync pass")
        finally:
            with self._sync_guard:
                self._is_syncing = False

    def _sync_hardware_state_once(self):
        try:
            # 1. Query device full dump
            gen = self._device_generation
            dump = self.bridge.dump_state()
            if not dump:
                logger.warning("Could not dump hardware state")
                return
            if gen != self._device_generation:
                # Active device changed while dumping: this tree may belong to the old unit
                logger.info("Active device changed during sync, discarding stale dump")
                self._resync_requested = True
                return

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
                saved_name = self.settings.value(f"show_name_{self._model_type}", None)
                if not saved_name and "currentShowName" in props and props["currentShowName"]:
                    self._show_name = props["currentShowName"]
                saved_icon = self.settings.value(f"show_icon_{self._model_type}", None)
                if saved_icon is None and "currentShowIcon" in props:
                    try:
                        self._show_icon = int(props["currentShowIcon"])
                    except (TypeError, ValueError):
                        pass

            # System & Firmware & SD Card
            sys_node = find_node(dump, "SYSTEM")
            if sys_node:
                props = {k: list(v.values())[0] for k, v in sys_node.get("properties", {}).items()}
                if "systemFirmwareVersion" in props:
                    self._firmware = props["systemFirmwareVersion"]
                if "systemName" in props and props["systemName"] and props["systemName"] not in ("Rodecaster", "RODECaster"):
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
                self._has_sd_card = (sd_volume is not None and sd_volume.get("cap", 0) > 0)
                self._storage_label = "MicroSD" if self._has_sd_card else "Memoria Interna"
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

            # Ducker depth (same node on Duo, Pro II and Streamer X)
            self._root_child_index = {}
            for ci, cn in enumerate(dump.get("children", [])):
                self._root_child_index.setdefault(cn.get("name"), ci)
            ducker_node = find_node(dump, "DUCKER")
            if ducker_node:
                dval = ducker_node.get("properties", {}).get("duckerDepth", {}).get("F64")
                if dval is not None:
                    self._ducker_depth = float(dval)
                    if self._ducker_depth < -0.5:
                        self._ducker_last_depth = self._ducker_depth

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
                if "outputMonLevel" in oprops:
                    self._headphone_volume = int(round(float(oprops["outputMonLevel"]) * 100))
                if "outputMonMute" in oprops:
                    self._headphone_mute = bool(oprops["outputMonMute"])
                self.headphoneVolumeChanged.emit()

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
            if self.isStreamerX:
                # Fader 0: Mic Gain (Node 191)
                if 191 < len(children) and len(self._faders) > 0:
                    g_prop = children[191].get("properties", {}).get("inputMicrophoneGain", {}).get("U32")
                    if g_prop is not None:
                        self._faders[0]["level"] = int(round((int(g_prop) / 76.0) * 100))
                if 5 < len(children) and len(self._faders) > 0:
                    em_props = children[5].get("properties", {})
                    if "emergencyMuteActive" in em_props:
                        self._faders[0]["mute"] = bool(em_props["emergencyMuteActive"].get("Bool", False))
                elif 28 < len(children) and len(self._faders) > 0:
                    c0_props = children[28].get("properties", {})
                    if "channelOutputMute" in c0_props:
                        self._faders[0]["mute"] = bool(c0_props["channelOutputMute"].get("Bool", False))
                # Fader 1: Headset Gain (Node 192, max 40 dB)
                if 192 < len(children) and len(self._faders) > 1:
                    hg_prop = children[192].get("properties", {}).get("inputMicrophoneGain", {}).get("U32")
                    if hg_prop is not None:
                        self._faders[1]["level"] = min(100, int(round((int(hg_prop) / 40.0) * 100)))
                # Faders 2..5: Stream Mix
                sx_map = {2: 182, 3: 184, 4: 187, 5: 188}
                for f_idx, node_id in sx_map.items():
                    if 0 <= f_idx < len(self._faders) and node_id < len(children):
                        node_props = children[node_id].get("properties", {})
                        if "streammixmixLevel" in node_props:
                            val = float(node_props["streammixmixLevel"].get("F64", 0.7))
                            if f_idx not in self._pending_fader_levels:
                                self._faders[f_idx]["level"] = int(round(val * 100))
                                if f_idx >= 2 and val == 0:
                                    self._faders[f_idx]["mute"] = True
                if 29 < len(children) and len(self._faders) > 1:
                    c1_props = children[29].get("properties", {})
                    if "channelOutputMute" in c1_props:
                        self._faders[1]["mute"] = bool(c1_props["channelOutputMute"].get("Bool", False))
            else:
                fout, _ = self.bridge.run_cmd(["fader", "list", "--json"])
                if fout:
                    try:
                        f_list = json.loads(fout)
                        for item in f_list:
                            idx = item.get("index", 0)
                            if 0 <= idx < len(self._faders):
                                self._faders[idx]["mute"] = bool(item.get("mute", False))
                                self._faders[idx]["listen"] = bool(item.get("listen", False))
                                self._faders[idx]["level"] = int(round(float(item.get("level", 0.7)) * 100))
                                self._faders[idx]["level_raw"] = float(item.get("level", 0.7))
                    except Exception as e:
                        logger.debug(f"Error parsing fader list: {e}")

            # Current active bank: already in the dump (GUI.selectedBank), no extra CLI call
            gui_node = find_node(dump, "GUI")
            sel = None
            if gui_node:
                sel = gui_node.get("properties", {}).get("selectedBank", {}).get("U32")
            if sel is not None:
                self._current_bank = int(sel)
            else:
                out, _ = self.bridge.run_cmd(["pad", "bank", "--json"])
                if out:
                    try:
                        bank_info = json.loads(out)
                        if "selected" in bank_info:
                            self._current_bank = bank_info["selected"]
                    except Exception:
                        pass

            # Per-pad voice FX live in PADEFFECTS/EFFECTS_PARAMETERS (effectsIdx == padIdx)
            self._pad_fx_nodes = self._map_pad_fx_nodes(dump)

            # Populate Pads from SOUNDPADS
            soundpads_node = find_node(dump, "SOUNDPADS")
            if soundpads_node:
                pads_per_bank = self._pads_per_bank
                self._banks = self._init_empty_banks()
                order = STREAMER_X_PHYSICAL_ORDER if self._is_streamer_x else (DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER)
                slot_counts = {}

                for c in soundpads_node.get("children", []):
                    p = {k: list(v.values())[0] for k, v in c.get("properties", {}).items()}
                    idx = p.get("padIdx")
                    if idx is None:
                        continue
                    idx = int(idx)
                    bank = idx // pads_per_bank
                    pos = idx % pads_per_bank
                    disp = order.index(pos) if pos in order else pos
                    slot_counts[(bank, disp)] = slot_counts.get((bank, disp), 0) + 1

                    if bank < len(self._banks) and pos < len(self._banks[bank]):
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
                            "mixer_mode": int(p.get("padMixerMode", 0)),
                            "mixer_trigger": int(p.get("padMixerTriggerMode", 0)),
                            "fx": dict(self._pad_fx_nodes.get(idx, {}).get("values", {})),
                            "fade_exclude_host": bool(p.get("padMixerFadeExcludeHost", False)),
                            "back_channel": {k: bool(p.get(f"padMixerBackChannel{k}", False)) for k in self.BACK_CHANNEL_KEYS},
                            "fx_channel": int(p.get("padEffectInput", 0)),
                            "fx_mode": int(p.get("padEffectTriggerMode", 1)),
                            "_raw": {k: v for k, v in p.items() if isinstance(v, (int, float, str, bool))}
                        }
                        self._banks[bank][pos] = pad_entry
                self.bridge.seed_pads(slot_counts)

                try:
                    self.settings.setValue(f"cached_banks_{self._model_type}", json.dumps(self._banks))
                    self.settings.sync()
                except Exception as e:
                    logger.debug(f"Error caching banks: {e}")

            # Populate DSP Channels from CHANNEL and INPUTSOURCE
            channel_nodes = [c for c in children if c.get("name") == "CHANNEL"]
            input_nodes = [c for c in children if c.get("name") == "INPUTSOURCE"]
            for i, dsp in enumerate(self._dsp_channels):
                c_node = channel_nodes[i] if i < len(channel_nodes) else None
                if c_node:
                    dsp["_synced"] = True
                    cp = {k: list(v.values())[0] for k, v in c_node.get("properties", {}).items()}
                    if "channelBypassProcessing" in cp:
                        bypass = bool(cp["channelBypassProcessing"])
                        dsp["bypass_processing"] = bypass
                        if bypass and (dsp.get("noise_gate_on") or dsp.get("aphex_on") or dsp.get("compressor_on")):
                            ch_node_idxs = [idx for idx, c in enumerate(children) if c.get("name") == "CHANNEL"]
                            if i < len(ch_node_idxs):
                                self.bridge.run_cmd(["set-property", str(ch_node_idxs[i]), "channelBypassProcessing", "bool:false"])
                                dsp["bypass_processing"] = False
                    if "aphexOn" in cp: dsp["aphex_on"] = bool(cp["aphexOn"])
                    if "aphexAEMix" in cp: dsp["aphex_ae_mix"] = float(cp["aphexAEMix"])
                    if "aphexAETune" in cp: dsp["aphex_ae_tune"] = float(cp["aphexAETune"])
                    if "aphexBBDrive" in cp: dsp["aphex_bb_drive"] = float(cp["aphexBBDrive"])
                    if "aphexBBTune" in cp: dsp["aphex_bb_tune"] = float(cp["aphexBBTune"])
                    if "noiseGateOn" in cp: dsp["noise_gate_on"] = bool(cp["noiseGateOn"])
                    if "noiseGateThreshold" in cp: dsp["noise_gate_threshold"] = float(cp["noiseGateThreshold"])
                    if "noiseGateRange" in cp: dsp["noise_gate_range"] = float(cp["noiseGateRange"])
                    if "noiseGateAttack" in cp: dsp["noise_gate_attack"] = float(cp["noiseGateAttack"])
                    if "noiseGateRelease" in cp: dsp["noise_gate_release"] = float(cp["noiseGateRelease"])
                    if "noiseGateHold" in cp: dsp["noise_gate_hold"] = float(cp["noiseGateHold"])
                    if "compressorOn" in cp: dsp["compressor_on"] = bool(cp["compressorOn"])
                    if "compressorThreshold" in cp: dsp["compressor_threshold"] = float(cp["compressorThreshold"])
                    if "compressorRatio" in cp: dsp["compressor_ratio"] = float(cp["compressorRatio"])
                    if "compressorGain" in cp: dsp["compressor_gain"] = float(cp["compressorGain"])
                    if "compressorAttack" in cp: dsp["compressor_attack"] = float(cp["compressorAttack"])
                    if "compressorRelease" in cp: dsp["compressor_release"] = float(cp["compressorRelease"])
                    if "hpfOn" in cp: dsp["hpf_on"] = bool(cp["hpfOn"])
                    if "hpfFrequency" in cp: dsp["hpf_frequency"] = float(cp["hpfFrequency"])
                    if "deesserOn" in cp: dsp["deesser_on"] = bool(cp["deesserOn"])
                    if "deesserThreshold" in cp: dsp["deesser_threshold"] = float(cp["deesserThreshold"])
                    if "deesserRatio" in cp: dsp["deesser_ratio"] = float(cp["deesserRatio"])
                    if "eqOn" in cp: dsp["eq_on"] = bool(cp["eqOn"])
                    if "eqLowGain" in cp: dsp["eq_low"] = float(cp["eqLowGain"])
                    if "eqMidGain" in cp: dsp["eq_mid"] = float(cp["eqMidGain"])
                    if "eqHighGain" in cp: dsp["eq_high"] = float(cp["eqHighGain"])
                    dsp["voxlab_depth"] = int(dsp.get("aphex_bb_drive", 0.5) * 100)
                    dsp["voxlab_sparkle"] = int(dsp.get("aphex_ae_mix", 0.5) * 100)
                    comp_t = dsp.get("compressor_threshold", 0.65)
                    dsp["voxlab_punch"] = max(0, min(100, int((1.0 - comp_t) / 0.55 * 100)))

                in_node = input_nodes[i] if i < len(input_nodes) else None
                if in_node:
                    inp = {k: list(v.values())[0] for k, v in in_node.get("properties", {}).items()}
                    if "inputMicrophoneGain" in inp: dsp["preamp_gain"] = int(inp["inputMicrophoneGain"])
                    if "inputPower" in inp:
                        pwr = int(inp["inputPower"])
                        dsp["phantom_power"] = (pwr == 1)
                    if "inputPhaseFlip" in inp: dsp["phase_flip"] = bool(inp["inputPhaseFlip"])

                # The device has no notion of "voice profile": infer it from the real values
                dsp["active_preset"] = detect_dsp_preset(dsp)

            # Streamer X channel strips are hard-wired (Mic, Headset, Wireless, Pads, USB 1,
            # USB 2/Chat, HDMI). Older builds could retarget a strip to an unused analog
            # input (e.g. source 4), which leaks an ungated mic signal into the headphones.
            if self._is_streamer_x:
                factory = [0, 1, 2, 11, 7, 8, 9]
                ch_nodes = [ci for ci, c in enumerate(children) if c.get("name") == "CHANNEL"]
                for strip, want in zip(ch_nodes, factory):
                    have = children[strip].get("properties", {}).get("channelInputSource", {}).get("U32")
                    if have is not None and have != want:
                        logger.warning(f"Streamer X CHANNEL {strip} had source {have}; restoring factory source {want}")
                        self.bridge.run_cmd(["set-property", str(strip), "channelInputSource", f"u32:{want}"])
                        children[strip].setdefault("properties", {})["channelInputSource"] = {"U32": want}

            # Map child node indices dynamically
            for child_idx, c in enumerate(children):
                if c.get("name") == "CHANNEL":
                    src = c.get("properties", {}).get("channelInputSource", {}).get("U32", 0)
                    if src < len(self._dsp_channels):
                        self._dsp_channels[src]["channel_idx"] = child_idx
                elif c.get("name") == "INPUTSOURCE":
                    iid = c.get("properties", {}).get("inputId", {}).get("U32", 0)
                    if iid < len(self._dsp_channels):
                        self._dsp_channels[iid]["input_idx"] = child_idx

            # Headphone submix layout (Duo / Pro II): MIX matrix + per-output mode
            self._mix_layout = self._build_mix_layout(children)
            if self._mix_layout:
                self._submix_custom = {}
                for b, mm_node in enumerate(self._mix_layout["mixminus_nodes"]):
                    mode = children[mm_node].get("properties", {}).get("outputMixMinus", {}).get("U32", 0)
                    self._submix_custom[b] = (mode == 2)
                self._read_submix_state(children)

            logger.info("Successfully synced hardware state!")
            self.stateChanged.emit()
            self.padsChanged.emit()
            self.selectedPadChanged.emit()
            self.fadersChanged.emit()
            self.recordingChanged.emit()
            self.deviceConfigChanged.emit()
            self.dspChanged.emit()
            self.toastMessage.emit(f"Synced with {self._model_name}" if self._language == "en" else f"Sincronizado con {self._model_name}")

        except Exception as e:
            logger.exception(f"Error parsing hardware state: {e}")

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
            for i, ch in enumerate(self._dsp_channels):
                ch["name"] = self._localized_dsp_channel_name(i)
            self.languageChanged.emit()
            self.dspChanged.emit()
            msg = "Idioma cambiado a Español" if lang == "es" else "Language changed to English"
            self.toastMessage.emit(msg)

    @pyqtProperty(QVariant, notify=devicesChanged)
    def connectedDevices(self):
        return self._devices

    @pyqtProperty(int, notify=devicesChanged)
    def selectedDeviceIndex(self):
        return self._selected_device_index

    @pyqtSlot(int)
    def selectDevice(self, index):
        if 0 <= index < len(self._devices):
            if index != self._selected_device_index:
                self._selected_device_index = index
                self._apply_device_config(self._devices[index])
                if getattr(self, "_is_streamer_x", False) and self._current_view == "recordings":
                    self._current_view = "home"
                    self.viewChanged.emit()
                self.devicesChanged.emit()
                dev_disp = self._devices[index].get('display_name', 'RØDECaster')
                self.toastMessage.emit(f"Switched to {dev_disp}" if self._language == "en" else f"Cambiado a {dev_disp}")

    @pyqtProperty(str, notify=stateChanged)
    def modelName(self):
        return self._model_name

    @pyqtProperty(bool, notify=stateChanged)
    def isDuo(self):
        return self._is_duo

    @pyqtProperty(bool, notify=stateChanged)
    def isStreamerX(self):
        return getattr(self, "_is_streamer_x", False)

    @pyqtProperty(str, notify=stateChanged)
    def modelType(self):
        return getattr(self, "_model_type", "Duo")

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

    @pyqtProperty(bool, notify=stateChanged)
    def hasMicroSD(self):
        return self._has_sd_card

    @pyqtProperty(str, notify=stateChanged)
    def storageLabel(self):
        return self._storage_label

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

    def _get_current_pad(self):
        order = STREAMER_X_PHYSICAL_ORDER if self._is_streamer_x else (DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER)
        logical_pos = order[self._selected_pad_index] if self._selected_pad_index < len(order) else self._selected_pad_index
        if 0 <= self._current_bank < len(self._banks):
            bank = self._banks[self._current_bank]
            if 0 <= logical_pos < len(bank):
                return bank[logical_pos]
        return None

    @pyqtProperty(bool, notify=padClipboardChanged)
    def canPastePad(self):
        return self._copied_pad is not None and self._copied_pad.get("type", "empty") != "empty"

    @pyqtProperty(QVariant, notify=padsChanged)
    def currentPads(self):
        order = STREAMER_X_PHYSICAL_ORDER if self._is_streamer_x else (DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER)
        if not (0 <= self._current_bank < len(self._banks)):
            return []
        bank = self._banks[self._current_bank]

        ordered_pads = []
        for display_idx in range(self._pads_per_bank):
            logical_pos = order[display_idx] if display_idx < len(order) else display_idx
            if 0 <= logical_pos < len(bank):
                ordered_pads.append(dict(bank[logical_pos]))
            else:
                ordered_pads.append({
                    "idx": self._current_bank * self._pads_per_bank + display_idx,
                    "pos": display_idx,
                    "name": "",
                    "color_idx": 0,
                    "color_hex": "#505055",
                    "type": "empty",
                    "mode": "toggle",
                    "loop": False,
                    "replay": False,
                    "gain": 0.0,
                    "file": ""
                })
        return ordered_pads

    @pyqtProperty(QVariant, notify=selectedPadChanged)
    def selectedPad(self):
        pad = self._get_current_pad()
        if pad:
            return dict(pad)
        return {
            "idx": self._current_bank * self._pads_per_bank + self._selected_pad_index,
            "pos": self._selected_pad_index,
            "name": "",
            "color_idx": 0,
            "color_hex": "#505055",
            "type": "empty",
            "mode": "toggle",
            "loop": False,
            "replay": False,
            "gain": 0.0,
            "file": ""
        }

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
            if self._is_streamer_x:
                self.settings.setValue(f"current_bank_{self._model_type}", bank)
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
            order = STREAMER_X_PHYSICAL_ORDER if self._is_streamer_x else (DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER)
            logical_pos = order[display_index] if display_index < len(order) else display_index
            bank = self._banks[self._current_bank] if (0 <= self._current_bank < len(self._banks)) else []
            pad = bank[logical_pos] if (0 <= logical_pos < len(bank)) else {}

            logger.info(f"Triggering Pad {display_index} (name: '{pad.get('name')}') on Bank {self._current_bank + 1}")
            if self._connected and not self._permission_error:
                self.executor.submit(self.bridge.trigger_pad, self._current_bank, display_index)

            # Local sound playback preview if audio file exists on Linux
            sound_file = pad.get("file_path") or pad.get("file")
            if sound_file:
                if not os.path.isabs(sound_file):
                    base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
                    sound_file = os.path.join(base_dir, "assets", "sounds", sound_file)
                if os.path.exists(sound_file):
                    self.executor.submit(subprocess.run, ["paplay", sound_file], capture_output=True)
            self.toastMessage.emit(f"Pulsado: {pad.get('name') or f'Pad {display_index+1}'}")

    @pyqtSlot(str)
    def updatePadName(self, name):
        pad = self._get_current_pad()
        if not pad:
            return
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
            pad = self._get_current_pad()
            if not pad:
                return
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
        pad = self._get_current_pad()
        if not pad:
            return
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
        pad = self._get_current_pad()
        if not pad:
            return
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
        pad = self._get_current_pad()
        if not pad:
            return
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
        pad = self._get_current_pad()
        if not pad:
            return
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

        ext = os.path.splitext(clean_path)[1].lower()
        if self._is_streamer_x and ext not in [".wav", ".mp3"]:
            self.toastMessage.emit("La Streamer X solo admite archivos de audio .wav o .mp3")
            return

        pad = self._get_current_pad()
        if not pad:
            return

        name = pad_name or os.path.splitext(os.path.basename(clean_path))[0]
        pad["name"] = name
        pad["file"] = os.path.basename(clean_path)
        pad["file_path"] = clean_path
        pad["type"] = "sound"

        self.padsChanged.emit()
        self.selectedPadChanged.emit()

        if self._connected and not self._permission_error:
            self.toastMessage.emit(f"Subiendo a la {self._model_name}: {name}...")
            b_idx, p_idx = self._current_bank, self._selected_pad_index
            def do_upload():
                # Upload always creates a new PAD node: remove whatever is in the
                # slot first, otherwise the old pad (e.g. an FX) survives underneath.
                self.bridge.clear_pad(b_idx, p_idx)
                out, err = self.bridge.run_cmd([
                    "pad", "upload",
                    str(b_idx),
                    str(p_idx),
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
        else:
            self.toastMessage.emit(f"Audio asignado al Pad {self._selected_pad_index + 1}: {name}")

    @pyqtSlot()
    def clearCurrentPad(self):
        pad = self._get_current_pad()
        if not pad:
            return
        pad["name"] = ""
        pad["file"] = ""
        pad["file_path"] = ""
        pad["type"] = "empty"
        self.padsChanged.emit()
        self.selectedPadChanged.emit()

        if self._connected and not self._permission_error:
            b_idx, p_idx = self._current_bank, self._selected_pad_index
            def do_clear():
                removed, err = self.bridge.clear_pad(b_idx, p_idx)
                if err:
                    logger.error(f"Error clearing pad: {err}")
                    self.toastMessage.emit(f"Error al limpiar: {err}")
                else:
                    if removed:
                        logger.info(f"Pad cleared on hardware (bank {b_idx}, pad {p_idx}, {removed} node(s) removed)")
                    else:
                        logger.info(f"Pad bank {b_idx} pad {p_idx} was already empty on hardware")
                    self.toastMessage.emit(f"Pad limpiado en la {self._model_name}")
                    self._sync_hardware_state()

            self.executor.submit(do_clear)
        else:
            self.toastMessage.emit("Pad limpiado")

    @pyqtSlot()
    def copyCurrentPad(self):
        pad = self._get_current_pad()
        if not pad or pad.get("type") == "empty":
            self.toastMessage.emit("El pad seleccionado está vacío")
            return
        self._copied_pad = dict(pad)
        self.padClipboardChanged.emit()
        self.toastMessage.emit(f"Pad copiado: {self._copied_pad.get('name') or 'Pad'}")

    @pyqtSlot(int)
    def pasteToPad(self, target_display_idx):
        if not self._copied_pad:
            self.toastMessage.emit("No hay ningún pad en el portapapeles")
            return
        self.copyPadData(self._copied_pad, target_display_idx)

    @pyqtSlot(int, int)
    def copyPad(self, src_display_idx, dst_display_idx):
        if src_display_idx == dst_display_idx:
            return
        order = STREAMER_X_PHYSICAL_ORDER if self._is_streamer_x else (DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER)
        src_logical = order[src_display_idx] if src_display_idx < len(order) else src_display_idx
        if not (0 <= self._current_bank < len(self._banks)):
            return
        bank = self._banks[self._current_bank]
        if not (0 <= src_logical < len(bank)):
            return
        src_pad = bank[src_logical]
        if src_pad.get("type") == "empty":
            return
        self.copyPadData(dict(src_pad), dst_display_idx)

    def copyPadData(self, pad_data, dst_display_idx):
        order = STREAMER_X_PHYSICAL_ORDER if self._is_streamer_x else (DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER)
        dst_logical = order[dst_display_idx] if dst_display_idx < len(order) else dst_display_idx
        if not (0 <= self._current_bank < len(self._banks)):
            return
        bank = self._banks[self._current_bank]
        if not (0 <= dst_logical < len(bank)):
            return

        target = bank[dst_logical]
        for k in ["name", "color_idx", "color_hex", "type", "mode", "loop", "replay", "gain", "file", "file_path", "fx_id", "fx_channel", "fx_mode"]:
            if k in pad_data:
                target[k] = pad_data[k]

        self.padsChanged.emit()
        self.selectedPadChanged.emit()
        pad_name = target.get("name") or "Pad"
        self.toastMessage.emit(f"Pad copiado a la posición {dst_display_idx + 1}: {pad_name}")

        if self._connected and not self._permission_error:
            ptype = target.get("type")
            b_str = str(self._current_bank)
            p_str = str(dst_display_idx)
            src_idx_chk = pad_data.get("idx")
            dst_idx_chk = self._current_bank * self._pads_per_bank + dst_logical
            if src_idx_chk is not None and int(src_idx_chk) == dst_idx_chk:
                return  # pasting a pad onto itself: nothing to do on hardware
            def do_sync():
                if ptype == "fx":
                    self.bridge.clear_pad(b_str, p_str)
                    fx_id = target.get("fx_id", 8)
                    fx_channel = target.get("fx_channel", 0)
                    fx_mode = target.get("fx_mode", 1)
                    col = target.get("color_idx", 8)
                    self._send_pad_props(b_str, p_str, [
                        ("padType", "u32:2"),
                        ("padFilePath", "str:"),
                        ("padName", f"str:{target.get('name', '')}"),
                        ("padColourIndex", f"u32:{col}"),
                        ("padEffectTriggerMode", f"u32:{fx_mode}"),
                        ("padEffectInput", f"u32:{fx_channel}"),
                        ("padTriggerControl", f"u32:{fx_id}"),
                        ("padTriggerSend", "u32:2"),
                        ("padTriggerChannel", "u32:1"),
                        ("padTriggerMode", "u32:1"),
                        ("padTriggerOn", "u32:127"),
                        ("padTriggerOff", "u32:0"),
                        ("padActive", "bool:false"),
                    ])
                elif ptype == "sound":
                    sound_p = target.get("file_path") or ""
                    tmp_path = None
                    if not (sound_p and os.path.exists(sound_p)):
                        # Audio only lives on the device: export it from the source pad first.
                        src_idx = pad_data.get("idx")
                        if src_idx is not None:
                            ppb = self._pads_per_bank
                            src_bank, src_pos = int(src_idx) // ppb, int(src_idx) % ppb
                            src_disp = order.index(src_pos) if src_pos in order else src_pos
                            ext = os.path.splitext(target.get("file") or "")[1] or ".wav"
                            fd, tmp_path = tempfile.mkstemp(prefix="cm_pad_", suffix=ext)
                            os.close(fd)
                            _, exp_err = self.bridge.run_cmd(
                                ["pad", "export", str(src_bank), str(src_disp), tmp_path], timeout=90)
                            if exp_err or os.path.getsize(tmp_path) == 0:
                                logger.error(f"Could not export source pad audio: {exp_err}")
                                self.toastMessage.emit("No se pudo leer el audio del pad de origen")
                                os.unlink(tmp_path)
                                tmp_path = None
                            else:
                                sound_p = tmp_path
                    if sound_p and os.path.exists(sound_p):
                        self.bridge.clear_pad(b_str, p_str)
                        _, up_err = self.bridge.run_cmd([
                            "pad", "upload", b_str, p_str, sound_p, "--name", target.get("name", "Sound")
                        ], timeout=60)
                        if up_err:
                            logger.error(f"Paste upload error: {up_err}")
                        else:
                            self.bridge.run_cmd(["pad", "set-prop", b_str, p_str, "padColourIndex", f"u32:{target.get('color_idx', 0)}"])
                    if tmp_path and os.path.exists(tmp_path):
                        os.unlink(tmp_path)
                self._sync_hardware_state()
            self.executor.submit(do_sync)

    @pyqtSlot(str)
    def exportCurrentPad(self, target_filepath):
        pad = self._get_current_pad()
        if not pad:
            return

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
            exp_bank, exp_pad = str(self._current_bank), str(self._selected_pad_index)

            def do_export():
                try:
                    out, err = self.bridge.run_cmd(
                        ["pad", "export", exp_bank, exp_pad, clean_path],
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
        name = name.strip()
        if not name:
            return
        self._show_name = name
        self.settings.setValue(f"show_name_{self._model_type}", name)
        self.settings.setValue("show_name", name)
        self.settings.sync()
        self.stateChanged.emit()
        if self._connected and not self._permission_error and not self._is_streamer_x:
            self.executor.submit(
                self.bridge.run_cmd,
                ["show", "set-name", name]
            )
        self.toastMessage.emit(f"Perfil guardado: {name}")

    @pyqtSlot(int)
    def updateShowIcon(self, icon_idx):
        self._show_icon = icon_idx
        self.settings.setValue(f"show_icon_{self._model_type}", icon_idx)
        self.settings.setValue("show_icon", icon_idx)
        self.settings.sync()
        self.stateChanged.emit()
        if self._connected and not self._permission_error and not self._is_streamer_x:
            self.executor.submit(
                self.bridge.run_cmd,
                ["show", "set-icon", str(icon_idx)]
            )

    @pyqtProperty(QVariant, notify=recordingsChanged)
    def recordings(self):
        return self._recordings

    @pyqtProperty(str, notify=transferStateChanged)
    def mountPoint(self):
        return self._mount_point

    def get_microsd_path(self):
        if self._mount_point and os.path.isdir(self._mount_point):
            return self._mount_point
        import glob
        matches = (
            glob.glob("/run/media/*/*Rode*") +
            glob.glob("/media/*/*Rode*") +
            glob.glob("/run/media/*/*RODE*") +
            glob.glob("/media/*/*RODE*")
        )
        for m in matches:
            if os.path.isdir(m):
                return m
        return ""

    @pyqtProperty(bool, notify=transferStateChanged)
    def isMicroSDMounted(self):
        p = self.get_microsd_path()
        return bool(p and os.path.isdir(p))

    @pyqtProperty(str, notify=transferStateChanged)
    def microSDRoot(self):
        return self.get_microsd_path()

    @pyqtSlot(str, result=bool)
    def exportShowProfile(self, target_filepath):
        try:
            clean_path = target_filepath
            if clean_path.startswith("file://"):
                clean_path = clean_path[7:]

            if not clean_path.endswith(".castershow") and not clean_path.endswith(".json"):
                clean_path += ".castershow"

            parent_dir = os.path.dirname(clean_path)
            if parent_dir and not os.path.exists(parent_dir):
                os.makedirs(parent_dir, exist_ok=True)

            model_name = self._model_name or ("RØDECaster Duo" if self._is_duo else "RØDECaster Pro II")
            profile_data = {
                "format": "castershow",
                "version": 1,
                "show_name": self._show_name or "TuPodcast",
                "show_icon": self._show_icon,
                "device_model": model_name,
                "is_duo": self._is_duo,
                "pads_per_bank": self._pads_per_bank,
                "exported_at": datetime.now().isoformat(),
                "banks": self._banks,
                "faders": self._faders,
                "device_config": {
                    "screen_brightness": self._screen_brightness,
                    "button_brightness": self._button_brightness,
                    "auto_brightness": self._auto_brightness
                }
            }

            with open(clean_path, "w", encoding="utf-8") as f:
                json.dump(profile_data, f, indent=2, ensure_ascii=False)

            filename = os.path.basename(clean_path)
            msg = f"Perfil guardado exitosamente: {filename}" if self._language == "es" else f"Profile saved successfully: {filename}"
            self.toastMessage.emit(msg)
            return True
        except Exception as e:
            logger.error(f"Error exporting show profile: {e}")
            err_msg = f"Error al exportar perfil: {e}" if self._language == "es" else f"Error exporting profile: {e}"
            self.toastMessage.emit(err_msg)
            return False

    @pyqtSlot(result=bool)
    def exportShowProfileToMicroSD(self):
        sd_path = self.get_microsd_path()
        if not sd_path:
            err = self.strings.get("microsd_not_mounted", "MicroSD no montada")
            self.toastMessage.emit(err)
            return False

        shows_dir = os.path.join(sd_path, "RODECaster", "Shows")
        os.makedirs(shows_dir, exist_ok=True)
        safe_name = "".join(c for c in (self._show_name or "Show") if c.isalnum() or c in (' ', '_', '-')).strip()
        if not safe_name:
            safe_name = "Show"
        target_path = os.path.join(shows_dir, f"{safe_name}.castershow")
        return self.exportShowProfile(target_path)

    @pyqtSlot(str, result=bool)
    def loadShowProfile(self, source_filepath):
        try:
            clean_path = source_filepath
            if clean_path.startswith("file://"):
                clean_path = clean_path[7:]

            if not os.path.exists(clean_path):
                self.toastMessage.emit("Archivo no encontrado")
                return False

            with open(clean_path, "r", encoding="utf-8") as f:
                data = json.load(f)

            if not isinstance(data, dict):
                self.toastMessage.emit(self.strings.get("profile_invalid", "Perfil no válido"))
                return False

            # 1. Update Show Name & Icon
            if "show_name" in data and data["show_name"]:
                self.updateShowName(str(data["show_name"]))
            if "show_icon" in data:
                self.updateShowIcon(int(data["show_icon"]))

            # 2. Update Banks and Pads
            if "banks" in data and isinstance(data["banks"], list):
                incoming_banks = data["banks"]
                ppb = self._pads_per_bank
                new_banks = self._init_empty_banks()

                for b_idx, bank_pads in enumerate(incoming_banks[:8]):
                    if isinstance(bank_pads, list):
                        for p_idx, p_data in enumerate(bank_pads[:ppb]):
                            if isinstance(p_data, dict):
                                pad = new_banks[b_idx][p_idx]
                                pad["name"] = p_data.get("name", "")
                                pad["color_idx"] = p_data.get("color_idx", pad["color_idx"])
                                pad["color_hex"] = p_data.get("color_hex", pad["color_hex"])
                                pad["type"] = p_data.get("type", "empty")
                                pad["mode"] = p_data.get("mode", "toggle")
                                pad["loop"] = bool(p_data.get("loop", False))
                                pad["replay"] = bool(p_data.get("replay", False))
                                pad["gain"] = float(p_data.get("gain", 0.0))
                                pad["file"] = p_data.get("file", "")
                                if "fx_name" in p_data:
                                    pad["fx_name"] = p_data["fx_name"]
                                if "fx_id" in p_data:
                                    pad["fx_id"] = p_data["fx_id"]
                                if "fx_channel" in p_data:
                                    pad["fx_channel"] = p_data["fx_channel"]
                                if "fx_mode" in p_data:
                                    pad["fx_mode"] = p_data["fx_mode"]

                self._banks = new_banks
                self.padsChanged.emit()
                self.selectedPadChanged.emit()

                # Sync hardware pads if connected
                if self._connected and not self._permission_error:
                    order = STREAMER_X_PHYSICAL_ORDER if self._is_streamer_x else (DUO_PHYSICAL_ORDER if self._is_duo else PRO_II_PHYSICAL_ORDER)
                    # Snapshot now: the closure must not read state that may change before it runs
                    snapshot = [[dict(p) for p in bank] for bank in self._banks[:8]]

                    def do_sync_pads():
                        for b, bank in enumerate(snapshot):
                            for p, cur in enumerate(bank):
                                # Writing to an empty slot creates a PAD node: only touch real pads
                                if not cur.get("name") and cur.get("type", "empty") == "empty":
                                    continue
                                disp = order.index(p) if p in order else p
                                if cur.get("name"):
                                    self.bridge.run_cmd(["pad", "set-prop", str(b), str(disp), "padName", f"str:{cur['name']}"])
                                if "color_idx" in cur:
                                    self.bridge.run_cmd(["pad", "set-prop", str(b), str(disp), "padColourIndex", f"u32:{cur['color_idx']}"])
                    self.executor.submit(do_sync_pads)

            # 3. Update Faders
            if "faders" in data and isinstance(data["faders"], list):
                incoming_faders = data["faders"]
                for i, in_f in enumerate(incoming_faders):
                    if i < len(self._faders) and isinstance(in_f, dict):
                        if "level" in in_f:
                            self._faders[i]["level"] = in_f["level"]
                        if "mute" in in_f:
                            self._faders[i]["mute"] = bool(in_f["mute"])
                        if "listen" in in_f:
                            self._faders[i]["listen"] = bool(in_f["listen"])
                self.fadersChanged.emit()

            # 4. Device config (brightness)
            if "device_config" in data and isinstance(data["device_config"], dict):
                cfg = data["device_config"]
                if "screen_brightness" in cfg:
                    self.setScreenBrightness(int(cfg["screen_brightness"]))
                elif "brightness" in cfg:
                    self.setScreenBrightness(int(cfg["brightness"]))
                if "button_brightness" in cfg:
                    self.setButtonBrightness(int(cfg["button_brightness"]))
                if "auto_brightness" in cfg:
                    self.setAutoBrightness(bool(cfg["auto_brightness"]))

            loaded_name = data.get("show_name", os.path.basename(clean_path))
            msg = f"Perfil '{loaded_name}' cargado con éxito" if self._language == "es" else f"Profile '{loaded_name}' loaded successfully"
            self.toastMessage.emit(msg)
            return True
        except Exception as e:
            logger.error(f"Error loading show profile: {e}")
            err_msg = f"Error al cargar perfil: {e}" if self._language == "es" else f"Error loading profile: {e}"
            self.toastMessage.emit(err_msg)
            return False

    @pyqtSlot(result=QVariant)
    def getMicroSDProfiles(self):
        sd_path = self.get_microsd_path()
        if not sd_path:
            return []
        import glob
        files = glob.glob(os.path.join(sd_path, "RODECaster", "Shows", "*.castershow")) + \
                glob.glob(os.path.join(sd_path, "RODECaster", "Shows", "*.json")) + \
                glob.glob(os.path.join(sd_path, "*.castershow"))
        res = []
        for f in files:
            name = os.path.splitext(os.path.basename(f))[0]
            try:
                with open(f, "r", encoding="utf-8") as fp:
                    meta = json.load(fp)
                    if isinstance(meta, dict) and "show_name" in meta:
                        name = meta["show_name"]
            except Exception:
                pass
            res.append({"name": name, "path": f, "filename": os.path.basename(f)})
        return res

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
                            "id": len(recordings) + 1,
                            "name": name,
                            "folder": entry,
                            "path": entry_path,
                            "date": date_str,
                            "duration": duration_str,
                            "duration_seconds": duration_s,
                            "multitrack": multichannel,
                            "size": size_str,
                            "stereo_wav": stereo_wav,
                            "color": "#3B82F6",
                            "is_new": True,
                            "selected": (len(recordings) == 0)
                        })
                    except Exception as e:
                        logger.debug(f"Error parsing {meta_path}: {e}")
        except Exception as e:
            logger.error(f"Error reading recordings directory: {e}")

        self._recordings = recordings
        self.recordingsChanged.emit()

    @pyqtSlot(str, int, result=QVariant)
    def getWaveformPeaks(self, wav_path, num_points=100):
        if not wav_path or not os.path.isfile(wav_path):
            import math
            res = []
            for i in range(num_points):
                val = 0.12 + 0.38 * abs(math.sin(i * 0.14)) + 0.35 * abs(math.cos(i * 0.28))
                if i % 8 == 0:
                    val *= 0.3
                if i % 13 == 0:
                    val = min(1.0, val * 1.4)
                res.append(round(min(1.0, max(0.06, val)), 3))
            return res

        import wave, struct
        try:
            with wave.open(wav_path, "rb") as wf:
                n_frames = wf.getnframes()
                if n_frames == 0:
                    return [0.1] * num_points
                step = max(1, n_frames // num_points)
                peaks = []
                sampwidth = wf.getsampwidth()
                for i in range(num_points):
                    wf.setpos(min(i * step, n_frames - 1))
                    chunk = wf.readframes(min(256, n_frames - i * step))
                    if sampwidth == 2:
                        samples = struct.unpack(f"{len(chunk)//2}h", chunk)
                        max_val = max(abs(s) for s in samples) if samples else 0
                        peaks.append(round(min(1.0, max(0.06, max_val / 32768.0)), 3))
                    elif sampwidth == 3: # 24-bit PCM
                        max_val = 0
                        for b in range(0, len(chunk) - 2, 3):
                            val = int.from_bytes(chunk[b:b+3], byteorder="little", signed=True)
                            if abs(val) > max_val:
                                max_val = abs(val)
                        peaks.append(round(min(1.0, max(0.06, max_val / 8388608.0)), 3))
                    else:
                        peaks.append(0.5)
                return peaks
        except Exception as e:
            logger.debug(f"Error reading wave peaks: {e}")
            import math
            return [round(0.1 + 0.4 * abs(math.sin(i * 0.15)) + 0.3 * abs(math.sin(i * 0.4)), 3) for i in range(num_points)]

    @pyqtSlot(int)
    def deleteRecording(self, index):
        if 0 <= index < len(self._recordings):
            rec = self._recordings[index]
            rec_path = rec.get("path", "")
            if rec_path and os.path.isdir(rec_path):
                import shutil
                try:
                    shutil.rmtree(rec_path)
                except Exception as e:
                    logger.error(f"Error deleting recording folder {rec_path}: {e}")
            del self._recordings[index]
            self.recordingsChanged.emit()
            msg = f"Grabación '{rec.get('name')}' eliminada" if self._language == "es" else f"Recording '{rec.get('name')}' deleted"
            self.toastMessage.emit(msg)

    @pyqtSlot(int, str)
    def renameRecording(self, index, new_name):
        if 0 <= index < len(self._recordings) and new_name.strip():
            self._recordings[index]["name"] = new_name.strip()
            rec_path = self._recordings[index].get("path", "")
            if rec_path and os.path.isdir(rec_path):
                meta_path = os.path.join(rec_path, "Meta.xml")
                if os.path.isfile(meta_path):
                    try:
                        import xml.etree.ElementTree as ET
                        tree = ET.parse(meta_path)
                        root = tree.getroot()
                        val = root.find("value0")
                        if val is not None:
                            name_el = val.find("name")
                            if name_el is not None:
                                name_el.text = new_name.strip()
                            else:
                                sub = ET.SubElement(val, "name")
                                sub.text = new_name.strip()
                            tree.write(meta_path)
                    except Exception as e:
                        logger.error(f"Error writing Meta.xml: {e}")
            self.recordingsChanged.emit()
            msg = f"Grabación renombrada a '{new_name.strip()}'" if self._language == "es" else f"Recording renamed to '{new_name.strip()}'"
            self.toastMessage.emit(msg)

    @pyqtSlot(str, str, str, str, str, str)
    def exportRecording(self, source_path, dest_path, format_type, sample_rate, bit_depth, loudness):
        clean_dest = dest_path
        if clean_dest.startswith("file://"):
            clean_dest = clean_dest[7:]

        def do_export():
            try:
                import subprocess
                self.toastMessage.emit("Exportando grabación con ajustes..." if self._language == "es" else "Exporting recording...")
                if source_path and os.path.isfile(source_path):
                    cmd = ["ffmpeg", "-y", "-i", source_path]
                    sr = "48000" if "48" in sample_rate else "44100"
                    cmd.extend(["-ar", sr])

                    fmt_lower = format_type.lower()
                    if "mp3" in fmt_lower:
                        cmd.extend(["-c:a", "libmp3lame", "-b:a", "320k"])
                    elif "flac" in fmt_lower:
                        cmd.extend(["-c:a", "flac"])
                    else: # WAV
                        if "24" in bit_depth:
                            cmd.extend(["-c:a", "pcm_s24le"])
                        else:
                            cmd.extend(["-c:a", "pcm_s16le"])

                    if loudness and "off" not in loudness.lower():
                        target_lufs = "-14" if "-14" in loudness else ("-16" if "-16" in loudness else "-19")
                        cmd.extend(["-af", f"loudnorm=I={target_lufs}:TP=-1.5:LRA=11"])

                    cmd.append(clean_dest)
                    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                    if res.returncode == 0:
                        filename = os.path.basename(clean_dest)
                        self.toastMessage.emit(f"¡Grabación exportada con éxito como {filename}!")
                    else:
                        self.toastMessage.emit(f"Error al procesar con ffmpeg: {res.stderr.decode()[:60]}")
                else:
                    self.toastMessage.emit("No se encontró el archivo de la grabación" if self._language == "es" else "Recording file not found")
            except Exception as e:
                logger.error(f"Error exporting recording: {e}")
                self.toastMessage.emit(f"Error al exportar: {e}")

        self.executor.submit(do_export)

    @staticmethod
    def _find_rode_partitions():
        """Block partitions whose USB ancestor is a RØDE device (vendor 19f7).

        Never touch arbitrary /dev/sdX nodes: they may be the user's own drives."""
        parts = []
        try:
            for name in sorted(os.listdir("/sys/class/block")):
                sys_path = os.path.join("/sys/class/block", name)
                if not os.path.exists(os.path.join(sys_path, "partition")):
                    continue
                cur = os.path.realpath(sys_path)
                while cur and cur != "/":
                    vid_file = os.path.join(cur, "idVendor")
                    if os.path.isfile(vid_file):
                        with open(vid_file) as f:
                            if f.read().strip().lower() == "19f7":
                                parts.append(f"/dev/{name}")
                        break
                    cur = os.path.dirname(cur)
        except Exception as e:
            logger.debug(f"Could not scan block devices: {e}")
        return parts

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
            # The storage takes a moment to enumerate after switching to transfer mode
            rode_parts = []
            for _ in range(10):
                rode_parts = self._find_rode_partitions()
                if rode_parts:
                    break
                time.sleep(0.5)
            for dev in rode_parts:
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
            for dev in self._find_rode_partitions():
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

    @currentView.setter
    def currentView(self, view):
        self.navigateTo(view)

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

    # Faders & Submixes Mixer
    @pyqtProperty(str, notify=activeMixTargetChanged)
    def activeMixTarget(self):
        return self._active_mix_target

    @pyqtSlot(str)
    def setActiveMixTarget(self, target):
        if target in ("main", "headphones") and target != self._active_mix_target:
            self._active_mix_target = target
            self.activeMixTargetChanged.emit()
            self.fadersChanged.emit()

    @pyqtProperty(QVariant, notify=fadersChanged)
    def faders(self):
        result = []
        is_hp = (self._active_mix_target == "headphones")
        for f in self._faders:
            f_copy = dict(f)
            # Level and mute according to active mix
            f_copy["main_level"] = f.get("level", 70)
            f_copy["submix_linked"] = f.get("submix_linked", True)
            # A linked channel follows the main fader on the headphone bus
            f_copy["submix_level"] = f_copy["main_level"] if f_copy["submix_linked"] else f.get("submix_level", f.get("level", 70))
            f_copy["submix_mute"] = f.get("submix_mute", False)
            f_copy["is_submix_mode"] = is_hp

            if is_hp:
                f_copy["level"] = f_copy["submix_level"]
                f_copy["mute"] = f_copy["submix_mute"]
            else:
                f_copy["level"] = f_copy["main_level"]
                f_copy["mute"] = f.get("mute", False)

            result.append(f_copy)
        return result

    @pyqtSlot(int)
    def toggleFaderMute(self, index):
        if 0 <= index < len(self._faders):
            if self._active_mix_target == "headphones":
                new_mute = not self._faders[index].get("submix_mute", False)
                self._faders[index]["submix_mute"] = new_mute
                self.fadersChanged.emit()
                if self._mix_layout and self._connected and not self._permission_error:
                    self.executor.submit(self._write_submix, self._submix_bus, index, None, new_mute, None)
                msg = f"{self._faders[index]['name']} (Auriculares {self._submix_bus + 1}): " + ("Mute" if new_mute else "Unmute")
                self.toastMessage.emit(msg)
            else:
                new_mute = not self._faders[index]["mute"]
                self._faders[index]["mute"] = new_mute
                self.fadersChanged.emit()
                if self._connected and not self._permission_error:
                    if self.isStreamerX:
                        if index == 0:
                            self.executor.submit(self.bridge.run_cmd, ["set-property", "5", "emergencyMuteActive", f"bool:{str(new_mute).lower()}"])
                            self.executor.submit(self.bridge.run_cmd, ["set-property", "28", "channelOutputMute", f"bool:{str(new_mute).lower()}"])
                            # Fader 0 level is the preamp gain, not the stream-mix level: restore the mix to unity
                            lvl = 0.0 if new_mute else 0.71
                            self.executor.submit(self.bridge.run_cmd, ["set-property", "179", "streammixmixLevel", f"f64:{lvl:.4f}"])
                        elif index == 1:
                            self.executor.submit(self.bridge.run_cmd, ["set-property", "29", "channelOutputMute", f"bool:{str(new_mute).lower()}"])
                            lvl = 0.0 if new_mute else 0.71
                            self.executor.submit(self.bridge.run_cmd, ["set-property", "180", "streammixmixLevel", f"f64:{lvl:.4f}"])
                        else:
                            sx_map = {2: 182, 3: 184, 4: 187, 5: 188}
                            node_id = sx_map.get(index)
                            if node_id is not None:
                                lvl = 0.0 if new_mute else (self._faders[index].get("level", 70) / 100.0)
                                self.executor.submit(self.bridge.run_cmd, ["set-property", str(node_id), "streammixmixLevel", f"f64:{lvl:.4f}"])
                    else:
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
            if self._active_mix_target == "main":
                self._faders[index]["level"] = clamped
                if self._faders[index].get("submix_linked", True):
                    self._faders[index]["submix_level"] = clamped
                self.fadersChanged.emit()
                self._pending_fader_levels[index] = clamped
                self._fader_timer.start()
            else:
                # Submix target: independent headphone monitoring
                self._faders[index]["submix_level"] = clamped
                self._faders[index]["submix_linked"] = False
                self.fadersChanged.emit()
                self._apply_submix_hardware(index, clamped)

    @pyqtSlot(int)
    def toggleSubmixLink(self, index):
        if 0 <= index < len(self._faders):
            curr = self._faders[index].get("submix_linked", True)
            new_linked = not curr
            self._faders[index]["submix_linked"] = new_linked
            if new_linked:
                self._faders[index]["submix_level"] = self._faders[index]["level"]
                if self._mix_layout and self._connected and not self._permission_error:
                    self.executor.submit(self._write_submix, self._submix_bus, index, None, None, True)
                else:
                    self._apply_submix_hardware(index, self._faders[index]["level"])
            elif self._mix_layout and self._connected and not self._permission_error:
                self.executor.submit(self._write_submix, self._submix_bus, index,
                                     self._faders[index].get("submix_level", self._faders[index]["level"]), None, None)
            self.fadersChanged.emit()
            msg = f"{self._faders[index]['name']}: " + ("Vinculado al Stream" if new_linked else "Monitoreo Personalizado")
            self.toastMessage.emit(msg)

    @pyqtSlot()
    def resetSubmix(self):
        for f in self._faders:
            f["submix_level"] = f["level"]
            f["submix_linked"] = True
            f["submix_mute"] = False
        self.fadersChanged.emit()
        if self._mix_layout and self._connected and not self._permission_error:
            bus = self._submix_bus
            fader_ids = list(range(len(self._faders)))

            def do_reset():
                for i in fader_ids:
                    self._write_submix(bus, i, link=True, mute=False)
                mm = self._mix_layout["mixminus_nodes"]
                if bus < len(mm):
                    # Back to "Main Mix" on this headphone output
                    self.bridge.run_cmd(["set-property", str(mm[bus]), "outputMixMinus", "u32:0"])
            self.executor.submit(do_reset)
        self.toastMessage.emit("Headphones submix reset to main mix" if self._language == "en" else "Submezcla de auriculares sincronizada con la mezcla principal")

    # ------------------------------------------------------------------
    # Headphone submix (RØDECaster Duo / Pro II)
    #
    # The root holds one MIX node per source and bus (13 buses per source, in
    # tree order). Bus N is "Headphone N+1". MIXMINUSES[bus].outputMixMinus
    # selects that output's mode: 0 Main Mix, 1 Mix Minus, 2 Custom.
    # A per-bus level only sticks with mixLink=false; mixLevelWithAnchor is
    # "<bus level>|<anchor>" (the firmware keeps the anchor = fader level).
    # ------------------------------------------------------------------
    MIX_BUSES = 13

    def _build_mix_layout(self, children):
        mix_nodes = [i for i, c in enumerate(children) if c.get("name") == "MIX"]
        mm_nodes = [i for i, c in enumerate(children) if c.get("name") == "MIXMINUSES"]
        if self._is_streamer_x:
            if len(mix_nodes) < 10 or not mm_nodes:
                return None
            # Streamer X faders: 0 (Mic), 1 (Headset), 2 (USB 1), 3 (USB 2), 4 (Pads), 5 (HDMI)
            sources = [0, 1, 7, 8, 11, 9]
            return {"mix_nodes": mix_nodes, "mixminus_nodes": mm_nodes, "sources": sources, "buses_per_source": 10}
        if len(mix_nodes) < self.MIX_BUSES or not mm_nodes:
            return None
        sources = []
        for c in children:
            if c.get("name") == "CHANNEL":
                src = c.get("properties", {}).get("channelInputSource", {}).get("U32")
                sources.append(src if src is not None and src < 1000 else None)
        return {"mix_nodes": mix_nodes, "mixminus_nodes": mm_nodes, "sources": sources, "buses_per_source": self.MIX_BUSES}

    def _submix_node(self, bus, fader_idx):
        lay = self._mix_layout
        if not lay or fader_idx >= len(lay["sources"]):
            return None
        src = lay["sources"][fader_idx]
        if src is None:
            return None
        buses = lay.get("buses_per_source", self.MIX_BUSES)
        k = src * buses + bus
        return lay["mix_nodes"][k] if k < len(lay["mix_nodes"]) else None

    def _read_submix_state(self, children):
        """Load the selected headphone bus levels/mutes/links into the faders."""
        if not self._mix_layout:
            return
        bus = self._submix_bus
        for i, f in enumerate(self._faders):
            node = self._submix_node(bus, i)
            if node is None or node >= len(children):
                continue
            props = {k: list(v.values())[0] for k, v in children[node].get("properties", {}).items()}
            linked = bool(props.get("mixLink", True))
            raw = str(props.get("mixLevelWithAnchor", ""))
            lvl_txt = raw.split("|")[0] if "|" in raw else raw
            try:
                lvl = float(lvl_txt)
            except ValueError:
                lvl = -1.0
            f["submix_linked"] = linked
            f["submix_mute"] = bool(props.get("mixMute", False))
            if linked or not (0.0 <= lvl <= 1.0):
                f["submix_level"] = f.get("level", 70)
            else:
                f["submix_level"] = int(round(lvl * 100))

    def _write_submix(self, bus, fader_idx, level=None, mute=None, link=None):
        """Blocking hardware write for one channel on one headphone bus (worker thread)."""
        node = self._submix_node(bus, fader_idx)
        if node is None:
            return
        run = self.bridge.run_cmd
        # The firmware keeps its own anchor (the main fader level); use the exact value when known
        f = self._faders[fader_idx] if fader_idx < len(self._faders) else {}
        anchor = round(float(f.get("level_raw", f.get("level", 70) / 100.0)), 6)
        if link is False or level is not None or mute is not None:
            # A custom value only applies when the output is in Custom mode
            mm = self._mix_layout["mixminus_nodes"]
            if bus < len(mm) and not self._submix_custom.get(bus):
                run(["set-property", str(mm[bus]), "outputMixMinus", "u32:2"])
                self._submix_custom[bus] = True
        if link is True:
            # Clear the custom value while unlinked, then hand control back to the fader
            run(["set-property", str(node), "mixLink", "bool:false"])
            run(["set-property", str(node), "mixLevelWithAnchor", f"str:{anchor}|{anchor}"])
            run(["set-property", str(node), "mixLink", "bool:true"])
        elif level is not None:
            run(["set-property", str(node), "mixLink", "bool:false"])
            run(["set-property", str(node), "mixLevelWithAnchor", f"str:{round(level / 100.0, 6)}|{anchor}"])
        if mute is not None:
            run(["set-property", str(node), "mixMute", f"bool:{str(bool(mute)).lower()}"])

    @pyqtProperty(int, notify=activeMixTargetChanged)
    def headphoneBus(self):
        return self._submix_bus

    @pyqtProperty(int, notify=stateChanged)
    def headphoneBusCount(self):
        if self._is_streamer_x:
            return 1
        return 2 if self._is_duo else 4

    @pyqtSlot(int)
    def setHeadphoneBus(self, bus):
        if 0 <= bus < self.headphoneBusCount and bus != self._submix_bus:
            self._submix_bus = bus
            self.activeMixTargetChanged.emit()
            if self._connected and not self._permission_error and self._mix_layout:
                def do_reload():
                    dump = self.bridge.dump_state()
                    if dump and bus == self._submix_bus:
                        self._read_submix_state(dump.get("children", []))
                        self.fadersChanged.emit()
                self.executor.submit(do_reload)

    def _apply_submix_hardware(self, index, level):
        if self._mix_layout and self._connected and not self._permission_error:
            self.executor.submit(self._write_submix, self._submix_bus, index, level, None, None)

    def _flush_faders_hardware(self):
        if not self._connected or self._permission_error or not self._pending_fader_levels:
            return
        to_send = dict(self._pending_fader_levels)
        self._pending_fader_levels.clear()
        if self.isStreamerX:
            sx_map = {2: 182, 3: 184, 4: 187, 5: 188}
            for idx, lvl in to_send.items():
                if idx == 0:
                    gain_db = int(round((lvl / 100.0) * 76))
                    self.executor.submit(
                        self.bridge.run_cmd,
                        ["set-property", "191", "inputMicrophoneGain", f"u32:{gain_db}"]
                    )
                    if len(self._dsp_channels) > 0:
                        self._dsp_channels[0]["preamp_gain"] = gain_db
                        self.dspChanged.emit()
                elif idx == 1:
                    gain_db = int(round((lvl / 100.0) * 40))
                    self.executor.submit(
                        self.bridge.run_cmd,
                        ["set-property", "192", "inputMicrophoneGain", f"u32:{gain_db}"]
                    )
                    if len(self._dsp_channels) > 1:
                        self._dsp_channels[1]["preamp_gain"] = gain_db
                        self.dspChanged.emit()
                else:
                    node_id = sx_map.get(idx)
                    if node_id is not None:
                        raw_val = round(lvl / 100.0, 4)
                        self.executor.submit(
                            self.bridge.run_cmd,
                            ["set-property", str(node_id), "streammixmixLevel", f"f64:{raw_val}"]
                        )
        else:
            for idx, lvl in to_send.items():
                raw_val = int(round(lvl * 127.0 / 100.0))
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
        # Streamer X channel strips are hard-wired to their inputs (CHANNEL node N is
        # not fader N there), so writing channelInputSource would retarget the wrong strip.
        if self._is_streamer_x:
            return
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
        if self.isStreamerX:
            def do_poll_streamerx():
                dump = self.bridge.dump_state()
                if not dump:
                    return
                children = dump.get("children", [])
                changed = False

                # 1. Rotary Knob 1: Input Gain & Mute
                # Input 0: Mic / Line (Node 191)
                if 191 < len(children) and len(self._dsp_channels) > 0:
                    g_val = children[191].get("properties", {}).get("inputMicrophoneGain", {}).get("U32")
                    if g_val is not None:
                        gain_int = int(g_val)
                        if self._dsp_channels[0].get("preamp_gain") != gain_int:
                            self._dsp_channels[0]["preamp_gain"] = gain_int
                            self.dspChanged.emit()
                        # Sync Fader 0 level (0..76 dB mapped to 0..100%)
                        if 0 not in self._pending_fader_levels and len(self._faders) > 0:
                            fader_lvl = int(round((gain_int / 76.0) * 100))
                            if abs(self._faders[0].get("level", 0) - fader_lvl) > 1:
                                self._faders[0]["level"] = fader_lvl
                                changed = True

                # Input 1: Headset (Node 192, max 40 dB)
                if 192 < len(children) and len(self._faders) > 1:
                    hs_val = children[192].get("properties", {}).get("inputMicrophoneGain", {}).get("U32")
                    if hs_val is not None and 1 not in self._pending_fader_levels:
                        hs_int = int(hs_val)
                        hs_lvl = min(100, int(round((hs_int / 40.0) * 100)))
                        if abs(self._faders[1].get("level", 0) - hs_lvl) > 1:
                            self._faders[1]["level"] = hs_lvl
                            changed = True

                # Mic Mute (Node 5 emergencyMuteActive / Node 28)
                if 5 < len(children) and len(self._faders) > 0:
                    em_val = children[5].get("properties", {}).get("emergencyMuteActive", {}).get("Bool")
                    if em_val is not None:
                        em_bool = bool(em_val)
                        if self._faders[0].get("mute") != em_bool:
                            self._faders[0]["mute"] = em_bool
                            changed = True
                elif 28 < len(children) and len(self._faders) > 0:
                    m_val = children[28].get("properties", {}).get("channelOutputMute", {}).get("Bool")
                    if m_val is not None:
                        mute_bool = bool(m_val)
                        if self._faders[0].get("mute") != mute_bool:
                            self._faders[0]["mute"] = mute_bool
                            changed = True

                # Headset Mute (Node 29)
                if 29 < len(children) and len(self._faders) > 1:
                    hm_val = children[29].get("properties", {}).get("channelOutputMute", {}).get("Bool")
                    if hm_val is not None:
                        hmute_bool = bool(hm_val)
                        if self._faders[1].get("mute") != hmute_bool:
                            self._faders[1]["mute"] = hmute_bool
                            changed = True

                # 2. Stream Mix levels (Nodes 182..188 for faders 2..5)
                sx_map = {2: 182, 3: 184, 4: 187, 5: 188}
                for f_idx, node_id in sx_map.items():
                    if 0 <= f_idx < len(self._faders) and node_id < len(children):
                        if f_idx in self._pending_fader_levels:
                            continue
                        lvl_prop = children[node_id].get("properties", {}).get("streammixmixLevel", {}).get("F64")
                        if lvl_prop is not None:
                            lvl_val = int(round(float(lvl_prop) * 100))
                            if not self._faders[f_idx].get("mute", False) and abs(self._faders[f_idx]["level"] - lvl_val) > 1:
                                self._faders[f_idx]["level"] = lvl_val
                                changed = True

                if changed:
                    self.fadersChanged.emit()

            self._submit_poll(do_poll_streamerx)
            return

        def do_poll():
            fout, _ = self.bridge.run_cmd(["fader", "list", "--json"], timeout=2)
            if fout:
                try:
                    f_list = json.loads(fout)
                    changed = False
                    for item in f_list:
                        idx = item.get("index", 0)
                        if 0 <= idx < len(self._faders):
                            new_mute = bool(item.get("mute", False))
                            new_listen = bool(item.get("listen", False))
                            new_lvl = int(round(float(item.get("level", 0.7)) * 100))
                            self._faders[idx]["level_raw"] = float(item.get("level", 0.7))
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

            rout, _ = self.bridge.run_cmd(["record", "status", "--json"], timeout=2)
            if rout:
                try:
                    rec_now = json.loads(rout).get("state") == "recording"
                except Exception:
                    rec_now = rout.strip().upper().startswith("REC")
                if rec_now != self._is_recording:
                    self._is_recording = rec_now
                    self.recordingChanged.emit()

        self._submit_poll(do_poll)

    def _submit_poll(self, fn):
        """Run a live poll in the executor, skipping the tick if the previous one is still running."""
        if self._poll_in_flight:
            return
        self._poll_in_flight = True

        def wrapper():
            try:
                fn()
            except Exception as e:
                logger.debug(f"Live poll failed: {e}")
            finally:
                self._poll_in_flight = False

        self.executor.submit(wrapper)

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

    @pyqtProperty(int, notify=headphoneVolumeChanged)
    def headphoneVolume(self):
        return self._headphone_volume

    @pyqtProperty(bool, notify=headphoneVolumeChanged)
    def headphoneMute(self):
        return self._headphone_mute

    @pyqtSlot(int)
    def setHeadphoneVolume(self, volume):
        clamped = max(0, min(100, volume))
        if clamped != self._headphone_volume:
            self._headphone_volume = clamped
            self.headphoneVolumeChanged.emit()
            if self._connected and not self._permission_error:
                raw_f64 = round(clamped / 100.0, 4)
                self.executor.submit(
                    self.bridge.run_cmd,
                    ["set-property", "13", "outputMonLevel", f"f64:{raw_f64}"]
                )

    @pyqtSlot()
    def toggleHeadphoneMute(self):
        new_mute = not self._headphone_mute
        self._headphone_mute = new_mute
        self.headphoneVolumeChanged.emit()
        if self._connected and not self._permission_error:
            self.executor.submit(
                self.bridge.run_cmd,
                ["set-property", "13", "outputMonMute", f"bool:{str(new_mute).lower()}"]
            )
        self.toastMessage.emit("Auriculares: " + ("Silenciados" if new_mute else "Activos"))

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
    def duckingEnabled(self):
        return self._ducker_depth < -0.5

    @pyqtProperty(float, notify=deviceConfigChanged)
    def duckingDepth(self):
        return self._ducker_depth if self._ducker_depth < -0.5 else self._ducker_last_depth

    def _write_ducker_depth(self, depth):
        self._ducker_depth = depth
        self.deviceConfigChanged.emit()
        if self._connected and not self._permission_error:
            node = self._find_root_child_index("DUCKER")
            if node is not None:
                self.executor.submit(self.bridge.run_cmd, ["set-property", str(node), "duckerDepth", f"f64:{depth:.1f}"])

    @pyqtSlot(bool)
    def setDuckingEnabled(self, enabled):
        self._write_ducker_depth(self._ducker_last_depth if enabled else 0.0)

    @pyqtSlot(float)
    def setDuckingDepth(self, depth):
        depth = max(-40.0, min(-1.0, round(float(depth))))
        self._ducker_last_depth = depth
        self.settings.setValue("ducker_last_depth", depth)
        self._write_ducker_depth(depth)

    def _find_root_child_index(self, name):
        """Index of the first root child with this node name (layouts differ per model)."""
        idx = getattr(self, "_root_child_index", {}).get(name)
        return idx if idx is not None else {"DUCKER": 1}.get(name)

    @pyqtProperty(bool, notify=deviceConfigChanged)
    def midiControl(self):
        return self._midi_control

    @pyqtSlot(bool)
    def setMidiControl(self, val):
        self._midi_control = val
        self.deviceConfigChanged.emit()
        if self._connected and not self._permission_error:
            self.executor.submit(self.bridge.run_cmd, ["set-property", "15", "systemMidiControl", f"bool:{str(val).lower()}"])

    @staticmethod
    def _raw_matches(raw_val, val_str):
        """Compare a value from the device dump with a CLI-typed value string."""
        if raw_val is None:
            return False
        kind, _, v = val_str.partition(":")
        try:
            if kind == "u32":
                return not isinstance(raw_val, bool) and int(raw_val) == int(v)
            if kind == "bool":
                return bool(raw_val) == (v in ("true", "1"))
            if kind == "f64":
                return abs(float(raw_val) - float(v)) < 1e-4
            if kind == "str":
                return str(raw_val) == v
        except (TypeError, ValueError):
            return False
        return False

    def _send_pad_props(self, b_str, p_str, props, raw=None):
        """Send pad properties, skipping the ones the device already has."""
        raw = raw if raw is not None else {}
        sent = 0
        for name, val in props:
            if self._raw_matches(raw.get(name), val):
                continue
            _, err = self.bridge.run_cmd(["pad", "set-prop", b_str, p_str, name, val])
            sent += 1
            if not err:
                kind, _, v = val.partition(":")
                raw[name] = (int(v) if kind == "u32" else v in ("true", "1") if kind == "bool"
                             else float(v) if kind == "f64" else v)
        logger.info(f"Pad {b_str}/{p_str}: {sent} of {len(props)} properties sent (rest unchanged)")

    @pyqtSlot(int, str, int, int)
    def assignPadEffect(self, fx_id, fx_name, input_ch=0, trigger_mode=1):
        """
        Assigns a hardware Voice FX preset to the current pad with proper properties.
        fx_id: 8=Voice Disguise, 9=Megaphone, 10=Large Robot, 12=Pitch Shift, 13=Monster, 14=Small Robot
        input_ch: 0=Mic 1, 1=Mic 2
        trigger_mode: 1=Latching, 0=Momentary
        """
        pad = self._get_current_pad()
        if not pad:
            return

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
            b_str = str(self._current_bank)
            p_str = str(self._selected_pad_index)
            raw = pad.setdefault("_raw", {})
            props = [
                ("padType", "u32:2"),
                ("padFilePath", "str:"),
                ("padName", f"str:{fx_name}"),
                ("padColourIndex", f"u32:{col}"),
                ("padEffectTriggerMode", f"u32:{trigger_mode}"),
                ("padEffectInput", f"u32:{input_ch}"),
                ("padTriggerControl", f"u32:{fx_id}"),
                ("padTriggerSend", "u32:2"),
                ("padTriggerChannel", "u32:1"),
                ("padTriggerMode", "u32:1"),
                ("padTriggerOn", "u32:127"),
                ("padTriggerOff", "u32:0"),
                ("padActive", "bool:false"),
            ]
            def do_assign():
                # Set proper hardware properties to prevent audio engine lockup
                self._send_pad_props(b_str, p_str, props, raw)
            self.executor.submit(do_assign)
        self.toastMessage.emit(f"Efecto '{fx_name}' configurado")

    # ------------------------------------------------------------------
    # Voice FX pads (padType 2). As in RØDE Unify / RØDECaster App, a pad can stack
    # several effects; each has an On flag plus parameters in its own
    # PADEFFECTS/EFFECTS_PARAMETERS node, matched by effectsIdx == padIdx.
    # (padTriggerControl is the pad's MIDI CC number, not an effect id.)
    # ------------------------------------------------------------------
    PAD_FX_PROPS = {
        "reverbOn", "reverbMix", "reverbModel", "reverbLowCut", "reverbHighCut",
        "echoOn", "echoMix", "echoDelay", "echoDecay", "echoLowCut", "echoHighCut",
        "distortionOn", "distortionIntensity",
        "robotOn", "robotMix", "robotLevel",
        "voiceDisguiseOn",
        "pitchShiftOn", "pitchShiftSemitones",
    }

    @staticmethod
    def _map_pad_fx_nodes(dump):
        """{padIdx: {"path": "PADEFFECTS,child", "values": {prop: value}}}"""
        res = {}
        for ti, top in enumerate(dump.get("children", [])):
            if top.get("name") != "PADEFFECTS":
                continue
            for ci, node in enumerate(top.get("children", [])):
                props = {k: list(v.values())[0] for k, v in node.get("properties", {}).items()}
                if "effectsIdx" in props:
                    res[int(props["effectsIdx"])] = {"path": f"{ti},{ci}", "values": props}
        return res

    def _pad_fx_path(self, pad_idx):
        info = getattr(self, "_pad_fx_nodes", {}).get(pad_idx)
        if info:
            return info["path"]
        dump = self.bridge.dump_state()  # worker thread: node may have just been created
        if dump:
            self._pad_fx_nodes = self._map_pad_fx_nodes(dump)
            info = self._pad_fx_nodes.get(pad_idx)
            return info["path"] if info else None
        return None

    # Defaults of a fresh EFFECTS_PARAMETERS block (as RØDE Unify creates it)
    PAD_FX_DEFAULTS = [
        ("reverbOn", "bool:false"), ("reverbMix", "f64:0.5"), ("reverbModel", "f64:0.6"),
        ("reverbLowCut", "f64:0.6661"), ("reverbHighCut", "f64:0.3333"),
        ("echoOn", "bool:false"), ("echoMix", "f64:0.5"), ("echoDelay", "f64:0.165"),
        ("echoDecay", "f64:0.5"), ("echoLowCut", "f64:0.5"), ("echoHighCut", "f64:0.5"),
        ("distortionOn", "bool:false"), ("distortionIntensity", "f64:0.7"),
        ("robotOn", "bool:false"), ("robotMix", "f64:0.0"), ("robotLevel", "f64:0.0"),
        ("voiceDisguiseOn", "bool:false"),
        ("pitchShiftOn", "bool:false"), ("pitchShiftSemitones", "f64:7.0"),
    ]

    def _ensure_fx_pad(self, pad):
        """Local state: turn the current pad into a voice-FX pad. Returns True if the
        hardware still has to be converted (see _hw_make_fx_pad)."""
        raw_type = (pad.get("_raw") or {}).get("padType")
        if pad.get("type") == "fx" and raw_type == 2:
            return False
        col = 7
        pad["type"] = "fx"
        pad["file"] = ""
        pad["name"] = "Voice FX"
        pad["color_idx"] = col
        pad["color_hex"] = PAD_COLORS[col]["hex"]
        pad.setdefault("fx_mode", 1)
        pad.setdefault("fx", {})
        pad["fx_channel"] = 7 if self._is_streamer_x else int(pad.get("fx_channel", 0))
        return True

    _fx_create_lock = threading.Lock()

    def _hw_ensure_fx_pad_locked(self, pad, b_str, p_str):
        """Serialise pad creation: the executor has 2 workers and a burst of slider
        moves must not create duplicate PAD / EFFECTS_PARAMETERS nodes."""
        with self._fx_create_lock:
            if (pad.get("_raw") or {}).get("padType") == 2 and int(pad.get("idx", -1)) in getattr(self, "_pad_fx_nodes", {}):
                return True
            return self._hw_make_fx_pad(pad, b_str, p_str)

    def _hw_make_fx_pad(self, pad, b_str, p_str):
        """Worker thread. Mirrors RØDE Unify: an FX pad needs its own
        PADEFFECTS/EFFECTS_PARAMETERS block, which the device does not create by itself."""
        pad_idx = int(pad.get("idx", 0))
        dump = self.bridge.dump_state()
        if not dump:
            return False
        children = dump.get("children", [])
        sp_i = next((i for i, c in enumerate(children) if c.get("name") == "SOUNDPADS"), None)
        pe_i = next((i for i, c in enumerate(children) if c.get("name") == "PADEFFECTS"), None)
        if sp_i is None or pe_i is None:
            logger.warning("SOUNDPADS / PADEFFECTS not found; cannot create FX pad")
            return False

        def pad_node(dmp):
            for c in dmp["children"][sp_i].get("children", []):
                pr = {k: list(v.values())[0] for k, v in c.get("properties", {}).items()}
                if pr.get("padIdx") == pad_idx:
                    return pr
            return None

        # 1. Effect block for this pad
        fx_nodes = self._map_pad_fx_nodes(dump)
        if pad_idx not in fx_nodes:
            insert = len(children[pe_i].get("children", []))
            props = [f"effectsIdx=u32:{pad_idx}"] + [f"{k}={v}" for k, v in self.PAD_FX_DEFAULTS]
            _, err = self.bridge.run_cmd(["add-child", str(pe_i), str(insert), "EFFECTS_PARAMETERS"] + props, timeout=10)
            logger.info(f"Created EFFECTS_PARAMETERS for pad {pad_idx}" + (f" FAILED: {err.strip()}" if err else ""))
            if err:
                return False

        # 2. A pad of another type is removed first (changing its type in place deletes it)
        existing = pad_node(dump)
        if existing is not None and existing.get("padType") != 2:
            self.bridge.clear_pad(b_str, p_str)
            dump = self.bridge.dump_state() or dump
            existing = pad_node(dump)

        # 3. Create the FX pad node with the full property set
        if existing is None:
            insert = len(dump["children"][sp_i].get("children", []))
            fx_input = int(pad.get("fx_channel", 7 if self._is_streamer_x else 0))
            props = [
                f"padIdx=u32:{pad_idx}", "padType=u32:2", "padName=str:Voice_FX", "padFilePath=str:",
                f"padColourIndex=u32:{int(pad.get('color_idx', 7))}", "padGain=f64:-12.0",
                "padLoop=bool:false", "padReplay=bool:false", "padActive=bool:false", "padPlayMode=u32:0",
                "padTriggerMode=u32:1", "padTriggerType=u32:0", f"padTriggerControl=u32:{pad_idx}",
                "padTriggerOn=u32:127", "padTriggerOff=u32:0", "padTriggerSend=u32:2",
                "padTriggerChannel=u32:1", "padTriggerCustom=bool:false", "padIsInternal=bool:false",
                f"padEffectInput=u32:{fx_input}", f"padEffectTriggerMode=u32:{int(pad.get('fx_mode', 1))}",
                "padEnvStart=f64:0.0", "padEnvStop=f64:0.0", "padEnvFadeIn=f64:0.0", "padEnvFadeOut=f64:0.0",
                "padMixerMode=u32:0", "padMixerTriggerMode=u32:0", "padMixerFadeInSeconds=f64:0.0",
                "padMixerFadeOutSeconds=f64:0.0", "padMixerFadeExcludeHost=bool:false",
                "padMixerCensorCustom=bool:false", "padMixerCensorFilePath=str:",
            ]
            _, err = self.bridge.run_cmd(["add-child", str(sp_i), str(insert), "PAD"] + props, timeout=10)
            logger.info(f"Created FX PAD {pad_idx}" + (f" FAILED: {err.strip()}" if err else ""))
            if err:
                return False

        dump = self.bridge.dump_state()
        if dump:
            self._pad_fx_nodes = self._map_pad_fx_nodes(dump)
            hw = pad_node(dump)
            if hw:
                pad["_raw"] = {k: v for k, v in hw.items() if isinstance(v, (int, float, str, bool))}
        return pad_idx in getattr(self, "_pad_fx_nodes", {})

    @staticmethod
    def _fx_val_str(prop, value):
        if prop.endswith("On"):
            return f"bool:{str(bool(value)).lower()}"
        return f"f64:{float(value):.4f}"

    @pyqtSlot(str, "QVariant")
    def setPadFxParam(self, prop, value):
        """Set one effect flag / parameter on the selected pad (converts it to an FX pad)."""
        if prop not in self.PAD_FX_PROPS:
            return
        pad = self._get_current_pad()
        if not pad:
            return
        needs_hw = self._ensure_fx_pad(pad)
        fx = dict(pad.get("fx") or {})
        fx[prop] = bool(value) if prop.endswith("On") else float(value)
        pad["fx"] = fx
        self.padsChanged.emit()
        self.selectedPadChanged.emit()
        if not (self._connected and not self._permission_error):
            return
        b_str, p_str = str(self._current_bank), str(self._selected_pad_index)
        pad_idx = int(pad.get("idx", self._current_bank * self._pads_per_bank + self._selected_pad_index))
        val = self._fx_val_str(prop, value)
        self._pending_fx_writes = getattr(self, "_pending_fx_writes", {})
        self._pending_fx_writes[(pad_idx, prop)] = val

        def do_set():
            if needs_hw and not self._hw_ensure_fx_pad_locked(pad, b_str, p_str):
                logger.warning(f"Could not create FX pad {pad_idx}")
                return
            v = self._pending_fx_writes.pop((pad_idx, prop), None)
            if v is None:
                return  # a newer value for the same control is already queued
            path = self._pad_fx_path(pad_idx)
            if not path:
                logger.warning(f"No PADEFFECTS node for pad {pad_idx}; cannot set {prop}")
                return
            _, err = self.bridge.run_cmd(["set-property", path, prop, v])
            logger.info(f"Pad FX {pad_idx} [{path}] {prop}={v}" + (f" FAILED: {err.strip()}" if err else ""))
        self.executor.submit(do_set)

    @pyqtSlot(int)
    def setPadFxTrigger(self, mode):
        """1 = Latching, 0 = Momentary (padEffectTriggerMode)."""
        pad = self._get_current_pad()
        if not pad:
            return
        needs_hw = self._ensure_fx_pad(pad)
        pad["fx_mode"] = 1 if mode else 0
        self.padsChanged.emit()
        self.selectedPadChanged.emit()
        if self._connected and not self._permission_error:
            b_str, p_str = str(self._current_bank), str(self._selected_pad_index)
            def do_set():
                if needs_hw and not self._hw_ensure_fx_pad_locked(pad, b_str, p_str):
                    return
                self._send_pad_props(b_str, p_str, [("padEffectTriggerMode", f"u32:{pad['fx_mode']}")],
                                     pad.setdefault("_raw", {}))
            self.executor.submit(do_set)

    @pyqtSlot(int)
    def setPadFxInput(self, ch):
        """Duo / Pro II: which microphone the pad's effects apply to."""
        pad = self._get_current_pad()
        if not pad or self._is_streamer_x:
            return
        pad["fx_channel"] = int(ch)
        self.padsChanged.emit()
        self.selectedPadChanged.emit()
        if self._connected and not self._permission_error and pad.get("type") == "fx":
            self.executor.submit(self._send_pad_props, str(self._current_bank), str(self._selected_pad_index),
                                 [("padEffectInput", f"u32:{int(ch)}")], pad.setdefault("_raw", {}))

    @pyqtSlot(int)
    def setPadMixerTrigger(self, mode):
        """Mixer pads: 1 = Latching, 0 = Momentary (padMixerTriggerMode)."""
        pad = self._get_current_pad()
        if not pad or pad.get("type") != "mixer":
            return
        pad["mixer_trigger"] = 1 if mode else 0
        self.padsChanged.emit()
        self.selectedPadChanged.emit()
        if self._connected and not self._permission_error:
            self.executor.submit(self._send_pad_props, str(self._current_bank), str(self._selected_pad_index),
                                 [("padMixerTriggerMode", f"u32:{pad['mixer_trigger']}")], pad.setdefault("_raw", {}))

    # PAD.padMixerMode values, in the order the official RØDECaster App lists them
    # (the factory "Censor" pad reads padType=3 / padMixerMode=0).
    PAD_MIXER_MODES = {0: "Censor", 1: "Trash Talk", 2: "Fade In/Out", 3: "Back Channel", 4: "Ducking"}

    @pyqtSlot(int)
    def assignPadMixer(self, mode):
        """Turn the current pad into a real mixer pad (padType 3) with the given mode."""
        if mode not in self.PAD_MIXER_MODES:
            return
        if mode == 1 and self._is_streamer_x:
            # RØDE Unify only offers Censor, Fade In/Out and Ducking on the Streamer X
            logger.warning("Trash Talk is not available on the Streamer X")
            return
        if mode == 3:
            # Back Channel: on the Streamer X this produced the Censor tone and reset the
            # unit; not verified on Duo / Pro II either, so refuse it until it is.
            logger.warning("Back Channel mixer pads are disabled (unverified mode number)")
            return
        pad = self._get_current_pad()
        if not pad:
            return
        name = self.PAD_MIXER_MODES[mode]
        col = {0: 4, 1: 6, 2: 8, 3: 10, 4: 2}.get(mode, 4)
        if mode == 3 and not pad.get("back_channel"):
            pad["back_channel"] = {k: False for k in self.BACK_CHANNEL_KEYS}
        pad["type"] = "mixer"
        pad["name"] = name
        pad["file"] = ""
        pad["mixer_mode"] = mode
        pad["mixer_trigger"] = 0 if mode == 0 else 1
        pad["color_idx"] = col
        pad["color_hex"] = PAD_COLORS[col]["hex"]
        self.padsChanged.emit()
        self.selectedPadChanged.emit()

        if self._connected and not self._permission_error:
            b_str = str(self._current_bank)
            p_str = str(self._selected_pad_index)
            raw = pad.setdefault("_raw", {})
            fade = "f64:3.0" if mode == 2 else "f64:0.0"
            props = [
                ("padType", "u32:3"),
                ("padFilePath", "str:"),
                ("padName", f"str:{name.replace(' ', '_')}"),
                ("padColourIndex", f"u32:{col}"),
                # Fade options go before the mode: the firmware reads them when the mode is set
                ("padMixerFadeInSeconds", fade),
                ("padMixerFadeOutSeconds", fade),
                ("padMixerFadeExcludeHost", f"bool:{str(bool(pad.get('fade_exclude_host', False))).lower()}"),
                ("padMixerMode", f"u32:{mode}"),
                # Censor is momentary, Fade / Ducking latch (RØDE Unify defaults)
                ("padMixerTriggerMode", f"u32:{0 if mode == 0 else 1}"),
                ("padPlayMode", "u32:1"),
                ("padActive", "bool:false"),
            ]
            self.executor.submit(self._send_pad_props, b_str, p_str, props, raw)
        self.toastMessage.emit((f"Mixer pad '{name}' configured" if self._language == "en"
                                else f"Pad de mezclador '{name}' configurado"))

    # PAD.padMixerBackChannel<key> flags (Duo / Pro II). The Streamer X has no picker:
    # its Back Channel always pulls every audio device and Chat out of the stream mix.
    BACK_CHANNEL_KEYS = ("Mic2", "Mic3", "Mic4", "Usb1Comms", "Usb2Main", "Bluetooth")

    @pyqtSlot(str, bool)
    def setPadBackChannel(self, key, enabled):
        if key not in self.BACK_CHANNEL_KEYS:
            return
        pad = self._get_current_pad()
        if not pad:
            return
        bc = dict(pad.get("back_channel") or {})
        bc[key] = bool(enabled)
        pad["back_channel"] = bc
        self.padsChanged.emit()
        self.selectedPadChanged.emit()
        if self._connected and not self._permission_error:
            b_str, p_str = str(self._current_bank), str(self._selected_pad_index)
            prop, val = f"padMixerBackChannel{key}", f"bool:{str(bool(enabled)).lower()}"
            def do_set():
                _, err = self.bridge.run_cmd(["pad", "set-prop", b_str, p_str, prop, val])
                logger.info(f"Pad {b_str}/{p_str}: {prop}={val}" + (f" FAILED: {err.strip()}" if err else ""))
                if not err:
                    pad.setdefault("_raw", {})[prop] = bool(enabled)
            self.executor.submit(do_set)

    @pyqtSlot(bool)
    def setPadFadeExcludeHost(self, exclude):
        """Fade In/Out pads: keep the host microphone live while everything else fades."""
        pad = self._get_current_pad()
        if not pad:
            return
        pad["fade_exclude_host"] = bool(exclude)
        self.padsChanged.emit()
        self.selectedPadChanged.emit()
        if self._connected and not self._permission_error:
            b_str, p_str = str(self._current_bank), str(self._selected_pad_index)
            mode = int(pad.get("mixer_mode", 2))
            excl = f"bool:{str(bool(exclude)).lower()}"
            def do_set():
                # The firmware applies this live on a Fade pad: no need to touch the mode
                # (re-arming through mode 0 briefly turned the pad into a Censor pad).
                _, err = self.bridge.run_cmd(["pad", "set-prop", b_str, p_str, "padMixerFadeExcludeHost", excl])
                logger.info(f"Pad {b_str}/{p_str} (mode {mode}): padMixerFadeExcludeHost={excl}"
                            + (f" FAILED: {err.strip()}" if err else ""))
                if not err:
                    pad.setdefault("_raw", {})["padMixerFadeExcludeHost"] = bool(exclude)
            self.executor.submit(do_set)

    @pyqtSlot(str)
    def updatePadType(self, ptype):
        pad = self._get_current_pad()
        if not pad:
            return
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
        self.toastMessage.emit("Syncing..." if self._language == "en" else "Sincronizando...")

    @pyqtProperty(bool, notify=deviceConfigChanged)
    def streamerXUnifyInstalled(self):
        return StreamerXAudioRouter.is_unify_profile_installed()

    @pyqtSlot(result=bool)
    def toggleStreamerXUnifyProfile(self):
        if StreamerXAudioRouter.is_unify_profile_installed():
            res = StreamerXAudioRouter.remove_unify_profile()
            self.toastMessage.emit("UNIFY profile (PipeWire) disabled" if self._language == "en" else "Perfil UNIFY (PipeWire) desactivado")
        else:
            res = StreamerXAudioRouter.install_unify_profile()
            self.toastMessage.emit("UNIFY profile (Multitrack PipeWire) enabled" if self._language == "en" else "Perfil UNIFY (Multipista PipeWire) activado")
        self.deviceConfigChanged.emit()
        return res

    # Streamer X USB multitrack: OUTPUT.outputMultiMode = 2 makes the unit re-enumerate
    # as "Streamer X Main Multitrack" (PID 0x0055) with 9 capture channels, exactly
    # what RØDE UNIFY enables on macOS/Windows.
    STREAMER_X_MULTITRACK_PID = "0055"

    def _restore_streamer_x_self_monitor(self, retries=10):
        """Re-enumerating into/out of multitrack reloads the unit state and drops the
        microphone from the headphone mix, so you stop hearing yourself.
        Ensure Mic (src 0) is monitored on headphone bus 0, and keep unused Headset
        (src 1) muted so its open analog preamp does not inject white noise."""
        import time
        for _ in range(retries):
            dump = self.bridge.dump_state()
            children = dump.get("children", []) if dump else []
            mix_nodes = [i for i, c in enumerate(children) if c.get("name") == "MIX"]
            if len(mix_nodes) >= 20:
                # 1. Ensure XLR Mic (src 0) is audible in headphones
                mic_node = mix_nodes[0]
                props = children[mic_node].get("properties", {})
                raw = str(list(props.get("mixLevelWithAnchor", {"": ""}).values())[0])
                try:
                    lvl = float(raw.split("|")[0])
                except ValueError:
                    lvl = -1.0
                if lvl <= 0.0:
                    logger.info(f"Restoring Streamer X microphone monitoring on MIX node {mic_node}")
                    self.bridge.run_cmd(["set-property", str(mic_node), "mixLevelWithAnchor", "str:0.7|-1"])

                # 2. Ensure Headset Mic (src 1) is NOT sending open-circuit hiss to headphones
                headset_node = mix_nodes[10]
                h_props = children[headset_node].get("properties", {})
                h_raw = str(list(h_props.get("mixLevelWithAnchor", {"": ""}).values())[0])
                try:
                    h_lvl = float(h_raw.split("|")[0])
                except ValueError:
                    h_lvl = -1.0
                if h_lvl > 0.0:
                    logger.info(f"Muting unused Headset open preamp on MIX node {headset_node}")
                    self.bridge.run_cmd(["set-property", str(headset_node), "mixLevelWithAnchor", "str:0|-1"])
                return
            time.sleep(1.0)

    @pyqtProperty(bool, notify=deviceConfigChanged)
    def streamerXMultitrack(self):
        return self._is_streamer_x and str(self.bridge.target_pid) == self.STREAMER_X_MULTITRACK_PID

    @pyqtSlot(bool)
    def setStreamerXMultitrack(self, enabled):
        if not self._is_streamer_x or not self._connected or self._permission_error:
            return
        if enabled == self.streamerXMultitrack:
            return
        if self._language == "en":
            self.toastMessage.emit("Switching Streamer X to USB multitrack mode..." if enabled
                                   else "Switching Streamer X to USB stereo mode...")
        else:
            self.toastMessage.emit("Cambiando la Streamer X a modo multipista USB..." if enabled
                                   else "Volviendo la Streamer X a modo estéreo USB...")

        def do_switch():
            import time
            self.bridge.run_cmd(["set-property", "13", "outputMultiMode", f"u32:{2 if enabled else 0}"])
            # The unit re-enumerates on USB: wait for PipeWire to expose the new capture device
            want_multi = bool(enabled)
            for _ in range(30):
                time.sleep(0.5)
                src = StreamerXAudioRouter.get_streamer_x_nodes().get("source")
                if src and StreamerXAudioRouter.is_multitrack_source(src) == want_multi:
                    break
            # Virtual UNIFY devices point at the old ALSA nodes: rebuild them for the new layout
            if StreamerXAudioRouter.is_unify_profile_installed():
                StreamerXAudioRouter.install_unify_profile()
            self._restore_streamer_x_self_monitor()
            self.deviceConfigChanged.emit()
            if self._language == "en":
                self.toastMessage.emit("Multitrack mode active: 9 USB channels" if enabled else "Standard stereo USB mode active")
            else:
                self.toastMessage.emit("Modo multipista activo: 9 canales por USB" if enabled else "Modo estéreo USB activo")

        self.executor.submit(do_switch)

    # DSP Processing Properties & Slots
    @pyqtProperty("QVariantList", notify=dspChanged)
    def dspChannels(self):
        return [
            {"id": i, "name": self._localized_dsp_channel_name(i), "channel_idx": ch.get("channel_idx", 28 + i)}
            for i, ch in enumerate(self._dsp_channels)
        ]

    @pyqtProperty(int, notify=activeDspChannelChanged)
    def activeDspChannel(self):
        return self._active_dsp_channel

    @pyqtSlot(int)
    def setActiveDspChannel(self, idx):
        if 0 <= idx < len(self._dsp_channels) and idx != self._active_dsp_channel:
            self._active_dsp_channel = idx
            self.activeDspChannelChanged.emit()
            self.dspChanged.emit()

    @pyqtProperty("QVariantMap", notify=dspChanged)
    def currentDsp(self):
        if 0 <= self._active_dsp_channel < len(self._dsp_channels):
            return self._dsp_channels[self._active_dsp_channel]
        return {}

    @pyqtSlot(str, "QVariant")
    def setDspParameter(self, name, value):
        if not (0 <= self._active_dsp_channel < len(self._dsp_channels)):
            return
        ch = self._dsp_channels[self._active_dsp_channel]
        prev = ch.get(name)
        unchanged = prev is not None and (
            prev == value if isinstance(value, (bool, str)) or isinstance(prev, bool)
            else abs(float(prev) - float(value)) < 1e-4)
        ch[name] = value
        if unchanged and ch.get("_synced"):
            return  # device already has this value: no hardware round-trip
        if name != "active_preset" and not name.startswith("voxlab_"):
            ch["active_preset"] = detect_dsp_preset(ch)
        self.dspChanged.emit()

        if not self._connected or self._permission_error:
            return

        channel_node_idx = ch.get("channel_idx", 28 + self._active_dsp_channel)
        input_node_idx = ch.get("input_idx", 191 + self._active_dsp_channel)

        if name == "preamp_gain":
            val_str = f"u32:{int(value)}"
            self._pending_dsp_updates[(input_node_idx, "inputMicrophoneGain")] = val_str
            self._dsp_timer.start()
        elif name == "phantom_power":
            val_str = f"u32:{1 if value else 0}"
            self._pending_dsp_updates[(input_node_idx, "inputPower")] = val_str
            self._flush_dsp_hardware()
        elif name == "phase_flip":
            val_str = f"bool:{str(bool(value)).lower()}"
            self._pending_dsp_updates[(input_node_idx, "inputPhaseFlip")] = val_str
            self._flush_dsp_hardware()
        else:
            prop_map = {
                "bypass_processing": ("channelBypassProcessing", "bool"),
                "aphex_on": ("aphexOn", "bool"),
                "aphex_ae_mix": ("aphexAEMix", "f64"),
                "aphex_ae_tune": ("aphexAETune", "f64"),
                "aphex_bb_drive": ("aphexBBDrive", "f64"),
                "aphex_bb_tune": ("aphexBBTune", "f64"),
                "noise_gate_on": ("noiseGateOn", "bool"),
                "noise_gate_threshold": ("noiseGateThreshold", "f64"),
                "noise_gate_range": ("noiseGateRange", "f64"),
                "noise_gate_attack": ("noiseGateAttack", "f64"),
                "noise_gate_release": ("noiseGateRelease", "f64"),
                "noise_gate_hold": ("noiseGateHold", "f64"),
                "compressor_on": ("compressorOn", "bool"),
                "compressor_threshold": ("compressorThreshold", "f64"),
                "compressor_ratio": ("compressorRatio", "f64"),
                "compressor_gain": ("compressorGain", "f64"),
                "compressor_attack": ("compressorAttack", "f64"),
                "compressor_release": ("compressorRelease", "f64"),
                "hpf_on": ("hpfOn", "bool"),
                "hpf_frequency": ("hpfFrequency", "f64"),
                "deesser_on": ("deesserOn", "bool"),
                "deesser_threshold": ("deesserThreshold", "f64"),
                "deesser_ratio": ("deesserRatio", "f64"),
                "eq_on": ("eqOn", "bool"),
                "eq_low": ("eqLowGain", "f64"),
                "eq_mid": ("eqMidGain", "f64"),
                "eq_high": ("eqHighGain", "f64"),
            }
            if name in prop_map:
                if name != "bypass_processing" and ch.get("bypass_processing"):
                    ch["bypass_processing"] = False
                    self._pending_dsp_updates[(channel_node_idx, "channelBypassProcessing")] = "bool:false"
                hw_prop, hw_type = prop_map[name]
                if hw_type == "bool":
                    val_str = f"bool:{str(bool(value)).lower()}"
                    self._pending_dsp_updates[(channel_node_idx, hw_prop)] = val_str
                    self._flush_dsp_hardware()
                elif hw_type == "f64":
                    val_str = f"f64:{float(value):.4f}"
                    self._pending_dsp_updates[(channel_node_idx, hw_prop)] = val_str
                    self._dsp_timer.start()

    def _flush_dsp_hardware(self):
        if not self._connected or self._permission_error or not self._pending_dsp_updates:
            return
        to_send = list(self._pending_dsp_updates.items())
        self._pending_dsp_updates.clear()
        def do_send():
            for (node_idx, prop_name), val_str in to_send:
                logger.info(f"Setting DSP hardware: node {node_idx} {prop_name} = {val_str}")
                self.bridge.run_cmd(["set-property", str(node_idx), prop_name, str(val_str)])
        self.executor.submit(do_send)

    @pyqtSlot(str, int)
    def setVoxlabMacro(self, macro_name, value):
        """
        Adjusts VoxLab macro controls (depth, sparkle, punch) and synchronizes with hardware DSP.
        """
        if not (0 <= self._active_dsp_channel < len(self._dsp_channels)):
            return
        ch = self._dsp_channels[self._active_dsp_channel]
        val = max(0, min(100, int(value)))
        norm_val = val / 100.0

        if macro_name == "depth":
            ch["voxlab_depth"] = val
            if val > 0 and not ch.get("aphex_on", False):
                self.setDspParameter("aphex_on", True)
            self.setDspParameter("aphex_bb_drive", norm_val)
        elif macro_name == "sparkle":
            ch["voxlab_sparkle"] = val
            if val > 0 and not ch.get("aphex_on", False):
                self.setDspParameter("aphex_on", True)
            self.setDspParameter("aphex_ae_mix", norm_val)
        elif macro_name == "punch":
            ch["voxlab_punch"] = val
            comp_thresh = 1.0 - (norm_val * 0.55)
            comp_ratio = 0.25 + (norm_val * 0.55)
            comp_gain = norm_val * 0.35
            if val > 0 and not ch.get("compressor_on", False):
                self.setDspParameter("compressor_on", True)
            self.setDspParameter("compressor_threshold", comp_thresh)
            self.setDspParameter("compressor_ratio", comp_ratio)
            self.setDspParameter("compressor_gain", comp_gain)

        ch["active_preset"] = "custom"
        self.dspChanged.emit()

    @pyqtSlot(str)
    def applyDspPreset(self, preset_name):
        """
        Applies standard studio voice presets to active DSP channel.
        Presets: 'broadcast', 'podcast', 'gaming', 'neutral'
        """
        if not (0 <= self._active_dsp_channel < len(self._dsp_channels)):
            return
        ch = self._dsp_channels[self._active_dsp_channel]

        presets = DSP_PRESETS

        if preset_name in presets:
            p_data = presets[preset_name]
            for k, v in p_data.items():
                self.setDspParameter(k, v)
            ch["active_preset"] = preset_name
            self.dspChanged.emit()
            preset_labels = {
                "broadcast": "Broadcast",
                "podcast": "Podcast Studio",
                "gaming": "Streaming / Gaming",
                "neutral": "Neutro / Plano"
            }
            label = preset_labels.get(preset_name, preset_name)
            msg = f"Perfil de voz '{label}' aplicado" if self._language == "es" else f"Voice profile '{label}' applied"
            self.toastMessage.emit(msg)

    @pyqtSlot()
    def openAudioProcessing(self):
        self.navigateTo("audio_processing")
