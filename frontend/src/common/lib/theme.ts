/** 색·모서리·간격 공용 토큰 — 화면·스타일 파일은 여기 값만 쓴다(하드코딩 금지). */
export const colors = {
    bg: "#ffffff", bgElevated: "#f8fafc", panel: "#f1f5f9", text: "#0f172a", textDim: "#64748b",
    textMuted: "#94a3b8", primary: "#2563eb", primaryInk: "#ffffff", danger: "#dc2626",
    border: "#e2e8f0",
};

export const radius = {
    sm: 8, md: 16, full: 999,
};

export function spacing(step: number): number {
    return step * 4;
}
