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
- 동료의 좌표는 화면이 아니라 전경 지면의 월드 좌표다. 배경 패럴랙스가 움직이면 바닥 흔적·전경 나무·바위·통나무·동료·그림자·이불·장난감·`Z Z Z`가 하나의 `-parallax × unit × 7`만큼 함께 이동한다.
- 일반 이동 목표는 바위와 통나무가 차지한 앞쪽 지면을 피하고, 몸체별 발자국 반경으로 두 번 분리 보정한다. 상호작용 참여자는 자리를 유지하고 비참여 동료가 밀려나므로 서로 포개지지 않는다.

## 함께 노는 장면

평소에는 각자 생활하지만 9~17초 간격으로 가능한 조합 하나만 골라 짧은 상호작용을 만든다. 참여 중인 동료만 예약하며 나머지는 계속 산책하거나 잔다. 장면이 끝나면 모두 새 산책 목표를 받아 자연스럽게 흩어진다.

- `cat_wand`: 원숭이가 픽셀 낚싯대의 깃털 장난감을 좌우·상하로 흔들고, 고양이는 실제 장난감 좌표를 쫓아 달려가며 주기적으로 뛰어오른다.
- `banana_toss`: 원숭이 둘이 마주 보고 바나나를 포물선으로 주고받으며 받는 순간 뛰고 반짝임이 난다.
- `mole_peek`: 두더지가 흙더미 아래로 숨었다가 튀어나오고, 지켜보던 원숭이 또는 고양이가 놀라 뛰어오른다.
- `chase_train`: 서로 다른 동료 세 마리가 간격을 유지한 채 방향을 바꾸며 줄지어 술래잡기하고 발밑에 작은 흙먼지를 남긴다.

상호작용 순서는 결정적으로 순환하므로 특정 장면만 반복되지 않는다. 자는 동료는 참여 후보에서 제외해 이불이 순간적으로 사라지지 않는다. 필요한 종이 해금되지 않았으면 가능한 다음 장면을 선택하고, 상호작용 도중 해당 동료가 해제되는 예외에도 남은 동료를 즉시 일상 상태로 돌린다.

## 배경 동물용품점과 놀이터

상점은 메뉴 버튼이나 동료 목록에 붙지 않는다. 로비 왼쪽 아래 공터에 있는 발바닥 간판의 목조 매점이 실제 클릭 대상이며, 건물을 눌렀을 때만 `숲속 꼬리 상점`이 열린다. 구매는 전투 수치에 영향을 주지 않고 `character_traits.sav`의 `lobby_item_*` 항목에 영구 저장된다.

| 상품 | 가격 | 설치 결과 | 이용 동료 |
|---|---:|---|---|
| 공놀이 울타리 | 8 P | 공 세 개와 낮은 울타리 | 모든 동물 |
| 모래 굴 놀이터 | 14 P | 모래밭과 짧은 굴 | 두더지 |
| 숲속 캣타워 | 18 P | 세 층 발판·숨숨집 | 고양이 |
| 통나무 그네 | 24 P | 통나무 프레임·밧줄 좌석 | 원숭이, 고양이 |

구매 직후 로비 공터에 시설이 나타난다. 산책 목표를 정할 때 비어 있는 호환 시설을 실제 목적지로 예약하며, 한 시설을 여러 동물이 겹쳐 쓰지 않는다. 도착한 동료는 공을 쫓아 뛰거나 모래 굴로 들어간다. 고양이는 캣타워 기둥을 올라 꼭대기에 머문 뒤 포물선으로 지면까지 뛰어내리고 착지 반동 후 걸어 나간다. 원숭이와 고양이는 8프레임 밧줄·좌석 아틀라스와 같은 궤도로 그네를 탄 뒤 좌석이 느려질 때 앞으로 뛰어내린다. 시설 이용 중에도 동물 몸체의 런타임 배율은 변하지 않는다. 후반 연구 비용과 경쟁하지 않도록 네 가격은 모두 초반 장식용 저가 구간으로 고정했다. 초기 시안의 `log_jungle` 구매 저장값은 캣타워 소유로 자동 승계한다.

상점 건물은 로비 **왼쪽 아래 공터**에 놓고 전경 지면선에 발을 맞춘다. 나무 위나 오른쪽 수관 사이에 배치하지 않는다. 중앙에는 놀이터 전용 빈 공간을 두고 전경 나무 군락은 오른쪽 끝에서 시작한다.

걷기는 승인된 원본 `graduate-monkey-atlas-pixel-v3.png`, `coin-miner-mole-atlas-pixel-v3.png`, `gray-oil-cat-atlas-pixel-v1.png`를 nearest로 재사용한다. 수면은 `lobby-companion-sleep-concept-v1.png`에서 각 동료의 닫힌 눈·베개·몸을 덮은 이불을 별도 제작한 뒤 고정 팔레트와 hard alpha로 6프레임을 굽는다. 단순히 서 있는 몸체를 회전하지 않는다. 원숭이는 잠잘 때만 녹색 수면모자와 작은 방울을 쓴다. 원본 전투 아틀라스는 수정하지 않는다.

수면 v2는 서 있는 아틀라스와 **동일한 런타임 배율**을 사용하고 원생 셀 자체를 키웠다. 원숭이 `192×160`, 두더지 `320×384`, 고양이 `192×160` 셀이라 머리 픽셀 밀도를 줄이지 않으면서 누운 몸과 이불이 가로로 넓어진다. 빌더는 실제 표시 경계가 기립 폭의 `1.65~2.25배`, 기립 높이의 `0.68~1.40배`인지 검사해 수면 시 축소나 과대화를 막는다.

## 제작과 검수

```bash
python scripts/build_lobby_companion_sleep.py
python scripts/build_lobby_interaction_props.py
python scripts/build_lobby_companion_shop.py
python scripts/headless_lua.py scripts/verify_lobby_companions.lua
python scripts/headless_lua.py scripts/verify_lobby_companion_shop.lua
python scripts/render_lobby_companions_preview.py
python scripts/render_lobby_companion_shop.py
```

- 실제 로비 낮: `docs/previews/lobby-companions-v1-production-day.png`
- 960×540 밤: `docs/previews/lobby-companions-v1-production-night-compact.png`
- 수면 원생 픽셀 3배: `docs/previews/lobby-companions-v3-sleep-3x.png`
- 걷기·휴식·수면 동작: `docs/previews/lobby-companions-v1-life.gif`
- 네 상호작용 비교: `docs/previews/lobby-companions-v2-interactions.png`
- 원숭이 낚싯대·고양이 추격 동작: `docs/previews/lobby-companions-v2-cat-wand.gif`
- 기립/수면 동일 발선·부피 비교: `docs/previews/lobby-companions-v3-scale-comparison.png`
- 지면 패럴랙스 고정 동작: `docs/previews/lobby-companions-v3-ground-anchored.gif`
- 패럴랙스 좌·중·우 비교: `docs/previews/lobby-companions-v3-ground-anchor-positions.png`
- 왼쪽 배경 건물·설치된 놀이터: `docs/previews/lobby-companion-shop-v2-world.png`
- 상점 구매 화면: `docs/previews/lobby-companion-shop-v2-store.png`
- 960×540 상점 화면: `docs/previews/lobby-companion-shop-v2-store-compact.png`
- 네 시설 실제 크기 상호작용: `docs/previews/lobby-companion-shop-v2-interactions.png`
- 캣타워 등반·점프: `docs/previews/lobby-cat-tower-v1.gif`
- 그네 탑승·하차: `docs/previews/lobby-swing-v1.gif`
- 시설 2배·그네 프레임 3배 픽셀 검수: `docs/previews/lobby-companion-shop-v2-pixel-zoom.png`

모든 검수는 게임 창을 열지 않는 실제 Lua 드로우 명령의 오프스크린 재생이다.
