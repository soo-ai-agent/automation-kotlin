import {useCallback} from "react";
import {useRouter} from "expo-router";

/**
 * 지도에서 되돌아가기.
 *
 * `<Link href="/">` 로는 안 된다 — 스택에 이미 있는 "/" 로 pop 되지 않고 **새로 push** 되어
 * 사용자 화면이 두 벌 쌓이고 기기 뒤로 가기가 다시 지도로 돌아온다.
 *
 * `/map` 을 주소로 바로 열면 되돌아갈 자리가 없다 — 그때는 "/" 로 바꿔 넣는다(뒤로 버튼이 먹통이 되지 않게).
 */
export function useMapBack(): {goBack: () => void} {
    const router = useRouter();

    const goBack = useCallback((): void => {
        if (router.canGoBack()) {
            router.back();
            return;
        }
        router.replace("/");
    }, [router]);

    return {goBack};
}
