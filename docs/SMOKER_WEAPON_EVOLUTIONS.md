# 흡연자 3레벨 분기와 만렙 무기 진화

## 진입 규칙

`꽁초 투척` 2→3레벨 선택 직후 전용 경로 2택을 연다. **화염 농축**은 착화·연소 중심이며 6레벨에 전자담배로, **줄꽁초**는 한 번에 3개비를 던지는 물량형이며 6레벨에 폭죽 발사기로 자동 진화한다. 경로는 해당 런에서 변경할 수 없고, 6레벨에는 선택창을 다시 띄우지 않는다.

## 3레벨 경로

- **화염 농축 → 전자담배:** 꽁초 불씨 전이 반경 +25%, 불씨 전이 확률 +35%, 비행 직격 피해 +35%, 식물형 연소 피해와 나무 간 확산 성능 +30%.
- **줄꽁초 → 폭죽 발사기:** 수동 투척과 자동 꽁초 투척이 한 번에 3개비로 갈라진다. 각 꽁초는 별도 비행·직격·착지·7초 불씨 전이 판정을 가지며 수동 공격은 탄약 3개비를 소비한다.

## 공통 패시브

진화 전 기본 공격이던 꽁초 투척은 자동 패시브로 전환된다. 6레벨 기준 2.6초마다 나무를 골라 꽁초를 던지며, 바닥에 7초간 남고 확률적으로 불씨를 옮긴다. 화염 농축은 강화된 불씨 수치를 유지하고, 줄꽁초는 자동 패시브도 3개비로 갈라진다.

## 전자담배

- 기본 공격: 마우스를 누르면 **흡입 → 압축 → 분사**를 약 0.9초에 걸쳐 진행한다. 계속 누르면 풀차지 분사를 자동 반복하고, 15% 이상 충전한 뒤 일찍 떼면 약한 풍압을 즉시 방출한다.
- 피해 주체는 증기 덩어리가 아니라 전방으로 넓어지는 풍압 전선이다. 충전에 따라 사거리 360→630, 끝 폭 42→114로 커지며 전선이 실제로 도달한 프레임에만 판정한다.
- 약한 분사도 수관에서 전용 잎 픽셀을 떼어내고 나무를 흔든다. 풀차지는 나무 스프라이트를 뿌리 발선에 고정한 채 뒤로 크게 휘게 하며 몬스터를 강하게 밀어낸다. 일반 타격 흔들림과 카메라 진동은 재사용하지 않는다.
- 차지 24프레임은 증기 픽셀이 기기 안으로 빨려 들어와 압축되는 방향으로 움직인다. 풍압도 24프레임/30fps로 재생하며, 서로 교차하지 않는 굵고 끊어진 난류 띠·전방 초승달 압력파·속도차를 둔 날리는 잎이 먼저 읽힌다. 전체 FX는 2.5D 바닥 기울기와 분리된 upright billboard로 그린다.

전자담배는 문서 시안이 아니라 실제 인게임 기본 공격 분기다. `src/clearcut_mode.lua`의 `updateVapeAttack`이 차지를 관리하고 `updateSmokerWeaponProjectiles`가 확장되는 원뿔형 풍압 판정·잎 파편·몬스터 넉백을 처리한다. `src/world.lua`의 `windImpactNode`는 나무를 뿌리 기준으로 휘게 하되 화면 진동을 만들지 않으며, `src/smoker_weapon_art.lua`가 차지·풍압·잎 전용 아틀라스를 그린다.

## 폭죽 발사기

- 기본 공격: 마우스를 누르는 동안 약 0.86초 간격으로 발사.
- 사거리 720, 로켓은 목표까지 곡사 비행.
- 착탄 반경 180. 나무와 몬스터에 광역 피해를 주고 살아남은 나무 및 식물형 몬스터에 불을 붙일 수 있다.
- 비행 6프레임과 폭발 전용 30프레임을 분리한다. 폭발은 384px 원생 셀을 1초 동안 30fps로 재생하며 점화→다색 곡선 방사→불티 분열과 낙하→연기·잔광 소멸이 프레임 사이에서 이어진다.
- 폭발은 빨강·금색·청록·초록·자홍을 함께 사용하지만 실사 입자나 매끈한 벡터 광선이 아니라 단계 명암의 카툰 픽셀 불티로 표현한다. 단색 원/사각형 런타임 도형은 사용하지 않는다.

### 인게임 가독성 기준 (2026-08-31)

셀(384px)은 런타임에서 폭발 지름(반경 180 + 특성, 실측 약 520px)으로 늘어난다. 아틀라스가 셀 가운데만 얇게 쓰면 실제 화면에서는 잔디 위에 색점 몇 개만 남아 "이펙트가 안 나온다"로 읽힌다. 그래서 다음을 지킨다.

- 점화 화염구는 켜져 있는 동안 **불투명**해야 한다. 알파를 프레임 0부터 떨어뜨리면 밝은 잔디에 묻힌다. 앞 절반은 알파 고정, 뒤 절반만 감쇠시킨다.
- 폭발 반경을 눈으로 알 수 있도록 **계단형 충격파 링**이 피해 가장자리까지 퍼진다.
- 혜성 갈래는 주 폭발 20개 + 위성 2개(12/10)이며, 궤적 두께와 머리 크기는 게임플레이 축소(약 1.35배 확대이므로 실질 확대)에서도 뭉개지지 않게 잡는다.
- 30프레임 중 뒤 3분의 2가 낙하 불티·연기 구간이므로, 그 구간에도 색점이 폭발 반경 전체에 남아 있어야 한다.
- 비행 로켓도 셀 안에서 충분히 크게 그리고(런타임 배율 0.78) 불꽃 노즐과 긴 스파크 꼬리를 붙인다.

인게임 검수는 `LAST_HAUL_CAPTURE_SCORE_FIREWORK=1`로 실제 기록 모드를 띄워 찍는다. **캡처는 `heldOverride`를 넘겨 강제로 발사하지 않고 `love.mouse.isDown`을 눌린 상태로 두고 `game:update`를 돌린다** — 실제 게임 루프와 같은 경로여야 "클릭해도 발사가 안 되는" 입력 배선 문제를 캡처가 지나치지 않는다. 실제로 `updateHeldAxe`가 폭죽에만 원본 `heldOverride`(실게임에서는 nil)를 넘기고 있어서, 아무리 클릭해도 발사되지 않았는데도 강제 발사 캡처는 멀쩡히 통과했었다. 회귀 검사는 `scripts/verify_score_weapon_slots.lua`가 오버라이드 없는 경로로 한 번 더 쏴 본다. `LAST_HAUL_SCORE_FIREWORK_AGE`로 폭발 경과 시간을 고르고(음수면 비행 중간), `LAST_HAUL_SCORE_FIREWORK_MAX=1`이면 쌍발·자탄·삼단까지 켠 최종 빌드를 재현한다. 결과물: `score-firework-rocket.png`, `score-firework-burst.png`, `score-firework-finale.png`.

## 자산과 검증

- 장비: `assets/characters/ingame/smoker-weapon-evolution-equipment-v1.png`
- FX: `assets/effects/smoker-weapon-evolution-fx-v1.png`
- 전자담배 차지: `assets/effects/smoker-vape-charge-fx-v2.png`
- 전자담배 풍압: `assets/effects/smoker-vape-pressure-fx-v2.png`
- 전자담배 잎 파편: `assets/effects/smoker-vape-leaves-fx-v2.png`
- 30fps 폭죽 폭발: `assets/effects/smoker-firework-burst-v2.png`
- 보존 시안: `assets/effects/concepts/smoker-weapon-evolutions-concept-v1.png`
- 런타임 모듈: `src/smoker_weapon_art.lua`
- 게임플레이 검증: `scripts/verify_smoker_weapon_evolutions.lua`
- 그래픽 검증: `scripts/verify_smoker_weapon_evolution_art.py`
- 전자담배 그래픽 검증: `scripts/verify_smoker_vape_pressure_art.py`
- 오프스크린 검수: `scripts/render_smoker_weapon_evolutions.py`
- GIF 검수: `docs/previews/smoker-firework-burst-v2.gif`
- 전자담배 GIF 검수: `docs/previews/smoker-vape-pressure-v2.gif`

## 보존된 과거 연습장에서 확인 (현재 로비 비활성)

로비의 `연습`에서 흡연자를 고른다. 오른쪽 `꽁초 투척`의 `+`를 눌러 3레벨이 되면 화염 농축/줄꽁초 전체화면 2택이 즉시 열린다. 선택 후 6레벨까지 올리면 각각 전자담배/폭죽 발사기로 자동 진화한다. 마우스 왼쪽 버튼을 누르고 있으면 해당 기본 공격을 시험할 수 있다.

실제 연습장 패널 오프스크린 검수본은 `docs/previews/skill-sandbox-v2.png`다.

## 현재 무한 연습장

로비 `P` 연습은 현재 벌목 기록 모드의 보유 영구 연구 또는 임시 전체 만렙 빌드를 시험한다. 예전 런 스킬 `+/-`·3레벨 분기 패널은 노출하지 않는다. 보존된 일반 작전용 전자담배·폭죽 진화는 `scripts/capture_smoker_weapon_evolutions.lua`와 `scripts/render_smoker_weapon_evolutions.py`로 창 없이 검수한다. 현재 패널 검수본은 `docs/previews/skill-sandbox-v2.png`다.
