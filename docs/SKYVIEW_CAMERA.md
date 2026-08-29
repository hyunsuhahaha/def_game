# SKYVIEW 카메라

`skyview`는 기존 월드 좌표와 충돌을 유지한 채 렌더링만 낮은 카메라처럼 바꾸는 독립 모드다. 기본 벌목 시점에는 자동으로 적용하지 않으며, 현재는 스킬 연습장의 `SKYVIEW 보기` 버튼으로 시험한다.

## 화면 구성

- 화면 높이의 28.5%를 지평선으로 사용한다.
- `assets/scenery/skyview/`의 맑은 하늘, 먼 산, 먼 숲, 안개를 분리된 고밀도 픽셀 레이어로 그린다.
- 실제 월드 지면 메시의 상단은 지평선 아래로 제한한다. 지면의 Y 간격은 `u^1.22` 곡선으로 멀수록 압축되어 지평선으로 수렴한다.
- 캐릭터·나무·몬스터·공중 FX는 투영된 발점 위에 균일 배율 빌보드로 그려 종횡비가 변하지 않는다.
- `Camera:setMode("skyview", duration)`과 `Camera:setMode("default", duration)`으로 호출한다. 전환 시간은 0.4~0.8초로 제한되고 기본값은 0.6초다. 따라서 라운드 시작, 보스 등장, 스킬 연출에서 같은 API를 재사용할 수 있다.

## 안전 조건

- `skyviewBlend == 0`이면 기존 투영식을 그대로 반환한다.
- 이동, 충돌, 공격 범위, AI 좌표는 바꾸지 않는다.
- 화면 좌표 입력은 같은 비선형 곡선의 역함수로 다시 월드 좌표로 변환한다.
- 투영 지면 캔버스는 축소 시 선형 보간과 8배 이방성 필터를 사용해 이동 중 잔디·뿌리 무늬의 텍스처 크롤링을 억제한다. 확대 필터와 별도 빌보드 스프라이트는 `nearest`를 유지한다.
- 연습장을 나가거나 새 런을 시작하면 새 카메라의 기본 모드는 `default`다.

## 검증

```powershell
python scripts/build_skyview_assets.py
python scripts/verify_skyview_assets.py
python scripts/headless_lua.py scripts/verify_skyview.lua scripts/verify_camera_25d.lua
```
