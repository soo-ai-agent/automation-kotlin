/**
 * 광고 단위 ID 결정 — 설정된 실 단위가 있으면 그것을, 없으면 개발 빌드에서만 테스트 단위를 쓴다.
 *
 * 배포 빌드에서 테스트 단위로 떨어지면 사용자에게 "테스트 광고"가 노출된다(수익도 없고 정책상도
 * 바람직하지 않다). 그래서 배포 빌드에서 단위가 비어 있으면 빈 문자열을 돌려주고, 호출부는
 * 지면 자체를 그리지 않는다.
 */
export function resolveAdUnitId(configuredId: string, testId: string): string {
    const configured: string = configuredId.trim();
    if (configured) {
        return configured;
    }
    return __DEV__ ? testId : "";
}
