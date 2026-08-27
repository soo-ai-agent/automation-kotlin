import {fetch} from "expo/fetch";
import {API_BASE_URL} from "@/utils/config";

/** 이 앱이 쓰는 HTTP 메서드. 문자열을 호출부에 흩뿌리지 않으려고 여기 둔다. */
export enum HttpMethod {
    GET = "GET",
    POST = "POST",
    DELETE = "DELETE",
}

/** 백엔드 `ApiResponse<T>` 의 result 필드. */
export enum ResultType {
    SUCCESS = "SUCCESS",
    ERROR = "ERROR",
}

/**
 * 성공했을 때만 data 가 존재한다. `result.ok` 를 확인하면 data 는 T 로 확정되므로
 * 호출부에 null 검사가 필요 없다. "성공인데 데이터가 없는" 모순 상태를 타입이 막는다.
 */
export type ApiResult<T> =
    | {ok: true; status: number; data: T}
    | {ok: false; status: number};

/**
 * 백엔드 `ApiResponse<T>` 그대로다 (core:core-common 의 response/ApiResponse.kt).
 * 서버 응답 모양이 바뀌면 고치는 곳은 이 타입 하나다.
 */
type ApiResponseDTO<T> = {
    result: ResultType;
    data: T;                       // 본문 없는 성공(삭제 등)은 null 로 오고, 호출부가 T 를 void 로 잡는다.
    error: ErrorMessageDTO | null; // 성공이면 null.
};

type ErrorMessageDTO = {
    code: string;
    message: string;
    data: unknown; // 서버가 오류마다 다른 모양으로 담는 부가 정보라 여기서는 좁힐 수 없다.
};

type PathOptions = {path: string};

type BodyOptions = {
    path: string;
    body: unknown;   // JSON 직렬화 경계라 여기서는 형태를 좁히지 않는다.
};

// body: unknown — 위 BodyOptions.body 와 같은 직렬화 경계 사유.
async function send<T>(method: HttpMethod, path: string, body: unknown): Promise<ApiResult<T>> {
    const response = await fetch(`${API_BASE_URL}${path}`, {
        method: method,
        credentials: "include",
        headers: body === undefined
            ? {Accept: "application/json"}
            : {Accept: "application/json", "Content-Type": "application/json"},
        body: body === undefined ? undefined : JSON.stringify(body),
    });

    const isSuccess: boolean = response.status >= 200 && response.status < 300;
    const payload: ApiResponseDTO<T> | undefined = await readPayload<T>(response);

    // 래퍼가 통째로 비었거나 result 가 ERROR 면 계약 위반이므로 성공으로 보지 않는다.
    if (!isSuccess || payload === undefined || payload.result !== ResultType.SUCCESS) {
        return {ok: false, status: response.status};
    }
    return {ok: true, status: response.status, data: payload.data};
}

/** 본문이 비었거나(204) JSON 이 아니면(프록시의 HTML 오류 페이지 등) 래퍼 없음으로 본다. */
async function readPayload<T>(response: Response): Promise<ApiResponseDTO<T> | undefined> {
    const text: string = await response.text();
    if (!text) {
        return undefined;
    }
    try {
        return JSON.parse(text) as ApiResponseDTO<T>;
    } catch {
        return undefined;
    }
}

export const apiClient = {
    get<T>({path}: PathOptions): Promise<ApiResult<T>> {
        return send<T>(HttpMethod.GET, path, undefined);
    },

    post<T>({path, body}: BodyOptions): Promise<ApiResult<T>> {
        return send<T>(HttpMethod.POST, path, body);
    },

    delete<T>({path}: PathOptions): Promise<ApiResult<T>> {
        return send<T>(HttpMethod.DELETE, path, undefined);
    },
};
