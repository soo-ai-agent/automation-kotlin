/** WebView → RN 메시지 구분 코드. 생산(WebView HTML 템플릿 보간)과 소비(handleMessage) 양쪽이 이 멤버를 참조한다. */
export enum MapWebViewMessageType {
    MAP_LOAD_FAILED = "mapLoadFailed",
}

export enum MapResultMessages {
    LOAD_FAILED = "지도를 불러오지 못했습니다. 네트워크와 Kakao JS 키(app.json extra.kakaoJsKey)를 확인해 주세요.",
}
