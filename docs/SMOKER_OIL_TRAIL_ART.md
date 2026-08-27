# 흡연자 융합 스킬 — 기름길 시각 설계

`기름을 실수로 붓다`의 수치와 판정은 유지하고, 시각 표현만 전용 고밀도 픽셀 아틀라스로 교체한다.

- 이동 중: 발밑에서 떨어지는 기름방울, 짧은 착지 튐, 서로 이어지는 갈흑색 젖은 기름 자국
- 점화 직후: 옆으로 퍼지는 짧은 점화 섬광과 불티
- 연소 중: 나무 화염을 복제하지 않는 낮고 넓은 유류 화염, 일부 구간의 짙은 연기
- 바닥 자국은 캐릭터보다 아래에, 화염은 월드 깊이 정렬 대상에 포함한다.
- 실제 피해 판정점 사이는 17px 이하 간격의 시각 전용 조각으로 보간한다. 빠르게 이동해도 기름과 불길이 끊기지 않으며, 보간 조각은 추가 피해를 발생시키지 않는다.
- 6초 기름 유지, 5초 연소, 55 피해 반경, 0.4초 피해 주기는 기존 로직 그대로다.

## 파일

- 생성 원본: `assets/fx/oil-trail/concepts/oil-trail-source-board-v1.png`
- 배경 제거용 원본: `assets/fx/oil-trail/concepts/oil-trail-cutout-source-v1.png`
- 런타임 아틀라스: `assets/fx/oil-trail/oil-trail-atlas-pixel-v2.png`
- 빌더: `scripts/build_oil_trail_fx.py`
- 정적 프리뷰: `docs/previews/oil-trail-runtime-v2.png`

## 생성 기록

내장 이미지 생성 모드(`game-asset-production`)로 실제 잔디, 담배, 나무 그래픽을 참조해 6×2 소스 보드를 제작했다. 첫 줄은 기름 자국·기름방울·착지 튐, 둘째 줄은 낮은 유류 화염·점화·연기·불티다. 이어 내장 이미지 편집 모드(`background-extraction`)로 배경 제거본을 만들었고, 체크무늬가 RGB로 구워진 부분은 빌더가 제거한다. 전체 생성 프롬프트는 작업 기록에 보존되어 있으며 원본 이미지는 덮어쓰지 않는다.

## 검증

```powershell
python scripts/build_oil_trail_fx.py
python scripts/verify_oil_trail_fx.py
python scripts/headless_lua.py scripts/verify_oil_trail_fx.lua scripts/verify_clearcut_fusions.lua
```
