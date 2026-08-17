export type LatLng = {
    lat: number;
    lng: number;
};

export type MapMarker = LatLng & {
    name: string;   // 마커 아래에 그대로 표시된다. 이름 없는 점이면 "" 로 넘긴다(라벨 생략).
};
