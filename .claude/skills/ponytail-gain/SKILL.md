---
name: ponytail-gain
description: >
  ponytail 의 측정된 효과를 압축 점수판으로 보여준다: 더 적은 코드, 더 적은
  비용, 더 빠른 속도 — 벤치마크 중앙값 기준. 일회성 표시이며 지속 모드도,
  저장소별 수치도 아니다. 트리거: /ponytail-gain, "ponytail gain",
  "ponytail 이 뭘 아껴줘", "ponytail 효과 보여줘", "ponytail 점수판".
license: MIT
---

> **출처** — DietrichGebert/ponytail (MIT, <https://github.com/DietrichGebert/ponytail>) 에서 가져왔고 원본 그대로 쓴다.
> 라이선스 전문은 [LICENSE](../LICENSE) 에 있다.
# Ponytail Gain

호출되면 이 점수판을 표시한다. 일회성: 모드를 바꾸거나, 플래그 파일을 쓰거나, 아무것도 지속하지 말 것.

수치는 공개된 벤치마크 중앙값이다(일상 작업 5개: 이메일 검증기, debounce, CSV 합산, 카운트다운 타이머, rate limiter; 모델 3개: Haiku, Sonnet, Opus). 현재 저장소에서 계산한 값이 아니라 도입 당시 가져온 외부 단발 생성 벤치마크 값이다. 최신 측정이나 이 템플릿의 성과로 소개하지 않는다.

출처는 [업스트림 저장소](https://github.com/DietrichGebert/ponytail)의 README와 벤치마크 자료다. 이 저장소에는 원시 벤치마크가 포함되어 있지 않다.

## 점수판

플레인 ASCII 막대로 그린다. 막대 길이는 측정 범위, 라벨이 정확한 수치를 담는다:

```
  ponytail gain                     벤치마크 중앙값 · 작업 5개 · 모델 3개

  코드 줄 수    no-skill  ████████████████████  100%
                ponytail  ██▌·················    6–20%   ▼ 80–94%
  비용          no-skill  ████████████████████  100%
                ponytail  █████▌··············   23–53%  ▼ 47–77%
  속도          ponytail  ▸ 3–6× 빠름

  이 저장소:  /ponytail-debt  (미뤄둔 지름길)
              /ponytail-audit (아직 잘라낼 수 있는 것)
```

## 정직의 경계

이 수치는 벤치마크 중앙값이지 이 저장소가 아니다. 저장소별 절감 수치("여기서 X줄/토큰 아꼈어요")는 절대 출력하지 말 것: 안 만든 버전은 애초에 쓰인 적이 없으니, 살아 있는 저장소에는 뺄 기준선이 존재하지 않는다. 저장소별 실제 수치는 `/ponytail-debt`(집계된 장부)에서만 나오며, 이 카드는 수치를 지어내는 대신 그쪽을 가리킨다.

## 경계

일회성 표시. 아무것도 수정하지 않고 모드도 바꾸지 않는다. "stop ponytail" 또는 "일반 모드": 복귀.
