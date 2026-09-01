# 로비 동물 동료 생활 연출

영구 연구에서 실제로 해금한 동물 동료만 로비 뒤쪽 공터에 나타난다. 전투 동료의 수치나 게임 플레이 상태를 가져오는 시스템이 아니라, 저장된 해금 결과를 로비에서 보여 주는 표현 계층이다.

## 해금 반영

| 연구 | 로비 동물 |
|---|---|
| `fire_score_axe_crew` | 도끼 졸업 원숭이 1마리 |
| `fire_score_rocket_crew` | 폭죽 졸업 원숭이 1마리 |
| `fire_score_popper_unlock` | 뻥튀기차 원숭이 1마리 |
| `universal_veteran_crew` | 해금한 도끼/폭죽 원숭이마다 1마리 추가 |
| `fire_score_popper_extra` | 뻥튀기 원숭이 1마리 추가 |
| `universal_mole_companion` / `universal_mole_extra` | 두더지 1~3마리 |
| `universal_gray_cat` | 회색 고양이 1마리 |

해금하지 않은 동물은 생성하지 않는다. 연구를 구매하고 로비로 돌아오면 `CharacterTraits:getLevel`의 현재 저장값을 다시 읽어 즉시 합류시킨다.

## 생활 상태와 깊이

- `walk`: 각 동료가 자기 속도로 로비 공터의 새 목표점까지 걸어간다. 좌우 방향은 실제 이동 방향을 따른다.
- `idle`: 1.5~4.5초 동안 멈춰 쉬고 다시 목표를 고른다.
- `sleep`: 6~12초 동안 베개에 머리를 대고 몸을 이불 속에 넣은 전용 자세와 6프레임 이불 호흡을 재생한다. 머리 위에는 세 단계 `Z Z Z`가 천천히 떠오른다.
- 목표 선택은 동료 ID 기반 결정적 난수라 전역 게임 난수를 소비하지 않는다.
- 얕은 위치의 동료는 전경 나무 뒤, 가까운 위치의 동료는 나무 앞에 그려 숲 사이를 오가는 깊이를 만든다. 메뉴와 오디오 바는 이후에 그려져 항상 읽힌다.
- 낮/밤 배경의 실제 밝기를 받아 몸체와 그림자 밝기도 함께 변한다.

## 함께 노는 장면

평소에는 각자 생활하지만 9~17초 간격으로 가능한 조합 하나만 골라 짧은 상호작용을 만든다. 참여 중인 동료만 예약하며 나머지는 계속 산책하거나 잔다. 장면이 끝나면 모두 새 산책 목표를 받아 자연스럽게 흩어진다.

- `cat_wand`: 원숭이가 픽셀 낚싯대의 깃털 장난감을 좌우·상하로 흔들고, 고양이는 실제 장난감 좌표를 쫓아 달려가며 주기적으로 뛰어오른다.
- `banana_toss`: 원숭이 둘이 마주 보고 바나나를 포물선으로 주고받으며 받는 순간 뛰고 반짝임이 난다.
- `mole_peek`: 두더지가 흙더미 아래로 숨었다가 튀어나오고, 지켜보던 원숭이 또는 고양이가 놀라 뛰어오른다.
- `chase_train`: 서로 다른 동료 세 마리가 간격을 유지한 채 방향을 바꾸며 줄지어 술래잡기하고 발밑에 작은 흙먼지를 남긴다.

상호작용 순서는 결정적으로 순환하므로 특정 장면만 반복되지 않는다. 필요한 종이 해금되지 않았으면 가능한 다음 장면을 선택하고, 상호작용 도중 해당 동료가 해제되는 예외에도 남은 동료를 즉시 일상 상태로 돌린다.

걷기는 승인된 원본 `graduate-monkey-atlas-pixel-v3.png`, `coin-miner-mole-atlas-pixel-v3.png`, `gray-oil-cat-atlas-pixel-v1.png`를 nearest로 재사용한다. 수면은 `lobby-companion-sleep-concept-v1.png`에서 각 동료의 닫힌 눈·베개·몸을 덮은 이불을 별도 제작한 뒤 고정 팔레트와 hard alpha로 6프레임을 굽는다. 단순히 서 있는 몸체를 회전하지 않는다. 원숭이는 잠잘 때만 녹색 수면모자와 작은 방울을 쓴다. 원본 전투 아틀라스는 수정하지 않는다.

## 제작과 검수

```bash
python scripts/build_lobby_companion_sleep.py
python scripts/build_lobby_interaction_props.py
python scripts/headless_lua.py scripts/verify_lobby_companions.lua
python scripts/render_lobby_companions_preview.py
```

- 실제 로비 낮: `docs/previews/lobby-companions-v1-production-day.png`
- 960×540 밤: `docs/previews/lobby-companions-v1-production-night-compact.png`
- 수면 원생 픽셀 3배: `docs/previews/lobby-companions-v1-sleep-3x.png`
- 걷기·휴식·수면 동작: `docs/previews/lobby-companions-v1-life.gif`
- 네 상호작용 비교: `docs/previews/lobby-companions-v2-interactions.png`
- 원숭이 낚싯대·고양이 추격 동작: `docs/previews/lobby-companions-v2-cat-wand.gif`

모든 검수는 게임 창을 열지 않는 실제 Lua 드로우 명령의 오프스크린 재생이다.
