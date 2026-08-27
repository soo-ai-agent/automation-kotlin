---
name: frontend-screen
description: 화면(src/screens)과 컴포넌트(src/components)의 저장소 고유 규칙. 화면 무상태 원칙(훅 1개 호출 + JSX)과 자기 표현 상태 예외 셋, 화면 폴더 콜로케이션, 모달 forwardRef 패턴, 전역 확인 팝업 호스트 구조를 담는다. 토큰 테마·재사용 컴포넌트 계약·승격 조건은 벤더링된 expo/expo-design-system 이, 네이티브 스타일은 expo/expo-native-ui 가 정본이다. screens/·components/ 파일을 만들거나 고치거나 리뷰할 때 frontend-common 과 함께 사용한다. "화면 추가", "컴포넌트", "모달" 요청에도 사용할 것.
---

# 화면·컴포넌트 (src/screens / src/components)

`src/app` 의 라우트가 그리는 **화면 본체**가 `src/screens/` 에 있고, 여러 화면이 함께 쓰는 UI 가 `src/components/` 에 있다.

**정본이 따로 있는 것들** — 여기 베껴 쓰지 않고 그때 연다.

| 알고 싶은 것 | 여는 문서 |
|---|---|
| 토큰 테마(색·간격·타이포·모서리·그림자·모션), 재사용 컴포넌트 계약(variant·size·state·style), 공용 승격 조건 셋, 디자인 이탈 감사 | [expo/expo-design-system](../expo/expo-design-system/SKILL.md) |
| 네이티브다운 스타일 — 시맨틱 색, 컨트롤, 아이콘, 미디어, 시각 효과 | [expo/expo-native-ui](../expo/expo-native-ui/SKILL.md) |
| `@expo/ui` 네이티브 컴포넌트 | [expo/expo-ui](../expo/expo-ui/SKILL.md) |
| 애니메이션·제스처 | [expo/expo-animation](../expo/expo-animation/SKILL.md) |
| 스타일·테스트 콜로케이션, 플랫폼별 파일 | [expo/expo-project-structure](../expo/expo-project-structure/SKILL.md) |

라우트 쪽 규칙(URL·`_layout`·이동)은 `frontend-route` 가 담당한다.

이 문서는 그 위에 얹는 저장소 규칙만 담는다 — **화면 무상태, 모달, 확인 팝업.**

## 화면 무상태 원칙 — 프론트에서 가장 중요한 규칙

이 규칙을 지킨 프로젝트와 아닌 프로젝트를 가르는 결정적 차이가 여기다. 실측 두 프로젝트의 수치로 보면:

| | 지킨 프로젝트 | 규칙 도입 전 프로젝트 |
|---|---|---|
| 화면 평균 길이 | 45~83줄 | 180~609줄 |
| 화면의 `useState` 총합 | **0** | **62** |
| 화면의 `useEffect` 총합 | 2 | 27 |
| 훅 파일 수 | 33 | 6 |

**화면은 상태를 갖지 않는다.** 화면이 하는 일은 딱 셋이다: **상태 훅 1개** 호출 → 받은 값을 컴포넌트에 배분 → JSX 반환.

"훅 1개"는 **상태를 들고 오는 훅**을 세는 말이다. `useStyles` 처럼 상태 없이 값을 파생하기만 하는 훅은 세지 않는다.

```tsx
// src/screens/user/index.tsx
// O — 상태 훅 1개, 화면 자체의 상태 0, 나머지는 배분과 JSX 뿐이다
export function User() {
    const {table, modalRefs} = useUsers();      // 상태 훅. 화면이 부르는 유일한 하나다
    const {detailModalRef} = modalRefs;         // ref 는 렌더 중 점으로 꺼내지 않는다(react-hooks/refs)
    const styles = useStyles(createStyles);     // 상태 없음 — 색에서 스타일을 파생할 뿐

    return (
        <SafeAreaView style={styles.container}>
            <UserToolbar selectedCount={table.selectedIds.length} isLoading={table.isLoading}
                reloadUsers={table.reloadUsers} deleteSelected={table.deleteSelected} />
            <UserTable users={table.users} listState={table.listState} selectedIds={table.selectedIds}
                toggleSelect={table.toggleSelect} openDetail={table.openDetail} deleteOne={table.deleteOne} />
            <UserDetailModal ref={detailModalRef} />
        </SafeAreaView>
    );
}

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

- 화면이 `utils/` 의 요청 함수를 직접 import 하면 **위반**(건너뛰기).

- 화면이 `try/catch` 로 에러 문자열을 조립하면 **위반**(훅의 일).

- 예외는 단 하나: `props` 로 받은 값을 그대로 내려보내는 순수 배분.

컴포넌트는 **props 로 받은 값만 그린다.** 서버 통신·상태코드·업무 규칙이 보이면 훅·요청 모듈로 내린다.

## 좁은 예외 — 자기 표현 상태

**아래 셋을 전부 만족하는 상태만** 컴포넌트 안에 남길 수 있다. 하나라도 어긋나면 훅이다.

1. **밖으로 나가지 않는다.** 그 값을 부모가 읽지 않는다 — props 로도 콜백 인자로도. (`onDone` 같은 단발 신호는 값 전달이 아니다.)

2. **그 자리에서만 알 수 있다.** DOM 이벤트·타이머·애니메이션 단계처럼 부모가 대신 알 수 없는 사실이다.

3. **서버 데이터도 업무 규칙도 아니다.**

통과하는 예 — 전부 동봉 코드에 있다: `ConfirmDialogHost` 의 대기 중 요청, `AdBanner` 의 `loaded`(SDK 콜백으로만 아는 사실),
이미지의 `didError`, 외부 SDK 가 만들어 주는 핸들.

통과 못 하는 것 — **그대로 위반이고 훅으로 뺀다**: 데이터 로딩 · 폼 입력값 · 서버 응답 · 다른 컴포넌트와 나눠 쓰는 값 · 화면 전환에 걸리는 값.

애매하면 훅이다. 예외는 좁을수록 쓸모 있다 — 넓히면 "이것도 자기 표현"이라는 말로 화면 상태가 도로 컴포넌트에 쌓인다.

## 화면 폴더 — 한 화면만 쓰는 것은 그 안에 둔다

화면이 파일 하나로 끝나면 `screens/settings.tsx` 로 충분하다. 쪼갤 만큼 커지면 폴더로 만든다.

```
src/screens/user/
├── components/          # 이 화면만 쓰는 컴포넌트
│   ├── user-table.tsx
│   └── user-toolbar.tsx
├── hooks/               # 이 화면만 쓰는 훅
│   ├── use-user-list.ts
│   └── use-users.ts
└── index.tsx            # 화면 본체 — src/app/index.tsx 가 그린다
```

**두 번째 화면이 쓰기 전에는 `src/components/`·`src/hooks/` 로 올리지 않는다.**
승격 조건 셋(두 화면 이상 · 이름 붙일 역할 · props 가 구현보다 작음)은 [expo/expo-design-system](../expo/expo-design-system/SKILL.md) 의 "When to extract" 가 정본이다.

미리 올린 공용 컴포넌트는 첫 사용처의 사정을 그대로 물려받아, 두 번째 사용처가 생기면 props 로 뒤덮인다.
잘못 뽑은 추상화가 중복보다 비싸다.

## 공용 컴포넌트의 계약은 Expo 문서가 정본이다

`src/components/` 에 올린 컴포넌트가 받는 props 는 넷으로 정리된다 — variant · size · state · style.
내용을 설명하는 props 가 늘면 `children` 으로 바꾼다. 상세와 근거는
[expo/expo-design-system](../expo/expo-design-system/SKILL.md) 의 "The component contract" 와 "Composition over configuration" 이다.

이 저장소가 더하는 것은 하나다 — **누를 수 있는 요소에 눌림 피드백을 반드시 준다.**
동봉 코드의 `Pressable` 들이 `disabled` 와 흐림 스타일을 함께 다루는 이유다.

## 모달 — forwardRef + useImperativeHandle

URL 로 열려야 하는 모달은 라우트로 만든다(`frontend-route`). **그 밖의 모달은 자기 열림 상태를 스스로 갖고, 부모는 ref 로 연다.**
부모에 `isXxxOpen` 상태를 만들지 않는다.

```tsx
// src/screens/user/components/user-detail-modal.tsx (요지)
export interface UserDetailModalRef {
    openDetail: (id: number) => void;
}

function UserDetailModalBase(_props: UserDetailModalProps, ref: Ref<UserDetailModalRef>) {
    const {handleError} = useServiceErrorHandler();
    const {detailState, openDetail, closeDetail} = useUserDetail(handleError);

    useImperativeHandle(ref, () => ({openDetail}), [openDetail]);

    return (
        <Modal visible={detailState.status !== DetailStatus.CLOSED} onRequestClose={closeDetail}>
            {/* … */}
        </Modal>
    );
}

export const UserDetailModal = forwardRef(UserDetailModalBase);
```

열림·로딩·데이터를 각각 상태로 두지 않고 **판별 union 하나**(`DetailState`)로 표현한다 — "로딩 중인데 데이터도 있음" 같은
모순 조합이 애초에 표현되지 않는다(`frontend-style` 의 판별 union).

- 모달 상태 훅과 동작 훅을 분리한다. 열고 닫기와 업무 처리는 다른 관심사다.

- 한 화면에 모달이 여럿이면 ref 들을 `useXxxModalRefs` 훅으로 묶고, 조립 훅이 `modalRefs` 키로 반환한다.

- 열기 함수 이름은 `open<행위>`: `openDetail`, `openBlock`. 모달 ref 타입은 `<모달명>Ref`.

## 전역 확인 팝업 — 호스트 + Promise

ref 패턴은 **부모가 아는 모달**에 쓴다. 확인 팝업처럼 **어디서든, 심지어 훅 밖(요청 모듈·비동기 흐름)에서도** 띄워야 하는 것은 부모가 없다 — 그래서 모양이 다르다.

```
호출부 ──▶ notify.confirm(options) ──▶ utils/confirm-dialog.ts (모듈 브리지)
                                              │  요청 전달
                     Promise<boolean> ◀── ConfirmDialogHost (앱 루트에 하나) ──▶ ConfirmModal
```

- **브리지(`utils/confirm-dialog.ts`)** 는 React 를 모른다. 호스트가 없으면 거부(`false`)로 귀결시킨다 — 팝업이 안 떴는데 삭제가 진행되면 안 된다.

- **호스트(`ConfirmDialogHost`)** 는 루트 레이아웃(`src/app/_layout.tsx`)에 **하나만** 둔다.

- **호출부는 브리지를 직접 부르지 않는다.** `notify.confirm` 만 부른다(`frontend-api` 의 알림 창구).

이 구조 덕에 화면마다 `isConfirmOpen` 상태를 만들 필요가 없고, 요청 모듈·유틸에서도 사용자에게 물어볼 수 있다.

## 스타일은 파일 맨 아래에, 색은 훅으로

`StyleSheet.create({...})` 를 **컴포넌트 파일 맨 아래**에 둔다. 별도 `.styles.ts` 파일로 빼지 않는다 — 그리는 것과 그 모양은 같이 읽혀야 한다
(`expo-project-structure` 의 "Colocate styles and tests").

**색이 들어가면 `useStyles(createStyles)` 를 쓴다.** `StyleSheet.create` 는 모듈이 읽힐 때 한 번만 도는데
색은 렌더 시점에야(밝게/어둡게) 정해지기 때문이다.

```tsx
export function UserToolbar(props: UserToolbarProps) {
    const styles = useStyles(createStyles);   // 훅 하나. 상태는 없다
    return <View style={styles.toolbar}>{/* … */}</View>;
}

// 파일 맨 아래, 최상위에 둔다 — 렌더마다 새 함수면 스타일 캐시가 매번 빗나간다
const createStyles = (colors: Colors) => StyleSheet.create({
    toolbar: {flexDirection: "row", gap: spacing(2)},
    count: {color: colors.textDim, fontSize: 14},
});
```

- 색이 안 들어가는 스타일은 그냥 최상위 `const styles = StyleSheet.create({...})` 로 둔다.

- `useStyles` 는 **화면 무상태 원칙의 예외가 아니다** — 상태를 갖지 않고 색에서 스타일을 파생할 뿐이다.
  화면이 `useUsers()` 와 `useStyles()` 둘을 부르는 것은 위반이 아니다.

- 색 한 벌만 필요하면 `useColors()` 를 쓴다(`_layout.tsx` 의 `contentStyle` 처럼).

색·간격·타이포는 **이 저장소의 토큰 파일 `src/theme.ts` 하나**만 쓴다. 그 옆에 두 번째 토큰 파일을 만들지 않는다.

토큰을 어떻게 나누고 언제 늘리는지는 [expo/expo-design-system](../expo/expo-design-system/SKILL.md) 이 정본이다. 요지 셋만 옮겨 둔다.

- **두 번 나타나는 시각 값은 토큰이다.** 화면 파일이 여백에 `spacing` 토큰을 쓰는 것은 괜찮고, 버튼 색을 다시 정의하는 것은 이탈이다.

- 토큰 밖 하드코딩은 그 자리에서만 뜻이 있는 값(아이콘 1px 광학 보정 등)에만 허용하고, **왜 그런지 주석을 단다.**

- 이미 디자인 언어를 갖고 있는 플랫폼 컴포넌트(`Switch`·스택 헤더 등)를 토큰을 태우려고 감싸지 않는다.

리스트 key·조건부 렌더링 등 JSX 문법 규칙은 `frontend-style` 이 담당한다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 화면·컴포넌트에 `useState`/`useEffect` | 화면 무상태 위반 — 자기 표현 상태 예외 셋을 먼저 본다 | Critical |
| 화면이 `utils/` 의 요청 함수를 직접 import | 건너뛰기 — 훅을 통한다 | Critical |
| 한 화면만 쓰는 컴포넌트가 `src/components/` 에 | 승격 조건 미달 — 화면 폴더로 | Important |
| 내용을 설명하는 props 가 늘어난 공용 컴포넌트 | `children` 으로 바꾼다 | Important |
| 누를 수 있는데 눌림 피드백이 없다 | 터치 앱에서 반응이 없다 | Important |
| 화면·훅에 `isConfirmOpen` 류 확인 팝업 상태 | 확인은 `notify.confirm` 이 호스트에서 그린다 | Important |
| 부모 컴포넌트의 `isXxxOpen` 모달 상태 | 모달이 스스로 갖고 ref 로 연다 | Important |
| 별도 `.styles.ts` 파일 | 스타일은 컴포넌트 파일 맨 아래 | Important |
| 토큰 없이 하드코딩한 색·간격 | `theme.ts` 토큰만 쓴다 | Important |
| 색이 든 `StyleSheet.create` 를 모듈 최상위에 둠 | 어두운 모드에서 안 바뀐다 — `useStyles(createStyles)` 로 | Critical |
| `createStyles` 를 컴포넌트 안에서 정의 | 렌더마다 스타일을 새로 만든다 — 최상위로 | Important |
| 화면의 `try/catch` 에러 문자열 조립 | 훅·요청 모듈의 일 | Important |

## 체크리스트

- [ ] 화면이 상태 훅 1개 호출 + JSX 뿐인가 (`useState` 0개, `useStyles` 는 세지 않는다)

- [ ] 컴포넌트에 남은 상태가 자기 표현 상태 예외 셋을 전부 만족하는가

- [ ] 한 화면만 쓰는 컴포넌트·훅이 그 화면 폴더 안에 있는가

- [ ] 모달이 ref 로 열리고, 확인 팝업은 `notify.confirm` 을 쓰는가

- [ ] 스타일이 파일 맨 아래에 있고 `theme.ts` 토큰만 쓰는가

- [ ] 색이 든 스타일이 `useStyles(createStyles)` 를 거치는가 (밝게·어둡게 둘 다 따라오는가)
