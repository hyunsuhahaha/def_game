# 비건 단체 회장 — 포크 전투 그래픽·게임플레이 규격

이 문서는 비건 단체 회장의 채택 디자인과 런타임 계약이다. 그래픽 수정 전 `GRAPHICS_STYLE_GUIDE.md`, `PIXEL_ART_PIPELINE.md`와 실제 v3 기준 보드를 먼저 확인한다.

## 채택 외형

- 성별과 체형: 중년 여성. 짧은 다리, 넓은 허리, 약간 구부정한 자세로 영웅형 8등신 체형을 피한다.
- 얼굴: 둥근 안경, 묶다 만 반묶음 머리. 실제 게임 크기에서도 안경과 머리 실루엣이 남아야 한다.
- 복장: 겨자색 셔츠, 자두색 재킷, 이끼색 앞치마, 베이지 바지, 작업화.
- 장비: 초록 손잡이와 자두색 끝마개가 있는 대형 스테인리스 **네 갈래 포크**. 창이나 막대기로 보이지 않도록 갈래 사이의 음영과 금속 하이라이트를 유지한다.

고정 원화는 `assets/characters/concepts/vegan-woman-model-v3-source.png`, 포크 원화는 `assets/characters/concepts/vegan-fork-model-v1-source.png`다. 캐릭터와 장비는 `scripts/build_vegan_fork_assets.py`, v2 접촉·회수·섭취 FX는 `assets/fx/concepts/vegan-fork-consume-fx-source-v2.png`를 입력으로 쓰는 `scripts/build_signature_fx_v2.py`에서 고정 픽셀 그리드와 공유 제한 팔레트로 다시 작성한다.

## 자산 계약

| 자산 | 규격 | 역할 |
|---|---:|---|
| `vegan-atlas-pixel-v3.png` | 576×384, 96×192 셀 6×2 | 1행 걷기, 2행 크게 숙여 찌르는 동작 |
| `vegan-fork-pixel-v1.png` | 256×96 | 손 앵커에 붙는 네 갈래 포크 |
| `vegan-fork-impact-atlas-v2.png` | 128×128, 6프레임 | 여러 대상에 네 갈래 포크가 꽂히는 금속성 접촉·파편 |
| `vegan-fork-consume-atlas-v2.png` | 160×160, 8프레임 | 꿰기·회수 속도선·입 앞 섭취 충격과 재질별 부스러기 |

모든 고체 자산은 이진 알파와 `nearest` 필터를 사용한다. 팔레트 숫자만 늘리지 말고 천, 금속, 피부, 나무마다 단계 명암과 픽셀 재질을 구분한다.

## 공격과 판정

1. 마우스 방향의 짧고 넓은 삼각형 전방 레인을 표시한다.
2. 캐릭터가 몸을 숙이고 포크를 뒤로 당긴다.
3. 액션 진행도 **0.53**에서 포크 끝이 목표에 닿으며 피해가 한 번 발생한다.
4. 판정은 화면에 보이는 레인과 같은 방향·길이·폭을 사용한다. 캐릭터 바로 앞만 맞는 숨은 원형 판정으로 대체하지 않는다.
5. 6레벨 `뷔페용 포크`는 초록 포크 잔상과 절반 피해의 두 번째 타격을 만든다.

## 포크에 꿰어 먹기 연출

포크 타격으로 나무 또는 적의 HP가 0이 되었을 때만 다음 순서를 실행한다. 전방 레인 안의 여러 대상이 동시에 맞고 죽었다면 각각 독립적으로 꿰어져 회수된다.

1. 포크 접점에서 충격 별과 잎·나무 조각이 튄다.
2. 쓰러진 나무 원본 또는 실제 적 스프라이트가 포크에 걸려 작아지며 곡선을 따라 캐릭터 입 쪽으로 끌려온다.
3. 입 근처에서 밝은 섭취 충격과 잎·나무·음식 부스러기가 터진다. 검은 삼각형 턱이나 범용 원형 폭발로 대체하지 않는다.
4. `접시 비우기`는 모든 섭취에 체력 회복을 주고, 나무 섭취에는 추가 목재도 준다. `한 그릇 더`는 먹은 직후 공격 속도를 준다.

연출은 공포스러운 포식이나 진지한 피·육편 표현을 쓰지 않는다. 과장된 포크, 별 모양 충격, 잎과 부스러기로 가볍고 우스운 느낌을 유지한다.

## 채택 스킬 구성

- **대왕 포크**: 기본 포크 찌르기의 피해·폭·다중 목표를 강화하며 포크로 쓰러뜨린 나무와 적을 먹는다.
- **뷔페용 포크**: 사거리와 찌르기 잔상을 강화하며 6레벨에 두 번째 포크 타격을 추가한다.
- **접시 비우기**: 포크로 쓰러뜨린 대상 섭취에 회복을 주고, 나무라면 추가 목재도 주며 6레벨에 부스러기 범위 피해를 낸다.
- **한 그릇 더**: 대상을 먹은 직후 공격 속도와 연속 식사 능력을 높인다.
- **융합 — 무한 리필**: `대왕 포크`와 `접시 비우기` 만렙 조합. 피해·동시 목표·식후 가속을 함께 강화한다.

비건에게 있던 독비·감염·중독 스킬은 제거한다. 철학자의 침 중독은 별도 캐릭터 기능이므로 이 규격과 무관하다.

## 생성 프롬프트의 고정 의도

캐릭터 원화는 “현재 v3 카툰 픽셀 게임의 고밀도 재질, 작은 게임 캐릭터 비율, stocky middle-aged Korean woman, short legs and broad waist, round glasses, messy half bun, moss apron, mustard shirt, plum jacket, beige pants, work boots”를 고정했다. 포크 원화는 “oversized reusable four-tine table fork, stainless stepped highlights, green handle, plum end cap, unmistakable fork rather than spear”를 고정했다. 생성 원화는 정체성 참고용이며 최종 게임 프레임은 빌더와 런타임 앵커로 통제한다.

## 완료 검증

- `py -3 scripts/verify_vegan_fork_art.py`
- `py -3 scripts/verify_character_pixel_atlases.py`
- `py -3 scripts/headless_lua.py`
- `docs/previews/signature-fx-v2-display-scale.png`, `vegan-fork-consume-v2-motion.gif`를 실제 크기로 확인한다.

표시 크기 미리보기에서 네 갈래 포크, 여러 대상의 접촉, 회수 방향, 섭취 파편이 즉시 읽히고 서로 겹쳐 판정을 오해하게 만들지 않아야 한다.
