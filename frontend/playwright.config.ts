import {defineConfig} from "@playwright/test";

export default defineConfig({
    testDir: "./e2e",
    use: {
        // Expo 기본 포트(8081)는 같은 머신의 다른 Expo 앱이 쓰고 있기 쉽다.
        // reuseExistingServer 가 남의 서버를 재사용하지 않게 E2E 전용 포트를 쓴다.
        baseURL: "http://localhost:8090",
        trace: "on-first-retry",   // 실패했을 때만 추적 파일을 남긴다
    },
    // 테스트를 돌리면 웹 개발 서버(react-native-web)를 알아서 띄우고, 끝나면 내린다
    webServer: {
        command: "npm run web -- --port 8090",
        url: "http://localhost:8090",
        reuseExistingServer: true,
        timeout: 120000,   // 첫 실행은 Metro 번들링 때문에 기본 60초를 넘길 수 있다
    },
});
