# 최우선: 모든 그래픽 작업 전에 필수 스타일 가이드 확인

## 저장소 내 공통 그래픽 스킬 — 모든 PC·모든 에이전트 필수

**그래픽을 만들거나 수정하거나 검수하는 모든 에이전트는 작업 시작 전에 [`.agents/skills/defense-game-pixel-art/SKILL.md`](.agents/skills/defense-game-pixel-art/SKILL.md)를 읽고 전 과정을 적용한다.** 스킬 자동 검색 여부에 의존하지 않는다. 이 파일과 스킬은 Git 저장소에 함께 보관되므로 다른 PC에서 복제하거나 다른 AI를 사용해도 동일한 진입 규칙을 따른다. 스킬의 실제 화면 참조, 런타임 연결, 판정 일치, 오프스크린 시각 검수, 전체 헤드리스 테스트 중 하나라도 생략하면 그래픽 작업은 미완료다.

**ALL AGENTS ON EVERY MACHINE: Before creating, editing, or reviewing any graphics, read and apply [`.agents/skills/defense-game-pixel-art/SKILL.md`](.agents/skills/defense-game-pixel-art/SKILL.md). Do not rely on automatic skill discovery; this tracked AGENTS.md is the mandatory entry point.**

**모든 AI는 그래픽을 만들거나 수정하기 전에 [GRAPHICS_STYLE_GUIDE.md](docs/GRAPHICS_STYLE_GUIDE.md)를 읽고, 그 문서가 지정한 실제 v3 화면과 자산 보드 이미지를 열어 본다. 현재 그래픽은 숲에만 한정하지 않는 향후 모든 그래픽의 표현 기준이다. 외형 설명, 좋은 예/금지 예, 제작 수치, 대상별 적용법, 실패 수정법, 완료 체크리스트와 AI 전달 문구를 따른다. “인디·고퀄·고밀도”라는 단어만으로 스타일을 추측하지 않는다.**

**ALL GRAPHICS TASKS: Read docs/GRAPHICS_STYLE_GUIDE.md and visually inspect its current-v3 references BEFORE editing. Apply its style and acceptance checklist to every asset category. Do not substitute your own interpretation of indie, high quality, or pixel art.**

## 모든 그래픽의 최소 품질 — 고밀도 픽셀아트

**승인된 숲 스타일(2026-08-26): 뱀서식 단순한 실루엣 + 조금 더 풍부한 픽셀 재질·동작. 카툰 나무와 기존 작은 몬스터 비율이 기준이다. 고밀도 = 실사·복잡한 장식이 아니다. [승인 시안·실제 자산·제작 규격](docs/FOREST_ARCADE_ART.md)을 먼저 확인한다. `assets/enemies/arcade/*-v3.png`가 현재 적용본이며, 미채택 v1/v2 자산은 연결하지 않는다.**

**이 저장소의 그래픽을 만들거나 수정하는 모든 AI는 [최소 품질 기준](docs/PIXEL_ART_PIPELINE.md#최우선-모든-그래픽의-최소-품질-기준)을 먼저 읽고 준수한다. 캐릭터·장비·적·보스·배경·건물·아이콘·투사체·FX 등 모든 그래픽 작업에 적용한다.**

- 기준 자산: [`smoker-cigarette-pixel-v2.png`](assets/characters/ingame/smoker-cigarette-pixel-v2.png). **256×48 원생 픽셀, 70색, 재질별 16단계 명암과 디더링**이 최소 시각 품질의 구체적인 예다. 단순 이미지 크기가 아니라 실제 픽셀 정보량·재질 구분·입체감을 맞춘다.
- FX 기준: 연기 **192×384 그리드 / 월드 60×120 = 축당 3.2 텍셀/월드 단위**. 크기를 늘리면 그리드도 함께 늘려 픽셀 밀도를 유지한다.
- **작은 픽셀 조각 확대, 몇 색의 큰 블록, 실사 원화 단순 축소, 블러로 경계 감추기, 의미 없는 노이즈 금지.** 명암 그라데이션은 고정 그리드·단계별 색상 램프·디더링으로 만들고 제작용 또는 런타임 셰이더를 적용한다.
- 실제 게임 크기와 확대 픽셀 뷰를 모두 확인한다. 수치와 테스트만 통과시킨 결과를 완성으로 보고하지 않는다. 게임 창은 자동 실행하지 않는다.
- 기존 저품질 자산이나 아래의 기존 아틀라스 크기는 품질 기준을 낮출 근거가 아니다. 사용자의 명시적 허용 없이는 이 기준을 완화하지 않는다.

**FOR ALL AGENTS: Mandatory for ALL future graphics work. Match or exceed the authored pixel detail, material shading and readability of the reference sprite. Large image dimensions alone do not qualify. Do not upscale a tiny sprite or use a photorealistic image as the final pixel art. Read the linked specification first.**

# 프로젝트 작업 규칙

## 현재 활성 개발 모드 — 벌목 기록 모드

**현재 로비에서 플레이어에게 노출하는 주 모드는 흡연자 `벌목 기록 모드(score_attack)` 하나다.** 일반 스테이지 작전, 다른 작업자, 지구본, 브리핑, 보스전, 러시 등 기존 코드는 폐기한 것이 아니라 향후 재사용을 위해 **의도적으로 비활성화**한 상태다. 삭제하거나 기록 모드에 억지로 합치지 않는다. 활성 범위와 복구 지점은 [`docs/ACTIVE_DEVELOPMENT_MODE.md`](docs/ACTIVE_DEVELOPMENT_MODE.md)를 따른다.

**FOR ALL AGENTS: The lobby intentionally exposes only the smoker score-attack prototype. Legacy campaign, character, map, briefing, boss, and rush code is preserved but deliberately unreachable from the production lobby. Do not delete it or accidentally re-enable it without an explicit user request.**

## 모든 완료 작업은 Git 원격 저장소에 반영

**모든 에이전트는 작업을 완료할 때 관련 검증을 실행하고, 변경 파일을 커밋한 뒤 현재 추적 브랜치의 원격 저장소까지 푸시한다.** 로컬 커밋만 만든 상태를 최종 완료로 보고하지 않는다. 푸시 결과와 커밋 해시를 최종 보고에 포함한다. 검증 실패, 충돌, 인증 오류로 안전하게 푸시할 수 없으면 실패 상태를 숨기지 말고 정확한 차단 원인을 보고한다.

**ALL COMPLETED WORK: Verify, commit, and push the completed changes to the tracked remote branch. Report the commit hash and push result. Never claim completion when the work exists only in the local working tree.**

## 플레이어 캐릭터 픽셀 애니메이션

플레이어 캐릭터와 이후 추가되는 주요 인게임 캐릭터는 반드시 [`docs/PIXEL_ART_PIPELINE.md`](docs/PIXEL_ART_PIPELINE.md)의 제작 규격을 따른다.

- ImageGen은 캐릭터 정체성·복장·재질·대표 포즈를 정하는 고해상도 콘셉트 원화에만 사용한다. 각 애니메이션 프레임을 서로 독립적으로 생성한 이미지를 최종 스프라이트로 사용하지 않는다.
- 한 캐릭터의 고정 모델(체형, 얼굴, 복장, 장비, 실루엣)을 먼저 잠근 뒤 같은 픽셀 그리드와 동일한 발선에서 모든 프레임을 제작한다.
- 현 플레이어 아틀라스 규격은 `6열 × 2행`, 셀 `96 × 192 px`, 전체 `576 × 384 px`, 투명 RGBA다. 1행은 걷기/대기, 2행은 고유 액션이며 발선은 셀 내부 `y=190`이다.
- 팔레트는 한 캐릭터 아틀라스 안에서만 공유한다. 캐릭터끼리 또는 카테고리끼리 색을 통일하지 않는다. 용도·성격·재질에 맞는 고유 색을 사용한다.
- 캐릭터 몸은 스프라이트 시트에 포함한다. 핵심 장비는 시트 또는 담배처럼 별도 고밀도 장비 스프라이트로 제작하고 프레임별 입·손 앵커에 연결한다. 단순 도형으로 대체하지 않는다. 연기, 불, 충격파, 투사체, 타격 파편은 별도 FX 레이어로 분리한다.
- 캐릭터와 한 화면에 크게 보이는 나무·중장비·보스도 실제 최종 표시 크기로 미리 픽셀화한다. 고해상도 원화를 런타임 `nearest` 축소로 대신하지 않는다.
- 고유 스킬 FX는 캐릭터의 재질·명도 범위에 맞춘 제한 팔레트와 정수 좌표 픽셀 형태를 사용한다. 부드러운 반투명 원·선·그라데이션 도형을 그대로 섞지 않는다.
- 타격·발사·채집 판정은 독립 타이머가 아니라 해당 액션의 접촉/방출 프레임에 연결한다.
- 런타임은 `nearest` 필터를 사용한다. 발선, 스케일, 방향 전환 기준을 캐릭터마다 임의로 바꾸지 않는다.
- 기존 원본·초안·이전 버전은 삭제하지 않는다. 새 결과는 버전이 붙은 별도 파일로 저장한다.
- 사용자가 명시적으로 허용하지 않는 한 검증을 위해 게임 창을 띄우지 않는다. 이 프로젝트에서는 현재 사용자의 상시 지시에 따라 게임 창을 절대 자동 실행하지 않고 헤드리스 검사만 수행한다.

## 특성/스킬 문서화

로비 특성(`src/character_traits.lua`), 인게임 스킬(`src/clearcut_mode.lua`의 `definitions`), 융합 스킬(`src/clearcut_fusions.lua`)을 추가·수정하면 반드시 **같은 작업 안에서 [`docs/character_dossier.html`](docs/character_dossier.html)의 데이터(`TRAITS`/`SKILLS`/`FUSIONS` 객체)를 같이 갱신**한다. 이름·설명·레벨·조합 조건·효과 중 하나라도 바뀌면 대상이다. 이 동기화가 빠진 작업은 구현과 테스트가 끝났더라도 미완료로 취급한다. 이 파일이 1차 소스다 — 저장소에 커밋되는 평범한 정적 HTML이라 Claude 로그인 없이 로컬에서 바로 열리고, Codex를 포함한 어떤 에이전트든 일반 텍스트 파일로 읽고 고칠 수 있다.

Claude Code 세션이라면, 이 파일을 고친 뒤 Claude Artifact "특성 인사기록부"(https://claude.ai/code/artifact/f441025a-1ef5-4b5f-8cda-13b3256f1083)도 같은 `url`로 재발행해서 사람이 보기 좋은 거울본을 최신 상태로 유지한다 — 단, 이 Artifact 갱신은 Claude 전용 도구가 필요해서 Codex 등 다른 에이전트는 스킵해도 된다(`docs/character_dossier.html`만 고치면 충분).
