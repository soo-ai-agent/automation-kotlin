/** 어느 화면에도 속하지 않는 문장 — 알림 제목, 공용 버튼 문구, 세션. */

export enum NotifyTitle {
    SUCCESS = "완료",
    WARNING = "확인 필요",
    ERROR = "오류",
}

/** 확인 팝업 버튼 문구 — 화면마다 "확인"·"취소"를 다시 적지 않게 여기 모은다. */
export enum ConfirmButtonLabel {
    CONFIRM = "확인",
    CANCEL = "취소",
    DELETE = "삭제",
}

export enum SessionResultMessages {
    EXPIRED = "세션이 만료되었습니다. 다시 로그인해 주세요.",
}

export enum NotFoundMessages {
    TITLE = "없는 화면입니다.",
    BODY = "주소가 바뀌었거나 삭제된 화면일 수 있어요.",
    GO_HOME = "처음으로",
}

export enum ErrorBoundaryMessages {
    TITLE = "화면을 그리지 못했습니다.",
    BODY = "잠시 뒤 다시 시도해 주세요. 계속되면 앱을 다시 켜 주세요.",
    RETRY = "다시 시도",
}
