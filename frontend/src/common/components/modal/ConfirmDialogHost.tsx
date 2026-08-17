import {useEffect, useState} from "react";
import {registerConfirmDialogHost, type ConfirmDialogRequest} from "../../lib/confirmDialog";
import {ConfirmModal} from "./ConfirmModal";

/**
 * `notify.confirm` 요청을 실제 팝업으로 그리는 호스트 — 앱 루트에 하나만 둔다.
 * 대기 중 요청은 이 컴포넌트 자신의 표현 상태다(밖으로 나가지 않는다 — 1-1장 예외).
 */
export function ConfirmDialogHost() {
    // 대기 중 요청이 없으면 팝업도 없다.
    const [request, setRequest] = useState<ConfirmDialogRequest | undefined>(undefined);

    useEffect(() => registerConfirmDialogHost(setRequest), []);

    function settle(confirmed: boolean): void {
        if (request) {
            request.resolve(confirmed);
        }
        setRequest(undefined);
    }

    if (!request) {
        return null;
    }

    return (
        <ConfirmModal
            options={request.options}
            onCancel={() => settle(false)}
            onConfirm={() => settle(true)}
        />
    );
}
