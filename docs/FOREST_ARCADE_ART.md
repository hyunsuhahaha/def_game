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
| 숲의 재생 성소 | `assets/enemies/arcade/planter-atlas-v2.png`, 256×256 | 너비 90, 고정 뿌리 기단·부유 수관·회전 목재 고리·중앙 씨앗 |
| 엘더 트렌트 | 같은 폴더, 256×256 | 너비 108 |
| 세계수 공성형 | `worldtree-siege-atlas-v1.png`, 1024×1024 | 너비 1050·판정 반경 420, HP별 4단 파괴, 전용 공격·낙하 FX 5종 |

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
- 재생 프리즘 v4 고정 원화: `assets/enemies/concepts/regrowth-prism-pedestals-concept-v4-cutout.png`. 네 지역의 수피·습지 뿌리·홍토·산호석을 낮은 열린 기단으로 만들고, 손가락형 지지대·얼굴·수관·고정된 작은 보석을 제거했다. `scripts/build_regrowth_totems_v4.py`가 256×256 셀의 안정된 본체 6+6칸을 굽고, 별도 `regrowth-prism-rotation-atlas-v1.png`의 24프레임 대형 코어를 기본 20fps·시전 24fps로 합성한다. 기존 v1~v3 원화·아틀라스·시전 FX는 삭제하지 않고 미연결 상태로 보존한다.
- 최종 프롬프트 세트: [FOREST_ARCADE_PROMPTS.md](FOREST_ARCADE_PROMPTS.md).
- 제작: `scripts/build_forest_arcade_assets.py` + `assets/shaders/forest-arcade-bake.glsl`. 원화의 형태를 고정하고 최종 픽셀 그리드, 재질 팔레트, 윤곽 명암, 발 접점과 동작을 결정적으로 굽는다.
- 런타임 재질: `assets/shaders/forest-arcade-light.glsl`. 피격/정예/독 상태를 기존 색 위에서 처리하고 이전 셰이더를 복구한다.
- 미채택 `forest-enemies-concept-v1`, `forest-enemies-indie-concept-v2`, `ingame/*-atlas-pixel-v1` 및 구형 나무는 보존하되 다시 연결하지 않는다.

## 검증

**사용자에게 보이는 게임 창은 실행하지 않았다.** 자산 검사는 오프스크린 GPU에서 수행했고, 최종 연결은 숨김 LÖVE 창으로 실제 런타임 캡처했다.

- [기본 줌 .72 미리보기](previews/forest-arcade-v3-camera072.png), [원생 크기](previews/forest-arcade-v3-runtime.png), [확대](previews/forest-arcade-v3-zoom.png), [6프레임 동작](previews/forest-arcade-v3-motion.gif), [자산 보드](previews/forest-arcade-v3-assets.png).
- 재생 프리즘: [실제 표시 배율](previews/regrowth-prism-v1-runtime-scale.png), [기본 카메라 24프레임](previews/regrowth-totems-v4-runtime-motion.gif), [v4 본체 확대](previews/regrowth-totems-v4-contact-sheet.png), [본체 제작 수치](previews/regrowth-totems-v4-build.json). v1~v3 미리보기는 교체 전 기록으로만 남긴다.
- `verify_boss_sprites.lua`: 8종 실물 파일·nearest·발선·셰이더 복구·이동 방향/정지·접촉/발사 반동·실제 World 앞뒤 순서·overlay 중복 그리기 방지 통과. 숲 배치는 실제 `generateForest`를 사용한다.
- `verify_regrowth_spirit_asset.py`: 1536×512 v4 열린 기단, 1536×256 시전 FX, 고정 본체·제한 팔레트·이진 알파·지역별 재질·대형 프리즘 카탈로그 연결을 검사한다. `verify_regrowth_prism_animation.py`는 24개 회전 단계와 20/24fps 런타임 경로를 검사한다.
- `verify_forest_arcade_assets.py`: 11개 파일, 이진 알파, 키색 잔여물, 서로 다른 걷기 6프레임, 모든 걷기 발선 검사 통과. 실제 런타임 재질/담배 불씨/연기 셰이더 3종 컴파일·렌더 통과.
- 2026-08-28 기준 `scripts/headless_lua.py`의 Lua 검사 26종 전체 통과. 재생의 정령 전용 Python 자산 검사도 별도로 통과했다.

재검증은 LÖVE 창 대신 Python(Pillow/numpy/moderngl)으로 `scripts/verify_forest_arcade_assets.py`를 실행한다. Lua DLL 기본 경로는 Windows LÖVE 설치 폴더이며 `LOVE_LUA_DLL`로 변경할 수 있다.
# 공격 식물과 자연 반격 (v2)

- 공격 식물 5종은 `assets/enemies/arcade/*-atlas-v1.png`의 160px 6x2 아틀라스를 사용한다.
- 외형은 실사 재질이 아닌 짧고 굵은 카툰 픽셀 실루엣이며, 둘째 줄은 장식 프레임이 아니라 실제 공격 예비동작/타격/회수다.
- 가시덩굴 사냥꾼은 연속 뿌리 찌르기, 망치 식인꽃은 지점 내려찍기, 폭발 씨앗 꼬투리는 5발 산탄, 대나무 압축포는 고속 직사, 송진 분사목은 감속 웅덩이를 만든다.
- 씨앗·대나무탄·송진탄·송진 장판은 더 이상 런타임 사각형·원·타원이 아니다. `assets/fx/attack-plants/attack-plant-projectiles-atlas-v2.png`의 160px 6프레임 행을 사용하며, 꼬투리 껍질·대나무 마디·점성 송진과 지면에 퍼지는 가장자리를 각각 다른 카툰 픽셀 재질로 그린다.
- 실제 표시 크기는 [공격 식물 FX v2](previews/attack-plant-fx-v2-display-scale.png), 확대 검수는 [2배 보드](previews/attack-plant-fx-v2-2x.png)를 기준으로 한다. `verify_attack_plant_fx_v2.py`가 이진 알파·프레임 차이·런타임 아틀라스 연결을 검사한다.
- 뿌리 지진과 낙하 가지는 `assets/fx/nature-counterattack-atlas-v1.png`를 사용하며 경고 이후 접촉 판정과 같은 프레임에 타격 그림이 나온다.

## 나무 파괴 손맛 (v1)

- 나무 피해율 1~37%, 38~71%, 72% 이상을 수종별 3단 손상 스프라이트로 표시한다. 별도 밑동 이미지를 덮지 않고 원본 줄기 픽셀 자체가 V자로 깎인다.
- 체력 4 이하의 작은 나무는 0.20초에 짧게 튕겨 나가며, 보통 나무는 0.44초, 체력 9 이상의 큰 나무는 0.64초에 묵직하게 쓰러진다.
- 바닥 접촉 프레임에는 `tree-break-burst-v1.png`의 목재·잎 파편과 기존 먼지·자원 방출만 발생한다.
- 쓰러진 나무가 다른 나무나 적에게 피해를 주는 연쇄 도미노 판정은 사용하지 않는다.

## 나무 지속 연소 FX (v2)

- 최초 담뱃불 도착의 착화 버스트는 그대로 유지한다. 착화 이후에는
  `assets/fx/tree-fire-loop-atlas-pixel-v2.png`의 320×320, 16프레임 불꽃을
  나무 뿌리 위치에 재생한다.
- 검수용 `assets/fx/tree-fire-loop-pixel-v2.gif`와 런타임 아틀라스는 같은
  결정적 프레임에서 생성한다. 여러 화염 갈래와 24개의 엇갈린 불티 궤적이
  각각 다른 위상으로 움직이며, 전체 불꽃을 동시에 팽창시키는 펄스는 없다.
- 구형 `tree-fire-pulse-atlas-pixel-v1.png`는 보존하지만 런타임에서 연결하지
  않는다. 반복 펄스에 맞춘 나무 좌우 흔들림과 타이머 파티클도 제거했다.

## 숲 재생과 구역 제압 (v1)

- 한 스테이지의 숲을 3×2, 최대 6개 구역으로 나눈다. 경계선을 화면에 크게 칠하지 않고 상단의 작은 구역 현황표로만 상태를 전달한다.
- 나무가 있는 각 구역에는 `planter-atlas-v2.png` 숲의 재생 성소를 재생핵으로 배치한다. 얼굴·팔다리가 있는 생명체가 아니라 땅에 고정된 구조물이며, 별도 임시 도형이나 저해상도 몸체를 만들지 않는다.
- 살아 있는 재생핵은 자기 구역의 베어진 나무만 복구한다. 전역 재생 펄스도 살아 있는 재생핵의 구역 하나를 골라 최대 3그루까지만 복구한다.
- 재생핵을 파괴하면 해당 구역의 재생은 즉시 멈춘다. 이후 남은 나무를 모두 제거하면 `확보` 상태가 되며 그 스테이지 동안 영구적으로 다시 자라지 않는다.
- 현황표의 숫자는 살아 있는 나무 수, `정리`는 재생핵 파괴 후 잔존 나무 제거 중, `확보`는 영구 제압 완료를 뜻한다.
- 해당 스테이지의 나무와 재생 구역을 모두 제거하기 전에는 고정형 세계수가 등장하지 않는다. 기존 소형 세계수는 별도 보존하며 세부 규격은 `WORLDTREE_SIEGE_BOSS.md`를 따른다.

### 재생 나무 등장 동작

- 재생 펄스와 재생 성소가 복구한 나무는 완성형 스프라이트가 즉시 켜지지 않는다. `regrowth-cast-atlas-v3.png`의 전용 뿌리빛이 먼저 지면에 나타난 뒤 0.95초 동안 승인된 나무 원본이 `0.56× → 1.065× → 1×`로 성장하고 짧게 좌우로 흔들리며 정착한다.
- 한 번에 최대 3그루가 복구될 때는 0.09초 간격으로 순차 등장한다. 벌집은 나무가 정착한 뒤에만 표시해 공중에 떠 보이지 않게 한다.
- 나무의 최종 이미지·발선·그림체·피해 단계는 바꾸지 않으며, 완료 프레임에는 원본 크기와 기존 2.5D 빌보드 정렬로 정확히 복귀한다.
- 실제 크기 6단계 검수: [재생 나무 등장 보드](previews/tree-emergence-v1-display-scale.png).
