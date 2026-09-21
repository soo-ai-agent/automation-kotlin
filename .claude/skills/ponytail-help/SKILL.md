---
name: ponytail-help
description: >
  ponytail 의 모든 모드·스킬·명령을 담은 빠른 참조 카드. 일회성 표시이며
  지속 모드가 아니다. 트리거: /ponytail-help, "ponytail help",
  "ponytail 명령 뭐 있어", "ponytail 어떻게 써".
license: MIT
---

> **출처** — DietrichGebert/ponytail (MIT, <https://github.com/DietrichGebert/ponytail>) 에서 가져왔고 원본 그대로 쓴다.
> 라이선스 전문은 [LICENSE](../LICENSE) 에 있다.
# Ponytail Help

호출되면 이 참조 카드를 표시한다. 일회성 — 모드를 바꾸거나, 플래그 파일을 쓰거나, 아무것도 지속하지 말 것.

## 레벨

| 레벨 | 트리거 | 달라지는 것 |
|-------|---------|-------------|
| **Lite** | `/ponytail lite` | 요청받은 대로 만들되, 더 게으른 대안을 한 줄로 언급. |
| **Full** | `/ponytail` | 사다리 강제: YAGNI → stdlib → 네이티브 → 한 줄 → 최소한. 기본값. |
| **Ultra** | `/ponytail ultra` | YAGNI 극단주의자. 추가보다 삭제 먼저. 만들기 전에 요구사항에 도전. |

레벨은 변경하거나 세션이 끝날 때까지 유지된다.

## 스킬

| 스킬 | 트리거 | 하는 일 |
|-------|---------|--------------|
| **ponytail** | `/ponytail` | 게으른 모드 본체. 동작하는 가장 단순한 해법. |
| **ponytail-review** | `/ponytail-review` | 오버엔지니어링 리뷰: `L42: yagni: 팩토리, 제품 하나. 인라인.` |
| **ponytail-audit** | `/ponytail-audit` | 저장소 전체 오버엔지니어링 감사: 지울 것 순위 목록. |
| **ponytail-debt** | `/ponytail-debt` | `ponytail:` 지름길 주석을 추적 장부로 수확. |
| **ponytail-gain** | `/ponytail-gain` | 측정 효과 점수판: 더 적은 코드, 더 적은 비용, 더 빠른 속도. |
| **ponytail-help** | `/ponytail-help` | 이 카드. |

Codex에서는 `$ponytail`, `$ponytail-review`, `$ponytail-help`처럼 호출한다.

## 끄기와 기본값

"stop ponytail" 또는 "일반 모드"라고 말한다. 기본 강도는 `full`이며 실제 요청을 우선한다.

## 설치와 갱신

이 저장소는 플러그인 실행 코드 없이 스킬 파일을 보관한다.

환경변수·사용자 설정 파일을 읽는 자동 활성화 기능과 플러그인 자동 업데이트는 포함하지 않는다.

갱신할 때는 `ponytail` 스킬 본문에 따라 원본과 대조하고, 저장소의 공통 원칙과 번역 변경을 보존한다.

## 더 보기

전체 문서 + 예시: https://github.com/DietrichGebert/ponytail
