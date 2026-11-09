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
pcm.StreamerX_Game {
    type pulse
    device "streamerx_game"
    hint { show on description "RØDE Streamer X - Game (UNIFY)" }
}
pcm.StreamerX_Chat {
    type pulse
    device "streamerx_chat"
    hint { show on description "RØDE Streamer X - Chat (UNIFY)" }
}
pcm.StreamerX_Music {
    type pulse
    device "streamerx_music"
    hint { show on description "RØDE Streamer X - Music (UNIFY)" }
}
pcm.StreamerX_System {
    type pulse
    device "streamerx_system"
    hint { show on description "RØDE Streamer X - System (UNIFY)" }
}
pcm.StreamerX_StreamMix {
    type pulse
    device "streamerx_stream_mix"
    hint { show on description "RØDE Streamer X - Stream Mix (UNIFY OBS/DAW)" }
}
# --- RODE UNIFY END ---
"""

class StreamerXAudioRouter:
    """
    Manages PipeWire and ALSA routing and virtual audio sinks for RØDE Streamer X.
    """

    CHANNELS = [
        ("streamerx_game", "UNIFY-Game"),
        ("streamerx_chat", "UNIFY-Chat"),
        ("streamerx_music", "UNIFY-Music"),
        ("streamerx_system", "UNIFY-System"),
        ("streamerx_stream_mix", "UNIFY-StreamMix"),
    ]

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
                if "streamer" in name.lower() or "streamer" in props.get("node.description", "").lower():
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
        Loads UNIFY virtual devices immediately in PipeWire/PulseAudio via pactl,
        saves ~/.asoundrc for ALSA DAWs, and writes pipewire.conf.d for session persistence.
        """
        try:
            nodes = cls.get_streamer_x_nodes()
            hw_sink = nodes.get("sink") or "alsa_output.usb-RODE_Streamer_X_HT0004996-00.analog-stereo"
            hw_source = nodes.get("source") or "alsa_input.usb-RODE_Streamer_X_HT0004996-00.analog-stereo"

            # 1. First remove any previous instances to avoid duplicates
            cls.remove_unify_profile(reload_services=False)

            # 2. Hot-load virtual sinks and loopbacks immediately
            loaded_ids = []
            for ch_name, ch_desc in cls.CHANNELS:
                # Load null-sink
                cmd_sink = [
                    "pactl", "load-module", "module-null-sink",
                    f"sink_name={ch_name}",
                    f"sink_properties=device.description='{ch_desc}'"
                ]
                res = subprocess.run(cmd_sink, capture_output=True, text=True, timeout=3)
                if res.returncode == 0 and res.stdout.strip().isdigit():
                    loaded_ids.append(res.stdout.strip())

                # For playback channels, loopback to Streamer X headphones
                if ch_name != "streamerx_stream_mix":
                    cmd_loop = [
                        "pactl", "load-module", "module-loopback",
                        f"source={ch_name}.monitor",
                        f"sink={hw_sink}"
                    ]
                    res_loop = subprocess.run(cmd_loop, capture_output=True, text=True, timeout=3)
                    if res_loop.returncode == 0 and res_loop.stdout.strip().isdigit():
                        loaded_ids.append(res_loop.stdout.strip())
                else:
                    # For Stream Mix: loopback Streamer X mic into the stream mix
                    cmd_mic = [
                        "pactl", "load-module", "module-loopback",
                        f"source={hw_source}",
                        f"sink={ch_name}"
                    ]
                    res_mic = subprocess.run(cmd_mic, capture_output=True, text=True, timeout=3)
                    if res_mic.returncode == 0 and res_mic.stdout.strip().isdigit():
                        loaded_ids.append(res_mic.stdout.strip())

            logger.info(f"Loaded {len(loaded_ids)} UNIFY PipeWire modules in real-time.")

            # 3. Write PipeWire configuration for persistence across reboots
            try:
                os.makedirs(PIPEWIRE_CONF_DIR, exist_ok=True)
                content = cls.generate_pipewire_config(hw_sink, hw_source)
                with open(STREAMERX_CONF_PATH, "w", encoding="utf-8") as f:
                    f.write(content)
            except Exception as pe:
                logger.warning(f"Could not write persistent conf: {pe}")

            # 4. ALSA configuration (~/.asoundrc for DAWs like Reaper, Ardour)
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
        Unloads active UNIFY modules immediately in real-time and removes configs.
        """
        try:
            # 1. Unload all modules associated with streamerx sinks
            try:
                out = subprocess.run(["pactl", "list", "modules", "short"], capture_output=True, text=True, timeout=3).stdout
                for line in out.splitlines():
                    parts = line.split()
                    if len(parts) >= 3:
                        mod_id = parts[0]
                        mod_args = " ".join(parts[2:])
                        if "streamerx" in mod_args:
                            subprocess.run(["pactl", "unload-module", mod_id], capture_output=True, timeout=2)
            except Exception as ue:
                logger.warning(f"Error unloading live modules: {ue}")

            # 2. Remove persistent PipeWire config file
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

