import {StyleSheet, useColorScheme} from "react-native";

/**
 * 색·모서리·간격 공용 토큰 — 컴포넌트의 StyleSheet 는 여기 값만 쓴다(하드코딩 금지).
 *
 * 색은 밝게/어둡게 두 벌을 짝으로 둔다. Expo 가 권하는 플랫폼 시맨틱 색(`Color`)은
 * 브랜드 색을 표현하지 못하고 `expo-router@57` 에 아직 없어, 짝을 직접 들고 훅으로 고른다
 * (`expo-design-system` 의 "brand light/dark pairs are hook-only").
 */
type ColorPalette = {
    bg: string; bgElevated: string; panel: string; text: string; textDim: string;
    textMuted: string; primary: string; primaryInk: string; danger: string;
    border: string; backdrop: string;
};

const palette: {light: ColorPalette; dark: ColorPalette} = {
    light: {
        bg: "#ffffff", bgElevated: "#f8fafc", panel: "#f1f5f9", text: "#0f172a", textDim: "#64748b",
        textMuted: "#94a3b8", primary: "#2563eb", primaryInk: "#ffffff", danger: "#dc2626",
        border: "#e2e8f0", backdrop: "rgba(15, 23, 42, 0.5)",
    },
    dark: {
        bg: "#0f172a", bgElevated: "#1e293b", panel: "#334155", text: "#f8fafc", textDim: "#cbd5e1",
        textMuted: "#94a3b8", primary: "#3b82f6", primaryInk: "#ffffff", danger: "#f87171",
        border: "#475569", backdrop: "rgba(2, 6, 23, 0.7)",
    },
};

export type Colors = ColorPalette;

/** 지금 화면 모드의 색 한 벌. 기기 설정을 따르고, 바뀌면 다시 렌더된다. */
export function useColors(): Colors {
    const scheme = useColorScheme();
    return scheme === "dark" ? palette.dark : palette.light;
}

/**
 * 색이 들어간 StyleSheet 를 만드는 창구.
 *
 * `StyleSheet.create` 는 모듈이 읽힐 때 한 번만 도는데, 색은 렌더 시점에야 정해진다.
 * 그래서 스타일 생성을 함수로 미뤄 두고, 여기서 (그 함수 × 모드)마다 딱 한 번만 만들어 재사용한다.
 * 목록의 행처럼 같은 컴포넌트가 여러 벌 그려져도 생성은 한 번이다.
 *
 * `createStyles` 는 파일 맨 아래 최상위에 두어야 한다 — 렌더마다 새 함수면 캐시가 매번 빗나간다.
 */
const styleCache = new WeakMap<object, Map<Colors, unknown>>();

export function useStyles<T extends StyleSheet.NamedStyles<T>>(createStyles: (colors: Colors) => T): T {
    const colors: Colors = useColors();

    let byMode: Map<Colors, unknown> | undefined = styleCache.get(createStyles);
    if (!byMode) {
        byMode = new Map();
        styleCache.set(createStyles, byMode);
    }
    const cached: unknown = byMode.get(colors);
    if (cached) {
        return cached as T;
    }
    const created: T = createStyles(colors);
    byMode.set(colors, created);
    return created;
}

export const radius = {
    sm: 8, md: 16, full: 999,
};

export function spacing(step: number): number {
    return step * 4;
}
