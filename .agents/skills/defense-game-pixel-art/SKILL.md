---
name: defense-game-pixel-art
description: Create, edit, integrate, or review pixel-art sprites, animation atlases, scenery, enemies, bosses, items, projectiles, and effects for this LÖVE2D repository. Use for every repository graphics task so the result follows the approved cartoon arcade style, matches gameplay geometry, and is verified at actual display scale.
---

# Defense Game Pixel Art

Apply this workflow to every visual asset in this repository. Treat it as a completion contract, not optional inspiration.

## Establish the repository and visual baseline

1. Work from the repository containing `conf.lua`, `src/`, `assets/`, and `docs/GRAPHICS_STYLE_GUIDE.md`. If these are absent, locate the repository before editing.
2. Read the nearest `AGENTS.md`, then read `docs/GRAPHICS_STYLE_GUIDE.md`, `docs/PIXEL_ART_PIPELINE.md`, and the category-specific art record named by those documents.
3. Open and visually inspect the guide's current-v3 reference images, including the actual camera view and asset board. Reading filenames or dimensions is insufficient.
4. Inspect the current runtime asset, loader, draw path, animation timing, anchor, facing logic, depth order, and collision geometry before changing it.
5. Follow the user's latest explicit art direction. High density means authored material, stepped shading, controlled dithering, and readable motion; it does not require making every object large, realistic, or ornate.

Use [references/project-map.md](references/project-map.md) for the canonical paths and commands.

## Choose the production route

- Use ImageGen for a new identity, silhouette study, raster concept, texture study, or deliberate edit when a bitmap reference materially helps.
- Do not use independently generated animation frames as a final atlas. Lock the model, proportions, palette, native grid, baseline, anchors, and facing first; then author or deterministically bake coherent frames.
- Prefer deterministic code-native drawing only when it can meet the fixed-grid material and motion requirements. Do not replace art with enlarged primitive blocks, smooth vector-like gradients, blurred downscaled art, or decorative noise.
- Preserve source and rejected versions. Save accepted work under a new versioned filename and update runtime references deliberately.

## Author for runtime

1. Design at the final native pixel grid and check both enlarged pixel view and intended in-game size.
2. Separate materials with purposeful color ramps, stepped highlights and shadows, selective outlines, and controlled dithering. Preserve transparent background pixels and hard alpha for solid sprite edges unless the effect specification requires translucency.
3. Keep a coherent silhouette through every frame. Maintain fixed cell size, baseline, attachment anchors, shadow footprint, and directional convention.
4. Use `nearest` filtering for pixel assets. Load images and quads once, restore graphics state after custom drawing, and place foreground/background layers intentionally.
5. For animated FX, create changing tongues, detached fragments, sparks, embers, smoke, or impact shapes across frames instead of translating one static silhouette.

## Match visuals to gameplay

- Derive visible range and hit geometry from the same authoritative gameplay values. Test near and far edges, movement during an action, multiple targets, target priority, direction changes, and level-dependent variants.
- Make contact, launch, detonation, and damage happen on the corresponding animation frame.
- Confirm the effect appears on the correct side of actors and scenery. Test front/back layering and camera-scale readability.
- When traits, skills, or fusions change, update `docs/character_dossier.html` in the same task and run `scripts/verify_character_dossier.lua`.

## Verify before reporting completion

1. Run the most focused asset builder and verifier for the changed category.
2. Render an offscreen fixture at the real game scale and visually inspect the resulting image. Also inspect an enlarged nearest-neighbor pixel view. Never approve graphics from numerical tests alone.
3. Run `py -3 scripts/headless_lua.py` from the repository root.
4. Run `git diff --check` and inspect `git diff --stat` plus the relevant diff.
5. Do not automatically launch the game window. State clearly whether verification used an offscreen render or a live game view.

Report the exact asset and code paths changed, the visual checks performed, test results, and any remaining limitation.
