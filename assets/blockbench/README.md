# Blockbench Source Assets

`quest_blocks.bbmodel`은 인게임 블록 body 형태(6종)를 담은 편집 가능한 Blockbench 원본이며,
**텍스처링 작업용** 소스입니다.

- 박스 4종(`square` / `diamond` / `chest` / `boss`) = **cube** 요소
- 원기둥 1종(`circle`) = **mesh** 요소(16면)
- 삼각기둥 1종(`triangle`) = **mesh** 요소(3면)
- 256×256 빈 텍스처 슬롯 1개(`quest_blocks`) — 여기에 페인팅
- 모든 요소는 원점 중심·축 정렬(unrotated). diamond 45°·triangle 180° 회전은 **인게임 코드**(`_body_yaw()`)에서 적용하므로 모델은 회전 없이 둡니다.
- 스케일: 1 월드 단위 = 16 Blockbench 단위(GLB로 내보내면 인게임 치수와 일치).

## 인게임 모델 (`assets/models/quest_blocks.glb`)

인게임 블록 body는 이제 `assets/models/quest_blocks.glb`에서 **rank별 메시**를 로드해 사용합니다
(`scripts/quest_block.gd`의 `_make_block_mesh()`). GLB가 없거나 아직 임포트되지 않았으면
절차 메시로 폴백하므로 항상 실행은 됩니다.

GLB에는 인게임과 **동일한 형태**의 6개 메시가 들어 있습니다(원점 중심, Y-up, 월드 단위):

| rank     | 형태            | 치수 (X,Y,Z)        |
|----------|-----------------|---------------------|
| circle   | 원기둥(16면)    | r0.55, h0.34        |
| triangle | 삼각기둥(3면)   | r0.66, h0.34        |
| square   | 박스            | 1.12 × 0.34 × 0.86  |
| diamond  | 박스(코드서 45° 회전) | 1.0 × 0.34 × 1.0 |
| chest    | 박스            | 1.0 × 0.42 × 0.78   |
| boss     | 박스            | 2.68 × 0.42 × 1.04  |

top_cap(상판)과 아이콘 스프라이트, 재질 색은 코드에서 적용하므로 GLB는 body 형태만 담습니다.

## 텍스처링 → GLB 재내보내기 워크플로

1. Blockbench에서 `quest_blocks.bbmodel`을 연다.
2. `quest_blocks` 텍스처(256²)에 페인팅. UV는 자동 배치된 시작점이라 필요시 요소별로 다시 언랩.
3. **File → Export → glTF(.glb)** 로 `assets/models/quest_blocks.glb`에 덮어쓴다.
4. Godot이 자동 재임포트 → 인게임 블록이 새 모델/텍스처로 표시.

> 치수 주의: square가 Godot에서 약 **1.12** 폭으로 들어와야 콜리전/그리드와 맞습니다.
> Blockbench glTF 내보내기 스케일이 다르면 Godot의 .glb 임포트 스케일로 보정.

현재 `assets/models/quest_blocks.glb`는 이 `.bbmodel`과 동일 형태로 `trimesh`가 생성한
**플레이스홀더**(텍스처 없음)입니다. Blockbench에서 텍스처 입힌 GLB로 덮어쓰면 대체됩니다.
