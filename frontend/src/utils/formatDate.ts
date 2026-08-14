export function formatDateTime(isoText: string): string {
    return new Date(isoText).toLocaleString("ko-KR");
}

export function formatOptionalDateTime(isoText: string | null): string {
    if (isoText === null) {
        return "-";
    }
    return formatDateTime(isoText);
}
