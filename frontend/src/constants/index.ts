/**
 * 사용자에게 보이는 문장의 단일 진입점 — 부르는 쪽은 언제나 `@/constants` 에서 가져온다.
 *
 * 파일은 화면·기능 단위로 나눈다. 한 파일에 몰면 화면이 늘 때마다 같은 파일을 모두가 건드려
 * 머지 충돌이 상습이 되고, 선택 기능을 들어낼 때 남의 문장 사이에서 내 것만 골라내야 한다.
 */
export * from "./common";
export * from "./user";
export * from "./map";
export * from "./ads";
export * from "./splash";
