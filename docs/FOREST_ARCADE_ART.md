# 승인된 숲 제작 규격 — 뱀서식 카툰 픽셀 v3

**앞으로의 모든 그래픽 작업은 [GRAPHICS_STYLE_GUIDE.md](GRAPHICS_STYLE_GUIDE.md)를 먼저 읽는다. 이 문서는 그 기준이 된 숲 v3의 구현·검증 기록이다.**

**모든 AI 필독: 고밀도 픽셀은 실사·장식·복잡한 캐릭터를 뜻하지 않는다. 사용자가 승인한 [숲 시안](previews/forest-vs-style-study-v1.png)의 큰 수관 덩어리, 간결한 줄기, 작은 몬스터 비율을 유지한다.**

2026-08-26 사용자가 시안을 승인하고 구현을 요청했다. v3를 적용한 뒤 사용자는 이 그래픽을 앞으로의 모든 그래픽 작업 기준으로 설명하는 문서를 요청했다. 그 요청을 공통 스타일 가이드에 반영했다. 이 사실을 기존의 모든 UI·벌집·경고 FX까지 각각 품질 승인받았다는 뜻으로 확대 해석하지 않는다.

## 공통 미술 규격

- 실루엣: 일반 적은 작고 단순하게. 다람쥐의 꼬리·붉은 눈, 멧돼지의 넓은 몸통·작은 엄니, 버섯의 갓, 덩굴괴수의 붉은 봉오리를 우선한다. 장비·장식·과도한 이빨을 추가하지 않는다.
- 나무: 활엽수·소나무·자작나무·단풍의 형태 차이를 큰 덩어리로 만든다. 사진 같은 잔가지·개별 잎 묘사를 되살리지 않는다.
- 재질: 각 자산 전용 8개 재질 램프 × 16단계 후보 팔레트, 고정 그리드 디더링, 위쪽 가장자리 조명과 아래쪽 음영. 실제 사용색은 나무 46~101색, 적 66~100색. 색 수를 억지로 채우지 않는다.
- 고체: RGBA, 알파 0/255, 런타임 `nearest`. 투명 체크무늬·마젠타 키색·선형 블러를 최종 자산에 남기지 않는다.
- 동작: 고정 모델 하나에서 제작용 GLSL로 같은 발선의 6개 걷기/대기 + 6개 액션 자세를 만든다. 프레임마다 ImageGen으로 새 캐릭터를 만들지 않는다. 현재 움직임은 같은 모델의 작은 변형과 런타임 반동이며, 전신 관절 애니메이션으로 표현하지 않는다.
- FX·투사체·HP바는 몸체와 별도 레이어다. 전투 경고와 HP는 수관 위에서도 보이고 몸체는 지면 기준 앞뒤 순서를 따른다.

## 연결 파일과 크기

| 대상 | 파일 / 프레임 셀 | 표시 기준 |
|---|---|---|
| 활엽수 | `assets/trees/broadleaf-tree-cartoon-v3.png`, 193×208 | 배율 1, 발선 약 189 |
| 소나무 | `assets/trees/pine-tree-cartoon-v3.png`, 151×226 | 배율 1, 발선 약 206 |
| 자작나무 | `assets/trees/birch-tree-cartoon-v3.png`, 144×216 | 배율 1, 발선 약 197 |
| 단풍 | `assets/trees/maple-tree-cartoon-v3.png`, 170×226 | 배율 1, 발선 약 206 |
| 다람쥐 / 멧돼지 / 버섯 | `assets/enemies/arcade/`, 128×128 | 몸체 너비 33 / 49 / 43 월드 단위 |
| 덩굴괴수 / 사신 | 같은 폴더, 160×160 | 너비 57 / 58 |
| 엘더 트렌트 | 같은 폴더, 256×256 | 너비 108 |
| 세계수 | 같은 폴더, 320×320 | 너비 202 |

적 아틀라스는 모두 6열×2행. 발선은 셀 높이−8, 투명 여백을 제외한 몸체 너비로 스케일을 계산한다. `src/forest_arcade_catalog.lua`가 단일 메타데이터 기준이다. 정예는 다람쥐/멧돼지의 동일 모델에 따뜻한 하이라이트와 기존 경고 표시를 적용한다.

## 런타임 변경

- `World:useArcadeForest()`가 clearcut 진입 시 새 나무를 연결한다. 기존 방어·rush 모드의 자산은 유지한다.
- `World:draw(player, actorSource)`에 적을 넣어 나무·플레이어와 함께 정렬한다. 나무 `frontBias=0`, 실제 루트 앵커는 기존 `.91×height` 계약을 유지한다. 적의 지면은 기존 전투 중심 `e.y + radius×.65`다.
- `forest_arcade_art.lua`가 이미지/쿼드/셰이더를 캐시한다. 좌우 방향은 실제 이동량에서 계산하고, 정지 시 유지한다. 좌향 원화인 다람쥐만 방향 정규화가 필요하다. 정면 멧돼지는 정면 체형을 유지한다.
- 접촉 공격과 투사체 발사에 시각 반동을 연결한다. 피해 시 짧은 재질 플래시, 이동 시 작은 몸 기울기/상하 운동. 기존 HP·피해·공격 주기·충돌 반경·이동속도는 바꾸지 않는다.
- 바닥은 기존 타일의 대비를 낮춰 사용하고 clearcut의 광범위한 가산 조명을 끈다. 베기·쓰러짐·흔들림 경로는 유지한다.
- 사용하지 않던 실사풍 보스 이미지의 선행 로딩을 제거했다. 원본 파일은 보존한다. 이전 코드의 문자 그리드 몬스터 모델은 현재 몸체 렌더 경로에서 사용하지 않는다.

## 원화와 생성 기록

내장 **ImageGen**을 사용했다. CLI/API 대체 경로는 사용하지 않았다.

- 나무 고정 원화: `assets/trees/concepts/forest-cartoon-models-v3.png`. 승인 시안에서 2×2 나무 보드를 만들고, 별도 배경 추출 요청으로 실제 RGBA를 받았다. 최초 보드의 가짜 체크무늬는 최종본에 사용하지 않았다.
- 몬스터 고정 원화: `assets/enemies/concepts/forest-arcade-models-v3.png`. 단색 마젠타 배경을 명시했고 제작용 GLSL에서 키잉한다. 이 원화를 게임에서 직접 그리지 않는다.
- 최종 프롬프트 세트: [FOREST_ARCADE_PROMPTS.md](FOREST_ARCADE_PROMPTS.md).
- 제작: `scripts/build_forest_arcade_assets.py` + `assets/shaders/forest-arcade-bake.glsl`. 원화의 형태를 고정하고 최종 픽셀 그리드, 재질 팔레트, 윤곽 명암, 발 접점과 동작을 결정적으로 굽는다.
- 런타임 재질: `assets/shaders/forest-arcade-light.glsl`. 피격/정예/독 상태를 기존 색 위에서 처리하고 이전 셰이더를 복구한다.
- 미채택 `forest-enemies-concept-v1`, `forest-enemies-indie-concept-v2`, `ingame/*-atlas-pixel-v1` 및 구형 나무는 보존하되 다시 연결하지 않는다.

## 검증

**게임 창을 실행하지 않았다.** 아래는 실제 Lua 그리기 명령을 기록해 AMD Radeon OpenGL에서 재생한 자산 검증이다. 전체 LÖVE 엔진 캡처가 아니며 HUD·카메라 흔들림·오디오·벌집 FX·실시간 입력은 포함하지 않는다.

- [기본 줌 .72 미리보기](previews/forest-arcade-v3-camera072.png), [원생 크기](previews/forest-arcade-v3-runtime.png), [확대](previews/forest-arcade-v3-zoom.png), [6프레임 동작](previews/forest-arcade-v3-motion.gif), [자산 보드](previews/forest-arcade-v3-assets.png).
- `verify_boss_sprites.lua`: 7종 실물 파일·nearest·발선·셰이더 복구·이동 방향/정지·접촉/발사 반동·실제 World 앞뒤 순서·overlay 중복 그리기 방지 통과. 숲 배치는 실제 `generateForest`를 사용한다.
- `verify_forest_arcade_assets.py`: 11개 파일, 이진 알파, 키색 잔여물, 서로 다른 걷기 6프레임, 모든 걷기 발선 검사 통과. 실제 런타임 재질/담배 불씨/연기 셰이더 3종 컴파일·렌더 통과.
- 기존 Python 자산 검사 3종 통과. 전체 Lua 12종 중 10종 통과.
- 남은 기존 실패 2종: `verify_clearcut_actions.lua`의 `playAutoAxeSwing` 모형 누락, `verify_trait_gameplay.lua`의 나무꾼 다중 대상/피해 기대값. 둘 다 `HEAD`의 기존 `clearcut_mode.lua`로 바꿔도 동일하게 실패함을 확인했다. 이번 그래픽 작업에서 게임 규칙이나 해당 테스트를 바꾸지 않았다. [기록](previews/forest-arcade-v3-tests.json).

재검증은 LÖVE 창 대신 Python(Pillow/numpy/moderngl)으로 `scripts/verify_forest_arcade_assets.py`를 실행한다. Lua DLL 기본 경로는 Windows LÖVE 설치 폴더이며 `LOVE_LUA_DLL`로 변경할 수 있다.
