# 11단계 이후 — 밝은 작업 고원

재생 1~10단계는 기존 [F안 호숫가](LAKESIDE_FIELD.md)를 유지한다. 11단계부터는 물·해안선이 전혀 없는 밝은 올리브색 고원으로 전환한다. 기존 카툰 픽셀 나무, 크레인, 전투 객체는 그대로 사용한다.

`src/upland.lua`가 비대칭 숲 영역 다섯 개를 정의한다. 새 나무는 18그루 단위로 군락을 채우고, 포화되면 다른 군락을 탐색한다. 월드가 커져도 군락 내부 간격은 유지한다. 11단계 진입 시 남은 일반 나무는 HP·상태·보상을 유지하며 재배치한다.

11단계의 실제 플레이 영역은 10단계 대비 가로·세로 정확히 2배, 면적 4배다. 기본 월드는 2240×1400에서 4480×2800으로 커지고 이후 단계도 남은 영역을 개방한다. 월드 크기는 중복 호출로 배증하지 않는다. 크레인 Ctrl+휠은 전체 조망의 0.65~3배를 지원하며 확대 시 플레이어를 따라간다. 객체 크기는 그대로다.

내장 ImageGen으로 사용자 참조에서 UI·크레인·불·나무를 제거하고 잔디·흙·낮은 바위·꽃의 픽셀 질감을 유지한 배경을 생성했다. 런타임은 `assets/scenery/upland/upland-environment-pixel-v2.png`와 `assets/shaders/upland-ground-v2.glsl`을 쓴다. 배경은 확대 전 월드 크기 단위로 반사 반복하므로 재질이 늘어나지 않으며, 전체 조망에서는 반복 무늬가 보일 수 있다. 이전 절차적 바닥 셰이더는 미연결 보존한다. 고원에서는 중복 바닥 장식을 끈다.

검증:

```text
py -3 scripts/headless_lua.py scripts/verify_upland.lua scripts/verify_lakeside.lua
py -3 scripts/render_upland.py
```

실제 런타임 명령의 오프스크린 결과는 `docs/previews/upland-stage-11-v1.png`, nearest 확대 검수본은 `docs/previews/upland-stage-11-pixel-v1.png`다. 게임 창은 자동 실행하지 않는다.
