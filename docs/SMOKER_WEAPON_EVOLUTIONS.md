# 흡연자 만렙 무기 진화

## 진입 규칙

`꽁초 투척` 5→6레벨 선택 직후 전용 2택을 연다. 선택은 해당 런에서 변경할 수 없다. 융합 조건도 같은 선택 흐름 뒤 정상 검사한다.

## 공통 패시브

진화 전 기본 공격이던 꽁초 투척은 자동 패시브로 전환된다. 6레벨 기준 2.6초마다 나무를 골라 꽁초를 던지며, 바닥에 7초간 남고 확률적으로 불씨를 옮기는 기존 규칙을 그대로 사용한다.

## 전자담배

- 기본 공격: 마우스를 누르는 동안 약 0.27초 간격으로 발사.
- 사거리 610, 증기 반경 45, 비행 수명 0.72초.
- 증기탄 하나가 지나간 경로 전체에서 나무와 몬스터를 각각 한 번씩 관통 타격한다.
- 청록·보라 증기 실루엣은 6프레임 모두 다르며 2.5D 바닥 기울기와 분리된 upright billboard로 그린다.

전자담배는 문서 시안이 아니라 실제 인게임 기본 공격 분기다. `src/clearcut_mode.lua`의 `updateVapeAttack`이 발사체를 생성하고 `updateSmokerWeaponProjectiles`가 이동 경로 전체의 나무·몬스터 충돌과 피해를 처리하며, `src/smoker_weapon_art.lua`가 손 장비와 증기탄을 그린다.

## 폭죽 발사기

- 기본 공격: 마우스를 누르는 동안 약 0.86초 간격으로 발사.
- 사거리 720, 로켓은 목표까지 곡사 비행.
- 착탄 반경 180. 나무와 몬스터에 광역 피해를 주고 살아남은 나무 및 식물형 몬스터에 불을 붙일 수 있다.
- 비행 6프레임과 폭발 전용 30프레임을 분리한다. 폭발은 384px 원생 셀을 1초 동안 30fps로 재생하며 점화→다색 곡선 방사→불티 분열과 낙하→연기·잔광 소멸이 프레임 사이에서 이어진다.
- 폭발은 빨강·금색·청록·초록·자홍을 함께 사용하지만 실사 입자나 매끈한 벡터 광선이 아니라 단계 명암의 카툰 픽셀 불티로 표현한다. 단색 원/사각형 런타임 도형은 사용하지 않는다.

## 자산과 검증

- 장비: `assets/characters/ingame/smoker-weapon-evolution-equipment-v1.png`
- FX: `assets/effects/smoker-weapon-evolution-fx-v1.png`
- 30fps 폭죽 폭발: `assets/effects/smoker-firework-burst-v2.png`
- 보존 시안: `assets/effects/concepts/smoker-weapon-evolutions-concept-v1.png`
- 런타임 모듈: `src/smoker_weapon_art.lua`
- 게임플레이 검증: `scripts/verify_smoker_weapon_evolutions.lua`
- 그래픽 검증: `scripts/verify_smoker_weapon_evolution_art.py`
- 오프스크린 검수: `scripts/render_smoker_weapon_evolutions.py`
- GIF 검수: `docs/previews/smoker-firework-burst-v2.gif`

## 연습장에서 확인

로비의 `연습`에서 흡연자를 고른다. 오른쪽 스킬 목록에서 `꽁초 투척` 행을 눌러 Lv.6으로 만든 뒤 `무기 진화`의 `전자담배` 또는 `폭죽 발사기`를 직접 고른다. 선택 직후 마우스 왼쪽 버튼을 누르고 있으면 해당 기본 공격을 시험할 수 있다. `전부 만렙`과 `전체 초기화`로 빌드를 빠르게 재설정할 수 있고, 목록이 화면보다 길면 패널 위에서 휠로 스크롤한다.

실제 연습장 패널 오프스크린 검수본은 `docs/previews/skill-sandbox-v2.png`다.
