# LAST HAUL

LÖVE 11.5 기반 2D 쿼터뷰 파밍 디펜스 프로토타입입니다. 플레이어는 직접 전투하지 않고 농사·벌목·채광으로 자원을 생산해 북쪽 전선을 방어합니다.

## 개발 환경 준비

1. [LÖVE 공식 사이트](https://love2d.org/)에서 LÖVE 11.5를 설치합니다.
2. 저장소를 클론합니다.

```bash
git clone https://github.com/hyunsuhahaha/def_game.git
cd def_game
```

3. 프로젝트 루트에서 실행합니다.

```bash
love .
```

- Windows: `PLAY.bat` 더블클릭
- macOS/Linux: `./run.sh`
- 별도 Lua 설치는 필요하지 않습니다. LuaJIT은 LÖVE에 포함됩니다.

## 조작

- 로비 `A/D` 또는 좌우 방향키: 시작 빌드 선택
- `Enter` 또는 `작전 투입` 버튼: 게임 시작
- `WASD` 또는 방향키: 이동
- 가까운 농지·나무·돌·광석을 왼쪽 클릭: 알맞은 도구 자동 사용
- 빈 농지 클릭: 나무 괭이로 씨앗 심기
- 심은 농지 클릭: 급수기로 물 주기
- 성장이 끝난 농지 클릭: 작물 수확
- `1`: 생체 수호자 생성
- `2`: 거점 포탑 강화
- `3`: 작업 장비 강화
- `4`: 목재와 돌로 방어벽 강화
- 방어벽 가까이에서 방벽 클릭: 수리 망치로 직접 수리
- 게임 중 `Escape`: 로비로 복귀

## 구현 상태

- 한글 로비와 시작 빌드 선택
- 플레이어 추적 카메라와 Y축 정렬 쿼터뷰
- 하나로 연결된 전투·농장·숲·채석장·광산
- 15분 웨이브와 거점 자동 전투
- 파종 → 물주기 → 성장 → 수확 농사 순환
- 나무 도끼 자동 벌목
- 나무 곡괭이 자동 돌·광석 채집
- 도구 등급에 따른 채집 시간 변화
- 4단계 외형과 체력을 가진 업그레이드 방어벽
- 적은 코어가 아니라 방어벽만 공격하며, 방어벽 붕괴 시 패배
- 채집을 중단하고 방어벽을 클릭해 목재·돌로 직접 수리
- 8프레임 걷기 및 도구별 작업 모션
- 자원 가방과 거점 자동 납품

## 프로젝트 구조

```text
.
├── main.lua           # LÖVE 진입점
├── conf.lua           # 창과 런타임 설정
├── src/
│   ├── game.lua       # 상태 전환과 게임 진행
│   ├── lobby.lua      # 로비 화면
│   ├── world.lua      # 월드·자원·웨이브
│   ├── player.lua     # 이동·작업·도구 모션
│   ├── camera.lua     # 추적 카메라
│   ├── ui.lua         # 공통 UI
│   └── selftest.lua   # 파밍 시스템 자동 검사
└── assets/            # 실행에 필요한 이미지와 한글 폰트
```

## 자동 검사

PowerShell:

```powershell
$env:LAST_HAUL_SELF_TEST='1'
& 'C:\Program Files\LOVE\lovec.exe' .
```

성공하면 다음 문구가 출력됩니다.

```text
SELF_TEST_OK: FARM TREE STONE ORE TOOL_SPEED
```

## 폰트 라이선스

한글 UI는 Google Fonts의 Noto Sans KR을 사용합니다. 폰트 라이선스는 `assets/FONT-OFL.txt`에 포함되어 있습니다.
