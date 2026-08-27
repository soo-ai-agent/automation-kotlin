import {defineConfig} from "@playwright/test";

export default defineConfig({
    testDir: "./e2e",
    use: {
        baseURL: "http://localhost:8081",
        trace: "on-first-retry",   // 실패했을 때만 추적 파일을 남긴다
    },
    // 테스트를 돌리면 웹 개발 서버(react-native-web)를 알아서 띄우고, 끝나면 내린다
    webServer: {
        command: "npm run web",
        url: "http://localhost:8081",
        reuseExistingServer: true,
        timeout: 180000,   // 첫 실행은 Metro 번들링 때문에 기본 60초를 넘는다
    },
});
