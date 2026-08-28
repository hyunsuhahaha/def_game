# Arcade v3 — ImageGen 프롬프트 기록

참조는 사용자 승인 목업 `docs/previews/forest-vs-style-study-v1.png`다. 최종 픽셀 아틀라스는 아래 원화에서 제작용 GLSL로 굽는다. 미채택 원화는 입력하지 않았다.

## 나무 모델 보드 요청

승인 참조에서 동일한 카툰 픽셀 나무 스타일을 가져온다. 2×2, 좌상단 olive-green broadleaf, 우상단 tiered dark teal pine, 좌하단 white-bark birch, 우하단 russet maple. 큰 잎 클러스터, 간결한 줄기와 뿌리, 정교한 픽셀 명암. 전체 나무를 잘리지 않게 분리하고 텍스트·지형·그림자·사실적인 개별 잎을 넣지 않는다. 투명 배경을 요청했다.

최초 결과의 배경이 실제 알파가 아니어서 다음 **최종 배경 추출 프롬프트**를 별도로 실행했다:

> Background extraction only. Preserve these exact four pixel cartoon tree designs and 2x2 positions. Remove the entire white/grey checkerboard. Output actual transparent RGBA alpha with no checkerboard baked into RGB, no background, no shadow. The birch white bark stays opaque. Clean hard pixel silhouette. Change nothing else.

보존한 실제 RGBA 결과: `assets/trees/concepts/forest-cartoon-models-v3.png`.

## 몬스터 모델 보드 최종 프롬프트

> Create a fixed-model concept sprite board for the SMALL SIMPLE monsters of this exact approved game screenshot. Preserve the squat uncomplicated indie arcade silhouettes of the brown boar and orange squirrel in the reference. Seven distinct full-body specimens in a spacious 4-column by 2-row grid, final cell empty. Row1: 1 angry orange squirrel, short round body, tiny feet, single upright curled tail at its right, small red eyes; 2 squat front-facing dark brown wild boar, simple broad oval body and short legs, two small ivory tusks and tiny angry eyes, not a humanoid; 3 small dusty purple mushroom turret, broad simple cap with three pale spots and stubby tan stem; 4 red-brown diamond-bulb carnivorous sprout, green tapered stem and flared roots, simple glowing warm center, no gigantic toothed mouth. Row2: 1 elder tree monster, olive clustered canopy, brown straight trunk with two amber eyes, two branch arms and two root feet; 2 worldtree boss, broad olive clustered crown, tapered thick trunk with amber eyes, planted broad root base, no ornaments; 3 hooded charcoal forest wraith, small red eyes, simple ragged plum-dark cloak, no weapon; 4 empty. The reference screenshot is visual identity and style reference. Chunky readable silhouettes with finely authored pixel highlights, material-specific stepped shading, dark colored 1-2 pixel outline at native sprite scale. Restrained olive/rust/brown woodland colors. Crisp fine pixel graphics, original Vampire Survivors indie-game simplicity with slightly richer material shading. No ornate character redesigns, no cute RPG mascots, no realistic anatomy, no painterly fine fur, no accessories, no armor, no diorama, no grass, no text, no cast ground shadows, no VFX. Face boar forward, squirrel three-quarter front. All isolated with wide empty gutters on pure solid magenta #ff00ff background for GPU chroma-key, no checkerboard. Do not imitate the red HP bars or player.

보존한 결과: `assets/enemies/concepts/forest-arcade-models-v3.png`. 단색 배경을 제거한 게임용 파일은 `assets/enemies/arcade/*-atlas-v3.png`다.

## 재생의 정령 고정 모델 최종 프롬프트

> Create one fixed-model concept sprite for a tree-planting enemy called the Regrowth Spirit, matching the attached approved Forest Arcade v3 asset references. It is a small squat woodland creature with a compact emerald seed-pod body, a bright lime two-leaf sprout growing from its head, two cyan glowing eyes, short root feet, and root-like hands cupping one luminous mint seed at chest height. The held seed and the two-leaf crown must make its tree-regrowth role readable at actual gameplay size. Preserve the game's cartoony Vampire-Survivors-like silhouette with richer authored pixel material: dark colored outline, stepped emerald and bark shading, small deliberate dithering, crisp highlights, and no soft blur. Saturated greens and mint light must separate it from the olive forest floor. One full body specimen centered with generous transparent margin, no ground, no cast shadow, no scenery, no text, no extra equipment, no armor, no flowers, no photorealism. High-density RGBA pixel art suitable as a fixed source model for a deterministic 6x2 GPU-baked animation atlas.

보존한 결과: `assets/enemies/concepts/regrowth-spirit-model-v1.png`. 게임용 파일은 `scripts/build_regrowth_spirit_asset.py`와 `forest-arcade-bake.glsl`로 만든 `assets/enemies/arcade/planter-atlas-v1.png`다.

## 숲의 재생 성소 v2 — 구조물형 재설계

v1의 얼굴·손·발·형광 씨앗을 제거하고, 고정 뿌리 기단 위에 세 뿌리 아치가 원형 성소를 이루며 중앙 씨앗과 두 목재 고리, 수관이 공중에 떠 있는 고대 숲 구조물로 재설계했다. 신비감은 네온 보석이 아니라 불가능한 부유 구조, 제한된 청록 내부광, 느린 꽃가루로 표현한다. 얼굴·눈·입·팔다리·동물 해부·일반 나무집·SF 기계는 금지한다.

최종 고정 원화는 `assets/enemies/concepts/regrowth-sanctum-model-v2.png`, 런타임 본체는 `assets/enemies/arcade/planter-atlas-v2.png`, 시전 FX는 `assets/fx/regrowth-cast-atlas-v3.png`다. ImageGen은 고정 원화에만 사용하고 12프레임 본체와 6프레임 시전은 같은 그리드에서 결정적으로 제작한다.
