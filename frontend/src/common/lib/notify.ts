import {Alert, Platform} from "react-native";
import {NotifyTitle} from "../enums/notify";

/**
 * 알림 단일 창구 — 알림 UI(Alert/토스트/모달)를 바꿀 때 이 파일만 고친다.
 *
 * 웹(react-native-web)에서는 Alert 가 아무것도 하지 않아(no-op) window.alert/confirm 으로 갈린다.
 * confirm 이 Promise 인 것도 같은 이유다 — 네이티브 Alert 는 버튼 콜백으로만 답을 준다.
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

    confirm(message: string): Promise<boolean> {
        if (Platform.OS === "web") {
            return Promise.resolve(window.confirm(message));
        }
        return new Promise((resolve) => {
            Alert.alert(NotifyTitle.CONFIRM, message, [
                {text: "취소", style: "cancel", onPress: () => resolve(false)},
                {text: "확인", onPress: () => resolve(true)},
            ]);
        });
    },
};

function show(title: NotifyTitle, message: string): void {
    if (Platform.OS === "web") {
        window.alert(message);
        return;
    }
    Alert.alert(title, message);
}
