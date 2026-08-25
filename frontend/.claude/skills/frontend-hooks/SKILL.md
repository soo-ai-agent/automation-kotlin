---
name: frontend-hooks
description: 훅 작성 규칙. 단일책임 훅(훅 하나 = 유스케이스 하나)과 조립 훅(소비처별 그룹 반환), 훅의 고정 골격, 3상태(ListState) 노출, 상태를 어디에 둘지 판정표, useEffect 를 쓰기 전 확인 넷을 다룬다. hooks/ 파일을 만들거나 고치거나 리뷰할 때 frontend-common 과 함께 사용한다. "훅 추가", "상태 관리", "useEffect" 요청에도 사용할 것.
---

# 훅 (hooks) — 상태의 유일한 거처, 그리고 조립

## 단일책임 훅

훅 하나 = 유스케이스 하나. 목록 로딩·선택·삭제·상세는 **각각 다른 훅**이다.

```ts
// O — 동봉 frontend/src/user/hooks/useUserList.ts (요지). 로딩 하나만 책임진다
export function useUserList(handleError: ServiceErrorHandler) {
    const [users, setUsers] = useState<User[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [listState, setListState] = useState<ListState>({status: ListStatus.OK, message: ""});

    const loadUserList = useCallback(async (): Promise<void> => {
        setIsLoading(true);
        try {
            const loadedUsers: User[] = await getUserList();           // services 호출
            setUsers(loadedUsers);
            if (loadedUsers.length === 0) {
                setListState({status: ListStatus.EMPTY, message: UserResultMessages.LIST_EMPTY});
            } else {
                setListState({status: ListStatus.OK, message: ""});
            }
        } catch (error) {
            setListState({status: ListStatus.ERROR, message: UserResultMessages.LIST_LOAD_ERROR});
            handleError(error, UserResultMessages.LIST_LOAD_ERROR);    // 공용 에러 핸들러
        } finally {
            setIsLoading(false);
        }
    }, [handleError]);

    return {users, isLoading, listState, loadUserList};
}
```

훅의 고정 골격 — 위 예시의 순서를 지킨다:

1. `useState` 선언 (로딩·데이터·상태 표시)

2. `useCallback` 으로 감싼 액션 함수

3. 액션 안: `setLoading(true)` → `try { services 호출 → setState }` → `catch { 공용 에러 핸들러 }` → `finally { setLoading(false) }`

4. 화면이 쓸 값만 골라 객체로 반환

훅에 두면 안 되는 것: JSX 반환(→ 컴포넌트), 서버 URL·HTTP 상태코드(→ `api`·`services`), 사용자 메시지 리터럴(→ 메시지 enum).
훅은 상태코드를 모른다 — `result.status ===` 가 보이면 `frontend-service` 위반이다.

## 조립 훅 — 소비처별로 묶어 반환

화면이 훅 여러 개를 필요로 하면, **화면이 훅을 여러 개 부르는 게 아니라** 조립 훅 하나가 하위 훅들을 모아
**소비 컴포넌트별로 그룹지어** 반환한다. 동봉 정답: `frontend/src/user/hooks/useUsers.ts`.

```ts
export const useUsers = () => {
    const {users, loading, listState, loadUserList} = useUserList();
    const {selectedIds, clearSelectedIds, toggleSelect} = useUserSelection(users);
    const {deleteOne, deleteSelected} = useUserDelete(selectedIds, loadUsers);

    useEffect(() => {
        void loadUsers();          // 최초 1회 로드. 데이터 로딩용 effect 는 여기에만 존재한다.
    }, [loadUsers]);

    return {
        table:       {users, loading, listState, selectedIds, toggleSelect, deleteOne, deleteSelected},
        detailModal: {/* … */},
    };
};
```

- 반환 객체의 **1단 키 = 그 값을 소비할 컴포넌트 이름**(`table`, `detailModal`, `modalRefs`). 화면이 `table.users` 처럼 쓰면 어느 컴포넌트로 갈 값인지 한눈에 보인다.

- 조립 훅 이름은 `use<화면이름>` 또는 `use<도메인복수>`: `useUsers`.

- 하위 훅 간 의존(삭제 후 재조회 등)은 조립 훅에서 함수를 주입해 연결한다. **하위 훅끼리 직접 import 하지 않는다.**

## 3상태는 하나의 상태 객체로 노출한다

로딩·에러·빈 상태를 훅마다 다른 모양으로 만들면 화면 코드가 제각각이 된다.
**목록·상세를 다루는 훅은 `loading` 플래그와 함께 공용 `ListState`(`common/lib/listState.ts` — `ListStatus.OK/EMPTY/ERROR`) 하나를 노출한다.**

- 빈 상태를 `items.length === 0` 로 화면에서 매번 다시 판정하지 않는다. 훅이 이미 알고 있다.

- `status` 는 닫힌 값 집합이므로 문자열 union 이 아니라 `enum` 이다.

## 상태 배치와 useEffect

| 이 데이터는… | 두는 곳 | 예 |
|---|---|---|
| 서버에서 온 것 | **훅의 `useState` + 로더 함수** | 목록, 상세 |
| 이 화면만의 입력·토글 | **훅의 `useState`** (화면 아님) | 모달 열림, 검색어 |
| 앱 전체가 공유하는 극소수 | Context / 전역 스토어 | 로그인 사용자, 테마 |
| 다른 값에서 계산 가능한 것 | **상태로 만들지 않는다** — 렌더 중 계산 | 총액, 필터된 목록 |

```tsx
// X — 파생값을 상태 + effect 로 동기화. 버그의 온상.
const [totalPrice, setTotalPrice] = useState(0);
useEffect(() => { setTotalPrice(sum(items)); }, [items]);

// O — 그냥 계산한다.
const totalPrice: number = sum(items);
```

**`useEffect` 를 첫 수단으로 쓰지 않는다.** 쓰기 전에 넷을 먼저 확인한다:

1. **다른 값에서 계산되는가?** → 렌더 중 계산.

2. **사용자 행동에 대한 반응인가?** → 이벤트 핸들러 안에서 처리.

3. **최초 1회 데이터 로드인가?** → **조립 훅에 `useEffect(() => { void load() }, [load])` 하나만.** 로더는 반드시 `useCallback` 으로 안정화한다 — 매 렌더 새 함수면 무한 반복된다.

4. **외부 시스템 동기화인가?**(이벤트 리스너, 타이머, 외부 SDK) → 이때만 `useEffect`. cleanup 필수.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 훅의 `result.status ===` 분기 | 상태코드 번역은 services 전담 | Critical |
| 데이터 로딩 `useEffect` 가 조립 훅 밖에 존재 | effect 자리 규칙 위반 | Important |
| 단일책임 훅이 다른 단일책임 훅을 import | 조합은 조립 훅의 일 | Important |
| 파생값을 상태 + effect 로 동기화 | 렌더 중 계산으로 — 동기화 버그의 온상 | Important |
| `useCallback` 없는 로더를 effect 의존성에 | 무한 재호출 | Critical |
| 훅이 JSX 를 반환 | 컴포넌트의 일 | Important |
| 훅마다 다른 모양의 로딩·에러·빈 표현 | 공용 `ListState` 하나로 | Important |

## 체크리스트

- [ ] 훅 하나가 유스케이스 하나만 책임지는가

- [ ] 조립 훅이 소비 컴포넌트별 키로 반환하는가

- [ ] 데이터 로딩 effect 가 조립 훅에 하나뿐이고 로더가 `useCallback` 인가

- [ ] 목록·상세 훅이 공용 `ListState` 를 노출하는가

- [ ] 파생값이 상태가 아니라 렌더 중 계산인가
