// https://docs.expo.dev/guides/using-eslint/
const {defineConfig} = require("eslint/config");
const expoConfig = require("eslint-config-expo/flat");
const stylistic = require("@stylistic/eslint-plugin");

module.exports = defineConfig([
    expoConfig,
    {
        ignores: ["dist/*", ".expo/*", ".claude/**"],
    },
    {
        plugins: {"@stylistic": stylistic},
        rules: {
            // 포맷은 사람이 아니라 도구가 정한다 — rules.md "리뷰 범위 밖: 포매팅은 포매터가 처리".
            "@stylistic/indent": ["error", 4, {SwitchCase: 1}],
            "@stylistic/quotes": ["error", "double", {avoidEscape: true}],
            "@stylistic/semi": ["error", "always"],
            "@stylistic/comma-dangle": ["error", "always-multiline"],
            "@stylistic/object-curly-spacing": ["error", "never"],
            "@stylistic/arrow-parens": ["error", "always"],
            "@stylistic/eol-last": ["error", "always"],
            "@stylistic/no-trailing-spaces": "error",
            "@stylistic/max-len": ["error", {
                code: 120, ignoreUrls: true, ignoreStrings: true,
                ignoreTemplateLiterals: true, ignoreRegExpLiterals: true,
            }],

            // 객체·배열을 어떻게 줄바꿈할지는 **일부러 규칙을 두지 않는다.**
            // frontend-common 의 "채워 적기"(100자까지 채우고 넘치면 다음 줄)를 도구가 깨지 않게 하려는 것이다.
            // Prettier 를 쓰지 않는 이유도 같다 — Prettier 는 이 배치를 강제로 한 줄씩 펼치고 끌 수 없다.
        },
    },
    {
        // 저장소 고유 규칙 중 **기계가 셀 수 있는 둘**만 여기서 막는다.
        // 규칙이 있으면 그것을 강제할 장치가 있어야 한다(core-principles) — 나머지는 리뷰어의 일이다.
        // 타입만 빌려 오는 import 까지 막히는 규칙은 넣지 않았다. 오탐이 나는 규칙은 곧 꺼지기 때문이다.
        files: ["src/screens/**/index.tsx", "src/screens/*.tsx"],
        rules: {
            "no-restricted-syntax": ["error", {
                selector: "CallExpression[callee.name=/^use(State|Effect|Ref)$/]",
                message: "화면은 상태를 갖지 않는다 — useState·useEffect·useRef 는 훅으로 옮긴다 (frontend-screen).",
            }],
        },
    },
    {
        // HTTP 창구는 api/client.ts 하나다. 두 번째가 생기면 인증과 에러 처리가 두 갈래로 갈라진다.
        files: ["src/**/*.ts", "src/**/*.tsx"],
        ignores: ["src/api/client.ts"],
        rules: {
            "no-restricted-imports": ["error", {
                paths: [{
                    name: "expo/fetch",
                    message: "HTTP 는 api/client.ts 만 부른다 — 자원별 요청 함수를 통한다 (frontend-api).",
                }],
            }],
        },
    },
]);
