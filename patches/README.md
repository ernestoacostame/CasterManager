# rcp2-cli patches

`bin/rcp2-cli` is built from rcp2-cli (MIT, © x1h0) plus
`rcp2-cli-streamerx-addchild.patch`, applied on top of the CasterManager pad/show commands:

- RØDE Streamer X support (PIDs `0x0038` stereo and `0x0055` USB multitrack, HID interface 6).
- `add-child <parent> <insert_at> <NODE> [name=type:value...]`: creates a node and sets its
  properties in one connection. CasterManager uses it to create voice-FX pads the way
  RØDE Unify does (a `PAD` plus its `PADEFFECTS/EFFECTS_PARAMETERS` block).

`rcp2-cli-set-properties.patch` (apply after the one above):

- `set-properties <indices> [name=type:value...]`: writes several properties of one node in a
  single connection. CasterManager uses it to apply a hardware voice preset (≈50 CHANNEL
  properties + `channelCurrentFxPreset`) in under a second instead of one process per property.

Rebuild: `patch -p1 < patches/rcp2-cli-streamerx-addchild.patch` and then
`patch -p1 < patches/rcp2-cli-set-properties.patch` inside the rcp2-cli tree, then
`cargo build --release --bin rcp2-cli` and copy `target/release/rcp2-cli` (stripped) to `bin/`.
