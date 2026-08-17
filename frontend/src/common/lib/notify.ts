import {Alert, Platform} from "react-native";
import {NotifyTitle} from "../enums/notify";
import {requestConfirm, type ConfirmDialogOptions} from "./confirmDialog";

/**
 * 알림 단일 창구 — 알림 UI 를 바꿀 때 이 파일만 고친다. 컴포넌트·훅·서비스는 이 창구만 부른다.
 *
 * 확인은 앱 디자인의 ConfirmModal 로 띄운다(플랫폼 공통). 단순 알림은 아직 OS 대화상자이고,
 * 웹(react-native-web)에서는 Alert 가 아무것도 하지 않아(no-op) window.alert 로 갈린다.
 */
export const notify = {
    success(message: string): void {
        show(NotifyTitle.SUCCESS, message);
    },

    warning(message: string): void {
        show(NotifyTitle.WARNING, message);
    },

    error(message: string): void {
        show(NotifyTitle.ERROR, message);
    },

    /** 앱 디자인 팝업으로 물어보고 사용자의 선택을 돌려준다. 그리는 것은 앱 루트의 ConfirmDialogHost 다. */
    confirm(options: ConfirmDialogOptions): Promise<boolean> {
        return requestConfirm(options);
    },
};

function show(title: NotifyTitle, message: string): void {
    if (Platform.OS === "web") {
        window.alert(message);
        return;
    }
    Alert.alert(title, message);
}
