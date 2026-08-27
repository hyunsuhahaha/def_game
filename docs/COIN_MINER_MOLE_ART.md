# 코인 채굴꾼 두더지 아트 기록

최종 연결 자산: `assets/characters/ingame/coin-miner-mole-atlas-pixel-v3.png`

- 6열 × 2행, 12프레임, RGBA, 공용 112색 팔레트
- 걷기 6프레임 / 발톱·잠복 6프레임
- `scripts/build_coin_miner_mole.py`가 원화의 체크 배경 제거, 발선 정렬, 공용 팔레트 양자화와 아틀라스 패킹만 담당한다.
- 거부된 조립식 v1은 `coin-miner-mole-rejected-concept-v1.png`로 보존하며 런타임에 연결하지 않는다.

## ImageGen 프롬프트

### 걷기 원화 — built-in `game-asset-production`

```text
Use case: game-asset-production
Asset type: six-frame horizontal walk-cycle concept strip for a 2D quarter-view high-resolution pixel game
Primary request: redraw the exact supplied squat foolish coin-miner mole as six distinct walking animation frames, wearing narrow black sunglasses
Identity lock: preserve the original extremely short squat proportions, small flat pink human-like face and tiny nose tucked under a heavy dark fringe, tiny arms, bare pink feet, thick gold chain and round medallion, droopy awkward silhouette, dark work clothes/fur; he must unmistakably be the supplied character
Motion: frame 1 idle contact, frame 2 left foot forward, frame 3 passing pose with body squash, frame 4 opposite contact, frame 5 right foot forward, frame 6 settle; restrained heavy waddling motion, chain and medallion lag naturally, tiny hands swing, feet remain on one shared baseline
Composition: exactly six complete isolated full-body figures in one straight horizontal row, equal cell widths, generous transparent space between figures, all facing screen-right at the same three-quarter quarter-view angle, no overlaps, no cropping, no platform
Style: exceptionally polished hand-authored high-density pixel art, crisp deliberate pixel clusters, nuanced stepped shading and subtle material gradients, readable at game scale, same visual finish as premium modern 2D pixel RPG characters; detailed clothing folds, individual chain links, reflective sunglasses, but no smooth vector edges
Palette: restrained charcoal, warm skin pink, aged gold, muted neutral highlights; transparent background
Constraints: preserve character scale and anatomy across all frames; no large snout, no egg-shaped ball body, no muscular build, no giant claws, no heroic stance, no pickaxe, no shovel, no grass tile, no text, no labels, no watermark, no cast shadow, no white/checkerboard background
Avoid: procedural circles, simple geometric construction, baby mascot, plush toy, realistic mole anatomy, 3D render, blurry anti-aliased painting, duplicated identical frames
```

### 액션 원화 — built-in `game-asset-production`

```text
Use case: game-asset-production
Asset type: six-frame horizontal combat/action concept strip matching the supplied coin-miner mole walk strip
Primary request: create six distinct readable action poses for the exact same squat foolish mole wearing narrow black sunglasses: (1) raises two small digging claws in anticipation, (2) pulls right paw back with claw tips visible, (3) forceful forward three-claw scratch contact pose with torso twist and chain lag, (4) dives headfirst into loose earth with only upper body and feet briefly visible, (5) fully underground represented by a low moving dirt mound with sunglasses no longer visible, (6) bursts up while gripping the exposed roots of one uprooted full-size tree, preparing to throw it
Identity lock: exact same tiny flat pink face, heavy fringe, short squat body, tiny arms, bare pink feet, gold chain and round medallion, charcoal clothes/fur and foolish character identity as the references; same body scale in frames where body is visible
Composition: exactly six equal-width cells in a single straight horizontal row, one key pose per cell, all facing screen-right at a three-quarter quarter-view angle, one shared foot baseline for visible standing poses, large transparent gaps, no overlap, no cropping; the uprooted tree in frame 6 may extend upward but must fit completely inside its cell
Style: exceptionally polished hand-authored high-density pixel art matching the supplied walk strip, crisp deliberate clusters, nuanced stepped shading, detailed cloth folds, chain links, root bark and soil chunks, readable silhouette at game scale
Motion readability: scratching must come from short retractable digging claws, not giant permanent hands; burrow mound must feel like displaced soil with a clear forward wake; uproot pose must communicate heavy strain and whole-tree weight
Constraints: no muscular build, no large snout, no egg-shaped procedural body, no giant fantasy claws, no pickaxe, no shovel, no text, no labels, no watermark, no platform, no cast shadow, transparent background
Avoid: simple geometric construction, duplicated frames, baby mascot, realistic mole anatomy, 3D render, smooth vector painting, explosion effects
```

### 액션 6번 수정 — built-in `precise-object-edit`

```text
Use case: precise-object-edit
Edit the supplied six-frame horizontal pixel-art action strip while preserving frames 1 through 5 exactly in character identity, rendering, scale, spacing, and pose.
Change only frame 6: remove the mole holding the uprooted tree entirely. Replace frame 6 with a forceful fast-moving underground tunnel mound: a low elongated pile of displaced brown soil moving toward screen-right, with a short trailing furrow and several chunky soil clods kicked outward to both sides. The mole remains completely underground; no hands, head, sunglasses, medallion, tree, roots, or body are visible in frame 6.
Motion meaning: the burrowed mole travels under trees, and the underground impact launches each tree sideways automatically; the mole never picks up or throws a tree by hand.
Composition: exactly six equal-width cells in one horizontal row, transparent background, no cropping, no overlap; keep frame 6 mound centered in its existing cell and on the same ground baseline as frame 5.
Style: match the existing exceptionally polished high-density authored pixel art, crisp clusters, detailed soil chunks and stepped shading.
Constraints: no tree in frame 6, no character in frame 6, no text, no labels, no watermark, no platform, no cast shadow, no checkerboard baked into the asset if avoidable.
Avoid: explosion cloud, magical glow, hand-thrown tree, character emerging, additional frames, smooth vector art.
```
