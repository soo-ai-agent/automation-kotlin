# frontend-react — 장 0~16 전문

SKILL.md 의 Quick Rules 가 요약이고, 여기가 전문이다. 장 번호는 SKILL.md 의 장 구성과 같다.

## 0. 도메인이 최상위, 그 아래가 계층

**도메인이 먼저고 계층이 그 아래다.** 한 도메인의 코드는 한 폴더 안에서 끝나야 한다 — 화면 하나를 고치려고 여섯 폴더를 오가면 구조가 틀린 것이다.

**이 지도에 없는 위치의 코드는 리뷰에서 잡는다.**

```
src/
├── app/                    # 라우팅·전역 스토어·부트스트랩. 어떤 도메인도 아니다
├── <도메인>/               # route · share · place · admin … 도메인 이름이 곧 폴더 이름
│   ├── pages/              # 화면 조립만. 훅 1개 호출 + JSX        (상태 0)  RN 은 screens/
│   ├── components/         # 이 도메인만 쓰는 표현 컴포넌트
│   ├── hooks/              # 화면 상태 + 유스케이스 오케스트레이션  (useState 는 여기에만)
│   ├── services/           # 업무 규칙 + 상태코드 → 결과/에러 번역   (React 금지)
│   ├── api/                # 엔드포인트 1:1 요청 함수 + 경로 상수
│   ├── lib/                # 이 도메인의 순수 로직·파생 계산
│   ├── types/              # 이 도메인의 서버 DTO·Row 타입
│   └── enums/              # 이 도메인의 메시지·결과·구분 enum
└── common/                 # 여러 도메인이 쓰는 것만. 도메인과 나란히 서는 유일한 비도메인 폴더
    ├── components/<종류>/  # ui · layout · map · modal
    └── hooks/ services/ api/ lib/ types/ utils/ enums/ styles/ testing/
```

**최상위에는 도메인과 `app`·`common` 만 둔다.** 공용 계층을 최상위에 흩어 놓으면 `route/`(도메인) 옆에 `hooks/`(계층)가 서서 한 줄에 두 기준이 섞여 보인다.

이름은 `shared` 가 아니라 **`common`** 이다. `share` 도메인이 있는 앱에서 `shared/` 는 한 글자 차이로 헷갈린다.

**공용 안에도 도메인 폴더를 파지 않는다.** `common/` 에서 하위 폴더로 한 번 더 나누는 것은 `components/<종류>/` 뿐이고 나머지는 평면이다.

`common/hooks/route/` 는 위반이다 — route 만 쓰면 `route/hooks/` 로 가야 하고, 여럿이 쓰면 `common/hooks/` 바로 아래다.

### 어느 도메인의 것인지 정하는 법

**쓰는 쪽이 정한다.** 화면을 뿌리로 두고 import 를 거꾸로 따라간다 — 한 도메인만 쓰면 그 도메인이 갖고, 둘 이상이 쓰면 공용 평면에 남는다.

손으로 정정하는 예외는 둘뿐이다.

1. **이름이 도메인을 말하는데 다른 도메인도 쓰는 것** — `shareSession` 은 길안내(route)도 부르지만 공유(share)의 것이다. 소유 도메인으로 보낸다.

2. **이름에 도메인이 없고 플랫폼 API 만 다루는 것** — `wakeLock`·`geo`·`localCache` 는 한 도메인만 써도 공용에 남는다.

   `lib`·`utils` 는 어떤 도메인 단어도 몰라야 한다는 규칙이 이긴다.

### 의존 방향

한 방향이다. **역방향과 건너뛰기를 둘 다 금지한다.**

```
pages ──▶ hooks ──▶ services ──▶ api ──▶ lib
  └────▶ components ──▶ hooks
```

- `services` 는 React 를 import 하지 않는다. `useState`·`useCallback` 이 보이면 위치가 틀렸다.

- `api` 는 업무 규칙을 모른다. 상태코드로 분기하거나 사용자 메시지를 만들면 `services` 로 내린다.

- `lib` 은 어떤 도메인 단어도 모른다. 등장하면 그 도메인의 `services`/`lib` 로 옮긴다.

- 페이지가 `services` 를 직접 부르면 건너뛰기 위반이다. 반드시 훅을 통한다.

**도메인끼리는 같은 계층만 가로지른다.** 관리자 화면이 보호자 화면을 미리보기로 그리는 식(`admin/pages` → `share/pages`)은 된다. 남의 도메인 훅·서비스 안쪽을 파고드는 것은 안 된다 — 필요하면 그 도메인이 밖으로 내주는 것만 쓴다.

### 옮길 때

1. import 는 손으로 고치지 않는다. **이동표(옛 경로 → 새 경로)를 만들어 상대 경로를 다시 계산**한다.

   tsc 의 `TS2307` 을 읽어 이름으로 맞추는 방법도 있지만, 같은 이름이 두 계층에 있으면(`geo` 가 `types`·`lib` 에 각각) 틀린 곳을 가리킨다.

2. **`tsc` 통과가 끝이 아니다.** 부작용 전용 import(`import "./x"`)는 타입 검사를 빠져나간다 — 웹은 `vitest`, RN 은 `expo export` 로 번들까지 돌려야 드러난다.

3. 폴더 이름이 파일명과 겹치면 `onboarding/onboarding/` 같은 중첩이 생긴다. 옮긴 뒤 평탄화한다.

4. 옮긴 뒤 **빈 폴더를 지운다.** 남아 있으면 다음 사람이 그 계층이 아직 산다고 읽는다.

서버 상태 라이브러리(React Query 등)는 **미도입**이다. 서버 데이터는 훅 안의 `useState` + 로더 함수로 관리하고, HTTP 는 중앙 클라이언트를 경유한다.

### 0-2. 파일 이름·확장자·export 규칙

같은 구조를 만들어도 이름이 제각각이면 다른 코드베이스가 된다. **레이어는 파일 이름만 보고 판별되어야 한다.**

| 레이어 | 파일 이름 | 확장자 | export |
|---|---|---|---|
| `pages/` | 화면명 PascalCase — `MemberRecord.tsx` | `.tsx` | **default** (+ 필요 시 named 병행) |
| `components/` | 컴포넌트명 PascalCase — `MemberRecordTable.tsx` | `.tsx` | **default** |
| `hooks/` | 훅명 그대로 — `useMemberRecordList.ts` | `.ts` | **named** |
| `services/` | 하는 일 camelCase — `userService.ts`, `routeCompare.ts` | `.ts` | **named** |
| `api/` | 부르는 자원 — `user.ts`, `routes.ts` | `.ts` | **named** |
| `lib/` | 역할명 camelCase — `apiClient.ts`, `notify.ts` | `.ts` | **named** |
| `types/` | 담는 것 — `user.ts`, `route.ts` | `.ts` | **named** |

**폴더가 이미 도메인을 말하므로 파일 이름에 도메인을 되풀이하지 않는다.** `route/services/routeService.ts` 는 `route` 를 세 번 말한다.

- **JSX 를 포함하지 않는 파일은 반드시 `.ts`.** 레퍼런스의 `api/member.tsx` 는 JSX 가 없는데 `.tsx` 인 실수다(13장). 따라 하지 않는다.

- **화면(pages·components)만 default export, 나머지 레이어는 전부 named export.** 레퍼런스에서 hooks·services·api·lib 의 `export default` 는 **0건**이다.

  named 로 통일해야 자동완성·일괄 치환이 듣는다.

- 한 파일에 하나의 주역만 둔다. 서비스 파일의 메시지 enum·결과 enum 은 그 서비스의 일부이므로 같은 파일에 둔다.

- 파일 이름과 그 안의 주역 이름은 **정확히 같은 철자**여야 한다. `useMemberRecordList.ts` 안의 훅은 `useMemberRecordList` 다. 다르면 검색이 끊긴다.

**스타일 파일은 만들지 않는다(웹).** 부엉이 웹은 Tailwind 유틸리티 클래스를 JSX 에 직접 쓴다. `UserTable.css` 같은 **컴포넌트별 CSS 파일을 새로 만들지 않는다.**

전역 토큰·폰트·리셋만 `src/styles/` 에 있고, 그 목록은 이미 고정돼 있다. 색·간격은 기존 토큰만 쓴다(CLAUDE.md 6절 "틀 준수").

React Native(`mobile/`)는 예외로 `Foo.tsx` → `Foo.styles.ts` 분리 규칙을 따른다.

## 1. 페이지 무상태 원칙 — 이 문서에서 가장 중요한 규칙

레퍼런스와 부엉이를 가르는 결정적 차이가 여기다. 수치로 보면:

| | 레퍼런스 | 부엉이 현행 |
|---|---|---|
| 페이지 평균 길이 | 45~83줄 | 180~609줄 |
| 페이지의 `useState` 총합 | **0** | **62** |
| 페이지의 `useEffect` 총합 | 2 | 27 |
| 훅 파일 수 | 33 | 6 |

**페이지는 상태를 갖지 않는다.** 페이지가 하는 일은 딱 셋이다: 훅 1개 호출 → 받은 값을 컴포넌트에 배분 → JSX 반환.

```tsx
// O — 실제 운영 프로젝트의 페이지 (전문, 45줄).  동봉 대응: frontend/src/pages/user/User.tsx
const MemberRecords = ({toggleSidebar}: ContentProps) => {
    const {table, detailModal} = useMemberRecords();   // 훅 1개. 이게 전부다.

    return (
        <main className="d-block col ps-2 pt-3 border-0 min-vh-100">
            <Navbar toggleSidebar={toggleSidebar} />

            <article className="blueshift_main" id="wrapper">
                <MemberRecordTable
                    records={table.records}
                    loading={table.loading}
                    listState={table.listState}
                    selectedIds={table.selectedIds}
                    toggleSelect={table.toggleSelect}
                    openDetailModal={table.openDetailModal}
                    deleteOne={table.deleteOne}
                    deleteSelected={table.deleteSelected}
                />
            </article>

            <MemberRecordDetailModal
                isOpen={detailModal.isOpen}
                markdown={detailModal.markdown}
                onClose={detailModal.closeDetailModal}
                onDelete={detailModal.deleteOne}
            />
        </main>
    );
};
```

```tsx
// X — 부엉이 src/pages/RouteComparison.tsx (262줄, useState 9 · useEffect 3)
export function RouteComparison() {
  const [routeOptions, setRouteOptions] = useState<RouteOption[]>([]);
  const [routeOptionsLoading, setRouteOptionsLoading] = useState(false);
  const [routeOptionsError, setRouteOptionsError] = useState<string | null>(null);
  const [previewFacilities, setPreviewFacilities] = useState<FacilitiesResponse | null>(null);
  const [directMarkersByType, setDirectMarkersByType] = useState<…>({});
  const [routeReloadNonce, setRouteReloadNonce] = useState(0);
  const [mapBottomInset, setMapBottomInset] = useState(0);
  // … 로드 effect, 취소 처리, 에러 문자열 조립까지 전부 페이지 안에
}
// → route/hooks/useRouteComparison.ts 로 상태 전량 이동.
//   페이지에는 const {map, sheet, routes} = useRouteComparison() 만 남는다.
```

판정 기준(리뷰에서 그대로 적용):

- 페이지 파일에 `useState`·`useEffect`·`useRef`·`AbortController` 가 있으면 **위반**.

- 페이지가 `services/`·`api/` 를 직접 import 하면 **위반**(건너뛰기).

- 페이지가 `try/catch` 로 에러 문자열을 조립하면 **위반**(훅의 일).

- 예외는 단 하나: `props` 로 받은 값을 그대로 내려보내는 순수 배분.

### 1-1. 좁은 예외 — 자기 표현 상태

**아래 셋을 전부 만족하는 상태만** 컴포넌트 안에 남길 수 있다. 하나라도 어긋나면 훅이다.

1. **밖으로 나가지 않는다.** 그 값을 부모가 읽지 않는다 — props 로도 콜백 인자로도. (`onDone` 처럼 끝났다는 단발 신호는 값 전달이 아니다.)

2. **그 자리에서만 알 수 있다.** DOM 이벤트·타이머·애니메이션 단계처럼 부모가 대신 알 수 없는 사실이다.

3. **서버 데이터도 업무 규칙도 아니다.**

통과하는 것(부엉이에서 실제로 판정한 전부):

| 무엇 | 왜 통과하나 |
|---|---|
| `ImageWithFallback` 의 `didError` | img `onError` 로만 알 수 있는 사실. 부모는 알 방법이 없다 |
| `SplashScreen` 의 페이드 단계 | 자기 소멸 타이머. 부모는 끝났다는 신호(`onDone`)만 받는다 |
| `Layout` 의 `splashVisible` | 앱 셸 자신의 표시 단계. 화면 상태가 아니다 |
| `BottomSheet` 의 열릴 때 높이 되돌리기 | 상태는 `useDraggableSheet` 에 있고 여기는 배선 한 줄 |
| `NativeAdCard` (웹) | 상태 없이 노출 1회 기록 effect 만 |
| `NativeAdCard` (모바일)의 `nativeAd` | 광고 SDK 만 만들 수 있는 핸들. 우리 서버 데이터가 아니고 밖으로 안 나간다 |

통과 못 하는 것 — **그대로 위반이고 훅으로 뺀다**: 데이터 로딩 · 폼 입력값 · 서버 응답 · 다른 컴포넌트와 나눠 쓰는 값 · 화면 전환에 걸리는 값.

애매하면 훅이다. 예외는 좁을수록 쓸모 있다 — 넓히면 "이것도 자기 표현"이라는 말로 화면 상태가 도로 컴포넌트에 쌓인다.

## 2. hooks — 상태의 유일한 거처, 그리고 조립

### 2-1. 단일책임 훅

훅 하나 = 유스케이스 하나. 목록 로딩·선택·삭제·상세는 **각각 다른 훅**이다.

```ts
// O — 로딩 하나만 책임지는 훅.  동봉 대응: frontend/src/hooks/useUserList.ts
export function useMemberRecordList(handleAuthRequired: AuthRequiredHandler) {
    const [records, setRecords] = useState<MemberRecord[]>([]);
    const [loading, setLoading] = useState(false);
    const [listState, setListState] = useState<ListState>({status: "ok", message: "Ready", fromNotFound: false});

    const loadRecordList = useCallback(async () => {
        setLoading(true);
        try {
            const res = await getMemberRecordList();          // services 호출
            setRecords(res);
            setListState({
                status: res.length === 0 ? "warn" : "ok",
                message: res.length === 0 ? "조회 성공 (데이터 없음)" : "조회 성공",
                fromNotFound: false,
            });
        } catch (err) {
            if (await handleAuthRequired(err)) {
                return;                                        // 401 은 공용 경로가 처리
            }
            console.error(err);
            setListState({status: "error", message: "목록 조회 실패", fromNotFound: false});
            await notify.error(MemberRecordResultMessages.LIST_LOAD_ERROR);   // 메시지는 enum
        } finally {
            setLoading(false);
        }
    }, [handleAuthRequired]);

    return {records, loading, listState, loadRecordList};
}
```

훅의 고정 골격 — 이 순서를 지킨다:

1. `useState` 선언 (로딩·데이터·에러/상태 표시)

2. `useCallback` 으로 감싼 액션 함수

3. 액션 안: `setLoading(true)` → `try { services 호출 → setState }` → `catch { 401 위임 → 로그 → notify }` → `finally { setLoading(false) }`

4. 화면이 쓸 값만 골라 객체로 반환

### 2-2. 조립 훅 — 소비처별로 묶어 반환

화면이 훅 여러 개를 필요로 하면, **페이지가 훅을 여러 개 부르는 게 아니라** 조립 훅 하나가 하위 훅들을 모아 **소비 컴포넌트별로 그룹지어** 반환한다.

```ts
// O — 조립 훅.  동봉 대응: frontend/src/hooks/useUsers.ts
export const useMemberRecords = () => {
    const {checkAuth} = useAuthRequired();
    const {records, loading, listState, loadRecordList} = useMemberRecordList(checkAuth);
    const {selectedIds, clearSelectedIds, toggleSelect, allSelected, toggleSelectAll} = useMemberRecordSelection(records);
    const {isOpen, isLoading, selectedId, markdown, openDetailModal, closeDetailModal} = useMemberRecordDetail(checkAuth);

    const loadRecords = useCallback(async () => {
        await loadRecordList();
        clearSelectedIds();
    }, [loadRecordList, clearSelectedIds]);

    const {deleteOne, deleteSelected} = useMemberRecordDelete(selectedIds, loadRecords, checkAuth);

    useEffect(() => {
        void loadRecords();                    // 최초 1회 로드. 데이터 로딩용 effect 는 여기에만 존재한다.
    }, [loadRecords]);

    return {
        table:       {records, loading, listState, selectedIds, toggleSelect, allSelected,
                      toggleSelectAll, openDetailModal, loadRecords, deleteOne, deleteSelected},
        detailModal: {isOpen, isLoading, selectedId, markdown, closeDetailModal, deleteOne},
    };
};
```

- 반환 객체의 **1단 키 = 그 값을 소비할 컴포넌트 이름**(`table`, `detailModal`, `modalRefs`, `actions`). 페이지가 `table.records` 처럼 쓰면 어느 컴포넌트로 갈 값인지 한눈에 보인다.

- 조립 훅 이름은 `use<화면이름>` 또는 `use<도메인복수>`: `useMemberRecords`, `useAdminsTabPage`.

- 하위 훅 간 의존(삭제 후 재조회 등)은 조립 훅에서 함수를 주입해 연결한다. 하위 훅끼리 직접 import 하지 않는다.

### 2-3. 훅에 두면 안 되는 것

- JSX 반환 → 컴포넌트로 내린다.

- 서버 URL·HTTP 상태코드 → 각각 `api/`·`services/` 로 내린다.

- 사용자 메시지 리터럴 → `enum` 으로 올린다.

### 2-4. 3상태는 하나의 상태 객체로 노출한다

CLAUDE.md 6절이 요구하는 로딩·에러·빈 상태를 훅마다 다른 모양으로 만들면 화면 코드가 제각각이 된다. **목록/상세를 다루는 훅은 `loading` 플래그와 함께 상태 객체 하나를 노출한다.**

```ts
// O — 동봉 frontend/src/lib/listState.ts (전문)
export enum ListStatus {
    OK = "OK",
    EMPTY = "EMPTY",
    ERROR = "ERROR",
}

export type ListState = {
    status: ListStatus;
    message: string;   // 화면에 그대로 띄울 문장. 정상 목록일 때는 빈 문자열.
};
```

```ts
// O — 동봉 frontend/src/hooks/useUserList.ts 에서 상태를 세팅하는 부분
if (loadedUsers.length === 0) {
    setListState({status: ListStatus.EMPTY, message: UserResultMessages.LIST_EMPTY});
} else {
    setListState({status: ListStatus.OK, message: ""});
}
```

- 빈 상태를 `notices.length === 0` 로 화면에서 매번 다시 판정하지 않는다. 훅이 이미 알고 있다.

- `status` 는 닫힌 값 집합이므로 문자열 union 이 아니라 `enum` 이다(Quick Rules).

- 부엉이에는 이미 같은 역할의 `AdminResourceStatus`(`'loading' | 'error' | 'ready'`)가 있다. **새 타입을 만들지 말고 이것을 enum 으로 승격해 재사용한다.**

## 3. services — 업무 규칙과 결과 번역

서비스는 **React 를 모르는 순수 TS 모듈**이다. 하는 일은 둘: ① `api/` 호출, ② 그 결과(상태코드·본문)를 **도메인 결과 또는 ServiceError 로 번역**.

```ts
// O — 상태코드를 번역하는 서비스.  동봉 대응: frontend/src/services/userService.ts
export enum BlockAdminResultMessages {
    SUCCESS         = "차단되었습니다. (활성 세션도 즉시 폐기됩니다)",
    SESSION_EXPIRED = "세션이 만료되었습니다.",
    FORBIDDEN       = "슈퍼 관리자만 접근할 수 있습니다.",
    NOT_FOUND       = "차단할 관리자를 찾을 수 없습니다.",
    ALREADY         = "이미 차단된 관리자입니다.",
    FAILED          = "차단에 실패했습니다.",
}

export async function blockAdminAccount(adminId: number, reason: string): Promise<void> {
    const result: ApiResult<void> = await admin.blacklist.add(adminId, {reason});

    if (result.ok) {
        return;
    }
    if (result.status === 401) {
        throw new ServiceError(BlockAdminResultMessages.SESSION_EXPIRED, 401, ErrorLevel.WARNING);
    }
    if (result.status === 403) {
        throw new ServiceError(BlockAdminResultMessages.FORBIDDEN, 403, ErrorLevel.WARNING);
    }
    if (result.status === 404) {
        throw new ServiceError(BlockAdminResultMessages.NOT_FOUND, 404, ErrorLevel.WARNING);
    }
    if (result.status === 409) {
        throw new ServiceError(BlockAdminResultMessages.ALREADY, 409, ErrorLevel.WARNING);
    }
    throw new ServiceError(BlockAdminResultMessages.FAILED, result.status, ErrorLevel.ERROR);
}
```

- **상태코드가 등장해도 되는 유일한 레이어**가 서비스다. 훅·컴포넌트에 `status === 404` 가 보이면 위반.

- 분기는 `if` 나열 + early return/throw. `switch` 중첩이나 삼항 사슬로 접지 않는다(`common/docs/code-review/rules.md` SHOULD "읽기 쉬운 분기").

- 서비스 함수는 **최상위 `export function`** 으로 쓴다(`api`·`lib` 의 객체 네임스페이스와 대비돼 레이어가 눈에 띈다).

- 서버 DTO → 화면 모델 정규화(선택 필드를 빈 문자열·빈 배열·0 으로)도 이 레이어에서 한 번만 한다(CLAUDE.md 6절).

## 4. api — 엔드포인트 1:1

경로 상수 + 요청 함수. **그 이상 아무것도 하지 않는다.**

```ts
// O — api 계층 전문.  동봉 대응: frontend/src/api/user.ts
const MEMBER_RECORDS = "/api/v1/member-records";

export const member = {
    list(): Promise<ApiResult<MemberRecord[]>> {
        return apiClient.get<MemberRecord[]>({path: MEMBER_RECORDS});
    },

    getMarkdown(id: number): Promise<ApiResult<MemberRecordMarkdown>> {
        return apiClient.get<MemberRecordMarkdown>({path: `${MEMBER_RECORDS}/markdown/${id}`});
    },

    delete(id: number) {
        return apiClient.delete<void>({path: `${MEMBER_RECORDS}/${id}`});
    },

    deleteBulk(ids: number[]) {
        return apiClient.deleteWithBody<void>({path: `${MEMBER_RECORDS}/bulk-delete`, body: {ids}});
    }
};
```

- 도메인당 파일 1개, `export const <도메인> = {...}` 객체 네임스페이스. 호출부는 `member.list()` 로 읽힌다.

- 경로는 파일 상단 상수로 한 번만 쓴다. 함수마다 문자열을 반복하지 않는다.

- 요청 함수에 **반환 타입을 명시**한다. 추론에 맡기면 `undefined` 가 섞여 들어온다.

- 여기서 금지: 상태코드 분기, 사용자 메시지, `notify`, 리다이렉트, 업무 계산.

## 5. lib — 인프라 단일 창구

HTTP 클라이언트는 **앱에 하나**다. 인증 헤더·CSRF·baseURL·공통 에러 매핑을 여기서만 설정한다.

**전문은 동봉 `frontend/src/lib/apiClient.ts` 에 있다. 그 파일을 복사해 쓴다.** 핵심 두 가지만 옮기면:

```ts
// 1) 비2xx 도 예외로 던지지 않고 상태코드를 그대로 넘긴다 — 판정은 services 의 몫이다.
const axiosClient: AxiosInstance = axios.create({
    withCredentials: true,
    validateStatus: () => true,
    headers: {Accept: "application/json"},
});

// 2) 공통 응답 래퍼를 여기서 한 번 벗겨 낸다. 화면은 래퍼를 모른다.
/**
 * 성공했을 때만 data 가 존재한다. `result.ok` 를 확인하면 data 는 T 로 확정되므로
 * 호출부에 null 검사가 필요 없다. "성공인데 데이터가 없는" 모순 상태를 타입이 막는다.
 */
export type ApiResult<T> =
    | {ok: true; status: number; data: T}
    | {ok: false; status: number};

export const apiClient = {
    get<T>({path}: ApiClientOptions): Promise<ApiResult<T>> {
        return send<T>(HttpMethod.GET, path);
    },
    // post·delete 도 같은 모양
};
```

- 인자는 **이름 있는 객체**(`{path, body}`)로 받는다. 위치 인자 `get(path, body, config)` 는 호출부에서 안 읽힌다.

- 인증 헤더·CSRF·baseURL 이 필요하면 `send()` 안에 한 번만 더한다. 호출부는 영향받지 않는다.

- 부엉이에서는 `src/utils/httpClient.ts` 가 이 자리다. **새 클라이언트를 만들지 않는다.** 테스트는 `createHttpClient({adapter})` 로 목 인스턴스를 주입한다(`src/testing/mockHttpClient.ts`).

## 6. 사용자 메시지는 enum 으로 모은다

문자열 리터럴을 호출부에 흩뿌리지 않는다. **서비스 파일 상단에 메시지 enum 을 선언**하고, 훅·컴포넌트는 그 멤버만 참조한다.

```ts
// O — 메시지 enum.  동봉 대응: frontend/src/services/userService.ts
export enum MemberRecordResultMessages {
    DELETE_SUCCESS             = "삭제되었습니다.",
    DELETE_ALREADY_MISSING     = "이미 삭제되었거나 존재하지 않는 레코드입니다.",
    DELETE_ERROR               = "삭제 중 오류가 발생했습니다.",
    BULK_DELETE_NO_SELECTION   = "선택된 레코드가 없습니다.",
    LIST_LOAD_ERROR            = "멤버 레코드 목록을 불러오지 못했습니다.",
}
```

```ts
// X — 부엉이 현행: 같은 성격의 문장이 페이지마다 인라인으로 흩어져 있다
const logs = useAdminResource(loadLogs, EMPTY_LOGS, '요청 로그를 불러오지 못했어요.');
setErrorMessage(error instanceof ApiError ? error.userMessage : '접속 내역을 불러오지 못했어요.');
```

- 이름은 `<도메인><용도>Messages`: `MemberRecordResultMessages`, `LoginResultMessages`, `MemberRecordDetailMessages`.

- 멤버는 `UPPER_SNAKE_CASE`, 값은 완성된 한국어 문장(마침표 포함).

- 부엉이 현행 `export enum` 은 **0건**이다. 신규 코드부터 이 규칙을 적용하고, 손대는 파일은 함께 정리한다.

## 7. 결과 enum vs ServiceError — 2분법

호출 결과를 **불리언이나 `null` 로 돌려주지 않는다.** 두 갈래 중 하나로 표현한다.

| 상황 | 표현 | 호출부 처리 |
|---|---|---|
| 예상된 비정상 (이미 삭제됨, 대상 없음 …) | **결과 enum 반환** | `if (outcome === X)` 로 분기, 안내 메시지 |
| 진짜 실패 (권한 없음, 서버 오류 …) | **`ServiceError` throw** | `catch` 에서 공용 핸들러 |

```ts
// O — 레퍼런스: 404 는 "실패"가 아니라 "이미 없음"이라는 결과다
export enum DeleteRecordOutcome {
    SUCCESS         = "SUCCESS",
    ALREADY_MISSING = "ALREADY_MISSING",
}

export async function deleteMemberRecord(id: number): Promise<DeleteRecordOutcome> {
    const res: ApiResult<void> = await member.delete(id);

    if (res.status === 404) {
        return DeleteRecordOutcome.ALREADY_MISSING;
    }
    if (!res.ok) {
        throw new ServiceError(MemberRecordResultMessages.DELETE_ERROR, res.status, ErrorLevel.ERROR);
    }
    return DeleteRecordOutcome.SUCCESS;
}
```

`ServiceError` 는 **표시 수준(level)** 을 함께 들고 다닌다. 이것이 알림 종류를 결정한다.

```ts
// O — 동봉 frontend/src/services/ServiceError.ts (전문)
export enum ErrorLevel {
    WARNING = "WARNING",
    ERROR = "ERROR",
}

export class ServiceError extends Error {
    constructor(
        message: string,
        readonly status: number,
        readonly level: ErrorLevel = ErrorLevel.ERROR,
    ) {
        super(message);
        this.name = "ServiceError";
    }
}
```

```ts
// O — 동봉 frontend/src/services/serviceErrorHandler.ts (전문). catch 는 이 한 함수로 수렴한다.
export enum SessionResultMessages {
    EXPIRED = "세션이 만료되었습니다. 다시 로그인해 주세요.",
}

export function handleServiceError(
    error: unknown,
    handleSessionExpired: () => void,
    fallbackMessage: string,
): void {
    if (!(error instanceof ServiceError)) {
        console.error(fallbackMessage, error);
        notify.error(fallbackMessage);
        return;
    }
    if (error.status === 401) {
        handleSessionExpired();
        return;
    }
    if (error.level === ErrorLevel.WARNING) {
        notify.warning(error.message);
        return;
    }
    notify.error(error.message);
}
```

**공용 에러 핸들러는 두 파일로 나눈다.** 한쪽에 몰면 서비스 규칙이 React 에 묶인다.

| 파일 | 역할 | React |
|---|---|---|
| `services/serviceErrorHandler.ts` | 판정 전부 — 401 위임 / `level` 별 알림 / 폴백 로깅. 세션 만료 처리는 **콜백으로 주입받는다** | 금지 |
| `hooks/useServiceErrorHandler.ts` | 얇은 래퍼 — 리다이렉트 같은 React 의존 동작을 콜백으로 넘기고 `useCallback` 으로 안정화 | 허용 |

401 은 이 경로 하나로만 처리한다. 개별 훅이 각자 로그인 페이지로 보내면 안 된다.

부엉이에는 이미 `ApiError`(`src/utils/apiError.ts`, `userMessage` 보유)가 있다. **새 에러 클래스를 만들지 말고** `ApiError` 에 이 역할을 맡긴다.

`level` 개념이 필요하면 `ApiError` 에 필드를 더한다.

## 8. 알림은 단일 창구

```ts
// O — 동봉 frontend/src/lib/notify.ts (전문). 알림 UI 를 아는 유일한 파일이다.
export const notify = {
    success(message: string): void {
        window.alert(message);
    },

    warning(message: string): void {
        window.alert(message);
    },

    error(message: string): void {
        window.alert(message);
    },

    confirm(message: string): boolean {
        return window.confirm(message);
    },
};
```

`window.alert` 은 **자리표시자**다. 프로젝트의 토스트·모달로 바꿀 때 고치는 파일은 이 하나뿐이다. 호출부는 한 줄도 손대지 않는다 — 그것이 이 창구를 두는 이유다.

- 확인 대화상자도 이 창구를 지난다: `if (!notify.confirm(UserResultMessages.DELETE_CONFIRM)) { return; }`

- 컴포넌트·훅이 알림 라이브러리를 직접 import 하면 위반. 알림 UI 교체가 한 파일 수정으로 끝나야 한다.

- 부엉이는 토스트를 쓴다. `src/utils/notify.ts` 를 만들어 **토스트 호출을 이 창구 뒤로 숨긴다.**

## 9. 모달 — forwardRef + useImperativeHandle

모달은 자기 열림 상태를 스스로 갖고, **부모는 ref 로 연다.** 부모에 `isXxxOpen` 상태를 만들지 않는다.

```tsx
// O — 모달 ref 패턴 (요지).  동봉 전문: frontend/src/components/modal/UserDetailModal.tsx
export interface BlockAdminModalRef {
    openBlock: (row: AdminRow) => void;
}

function BlockAdminModal({isSuperAdmin, myAdminId, loadAdmins, loadBlacklist}: Props, ref: Ref<BlockAdminModalRef>) {
    const {isOpen, selectedAdmin, reason, setReason, openBlock, closeBlock} = useBlockAdminModal();
    const {isBlocking, blockAdmin} = useBlockAdmin({isSuperAdmin, myAdminId, loadAdmins, loadBlacklist});

    useImperativeHandle(ref, () => ({openBlock}), [openBlock]);

    return (
        <Modal show={isOpen} onHide={closeBlock} centered>
            {/* … */}
        </Modal>
    );
}

export default forwardRef(BlockAdminModal);
```

- 모달 상태 훅(`useBlockAdminModal`)과 동작 훅(`useBlockAdmin`)을 분리한다. 열고 닫기와 업무 처리는 다른 관심사다.

- 한 화면에 모달이 여럿이면 ref 들을 `useXxxModalRefs` 훅으로 묶고, 조립 훅이 `modalRefs` 키로 반환한다.

- 열기 함수 이름은 `open<행위>`: `openBlock`, `openSessions`, `openAuthLogs`.

## 10. 상태 배치와 useEffect

| 이 데이터는… | 두는 곳 | 예 |
|---|---|---|
| 서버에서 온 것 | **훅의 `useState` + 로더 함수** | 목록, 상세 |
| 이 화면만의 입력·토글 | **훅의 `useState`** (페이지 아님) | 모달 열림, 검색어 |
| 앱 전체가 공유하는 극소수 | Context / 전역 스토어 | 로그인 사용자, 테마 |
| 다른 값에서 계산 가능한 것 | **상태로 만들지 않는다** — 렌더 중 계산 | 총액, 필터된 목록 |

```tsx
// X — 파생값을 상태 + effect 로 동기화. 버그의 온상.
const [totalPrice, setTotalPrice] = useState(0)
useEffect(() => {
  setTotalPrice(items.reduce((sum, item) => sum + item.price, 0))
}, [items])

// O — 그냥 계산한다.
const totalPrice = items.reduce((sum, item) => sum + item.price, 0)
```

`useEffect` 를 쓰기 전에 넷을 먼저 확인한다:

1. **다른 값에서 계산되는가?** → 렌더 중 계산.

2. **사용자 행동에 대한 반응인가?** → 이벤트 핸들러 안에서 처리.

3. **최초 1회 데이터 로드인가?** → **조립 훅에 `useEffect(() => { void load() }, [load])` 하나만.** 로더는 반드시 `useCallback` 으로 안정화한다. 매 렌더 새 함수면 무한 반복된다.

4. **외부 시스템 동기화인가?**(이벤트 리스너, 타이머, 외부 지도 SDK) → 이때만 `useEffect`. cleanup 필수.

## 11. 타입 규칙

- `any` 금지. `unknown` 도 최소화 — 모양을 정말 보장할 수 없는 자리(catch 예외, 직렬화 경계)에서만 쓰고, "왜 모를 수밖에 없는지" 주석을 달아 경계에서 즉시 좁힌다.

  동봉 `apiClient.ts` 의 `body: unknown` 주석이 표준 예다.

- **지역 변수에도 타입을 적는다.** 레퍼런스 전반의 관례이자 `common/docs/code-review/rules.md` MUST "명확한 타입 선언"이다.

  ```ts
  const res: ApiResult<void> = await member.delete(id);
  const accessToken: string | null = authStorage.getAccessToken();
  const csrfToken: string | undefined = Cookies.get("csrf_token");
  ```

- **DTO 는 서버 필드명을 그대로 쓴다.** `user_id`, `is_superuser`, `created_at` 을 camelCase 로 바꾸지 않는다. 계약서와 눈으로 대조되어야 한다. 화면용 이름이 필요하면 `services` 에서 화면 모델로 변환한다.

- **`?` 와 `| null` 을 구분한다.** `?` 는 "필드 자체가 안 올 수 있다", `| null` 은 "필드는 오지만 값이 빌 수 있다"는 뜻이다.

  서버 계약이 항상 보내는 필드에 습관적 `?` 를 붙이지 않는다 — undefined 분기가 온 화면에 퍼진다.

- **`x?: T | null` 은 두 없음이 정말 다른 뜻일 때만 쓴다.** 같은 뜻이면 규칙 위반이라 하나로 모은다(`coding-style.md` MUST).

  판정은 하나 — **"안 넘김"과 "null" 이 서로 다른 일을 시키는가.** 갈라 보면 대개 셋 중 하나다.

  | 상황 | 어떻게 |
  |---|---|
  | 화면 props 에서 둘 다 "없음" | `?` 만. store 의 `\| null` 은 호출부에서 `?? undefined` 로 한 번 정규화 |
  | 서버가 필드를 늘 보내고 값만 빈다 | `\| null` 만. `?` 는 거짓말이다 — **응답 DTO 코드를 열어 확인**한다 |
  | 주입점에서 "안 넘김=기본값", "null=그 API 가 없음" | 3상태라 합칠 수 없다. **둘의 뜻이 다르다고 주석에 적는다** |

  등록·조회를 겸하는 타입처럼 한쪽은 필드를 안 싣고 다른 쪽은 null 을 주는 경우도 남긴다 — 역시 그 사실을 주석에 적는다.

### 11-1. `?` 를 쓸 거면 왜 없을 수 있는지 적는다 (MUST)

`?` 만 봐서는 **"안 올 수 있는 값"인지 "안 줘도 되는 값"인지** 읽는 사람이 구분할 수 없다. 선언마다 이유를 한 줄로 남긴다.

**사유를 못 적겠으면 `?` 를 지우라는 뜻이다.** 기본값·빈 배열·전용 타입으로 바꾼다.

실제로 쓸 만한 이유는 네 갈래뿐이다. 이 넷에 안 들어가면 대개 습관적 `?` 다.

| 갈래 | 예 |
|---|---|
| 외부 규격이 그렇다 | `// 카카오 SDK 규격 — 생략하면 SDK 기본 결과 개수.` |
| 원천 데이터가 비어 온다 | `// 원천에 이름·주소가 없는 점이 있다.` |
| 주입점·기본값이다 | `// 주입점 — 생략하면 중앙 httpClient 를 쓴다.` |
| 화면마다 넘기는 게 다르다 | `// 목적지를 아직 안 고른 화면(홈)에서는 없다.` |

**사유는 필드마다 그 자리에 적는다.** 묶음 위에 한 줄로 몰아 적으면 어느 필드 이야기인지 흐려진다(`coding-style.md` MUST — 이 규칙이 "되풀이 주석 금지"보다 우선한다).

문장은 `<언제> 없음` 꼴로 끝내, 어떤 상황에서 값이 없는지가 바로 읽히게 한다.

```ts
// O — 필드마다 언제 없는지가 다르고, 그 차이가 그 자리에 적혀 있다
export interface MapMarker extends LatLng {
  type: MapMarkerType;
  purpose?: string;     // 설치목적을 주는 원천이 CCTV 뿐이라 그 밖의 마커에는 없음
  cameraCount?: number; // 카메라 대수를 주는 원천이 CCTV 뿐이라 그 밖의 마커에는 없음
  phone?: string;       // 전화로 도움을 청할 수 있는 시설이 아니면 없음
}

// X — 묶음 위 한 줄. 어느 필드가 왜 없는지 흐려진다
export interface MapMarker extends LatLng {
  // 출발·도착 마커는 이 정보가 전부 없다.
  purpose?: string;
  cameraCount?: number;
  phone?: string;
}

// X — 이유가 아니라 이름을 되풀이한다
/** 소요 ms. */
durationMs?: number;
```

같은 문장이 여러 줄 반복되면 주석을 줄일 게 아니라 **`?` 를 줄일 자리**다 — 정말 같은 조건에서 함께 비는 값이면 한 덩이(전용 타입)로 묶어 그 덩이 하나를 `?` 로 만든다.

`| null` 도 같다. "왜 빌 수 있는지"를 적는다 — `lastRefreshCount: number | null;` 위의 `// 갱신에 실패했거나 아직 한 번도 안 돌았다.` 가 그것이다.

찾을 때: `?:` 선언을 훑어 **그 줄에도 바로 위에도 사유가 없는 줄**을 본다. 그 줄이 곧 위반이다.

### 11-2. 이름을 되풀이하는 주석은 지운다 (MUST)

기본은 무주석이다. 주석은 **코드가 말할 수 없는 것**만 적는다 — 왜 없을 수 있는지(11-1), 외부 규격, 단위·범위, 의도한 규칙 이탈.

이름과 타입이 이미 말한 것을 한국어로 옮겨 적으면 지운다. 정보가 0인데 diff 만 늘리고, 이름이 바뀌면 거짓말이 된다.

```ts
// X — 지운다. 이름과 타입이 이미 말한다
/** 소요 ms. */            durationMs: number;
/** HTTP 상태 코드. */     status: number;
/** 진행 중 여부. */       isRunning: () => boolean;

// O — 남긴다. 코드가 말할 수 없는 것이다
/** 0~1. */                                        successRate: number;
/** 호출수 내림차순. */                            byEndpoint: EndpointTraffic[];
/** 백엔드 추가 필드(하위호환) — 누락 시 0. */     p95DurationMs?: number;
```

이름만 되풀이하는데 그 줄에 `?` 가 있으면, 지우지 말고 **`?` 사유로 바꿔 쓴다.**

- `object`·`{}`·`Record<string, unknown>` 을 도메인 데이터에 쓰지 않는다. 필드를 아는 데이터는 필드를 적는다.

- 응답 래퍼(`ApiResponseDTO<T>`)는 `lib` 에 한 번만 정의하고, `api` 가 벗겨서 알맹이를 돌려준다.

- `props` 는 항상 명시적 `type`/`interface`. 훅 파라미터가 2개를 넘으면 이름 있는 객체(`UseXxxParams`)로 받는다.

- 닫힌 값 집합은 `enum`. 다만 객체 구조·함수 시그니처·라우팅 파라미터 타입은 enum 대상이 아니다.

- **enum 선언 위치는 `enums/` 로 고정한다.** 한 도메인의 enum(메시지·결과·상태)은 `<도메인>/enums/`, 여러 도메인이 쓰는 것과 인프라 enum 은 공용 `src/enums/` 에 각자 파일로. 사용처 파일 안 인라인 선언은 위반이다.

### 11-3. 서버 DTO 는 `types/` 에만 산다 (MUST)

서비스 파일 안에 응답 인터페이스를 선언하면, **계약서(서버 응답)와 업무 규칙이 한 파일에서 섞인다.** 서버가 필드를 하나 바꿀 때 어디를 보면 되는지가 흐려진다.

| 무엇 | 어디 |
|---|---|
| 요청 본문·응답 페이로드·행(row) | `<도메인>/types/<자원>.ts` |
| 클라이언트 옵션 — `*Options`·`*Query`(주입점·페이지·signal) | 서비스 파일 |
| 결과 표현 — `*Result`·`*Outcome`(결과 enum·판정) | 서비스 파일 |

```ts
// O — route/types/routeCompare.ts : 서버가 주는 모양만
export interface RouteOption { id: string; name: string; score: number; }

// O — route/services/routeCompare.ts : 규칙과 옵션만
import type { RouteOption } from '../types/routeCompare';
export interface RouteCompareClientOptions { /* 주입점 — 생략하면 기본 엔드포인트 */ endpoint?: string; }

// X — 한 파일이 계약서이자 업무 규칙
export interface RouteOption { … }
export async function fetchRouteCompare(…) { … }
```

**`types/` 는 아무것도 import 하지 않는 바닥이다.** `types/` 가 `services/` 를 참조하면 방향이 뒤집힌 것이다 — 값(함수·상수)이 필요해 보이면 그건 DTO 가 아니다.

## 12. 이름 규칙

원칙은 백엔드와 같다: **이름 = 대상 + 행위. 이름만 읽고 한 문장으로 설명되는가?**

| 대상 | 규칙 | 예 |
|---|---|---|
| 페이지 | PascalCase, 화면 이름 | `MemberRecord`, `AdminsTabPage` |
| 컴포넌트 | PascalCase 명사, 무엇을 그리는지 | `MemberRecordTable`, `BlockAdminModal` |
| 조립 훅 | `use` + 화면/도메인복수 | `useMemberRecords`, `useAdminsTabPage` |
| 단일책임 훅 | `use` + 대상 + 행위 | `useMemberRecordList`, `useMemberRecordDelete` |
| 상세 조회 훅 | `use<대상>Detail` (`…DetailModal` 아님) | `useMemberRecordDetail` |
| 모달 ref 묶음 훅 | `use<대상>ModalRefs` | `useMemberRecordModalRefs` |
| 서비스 함수 | 동사 + 대상 | `getMemberRecordList`, `blockAdminAccount`, `submitLogin` |
| api 객체 / 메서드 | 도메인 명사 / 짧은 동사 | `member.list()`, `admin.blacklist.add()` |
| 메시지 enum | `<도메인><용도>Messages` | `LoginResultMessages`, `BlockAdminResultMessages` |
| 결과 enum | `<행위>Outcome`, 멤버 UPPER_SNAKE | `DeleteRecordOutcome.ALREADY_MISSING` |
| 모달 ref 타입 | `<모달명>Ref` | `BlockAdminModalRef` |
| 열기 함수 | `open` + 행위 | `openBlock`, `openDetailModal` |
| 이벤트 핸들러 | `handle` + 무엇을 어떻게 | `handleCancelClick`, `handleSubmit` |
| 콜백 prop | `on` + 행위 | `onCancel`, `onClose` |
| boolean | `is`/`has`/`can` 긍정형 | `isLoading`, `hasError`, `canSubmit` |

리뷰에서 잡아야 할 알아보기 힘든 이름:

| 나쁜 이름 | 문제 | 대안 |
|---|---|---|
| `data`, `info`, `temp` | 무엇의 데이터인지 없음 | `records`, `adminProfile` |
| `Comp1`, `Item`, `Wrapper` | 무엇을 그리는지 없음 | `MemberRecordRow` |
| `useData()`, `useStuff()` | 어떤 유스케이스인지 없음 | `useMemberRecordList()` |
| `handleClick` (여러 개일 때) | 무엇을 클릭했는지 없음 | `handleDeleteClick` |
| `flag`, `notDisabled` | 부정형·무의미 | `isEditable`, `isSubmitting` |
| `res`, `r` (서비스 밖에서) | 무슨 응답인지 없음 | `blockResult` |

## 13. 레퍼런스에서 베끼면 안 되는 것

레퍼런스도 완벽하지 않다. 아래는 **규칙이 아니라 그 프로젝트의 부채**다. 따라 하지 않는다.

| 레퍼런스의 실제 상태 | 왜 베끼면 안 되는가 | 부엉이에서는 |
|---|---|---|
| **테스트 0건** (`*.test.*` 없음, vitest 미설치) | CLAUDE.md 7절 DoD 가 테스트 통과를 요구한다. 최소주의(ponytail)로도 생략 불가 | 현행 106개 테스트 유지. 신규 훅·서비스에 테스트 동반 |
| **HTTP 클라이언트 2개 공존** (`lib/api.ts` 의 `restfulApiClient` + `lib/apiClient.ts` 의 `apiClient`) | 인증 헤더·에러 처리가 두 갈래로 갈라져 있다. 5장의 "단일 창구" 원칙을 스스로 위반 | `src/utils/httpClient.ts` **하나만** 쓴다 |
| `send()` 에서 `throw result` — **Error 가 아닌 평범한 객체를 throw** | `instanceof` 로 못 걸러지고 스택도 없다 | 항상 `Error` 하위 타입(`ApiError`)을 throw |
| `restfulApiClient.get()` 등 **반환 타입 미선언** | 추론이 `AxiosResponse \| undefined` 로 새어 호출부가 옵셔널 체이닝 범벅이 된다 | api 함수에 반환 타입 명시(4장) |
| `api/*.tsx` — JSX 가 없는데 `.tsx` 확장자 | 확장자로 레이어를 판별할 수 없게 된다 | JSX 없으면 `.ts` (0-2장) |
| `apiClient.ts` 의 `// @TODO API Client 는 Data만 다루는 부분일텐데.. UI를???` | 미해결 설계 의문이 코드에 남아 있는 상태 | 레이어 경계를 지켜 애초에 발생시키지 않는다 |
| `README.md` 가 Vite 템플릿 기본값 | 규약이 문서화돼 있지 않아 코드를 읽어야만 알 수 있다 | 이 스킬 문서가 그 역할을 한다 |
| Bootstrap·SweetAlert2·DataTables 조합 | 그 프로젝트의 스택 선택일 뿐 보편 규칙이 아니다 | 부엉이 기존 공용 컴포넌트를 쓴다(CLAUDE.md 6절 "틀 준수") |

## 14. 부엉이 현행 코드 → 목표 구조 이관 지도

부엉이는 이미 상당 부분이 정렬돼 있다. **없는 것과 어긋난 것만** 표로 고정한다.

| 항목 | 부엉이 현행 | 목표 | 우선순위 |
|---|---|---|---|
| 페이지 상태 | `pages/` 에 `useState` 62 · `useEffect` 27 | 훅으로 전량 이동, 페이지 상태 0 | **높음** |
| 훅 수 | 6개 (`useRequestOrigin`·`useWakeLock`·`useOffRouteReroute`·`useAdminResource` …) | 화면당 조립 훅 1 + 단일책임 훅 N | **높음** |
| api 레이어 | 없음 — `<도메인>/services/*.ts` 가 HTTP + 규칙을 겸함 | `<도메인>/api/` 신설, 서비스는 규칙만 | **높음** |
| 메시지 enum | 0건, 문장이 호출부 인라인 | `<도메인>ResultMessages` 로 수렴 | 중간 |
| 결과 표현 | 불리언·`null`·문자열 혼재 | 결과 enum + `ApiError` 2분법 | 중간 |
| 알림 창구 | 토스트 직접 호출이 8개 파일에 분산 | `src/utils/notify.ts` 단일 창구 | 중간 |
| 폴더 구조 | 도메인 최상위 + 계층 하위(0장) | **이미 목표 상태.** 유지 | — |
| 공용 에러 핸들러 | `useAdminResource` 안에만 존재(관리자 전용) | `useServiceErrorHandler` 로 앱 전역화 | 중간 |
| HTTP 클라이언트 | `src/utils/httpClient.ts` 단일 · 인터셉터 · DI 목 | **이미 목표 상태.** 유지 | — |
| 에러 타입 | `ApiError`(`userMessage` 보유) | **이미 목표 상태.** `level` 만 보강 | — |
| 테스트 | 106개 | **이미 목표 이상.** 유지 | — |

이관 방식 — **한 번에 전면 개편하지 않는다.** 손대는 화면 단위로 옮긴다:

1. 그 화면의 페이지에서 `useState`/`useEffect` 를 전부 뽑아 `<도메인>/hooks/use<화면>.ts` 로 옮긴다.

2. 상태 덩어리가 2개 이상이면 단일책임 훅으로 쪼개고 조립 훅으로 묶는다.

3. 그 화면이 쓰는 서비스에서 HTTP 호출부를 `api/` 로 분리한다.

4. 그 화면의 사용자 메시지를 서비스의 enum 으로 모은다.

5. 기존 테스트가 그대로 통과하는지 확인한다. DOM·API 계약은 불변이어야 한다(ADR 0001).

## 15. 새 화면을 만들 때 — 순서

이 순서대로 파일을 만들면 레퍼런스와 같은 모양이 나온다.

"사용자(user)" 화면을 예로 들면 만들 파일은 정확히 아래와 같다.

| 순서 | 파일 | 내용 |
|---|---|---|
| 1 | `types/notice.ts` | 서버 DTO 를 서버 필드명 그대로. nullable 에 사유 주석 |
| 2 | `api/notice.ts` | `const NOTICES = "/api/v1/notices"` + `export const notice = {...}`. 반환 타입 명시, 상태코드 분기 없음 |
| 2.5 | `enums/user.ts` | `UserResultMessages`·`DeleteUserOutcome`·`DetailStatus` — 도메인 enum 전부 여기 |
| 3 | `services/userService.ts` | `export function` 들. 상태코드를 결과/`ApiError` 로 번역 (enum 은 import) |
| 4 | `hooks/useUserList.ts`<br>`hooks/useUserSelection.ts`<br>`hooks/useUserDelete.ts` | 단일책임 훅. `useState` 는 전부 여기. 각 액션은 `useCallback` |
| 5 | `hooks/useUsers.ts` | 조립 훅. 하위 훅을 모아 `{table: {...}, detailModal: {...}}` 로 반환. 최초 로드 `useEffect` 하나 |
| 6 | `components/data_table/UserTable.tsx` | props 로 받은 값만 그린다. default export |
| 7 | `components/modal/UserDetailModal.tsx` | `forwardRef` + `useImperativeHandle`, `UserDetailModalRef` 인터페이스 |
| 8 | `pages/user/User.tsx` | `const {table, detailModal} = useUsers()` + JSX. **상태 0** |
| 9 | `*.test.ts` | 서비스는 상태코드별 분기(정상 1 + 에러 2 이상), 훅은 로딩→성공/실패 전이 |

마지막으로 **3상태 확인**: 로딩·에러(재시도)·빈 상태가 화면에 다 있는가(CLAUDE.md 6절 의무).

이 표와 다른 파일 목록이 나왔다면 규칙을 벗어난 것이다. 특히 자주 나오는 이탈 두 가지: `hooks/useUsers.ts` 하나에 전부 몰아넣기(4번 생략), `api/` 없이 서비스가 HTTP 를 직접 호출하기(2번 생략).

## 16. 코드 리뷰 절차

리뷰를 요청받으면 아래 순서로 확인한다. 발견한 것마다 이 형식으로 지적한다: `파일경로:줄 — [위반 규칙] 현재 상태 → 수정 제안`

0. **이해가 먼저.** 변경된 파일 전부와, 수정된 컴포넌트/훅의 사용처를 읽는다. 읽지 않고 지적하지 않는다.

1. **페이지 무상태.** 페이지에 `useState`/`useEffect`/`useRef`/`AbortController` 가 있는가? 페이지가 50줄을 크게 넘는가? (1장)

2. **위치·이름·export.** 모든 파일을 0장 지도, 0-2장 표와 대조한다.

   컴포넌트 안의 통신, `services` 안의 React, `lib` 안의 도메인 단어·DTO, JSX 없는 `.tsx`, 훅/서비스의 `export default`, `components/<도메인>/` 폴더.

3. **의존 방향.** 역방향 import 나 건너뛰기(페이지 → 서비스 직접 호출)가 있는가?

4. **레이어 책임.** api 가 상태코드로 분기하는가? 훅이 상태코드를 아는가? 서비스가 JSX·알림을 다루는가?

5. **결과 표현.** 불리언·`null` 반환으로 실패를 표현하는가? 예상된 분기가 예외로 던져지는가? (7장)

6. **메시지·알림.** 한국어 문장이 호출부에 인라인으로 있는가? 알림 라이브러리를 직접 부르는가? (6·8장)

7. **타입.** `any`, 지역 타입 누락, 사유 없는 nullable, 반환 타입 없는 api 함수, camelCase 로 개명된 DTO 필드.

8. **이름·읽기 난이도.** 12장 표와 대조하고 **반드시 대안 이름을 함께 제시**한다. 삼항 중첩, index key, 조기 최적화, 이미 있는 공용 훅/컴포넌트의 재구현.

지적 예시:

- `route/pages/RouteComparison.tsx:38 — [페이지 무상태] 페이지에 useState 9개·로드 useEffect 존재 → route/hooks/useRouteComparison.ts 로 이동, 페이지는 const {map, sheet, routes} = useRouteComparison() 만`

- `route/services/routeCompare.ts:52 — [레이어 책임] 서비스가 httpClient 를 직접 호출 → route/api/routes.ts 의 fetchRouteCompare() 로 분리하고 서비스는 결과 번역만`

- `pages/admin/LogsPage.tsx:89 — [메시지] 한국어 문장이 인라인 → services/apiLogs.ts 에 ApiLogsResultMessages.LOAD_ERROR 로 승격`

- `share/services/shareSession.ts:120 — [결과 표현] 실패를 null 반환으로 표현 → ShareSessionOutcome enum 반환 + 진짜 실패는 ApiError throw`

지적만 하지 않는다. 각 항목에 "왜 문제인지 한 문장 + 고친 모습"까지 제시해야 리뷰가 끝난 것이다.
