# 지구본 지리 원본

`globe-world-pixel-v1.png`의 해안선·섬·호수 형상은 Natural Earth 1:50m GeoJSON을 사용한다. 국경선은 사용하지 않는다.

- 원본 저장소: `https://github.com/nvkelso/natural-earth-vector/tree/master/geojson`
- 공식 배포 페이지: `https://www.naturalearthdata.com/downloads/50m-physical-vectors/`
- 이용 조건: `https://www.naturalearthdata.com/about/terms-of-use/` — 공개 도메인
- `ne_50m_land.geojson` SHA-256: `E874B27A51D146452BE360CAFB3CC50C86001074A67D534113E6534682F9826B`
- `ne_50m_lakes.geojson` SHA-256: `D350B75978B26FE839B797C2C529B2FB8F47FB3983C03F4964E36D5DF9378A52`

`scripts/build_globe_map_v1.py`가 원본 좌표를 1024×512 등거리 원통 도법 픽셀 지도에 그린 뒤, 해안 외곽선·바다·기후대·산맥의 카툰 픽셀 재질만 추가한다. 대륙 실루엣을 손으로 다시 그리거나 생성형 이미지로 대체하지 않는다.
