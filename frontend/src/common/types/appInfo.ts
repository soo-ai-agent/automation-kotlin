/**
 * GET /api/v1/app-info 응답의 data — 스플래시가 서버 버전 표기에 쓴다.
 * 백엔드가 아직 이 엔드포인트를 만들지 않았어도 된다 — 실패하면 서버 조각 표시만 생략된다(services/appInfo.ts).
 */
export type AppInfo = {
    serverVersion: string;   // 빌드 정보가 없는 실행(IDE 클래스 빌드)이면 ""
};
