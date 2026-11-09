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
        """Checks if the PipeWire configuration file is currently installed."""
        return os.path.isfile(STREAMERX_CONF_PATH)

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
        """Installs the PipeWire and ALSA configurations and reloads user services."""
        try:
            nodes = cls.get_streamer_x_nodes()
            hw_sink = nodes.get("sink") or "alsa_output.usb-RODE_Streamer_X_HT0004996-00.analog-stereo"
            hw_source = nodes.get("source") or "alsa_input.usb-RODE_Streamer_X_HT0004996-00.analog-stereo"

            # 1. PipeWire configuration
            os.makedirs(PIPEWIRE_CONF_DIR, exist_ok=True)
            content = cls.generate_pipewire_config(hw_sink, hw_source)
            with open(STREAMERX_CONF_PATH, "w", encoding="utf-8") as f:
                f.write(content)

            logger.info(f"Streamer X PipeWire profile written to {STREAMERX_CONF_PATH}")

            # 2. ALSA configuration (~/.asoundrc for DAWs like Reaper, Ardour, Bitwig)
            try:
                existing_asound = ""
                if os.path.isfile(ASOUNDRC_PATH):
                    with open(ASOUNDRC_PATH, "r", encoding="utf-8") as af:
                        existing_asound = af.read()
                if "# --- RODE UNIFY START ---" not in existing_asound:
                    with open(ASOUNDRC_PATH, "a", encoding="utf-8") as af:
                        af.write("\n" + ASOUND_UNIFY_BLOCK)
                    logger.info("Added RØDE UNIFY virtual devices to ~/.asoundrc")
            except Exception as ae:
                logger.warning(f"Could not update ~/.asoundrc: {ae}")

            # 3. Reload PipeWire, WirePlumber and PipeWire-Pulse to expose nodes
            subprocess.run(["systemctl", "--user", "restart", "pipewire", "pipewire-pulse", "wireplumber"], check=False)
            return True
        except Exception as e:
            logger.error(f"Failed to install PipeWire profile: {e}")
            return False

    @classmethod
    def remove_unify_profile(cls) -> bool:
        """Removes the PipeWire and ALSA configurations and reloads."""
        try:
            if os.path.exists(STREAMERX_CONF_PATH):
                os.remove(STREAMERX_CONF_PATH)
                logger.info(f"Removed {STREAMERX_CONF_PATH}")

            # Remove from ~/.asoundrc
            try:
                if os.path.isfile(ASOUNDRC_PATH):
                    with open(ASOUNDRC_PATH, "r", encoding="utf-8") as af:
                        asound_content = af.read()
                    if "# --- RODE UNIFY START ---" in asound_content:
                        import re
                        cleaned = re.sub(r"# --- RODE UNIFY START ---[\s\S]*?# --- RODE UNIFY END ---\n?", "", asound_content)
                        with open(ASOUNDRC_PATH, "w", encoding="utf-8") as af:
                            af.write(cleaned.strip() + "\n" if cleaned.strip() else "")
                        logger.info("Removed RØDE UNIFY devices from ~/.asoundrc")
            except Exception as ae:
                logger.warning(f"Could not clean ~/.asoundrc: {ae}")

            subprocess.run(["systemctl", "--user", "restart", "pipewire", "pipewire-pulse", "wireplumber"], check=False)
            return True
        except Exception as e:
            logger.error(f"Failed to remove PipeWire profile: {e}")
            return False

