/** 지도를 안 쓰는 앱이면 이 파일과 index.ts 의 재노출 한 줄을 지운다 (frontend/docs/map.md). */
export enum MapResultMessages {
    LOAD_FAILED = "지도를 불러오지 못했습니다. 네트워크와 Kakao JS 키(app.json extra.kakaoJsKey)를 확인해 주세요.",
    KEY_MISSING = "지도 키(kakaoJsKey)가 설정되지 않았습니다.",
    KEY_MISSING_HINT = "app.json extra.kakaoJsKey 에 Kakao JS 키를 넣어주세요.",
    WEB_UNSUPPORTED = "지도는 네이티브 앱(iOS·Android)에서 표시됩니다.",
}
