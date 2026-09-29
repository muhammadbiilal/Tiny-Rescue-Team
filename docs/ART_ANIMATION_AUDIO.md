# 2D Art, Animation and Audio Production Bible

## Art direction
Original high-quality stylized 2D illustrated mobile game: readable silhouettes, layered city environments, expressive but restrained faces, soft lighting painted into sprites, clear foreground/background separation, polished VFX. No pixel-art requirement and no 3D geometry requirement. Aim for the character presence and feedback quality seen in commercial 2D autobattlers, without copying any existing hero, UI, palette, logo or animation. Select a camera in vertical slice (top-down 3/4 or side-isometric illustration) and lock world geometry before bulk art.

## Production inventory
12 district backgrounds with modular ground/road/building/prop sets; 12 role character sprite atlases; civilians with 4 variants; vehicles, equipment, hazards and UI icons; world map and mission cards; splash/icon/feature graphics. Character states minimum: idle, move (4 or 8 directions as camera requires), select, deploy, primary action, tactical ability, react, success, fail. Effects: path preview, scan, smoke, water, fire, debris, repair, healing, extraction, objective complete. Every action animation must match simulation event and duration. Mark placeholders visibly in internal builds; final release rejects them.

## Asset contract
Before bulk creation, make a style guide and one complete vertical-slice character with sprite atlas and runtime animation. Define pixels-per-unit, canvas, pivot, padding, frame order, FPS, trim policy, naming, alpha, color space, scaling/LOD and texture memory budgets. Maintain `ASSET_REGISTER` with provenance, rights, author, license, source file and review status. Use original or licensed audio/art. Generated assets require rights and consistency review. Never present rough geometric placeholders as finished artwork.

## Audio and feedback
Per-role action cues, hazards, selection, dispatch, objective/result, UI and 12 ambient district variations. Music/effects separate volume and mute. No audio-only gameplay information; support captions/visual cues, haptics off and reduced motion. No flashing effects. Mix for mobile speakers and test on devices.

## Visual acceptance
At gameplay scale, each role identifiable without color alone; 60 FPS target on chosen reference devices, measured not assumed; action/target relationship obvious. Record screenshot/video comparisons, visual QA, asset rights and animation timing. A functional code demo is not an art-complete release.
