import type {StyleProp, ViewStyle} from "react-native";
import type {LatLng, MapMarker} from "../types/map";

/** 네이티브 구현(KakaoMapView.tsx)과 웹 대체 구현(.web.tsx)이 같은 모양을 지키게 하는 공용 props. */
export type KakaoMapViewProps = {
    center: LatLng;
    level: number;
    markers: MapMarker[];
    style: StyleProp<ViewStyle>;
};
