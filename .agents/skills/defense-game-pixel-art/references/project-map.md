# Project map and acceptance references

Resolve every path from the `love2d` repository root.

## Mandatory visual references

- `docs/GRAPHICS_STYLE_GUIDE.md`: project-wide style, forbidden patterns, category rules, repair workflow, and acceptance checklist.
- `docs/PIXEL_ART_PIPELINE.md`: native-grid production rules and the project-wide visual quality floor.
- `docs/FOREST_ARCADE_ART.md`: approved cartoon arcade forest implementation record. Do not reconnect rejected v1/v2 monster art.
- `docs/previews/forest-arcade-v3-camera072.png`: actual-scale camera composition reference.
- `docs/previews/forest-arcade-v3-assets.png`: approved asset-board reference.
- `docs/previews/forest-arcade-v3-zoom.png`: enlarged pixel-detail reference.
- `docs/previews/forest-arcade-v3-motion.gif`: motion and frame-readability reference.

Open the relevant images with an image viewer before editing. Do not infer their appearance from prose.

## Repository areas

- `assets/`: runtime raster assets. Keep new accepted versions alongside prior versions rather than deleting history.
- `src/`: asset loading, animation, rendering, gameplay ranges, hit geometry, and level behavior.
- `scripts/`: deterministic builders, offscreen render fixtures, and headless regression tests.
- `docs/character_dossier.html`: required static mirror for character traits, skills, and fusions.

## Common verification tools

- `py -3 scripts/headless_lua.py`: all headless Lua regression tests without opening a LÖVE window.
- `py -3 scripts/headless_lua.py scripts/<focused-verifier>.lua`: one focused Lua verifier.
- `scripts/forest_render_fixture.lua`: reusable offscreen-compatible runtime fixture.
- `py -3 scripts/verify_forest_arcade_assets.py`: forest asset inspection and render utilities.
- `scripts/verify_character_dossier.lua`: skill-definition and dossier synchronization guard.
- `git diff --check`: whitespace and patch-integrity check.

## Non-universal examples

- Current player atlas: 6 columns by 2 rows, 96 by 192 pixels per cell, 576 by 384 total, baseline `y=190`.
- Approved small arcade enemies commonly use 128 by 128 cells.
- Smoke density floor: 192 by 384 FX grid for a 60 by 120 world footprint, or 3.2 texels per world unit on each axis.
- Cigarette detail reference: `assets/characters/ingame/smoker-cigarette-pixel-v2.png` at 256 by 48 pixels with deliberate material ramps and dithering.

These are category examples, not dimensions to copy blindly. Scale the native grid with the object's world footprint so detail density is preserved.
