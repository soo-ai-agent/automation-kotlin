/** 내비게이션 스택의 화면 목록 — 화면을 추가·삭제하면 App.tsx 의 Stack.Screen 과 함께 고친다. */
export type RootStackParamList = {
    User: undefined;
    Map: undefined;   // 지도 화면을 들어냈다면 이 줄도 지운다 (src/map/README.md)
};
