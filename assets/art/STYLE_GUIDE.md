# Tiny Rescue Team — art / animation contract (vertical slice)

Camera: portrait top-down 3/4. World space 800 × 1040. Pixels-per-unit: 1. Character draw size 72 × 88 world units, pivot at feet.

Palette
- Harbor water `#38BDF8` → `#0E7490`
- Boardwalk `#B45309`, roads `#E7D3A5`
- Rosa accent `#E4572E` helmet/vest; Tomi accent `#14B8A6` bag/jacket
- Roles must stay identifiable without hue: helmet brim (Rosa), satchel-plus (Tomi)

States (both playable responders)
idle, walk (4 facing), deploy, primary action (work), tactical ability, react/down, success/cheer

Timing
- Simulation tick 100 ms. Walk cycle 1 Hz. Idle bob 1 Hz. Work is a kneel held while `Activity.working`.
- Animation interpolates between `prevX/prevY` and `x/y`; it never writes simulation state.

Naming
- Portraits: `rosa_portrait.png`, `tomi_portrait.png`
- District card: `harbor_backdrop.png`
- In-mission bodies are original painted figures in `lib/game_scene/character_draw.dart` (atlas-equivalent frames via pose + facing + time)

LOD / memory
- Three raster portraits, ~1.2 MB total. No particle atlas yet; VFX are solid circles with a cap of one per node.

Placeholders
- Locked roles use a grey silhouette of the same figure language. Not for release of those roles.
