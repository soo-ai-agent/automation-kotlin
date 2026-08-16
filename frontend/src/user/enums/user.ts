export enum UserResultMessages {
    LIST_EMPTY = "등록된 사용자가 없습니다.",
    LIST_LOAD_ERROR = "사용자 목록을 불러오지 못했습니다.",
    DETAIL_LOAD_ERROR = "사용자 상세를 불러오지 못했습니다.",
    DETAIL_NOT_FOUND = "이미 삭제되었거나 존재하지 않는 사용자입니다.",
    DELETE_CONFIRM = "이 사용자를 삭제할까요?",
    BULK_DELETE_CONFIRM = "선택한 사용자를 모두 삭제할까요?",
    DELETE_SUCCESS = "삭제되었습니다.",
    DELETE_ALREADY_MISSING = "이미 삭제되었거나 존재하지 않는 사용자입니다.",
    DELETE_ERROR = "삭제 중 오류가 발생했습니다.",
    BULK_DELETE_NO_SELECTION = "선택된 사용자가 없습니다.",
    FORBIDDEN = "사용자 정보에 접근할 권한이 없습니다.",
}

export enum DeleteUserOutcome {
    SUCCESS = "SUCCESS",
    ALREADY_MISSING = "ALREADY_MISSING",
}

export enum DetailStatus {
    CLOSED = "CLOSED",
    LOADING = "LOADING",
    LOADED = "LOADED",
}
