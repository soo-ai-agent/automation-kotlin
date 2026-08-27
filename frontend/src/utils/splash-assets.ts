import {Asset} from "expo-asset";

/**
 * 스플래시 다음에 곧바로 그려지는 에셋을 미리 받아 둔다.
 *
 * 안 받아 두면 첫 화면이 뜬 뒤에 이미지가 따라 들어와 한 번 깜빡인다.
 * 이미지를 추가하면 `require("../../assets/…")` 로 이 배열에 넣는다 — 그러면 스플래시가 그만큼 더 기다린다.
 */
const PRELOAD_IMAGES: number[] = [];

export async function loadSplashAssets(): Promise<void> {
    if (PRELOAD_IMAGES.length === 0) {
        return;
    }
    await Asset.loadAsync(PRELOAD_IMAGES);
}
