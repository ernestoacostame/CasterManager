"""
Streamer X PipeWire Multitrack Routing (UNIFY on Linux)

Provides virtual audio sinks and submixes for RØDE Streamer X on Linux,
replicating the functionality of RØDE UNIFY (Game, Chat, Music, System, Stream Mix, Chat Mix)
using PipeWire native loopback and combine modules.
"""

import os
import shutil
import subprocess
import json
import logging
from typing import Dict, List, Optional

logger = logging.getLogger("CasterManager.streamerx_audio")

PIPEWIRE_CONF_DIR = os.path.expanduser("~/.config/pipewire/pipewire.conf.d")
STREAMERX_CONF_PATH = os.path.join(PIPEWIRE_CONF_DIR, "99-streamerx-unify.conf")

ASOUNDRC_PATH = os.path.expanduser("~/.asoundrc")
ASOUND_UNIFY_BLOCK = """# --- RODE UNIFY START ---
pcm.UNIFY_StreamMix {
    type pulse
    device "unify_stream_mix_in"
    hint { show on description "UNIFY - Stream Mix (Broadcast / OBS)" }
}
pcm.UNIFY_Game {
    type pulse
    device "unify_game_in"
    hint { show on description "UNIFY - Game" }
}
pcm.UNIFY_Chat {
    type pulse
    device "unify_chat_in"
    hint { show on description "UNIFY - Chat" }
}
pcm.UNIFY_Music {
    type pulse
    device "unify_music_in"
    hint { show on description "UNIFY - Music" }
}
pcm.UNIFY_System {
    type pulse
    device "unify_system_in"
    hint { show on description "UNIFY - System" }
}
# --- RODE UNIFY END ---
"""

class StreamerXAudioRouter:
    """
    Manages PipeWire and ALSA routing and virtual audio sinks/sources for RØDE Streamer X.
    """

    CHANNELS = [
        ("streamerx_game", "UNIFY-Game", "unify_game_in"),
        ("streamerx_chat", "UNIFY-Chat", "unify_chat_in"),
        ("streamerx_music", "UNIFY-Music", "unify_music_in"),
        ("streamerx_system", "UNIFY-System", "unify_system_in"),
        ("streamerx_stream_mix", "UNIFY-StreamMix", "unify_stream_mix_in"),
    ]

    # USB multitrack mode (OUTPUT.outputMultiMode = 2, USB PID 0x0055): the capture
    # device exposes 9 mono channels, one per UNIFY slot. Each entry becomes a named
    # PipeWire source so a DAW can record every input on its own track.
    # (source name, description, multichannel positions, output positions)
    MULTITRACK_SOURCES = [
        ("streamerx_mt_mic", "Streamer X - Micrófono", "aux0", "mono"),
        ("streamerx_mt_headset", "Streamer X - Headset", "aux1", "mono"),
        ("streamerx_mt_wireless", "Streamer X - Wireless", "aux2", "mono"),
        ("streamerx_mt_pads", "Streamer X - SMART Pads", "aux3,aux4", "front-left,front-right"),
        ("streamerx_mt_aux67", "Streamer X - Canales 6-7", "aux5,aux6", "front-left,front-right"),
        ("streamerx_mt_aux89", "Streamer X - Canales 8-9", "aux7,aux8", "front-left,front-right"),
    ]

    @staticmethod
    def is_multitrack_source(source_name: Optional[str]) -> bool:
        return bool(source_name) and "multichannel" in source_name

    @staticmethod
    def get_streamer_x_nodes() -> Dict[str, Optional[str]]:
        """Finds the current PipeWire sink and source node names for Streamer X."""
        sink_name = None
        source_name = None

        try:
            out = subprocess.run(["pw-dump"], capture_output=True, text=True, timeout=3).stdout
            nodes = json.loads(out)
            for n in nodes:
                props = n.get("info", {}).get("props", {})
                name = props.get("node.name", "")
                media_class = props.get("media.class", "")
                # Only the real ALSA device: our own virtual nodes are also named "streamerx_*"
                if name.startswith("alsa_") and "streamer_x" in name.lower():
                    if media_class == "Audio/Sink" and not sink_name:
                        sink_name = name
                    elif media_class == "Audio/Source" and not source_name:
                        source_name = name
        except Exception as e:
            logger.warning(f"Error querying PipeWire nodes: {e}")

        # Fallback to standard naming if not directly discovered
        if not sink_name:
            sink_name = "alsa_output.usb-RODE_Streamer_X_HT0004996-00.analog-stereo"
        if not source_name:
            source_name = "alsa_input.usb-RODE_Streamer_X_HT0004996-00.analog-stereo"

        return {"sink": sink_name, "source": source_name}

    @classmethod
    def is_unify_profile_installed(cls) -> bool:
        """Checks if the UNIFY virtual audio sinks are actively loaded in PipeWire/PulseAudio."""
        try:
            res = subprocess.run(["pactl", "list", "sinks", "short"], capture_output=True, text=True, timeout=2)
            if res.returncode == 0 and "streamerx_game" in res.stdout:
                return True
        except Exception:
            pass
        return False

    @classmethod
    def generate_pipewire_config(cls, hw_sink: str, hw_source: str) -> str:
        """
        Generates PipeWire SPA-JSON configuration creating virtual sinks
        matching RØDE UNIFY: Game, Chat, Music, System, Stream Mix, Chat Mix.
        """
        config = f"""# RØDE Streamer X - UNIFY Architecture for PipeWire (Linux)
# Generated automatically by CasterManager
# Replicates RØDE UNIFY multitrack virtual channels with mix-minus routing

context.modules = [
    # 1. Virtual Sink: Game
    {{
        name = libpipewire-module-loopback
        args = {{
            node.description = "Streamer X - Game (UNIFY)"
            capture.props = {{
                node.name = "streamerx_game"
                node.description = "Streamer X - Game (UNIFY)"
                media.class = "Audio/Sink"
                audio.position = [ FL FR ]
            }}
            playback.props = {{
                node.name = "streamerx_game_out"
                audio.position = [ FL FR ]
                target.object = "{hw_sink}"
            }}
        }}
    }}

    # 2. Virtual Sink: Chat (Discord, Teams, Zoom)
    {{
        name = libpipewire-module-loopback
        args = {{
            node.description = "Streamer X - Chat (UNIFY)"
            capture.props = {{
                node.name = "streamerx_chat"
                node.description = "Streamer X - Chat (UNIFY)"
                media.class = "Audio/Sink"
                audio.position = [ FL FR ]
            }}
            playback.props = {{
                node.name = "streamerx_chat_out"
                audio.position = [ FL FR ]
                target.object = "{hw_sink}"
            }}
        }}
    }}

    # 3. Virtual Sink: Music (Spotify, Browser, Music Player)
    {{
        name = libpipewire-module-loopback
        args = {{
            node.description = "Streamer X - Music (UNIFY)"
            capture.props = {{
                node.name = "streamerx_music"
                node.description = "Streamer X - Music (UNIFY)"
                media.class = "Audio/Sink"
                audio.position = [ FL FR ]
            }}
            playback.props = {{
                node.name = "streamerx_music_out"
                audio.position = [ FL FR ]
                target.object = "{hw_sink}"
            }}
        }}
    }}

    # 4. Virtual Sink: System (OS Alerts, Notifications)
    {{
        name = libpipewire-module-loopback
        args = {{
            node.description = "Streamer X - System (UNIFY)"
            capture.props = {{
                node.name = "streamerx_system"
                node.description = "Streamer X - System (UNIFY)"
                media.class = "Audio/Sink"
                audio.position = [ FL FR ]
            }}
            playback.props = {{
                node.name = "streamerx_system_out"
                audio.position = [ FL FR ]
                target.object = "{hw_sink}"
            }}
        }}
    }}

    # 5. Virtual Source: Stream Mix (Broadcast submix for OBS Studio and DAWs)
    {{
        name = libpipewire-module-loopback
        args = {{
            node.description = "Streamer X - Stream Mix (UNIFY OBS/DAW)"
            capture.props = {{
                node.name = "streamerx_stream_mix_in"
                audio.position = [ FL FR ]
                target.object = "{hw_source}"
            }}
            playback.props = {{
                node.name = "streamerx_stream_mix"
                node.description = "Streamer X - Stream Mix (UNIFY OBS/DAW)"
                media.class = "Audio/Source"
                audio.position = [ FL FR ]
            }}
        }}
    }}
]
"""
        return config

    @classmethod
    def install_unify_profile(cls) -> bool:
        """
        Loads UNIFY virtual devices on-demand in PipeWire/PulseAudio via pactl,
        providing both playback sinks and recording sources (visible to OBS Studio,
        DAWs like KutEditor/Reaper, and system mixers) with zero PipeWire restarts.
        """
        try:
            nodes = cls.get_streamer_x_nodes()
            hw_sink = nodes.get("sink") or "alsa_output.usb-RODE_Streamer_X_HT0004996-00.analog-stereo"
            hw_source = nodes.get("source") or "alsa_input.usb-RODE_Streamer_X_HT0004996-00.analog-stereo"

            # 1. First remove any previous instances to avoid duplicates
            cls.remove_unify_profile(reload_services=False)

            multitrack = cls.is_multitrack_source(hw_source)

            # 2. Hot-load virtual playback sinks, loopbacks and recording sources immediately
            loaded_ids = []

            if multitrack:
                # One named source per hardware channel (Mic, Headset, Wireless, Pads...)
                for src_name, desc, master_map, out_map in cls.MULTITRACK_SOURCES:
                    n_ch = len(master_map.split(","))
                    cmd_mt = [
                        "pactl", "load-module", "module-remap-source",
                        f"source_name={src_name}",
                        f"master={hw_source}",
                        f"channels={n_ch}",
                        f"master_channel_map={master_map}",
                        f"channel_map={out_map}",
                        "remix=no",
                        f"source_properties=device.description='{desc}'",
                    ]
                    res_mt = subprocess.run(cmd_mt, capture_output=True, text=True, timeout=3)
                    if res_mt.returncode == 0 and res_mt.stdout.strip().isdigit():
                        loaded_ids.append(res_mt.stdout.strip())
                    else:
                        logger.warning(f"Could not create multitrack source {src_name}: {res_mt.stderr.strip()}")
            for ch_name, ch_desc, src_name in cls.CHANNELS:
                # A) Load virtual playback sink (Output Device in KDE/System)
                cmd_sink = [
                    "pactl", "load-module", "module-null-sink",
                    f"sink_name={ch_name}",
                    f"sink_properties=device.description='{ch_desc}'"
                ]
                res_sink = subprocess.run(cmd_sink, capture_output=True, text=True, timeout=3)
                if res_sink.returncode == 0 and res_sink.stdout.strip().isdigit():
                    loaded_ids.append(res_sink.stdout.strip())

                # B) Loopback routing
                if ch_name != "streamerx_stream_mix":
                    # Loopback from channel monitor to Streamer X physical headphones
                    cmd_loop = [
                        "pactl", "load-module", "module-loopback",
                        f"source={ch_name}.monitor",
                        f"sink={hw_sink}"
                    ]
                    if multitrack:
                        # 4-channel playback in multitrack mode: feed USB 1 (FL/FR) only
                        cmd_loop += ["channels=2", "channel_map=front-left,front-right", "remix=false"]
                    res_loop = subprocess.run(cmd_loop, capture_output=True, text=True, timeout=3)
                    if res_loop.returncode == 0 and res_loop.stdout.strip().isdigit():
                        loaded_ids.append(res_loop.stdout.strip())
                else:
                    # For Stream Mix: loopback physical mic into the stream mix sink
                    cmd_mic = [
                        "pactl", "load-module", "module-loopback",
                        f"source={'streamerx_mt_mic' if multitrack else hw_source}",
                        f"sink={ch_name}"
                    ]
                    res_mic = subprocess.run(cmd_mic, capture_output=True, text=True, timeout=3)
                    if res_mic.returncode == 0 and res_mic.stdout.strip().isdigit():
                        loaded_ids.append(res_mic.stdout.strip())

                # C) Load virtual recording source (Input Device in OBS Studio, KutEditor & DAWs!)
                cmd_src = [
                    "pactl", "load-module", "module-remap-source",
                    f"source_name={src_name}",
                    f"master={ch_name}.monitor",
                    f"source_properties=device.description='{ch_desc}'"
                ]
                res_src = subprocess.run(cmd_src, capture_output=True, text=True, timeout=3)
                if res_src.returncode == 0 and res_src.stdout.strip().isdigit():
                    loaded_ids.append(res_src.stdout.strip())

            logger.info(f"Loaded {len(loaded_ids)} UNIFY PipeWire virtual sink/source modules in real-time.")

            # 3. Clean any persistent file from pipewire.conf.d so PipeWire never auto-loads it on session start
            if os.path.exists(STREAMERX_CONF_PATH):
                try:
                    os.remove(STREAMERX_CONF_PATH)
                except Exception:
                    pass

            # 4. ALSA configuration (~/.asoundrc for DAWs like Reaper, Ardour, KutEditor)
            try:
                existing_asound = ""
                if os.path.isfile(ASOUNDRC_PATH):
                    with open(ASOUNDRC_PATH, "r", encoding="utf-8") as af:
                        existing_asound = af.read()
                if "# --- RODE UNIFY START ---" not in existing_asound:
                    with open(ASOUNDRC_PATH, "a", encoding="utf-8") as af:
                        af.write("\n" + ASOUND_UNIFY_BLOCK)
            except Exception as ae:
                logger.warning(f"Could not update ~/.asoundrc: {ae}")

            return True
        except Exception as e:
            logger.error(f"Failed to install PipeWire profile: {e}")
            return False

    @classmethod
    def remove_unify_profile(cls, reload_services=True) -> bool:
        """
        Unloads active UNIFY modules immediately in real-time without restarting audio services.
        """
        try:
            # 1. Unload all modules associated with streamerx or unify sinks/sources
            try:
                out = subprocess.run(["pactl", "list", "modules", "short"], capture_output=True, text=True, timeout=3).stdout
                for line in out.splitlines():
                    parts = line.split()
                    if len(parts) >= 3:
                        mod_id = parts[0]
                        mod_args = " ".join(parts[2:]).lower()
                        if "streamerx" in mod_args or "unify" in mod_args:
                            subprocess.run(["pactl", "unload-module", mod_id], capture_output=True, timeout=2)
            except Exception as ue:
                logger.warning(f"Error unloading live modules: {ue}")

            # 2. Ensure persistent PipeWire config file is completely removed
            if os.path.exists(STREAMERX_CONF_PATH):
                try:
                    os.remove(STREAMERX_CONF_PATH)
                except Exception:
                    pass

            # 3. Clean ~/.asoundrc
            try:
                if os.path.isfile(ASOUNDRC_PATH):
                    with open(ASOUNDRC_PATH, "r", encoding="utf-8") as af:
                        asound_content = af.read()
                    if "# --- RODE UNIFY START ---" in asound_content:
                        import re
                        cleaned = re.sub(r"# --- RODE UNIFY START ---[\s\S]*?# --- RODE UNIFY END ---\n?", "", asound_content)
                        with open(ASOUNDRC_PATH, "w", encoding="utf-8") as af:
                            af.write(cleaned.strip() + "\n" if cleaned.strip() else "")
            except Exception as ae:
                logger.warning(f"Could not clean ~/.asoundrc: {ae}")

            return True
        except Exception as e:
            logger.error(f"Failed to remove PipeWire profile: {e}")
            return False
            return False

