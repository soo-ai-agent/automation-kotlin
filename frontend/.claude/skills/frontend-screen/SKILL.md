---
name: frontend-screen
description: 화면(screens)과 컴포넌트·모달 작성 규칙. 페이지 무상태 원칙(훅 1개 호출 + JSX), 자기 표현 상태 예외 셋, 모달 forwardRef 패턴, 전역 확인 팝업(호스트 + Promise), 스타일 파일 분리를 다룬다. screens/·components/ 파일을 만들거나 고치거나 리뷰할 때 frontend-common 과 함께 사용한다. "화면 추가", "컴포넌트", "모달" 요청에도 사용할 것.
---

# 화면·컴포넌트 (screens / components)

## 페이지 무상태 원칙 — 프론트에서 가장 중요한 규칙

이 규칙을 지킨 프로젝트와 아닌 프로젝트를 가르는 결정적 차이가 여기다. 실측 두 프로젝트의 수치로 보면:

| | 지킨 프로젝트 | 규칙 도입 전 프로젝트 |
|---|---|---|
| 페이지 평균 길이 | 45~83줄 | 180~609줄 |
| 페이지의 `useState` 총합 | **0** | **62** |
| 페이지의 `useEffect` 총합 | 2 | 27 |
| 훅 파일 수 | 33 | 6 |

**화면은 상태를 갖지 않는다.** 화면이 하는 일은 딱 셋이다: 훅 1개 호출 → 받은 값을 컴포넌트에 배분 → JSX 반환.

```tsx
// O — 동봉 frontend/src/user/screens/User.tsx (요지). 훅 1개, 상태 0, 나머지는 배분과 JSX 뿐이다
const User = ({navigation}: UserProps) => {
    const {table, modalRefs} = useUsers();   // 훅 1개. 이게 전부다.

    return (
        <SafeAreaView style={styles.container}>
            <UserToolbar selectedCount={table.selectedIds.length} isLoading={table.isLoading}
                reloadUsers={table.reloadUsers} deleteSelected={table.deleteSelected} />
            <UserTable users={table.users} listState={table.listState} selectedIds={table.selectedIds}
                toggleSelect={table.toggleSelect} openDetail={table.openDetail} deleteOne={table.deleteOne} />
            <UserDetailModal ref={modalRefs.detailModalRef} />
        </SafeAreaView>
    );
};

// X — 규칙 도입 전 화면 (실측 262줄, useState 9 · useEffect 3). 전부 훅으로 이동 대상이다
export function RouteComparison() {
    const [routeOptions, setRouteOptions] = useState<RouteOption[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    // … 로드 effect, 취소 처리, 에러 문자열 조립까지 전부 화면 안에
}
```

화면이 50줄을 크게 넘으면 훅 분해가 덜 된 것이다.

판정 기준(리뷰에서 그대로 적용):

- 화면 파일에 `useState`·`useEffect`·`useRef`·`AbortController` 가 있으면 **위반.**

- 화면이 `services/`·`api/` 를 직접 import 하면 **위반**(건너뛰기).

- 화면이 `try/catch` 로 에러 문자열을 조립하면 **위반**(훅의 일).

- 예외는 단 하나: `props` 로 받은 값을 그대로 내려보내는 순수 배분.

컴포넌트는 **props 로 받은 값만 그린다.** 서버 통신·상태코드·업무 규칙이 보이면 훅·서비스로 내린다.

## 좁은 예외 — 자기 표현 상태

**아래 셋을 전부 만족하는 상태만** 컴포넌트 안에 남길 수 있다. 하나라도 어긋나면 훅이다.

1. **밖으로 나가지 않는다.** 그 값을 부모가 읽지 않는다 — props 로도 콜백 인자로도. (`onDone` 같은 단발 신호는 값 전달이 아니다.)

2. **그 자리에서만 알 수 있다.** DOM 이벤트·타이머·애니메이션 단계처럼 부모가 대신 알 수 없는 사실이다.

3. **서버 데이터도 업무 규칙도 아니다.**

통과하는 예: `ConfirmDialogHost` 의 대기 중 요청, 이미지의 `didError`(`onError` 로만 아는 사실), 스플래시 페이드 단계,
외부 SDK 가 만들어 주는 핸들(광고·지도 인스턴스).

통과 못 하는 것 — **그대로 위반이고 훅으로 뺀다**: 데이터 로딩 · 폼 입력값 · 서버 응답 · 다른 컴포넌트와 나눠 쓰는 값 · 화면 전환에 걸리는 값.

애매하면 훅이다. 예외는 좁을수록 쓸모 있다 — 넓히면 "이것도 자기 표현"이라는 말로 화면 상태가 도로 컴포넌트에 쌓인다.

## 모달 — forwardRef + useImperativeHandle

모달은 자기 열림 상태를 스스로 갖고, **부모는 ref 로 연다.** 부모에 `isXxxOpen` 상태를 만들지 않는다.
동봉 전문: `frontend/src/user/components/UserDetailModal.tsx`.

```tsx
export interface UserDetailModalRef {
    openDetail: (id: number) => void;
}

function UserDetailModal(props: Props, ref: Ref<UserDetailModalRef>) {
    const {isOpen, markdown, openDetail, closeDetail} = useUserDetail();

    useImperativeHandle(ref, () => ({openDetail}), [openDetail]);

    return <Modal visible={isOpen} onRequestClose={closeDetail}>{/* … */}</Modal>;
}

export default forwardRef(UserDetailModal);
```

- 모달 상태 훅과 동작 훅을 분리한다. 열고 닫기와 업무 처리는 다른 관심사다.

- 한 화면에 모달이 여럿이면 ref 들을 `useXxxModalRefs` 훅으로 묶고, 조립 훅이 `modalRefs` 키로 반환한다.

- 열기 함수 이름은 `open<행위>`: `openDetail`, `openBlock`. 모달 ref 타입은 `<모달명>Ref`.

## 전역 확인 팝업 — 호스트 + Promise

ref 패턴은 **부모가 아는 모달**에 쓴다. 확인 팝업처럼 **어디서든, 심지어 훅 밖(서비스·비동기 흐름)에서도** 띄워야 하는 것은 부모가 없다 — 그래서 모양이 다르다.

```
호출부 ──▶ notify.confirm(options) ──▶ lib/confirmDialog (모듈 브리지)
                                              │  요청 전달
                     Promise<boolean> ◀── ConfirmDialogHost (앱 루트에 하나) ──▶ ConfirmModal
```

- **브리지(`lib/confirmDialog.ts`)** 는 React 를 모른다. 호스트가 없으면 거부(`false`)로 귀결시킨다 — 팝업이 안 떴는데 삭제가 진행되면 안 된다.

- **호스트(`ConfirmDialogHost`)** 는 앱 루트에 **하나만** 둔다.

- **호출부는 브리지를 직접 부르지 않는다.** `notify.confirm` 만 부른다(`frontend-service` 의 알림 창구).

이 구조 덕에 화면마다 `isConfirmOpen` 상태를 만들 필요가 없고, 서비스·유틸에서도 사용자에게 물어볼 수 있다.

## 스타일

스타일 정의(`StyleSheet.create`·큰 인라인 style)는 컴포넌트 파일에 두지 않고 나란한 `이름.styles.ts` 로 뺀다.
색·간격은 `src/common/lib/theme.ts` 토큰만 쓴다 — 하드코딩 금지.

리스트 key·조건부 렌더링 등 JSX 문법 규칙은 `frontend-style` 이 담당한다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 화면·컴포넌트에 `useState`/`useEffect` | 페이지 무상태 위반 — 자기 표현 상태 예외 셋을 먼저 본다 | Critical |
| 화면이 `services/`·`api/` 를 직접 import | 건너뛰기 — 훅을 통한다 | Critical |
| 화면·훅에 `isConfirmOpen` 류 확인 팝업 상태 | 확인은 `notify.confirm` 이 호스트에서 그린다 | Important |
| 부모 컴포넌트의 `isXxxOpen` 모달 상태 | 모달이 스스로 갖고 ref 로 연다 | Important |
| 컴포넌트 파일 안의 `StyleSheet.create`·색 하드코딩 | 스타일 분리·theme 토큰 위반 | Important |
| 화면의 `try/catch` 에러 문자열 조립 | 훅·서비스의 일 | Important |

## 체크리스트

- [ ] 화면이 훅 1개 호출 + JSX 뿐인가 (`useState` 0개)

- [ ] 컴포넌트에 남은 상태가 자기 표현 상태 예외 셋을 전부 만족하는가

- [ ] 모달이 ref 로 열리고, 확인 팝업은 `notify.confirm` 을 쓰는가

- [ ] 스타일이 `이름.styles.ts` 에 있고 theme 토큰만 쓰는가
