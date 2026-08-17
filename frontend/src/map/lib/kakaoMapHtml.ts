import {MapWebViewMessageType} from "../enums/map";

/**
 * 카카오 지도를 띄우는 WebView 문서. RN 은 아래 창구로만 이 문서와 이야기한다(경계 계약).
 *  - `window.__INITIAL__`            : 첫 렌더 payload (injectedJavaScriptBeforeContentLoaded 로 주입)
 *  - `window.__update(payload)`      : 중심·배율·마커를 통째로 다시 그린다
 *  - postMessage({type})             : SDK 로드 실패를 RN 으로 올려보낸다
 */
export function buildKakaoMapHtml(jsKey: string): string {
    return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no" />
  <style>
    html,body,#map{margin:0;padding:0;width:100%;height:100%;background:#f1f5f9;}
    .marker{transform:translate(0,-6px);display:flex;flex-direction:column;align-items:center;}
    .marker-dot{width:16px;height:16px;border-radius:9999px;background:#2563eb;border:3px solid #ffffff;box-shadow:0 1px 4px rgba(0,0,0,.35);}
    .marker-name{margin-top:2px;padding:2px 6px;border-radius:6px;background:rgba(255,255,255,.92);color:#0f172a;font-size:11px;font-weight:700;white-space:nowrap;}
  </style>
</head>
<body>
  <div id="map"></div>
  <script src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=${jsKey}&autoload=false" onerror="window.__sdkLoadFailed = true"></script>
  <script>
    var map = null;
    var overlays = [];

    function reportLoadFailed() {
      if (window.ReactNativeWebView) {
        window.ReactNativeWebView.postMessage(JSON.stringify({ type: '${MapWebViewMessageType.MAP_LOAD_FAILED}' }));
      }
    }

    // innerHTML 대신 textContent — 마커 이름은 데이터라 HTML 로 해석되면 안 된다.
    function markerElement(marker) {
      var root = document.createElement('div');
      root.className = 'marker';
      var dot = document.createElement('div');
      dot.className = 'marker-dot';
      root.appendChild(dot);
      if (marker.name) {
        var name = document.createElement('div');
        name.className = 'marker-name';
        name.textContent = marker.name;
        root.appendChild(name);
      }
      return root;
    }

    window.__update = function (payload) {
      if (!map) { return; }
      map.setCenter(new kakao.maps.LatLng(payload.center.lat, payload.center.lng));
      map.setLevel(payload.level);
      for (var i = 0; i < overlays.length; i++) { overlays[i].setMap(null); }
      overlays = [];
      for (var j = 0; j < payload.markers.length; j++) {
        var marker = payload.markers[j];
        var overlay = new kakao.maps.CustomOverlay({
          position: new kakao.maps.LatLng(marker.lat, marker.lng),
          content: markerElement(marker),
        });
        overlay.setMap(map);
        overlays.push(overlay);
      }
    };

    if (window.__sdkLoadFailed || !window.kakao || !window.kakao.maps) {
      reportLoadFailed();
    } else {
      kakao.maps.load(function () {
        var initial = window.__INITIAL__;
        map = new kakao.maps.Map(document.getElementById('map'), {
          center: new kakao.maps.LatLng(initial.center.lat, initial.center.lng),
          level: initial.level,
        });
        window.__update(initial);
      });
    }
  </script>
</body>
</html>`;
}
