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
]);
