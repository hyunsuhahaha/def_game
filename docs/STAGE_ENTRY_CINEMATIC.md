# 스테이지 진입 시네마틱

지구본과 브리핑에서 `작업 시작`을 확정한 뒤 실제 플레이가 시작되기 전 5초 동안 재생되는 인게임 연출이다. 별도 영상이 아니라 현재 선택한 맵·수종·작업자·야생동물을 그대로 사용한다.

## 진행 순서

1. **0.0–1.05초 — 고요한 현장:** HUD, 작업자, 재생핵과 전투 개체를 숨긴다. 카메라는 1구역 중앙 공터를 평소보다 16% 가까이 보여주며 맵 이름만 표시한다.
2. **1.05–1.42초 — 작업자 진입:** 작업자가 중앙 공터 왼쪽에서 실제 걷기 프레임으로 들어온다. 지역명은 이 구간 안에 사라져 액션을 가리지 않는다.
3. **1.42–3.42초 — 수관 폭발:** 네 곳의 수관에서 지역별 새 14마리가 무리 단위로 튀어나온다. 수관이 먼저 흔들리고 잎과 깃털이 터진 뒤, 후경·중경·전경의 새가 서로 다른 곡선으로 비행한다. 가장 가까운 새는 화면 앞을 크게 가로지르며 첫 이탈 순간에만 짧은 카메라 충격을 준다. 맹그로브의 게, 마다가스카르의 여우원숭이, 무인도의 앵무새도 작업자 반대 방향으로 달아난다.
4. **3.42–5.0초 — 조작 전환:** 작업자가 중앙에 멈추고 카메라가 해당 스테이지의 실제 줌으로 돌아간다. 별도의 `작전 개시`·`전투 시작` 문구 없이 HUD와 전투 개체가 자연스럽게 나타난다.

연출 중에는 `ClearcutMode.elapsed`, 전체 제한 시간, 적 이동·공격·스폰, 플레이어 공격이 진행되지 않는다. `SPACE`, Enter, Escape 또는 좌클릭으로 건너뛸 수 있으며, 건너뛰어도 전투 시간은 0초부터 시작한다.

## 지역별 새

`assets/fx/stage-intro/stage-intro-birds-atlas-pixel-v2.png`은 160×112 셀, 8프레임, 4행으로 구성한다. 48색의 단계식 깃털 명암과 하드 알파를 사용한다. 잎 6종과 깃털 2종은 `stage-intro-debris-atlas-pixel-v2.png`의 32×32 셀로 분리해 회전·낙하·페이드한다.

- 온대 숲·초심자의 숲: 밝은 배와 짙은 머리의 온대 조류
- 맹그로브: 청록색 물총새 계열
- 마다가스카르: 푸른 쿠아 계열
- 무인도: 녹색 앵무새 계열

모든 프레임은 같은 몸통·눈·부리 앵커를 유지하고 날개가 위→접힘→아래→복귀하는 8단계를 지난다. 런타임은 nearest 필터를 사용한다. 후경은 0.58–0.84배, 중경은 0.89–1.40배, 전경은 1.46–1.58배로 그려 무리가 납작한 원이 아니라 카메라 깊이를 통과하도록 한다. 작업자의 발걸음에도 작은 잎 파편을 연결한다.

## 검증 자료

v2 캡처는 실제 오프스크린 게임 화면으로 갱신한다. `sources/stage-intro-action-concept-v2.png`는 무리 구성과 화면 깊이만 정한 스토리보드이며 런타임 자산으로 사용하지 않는다.

- `docs/previews/stage-intro-fx-pixel-v2-2x.png`
- `docs/previews/stage-intro-forest-v2-quiet-1280.png`
- `docs/previews/stage-intro-forest-v2-burst-1280.png`
- `docs/previews/stage-intro-forest-v2-depth-1280.png`
- `docs/previews/stage-intro-forest-v2-arrival-1280.png`
- `docs/previews/stage-intro-island-v2-burst-1280.png`
- `docs/previews/stage-intro-ui-v2-region-1280.png`
- `docs/previews/stage-intro-ui-v2-no-start-banner-1280.png`

- `docs/previews/stage-intro-forest-v1-quiet-1280.png`
- `docs/previews/stage-intro-forest-v1-scatter-1280.png`
- `docs/previews/stage-intro-forest-v1-arrival-1280.png`
- `docs/previews/stage-intro-mangrove-v1-scatter-1280.png`
- `docs/previews/stage-intro-madagascar-v1-scatter-1280.png`
- `docs/previews/stage-intro-island-v1-scatter-1280.png`
