import type {StyleProp, ViewStyle} from "react-native";

export type LatLng = {
    lat: number;
    lng: number;
};

export type MapMarker = LatLng & {
    name: string;   // 마커 아래에 그대로 표시된다. 이름 없는 점이면 "" 로 넘긴다(라벨 생략).
};

/** 네이티브 구현(kakao-map-view.tsx)과 웹 대체 구현(.web.tsx)이 같은 모양을 지키게 하는 공용 props. */
export type KakaoMapViewProps = {
    center: LatLng;
    level: number;
    markers: MapMarker[];
    style: StyleProp<ViewStyle>;
};
