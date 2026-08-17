/**
 * 앱 디자인의 확인 팝업을 훅 밖(서비스·비동기 흐름)에서도 띄우기 위한 모듈 브리지.
 * 실제 그리기는 앱 루트의 ConfirmDialogHost 가 맡고, 부르는 창구는 notify.confirm 하나다.
 */

export interface ConfirmDialogOptions {
    title: string;
    // 제목만으로 충분한 팝업은 빈 문자열.
    body: string;
    confirmText: string;
    cancelText: string;
    // 되돌릴 수 없는 동작(삭제·종료)이면 true — 확인 버튼을 위험색으로 그린다.
    destructive: boolean;
}

export interface ConfirmDialogRequest {
    options: ConfirmDialogOptions;
    resolve: (confirmed: boolean) => void;
}

// 호스트 미장착이 기본값이다 — 앱 루트가 마운트되면서 채운다.
let host: ((request: ConfirmDialogRequest) => void) | undefined;

export function registerConfirmDialogHost(
    handler: (request: ConfirmDialogRequest) => void,
): () => void {
    host = handler;
    return function unregisterConfirmDialogHost(): void {
        host = undefined;
    };
}

/** 확인 팝업을 띄우고 사용자의 선택을 돌려준다. 호스트가 없으면(비정상) 거부로 귀결시킨다. */
export function requestConfirm(options: ConfirmDialogOptions): Promise<boolean> {
    const activeHost = host;
    if (!activeHost) {
        return Promise.resolve(false);
    }
    return new Promise((resolve) => {
        activeHost({options, resolve});
    });
}
