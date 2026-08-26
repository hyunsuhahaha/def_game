# 숲·산 환경 장식 1차 적용

[공통 그래픽 스타일](GRAPHICS_STYLE_GUIDE.md)의 카툰 실루엣과 고밀도 픽셀 재질을 따른다. 기존 나무·몬스터를 교체하지 않고, 바위·고사리 수풀·낙엽·쓰러진 통나무를 추가했다.

## 적용 범위

- **바위 능선:** 소나무 비중을 높이고, 이끼 낀 바위와 작은 돌을 배치.
- **숲속 공터:** 기존 시작 공터를 유지하고 굽은 두 이동 공간을 연결. 주변에 통나무와 낮은 수풀 배치.
- **수풀 지대:** 자작나무·활엽수와 고사리 군락을 묶음.
- **낙엽 숲:** 단풍나무 비중을 높이고 낮은 낙엽 패치와 통나무를 배치.

지역은 절벽·고도·하천 물리가 아니라 **배치 테마**다. 이번 패스의 새 자연물은 비충돌 장식이다. 큰 바위 충돌, 통나무 채집, 낙엽의 연소·화재 전파는 아직 구현하지 않았다. 기존 꽁초·나무 화재 규칙은 바꾸지 않았다.

장식물은 `world.nodes`와 별도인 `world.forestScenery`에 저장한다. 벌목 목표, 남은 나무 수, 경험치, 공격 대상을 늘리지 않는다. 플레이어의 발을 가리는 가까운 장식물은 반투명해진다. 낙엽은 지면에 먼저, 나머지는 나무·캐릭터와 같은 발 위치 정렬 큐에 그린다.

## 제작 자산과 프롬프트

**내장 ImageGen 사용. CLI/API 우회는 사용하지 않았다.** 자연물마다 별도 생성 호출을 사용했고, 네 원본의 실제 RGBA 투명도를 보존했다. 원화는 프로젝트 안에 저장했다.

- [전체 생성 프롬프트](../assets/scenery/forest/concepts/prompts-v1.json)
- 원화: [바위](../assets/scenery/forest/concepts/rock-v1.png), [수풀](../assets/scenery/forest/concepts/fern-v1.png), [낙엽](../assets/scenery/forest/concepts/leaves-v1.png), [통나무](../assets/scenery/forest/concepts/log-v1.png)
- 최종 자산: [바위](../assets/scenery/forest/rock-pixel-v1.png), [수풀](../assets/scenery/forest/fern-pixel-v1.png), [낙엽](../assets/scenery/forest/leaves-pixel-v1.png), [통나무](../assets/scenery/forest/log-pixel-v1.png)

| 자산 | 원생 그리드 | 실제 사용색 | 게임 표시 기준 너비 |
|---|---|---|---|
| 바위 | 256×192 | 80 | 100 월드 단위 |
| 수풀 | 256×160 | 95 | 86 월드 단위 |
| 낙엽 | 256×160 | 88 | 174 월드 단위 |
| 통나무 | 320×160 | 80 | 132 월드 단위 |

너비는 투명 여백을 포함한 전체 이미지 기준이며, 개체 배율로 변화한다. 자연스러운 변형은 작은 크기 차이와 좌우 반전으로 만든다. 낙엽에만 작은 회전을 허용한다.

기존 `forest-arcade-bake.glsl` 제작 셰이더를 오프스크린 GPU에서 실행했다. 고정 원생 그리드, 재질별 16단계 명암 램프, 정렬 디더링, 상하 윤곽 음영을 적용하고 원화의 흐릿한 투명 테두리는 최종 고체 자산에 남기지 않았다. 결과는 알파 0/255, 런타임 `nearest`이며 원화를 게임에서 바로 줄여 그리지 않는다. [제작 스크립트](../scripts/build_forest_scenery.py)와 [자산 검사 기록](previews/forest-scenery-v1-build.json)을 함께 보존한다.

## 배치와 성능 범위

- [배치 모듈](../src/forest_scenery.lua): 지역 판정, 공터/이동 공간, 9곳의 장식물 전용 작은 빈터, 제한된 격자 지터 배치.
- 장식 빈터는 나무 뿌리뿐 아니라 **앞쪽 나무 수관이 가릴 영역**도 비운다. 최초 화면에서 바위·통나무가 거의 숨는 문제를 확인한 뒤 반영했다.
- 나무가 너무 빽빽해 목표 개수를 채우지 못할 때만 배치 간격을 단계적으로 줄인다. 빈터와 통로는 채우지 않는다. 1~5스테이지 260/305/350/395/440그루 생성 검사 통과.
- 장식 난수는 별도 결정적 생성기를 사용한다. 장식만 다시 생성해도 전투 난수를 소비하지 않는다. 스테이지마다 새 목록으로 교체한다.
- 검사 시드의 첫 스테이지는 나무 260그루, 장식 181개(바위 23, 수풀 65, 낙엽 81, 통나무 12). 실제 개수는 나무 위치와 스테이지에 따라 달라진다.
- 이미지 네 개를 캐시하며 프레임마다 다시 읽지 않는다. 실제 엔진 FPS 측정은 하지 않았다.

## 실제 코드 미리보기

- [네 구역 비교](previews/forest-scenery-regions.png)
- 기본 줌 .72: [바위 능선](previews/forest-scenery-ridge-camera072.png), [공터](previews/forest-scenery-woodland-camera072.png), [수풀](previews/forest-scenery-hollow-camera072.png), [낙엽 숲](previews/forest-scenery-dry-camera072.png)
- [원생 자산·재질 확대 검사](previews/forest-scenery-v1-assets.png)
- [장식만 숨긴 동일한 나무 배치](previews/forest-scenery-without-camera072.png): 이전 버전 전체 비교가 아니라 장식 유무 비교용.

위 장면은 실제 `generateForest`와 `World:draw`/플레이어/몬스터의 그리기 명령을 독립 GPU에서 재생한 것이다. **게임 창은 실행하지 않았다.** HUD와 실시간 입력을 포함한 엔진 캡처가 아니며, 시각 검사용으로 각 구역에 플레이어와 기존 적 3종을 놓고 벌집 표시는 생략했다.

## 검증

[회귀 검사](../scripts/verify_forest_scenery.lua)는 자산 연결, 4종 분포, 목표 나무 수, 열린 공간, 수관 빈터, 결정적 배치, 전투 난수 분리, 정렬 기준, 플레이어 가림 완화, 이미지 캐시, 스테이지 교체를 검사한다. 제작 GPU 검사와 실제 World 렌더 5뷰도 통과했다.

전체 Lua 검사 14종 중 당시 7종 통과/7종 실패. 실패는 별도 진행 중인 영구 특성 연결에서 테스트 모형의 `range`/`area`/`attackSpeed` 기본값이 없는 경우다. 이번 숲 생성 변경을 메모리에서 제거한 비교 실행에서도 7건 모두 재현됐다. 다른 작업의 코드를 되돌리지 않았다. [전체 결과·비교 오류](previews/forest-scenery-tests.json).

재검증(저장소 루트, LÖVE Lua DLL/Pillow/numpy/moderngl 필요):

```text
python scripts/build_forest_scenery.py
python scripts/headless_lua.py scripts/verify_forest_scenery.lua scripts/verify_tree_variants.lua
python scripts/render_forest_scenery.py
```
