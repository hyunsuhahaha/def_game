# 환경 설정과 오디오 마스터

환경 설정은 `src/settings.lua`의 `last_haul_settings_v1.txt`에 저장한다. 설정 화면에서 값을 바꾸면 런 재시작 없이 즉시 반영되고, 다음 실행에서 다시 불러온다.

| 항목 | 기본값 | 저장 | 런타임 반영 |
|---|---:|---|---|
| 배경음악 | 70% | `musicVolume` | 로비 현재 트랙과 이미 캐시된 전 트랙에 즉시 적용 |
| 효과음 | 80% | `sfxVolume` | 벌목·타격·불·보상 효과음의 마스터 배율 |
| 화면 흔들림 | 켜짐 | `screenShake` | 카메라 반동 즉시 적용 |
| 시점 기울기 | 76% | `viewPitch` | 벌목 지역·연습장 2.5D 지면에 적용 |
| 전체 화면 | 현재 OS/창 상태 | 별도 수치로 저장하지 않음 | LÖVE 창 상태를 바로 전환 |

## 입력과 피드백

- 배경음악·효과음·시점 기울기는 슬라이더 드래그와 마우스 휠을 모두 지원한다.
- 배경음악은 드래그하는 동안 실제 로비 음악 크기가 즉시 변한다.
- 효과음은 드래그를 놓을 때 짧은 시험음을 재생해 현재 크기를 확인한다.
- 0%는 완전 음소거며, 배경음악의 트랙별 기본 음량과 효과음의 강/약 타격 차이는 마스터 배율 안에서 유지된다.
- 헤드리스 캡처·자가 검사 프로필은 `Settings.load(true, ...)`를 쓰며 사용자 설정 파일을 읽거나 쓰지 않는다.

## 검증

```bash
python scripts/headless_lua.py scripts/verify_audio_settings.lua scripts/verify_view_tilt_setting.lua
python scripts/render_audio_settings.py
```

- 1280×720: `docs/previews/audio-settings-v1.png`
- 960×540: `docs/previews/audio-settings-v1-960.png`
