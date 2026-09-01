# LAST HAUL

**나무를 가능한 한 많이 없애는 게임.** 버린 담뱃불이 그 출발점이자 게임의 얼굴이고, 도끼와 그 뒤에 열리는 무기들은 각자 다른 방식으로 같은 목표를 친다. LÖVE 11.5 / Lua.

---

## 작업 전에 읽을 것 — AI·사람 공통

| 순서 | 문서 | 내용 |
|---|---|---|
| 1 | [`AGENTS.md`](AGENTS.md) | 저장소 작업 규칙. **모든 에이전트의 진입점** |
| 2 | [`docs/SYSTEM_MAP.md`](docs/SYSTEM_MAP.md) | 현재 게임의 시스템·수치 한 장 요약 |
| 3 | [`docs/ACTIVE_DEVELOPMENT_MODE.md`](docs/ACTIVE_DEVELOPMENT_MODE.md) | 무엇이 활성이고 무엇이 의도적 비활성인지 |
| 4 | [`docs/GRAPHICS_STYLE_GUIDE.md`](docs/GRAPHICS_STYLE_GUIDE.md) | **그래픽 작업이면 필수.** 기준 이미지를 실제로 열어 볼 것 |

수치와 시스템 세부는 이 README가 아니라 **`docs/SYSTEM_MAP.md`가 1차 소스**다. README는 자주 바뀌지 않는 것만 담는다.

## 지금 플레이할 수 있는 것은 하나뿐이다

로비에서 진입 가능한 모드는 흡연자의 **벌목 기록 모드(`score_attack`)** 하나다.

```text
나무 6그루로 시작 → 벌목 → 목재 점수와 수종별 정산 재고 누적
활성 나무 0그루 달성 또는 60초 뒤 세계수 처치 → 재생 단계 영구 상승 · 단계 시간 초기화
활성 나무가 허용량에 닿으면 즉시 종료 → 정산 → 영구 연구 → 다시 시작
```

고정 제한 시간은 없다. 지는 이유는 언제나 **숲이 다시 차오르는 속도를 못 따라잡아서**다.

### 보이지 않는 절반 — 삭제하지 말 것

일반 작전(1-1~4-4), 흡연자 외 5명의 작업자, 지구본 맵 선택, 보스전, 러시 모드는 **코드가 그대로 살아 있고 로비 진입점만 닫혀 있다.** 폐기한 것이 아니라 의도적 비활성이다.

- 활성/비활성 경계와 복구 지점: [`docs/ACTIVE_DEVELOPMENT_MODE.md`](docs/ACTIVE_DEVELOPMENT_MODE.md)
- 그 시절 README 원본: [`docs/ARCHIVED_CAMPAIGN.md`](docs/ARCHIVED_CAMPAIGN.md)

> 이 저장소에는 사실상 게임이 두 개 들어 있다. **작업 전에 어느 쪽을 만지는지 먼저 확인한다.** 비활성 코드를 정리 대상으로 보고 삭제하거나 대규모 리팩터링하지 않는다.

## 실행

LÖVE 11.5를 설치한 뒤 저장소 루트에서:

```bash
love .
```

Windows는 `PLAY.bat`, macOS/Linux는 `./run.sh`. 별도 Lua 설치는 필요 없다(LuaJIT이 LÖVE에 포함).

## 조작

| 입력 | 동작 |
|---|---|
| `WASD` / 방향키 | 이동 |
| 마우스 왼쪽 | 대상과 거리에 맞는 무기로 자동 공격 (누른 채 이동하면 계속 공격) |
| `Escape` | 로비로 복귀 |
| 로비 `Enter`·`Space`·`M` | 기록 모드 시작 |
| 로비 `T` | 영구 연구 (강화하기) |
| 로비 `P` | 현재 기록 모드 무한 연습장 (나무 계속 생성·종료 없음) |
| 로비 `R` / `[`·`]` | 픽셀 오디오 재생·정지 / 트랙 전환 |
| 어디서나 `F10` | 개발용 테스트 옵션 |

무기 구성과 해금 순서는 계속 바뀌므로 [`docs/SYSTEM_MAP.md`](docs/SYSTEM_MAP.md)를 본다.

## 검증

**기본은 창을 띄우지 않는 헤드리스 검사다.**

```bash
python scripts/headless_lua.py
```

`scripts/verify_*.lua` 전체를 LÖVE 프로세스 없이 `lua51.dll`로 직접 돌린다. 파일 하나만 돌리려면 경로를 인자로 준다.

자산을 새로 연결하거나 버전을 올렸으면 반드시 함께 돌린다.

```bash
python scripts/verify_asset_versions.py
```

런타임이 연결한 경로가 실제로 존재하는지, 한 자산군에서 두 버전을 동시에 쓰지 않는지, **더 높은 버전이 놀고 있는데 낡은 버전을 연결하지 않았는지**, 미채택으로 명시된 시안을 연결하지 않았는지 검사한다. 의도된 예외는 스크립트의 `ALLOWED_FAMILIES` 에 이유와 함께 등록한다.

그래픽 작업은 오프스크린 렌더로 눈으로 확인한다. 수치 검사만 통과시킨 결과를 완성으로 보고하지 않는다.

```bash
python scripts/render_score_trait_board.py      # 연구판
python scripts/render_graduate_monkey_preview.py # 졸업 동료
```

> **게임 창을 자동으로 띄우지 않는다.** LÖVE를 실행하는 검사(`LAST_HAUL_SELF_TEST`, `LAST_HAUL_CAPTURE_*`)는 사용자가 명시적으로 요청할 때만 돌린다. `lovec.exe`는 콘솔 창이 뜨므로 허용된 경우에도 `love.exe`를 쓴다.

## 프로젝트 구조

```text
main.lua                진입점 (환경변수로 자동 검사 모드 진입)
conf.lua                창·런타임 설정
src/
  clearcut_mode.lua     기록 모드 본체 — 무기·불·적·카드
  character_traits.lua  영구 연구 데이터
  character_trait_board.lua  연구판 UI
  score_operations.lua  런 중 드래프트 카드
  game.lua / lobby.lua  상태 전환과 로비
  world.lua / player.lua / camera.lua
  *_art.lua             자산 로더와 그리기
scripts/
  headless_lua.py       창 없이 Lua 실행 (검증의 기본)
  verify_*.lua          회귀 검사
  build_*.py            픽셀 자산 생성
  capture_* / render_*  오프스크린 시각 검수
docs/                   설계·규격·검수 기록
assets/                 이미지·폰트
```

## 자산 버전 규칙

같은 대상의 `v1`, `v2`, `v3`가 한 폴더에 공존한다. **가장 큰 숫자가 현역이라는 보장은 없다.** 코드가 실제로 로드하는 파일만 현역이며, 나머지는 보존된 이전 버전이거나 미채택 시안이다.

- 새 자산은 기존 파일을 덮어쓰지 않고 버전을 올려 저장한다
- 미채택 시안은 [`assets/enemies/README.md`](assets/enemies/README.md)에 명시되어 있다
- 어느 버전이 연결되어 있는지는 `src/*.lua`의 로드 경로로 확인한다

## 폰트 라이선스

본문 한글 UI는 Google Fonts의 Noto Sans KR을 사용한다. 라이선스는 `assets/FONT-OFL.txt`에 포함되어 있다.

로비 메뉴와 픽셀 오디오는 Neo둥근모 Pro를 사용한다. 라이선스는 `assets/FONT-NEODGM-OFL.txt`에 포함되어 있다.
