import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebviewBridge {
  static InAppWebViewSettings get defaultSettings {
    return InAppWebViewSettings(
      javaScriptEnabled: true,
      allowFileAccessFromFileURLs: true,
      allowUniversalAccessFromFileURLs: true,
      useHybridComposition: true,
      isInspectable: true,
      supportZoom: true,
      builtInZoomControls: false,
      displayZoomControls: false,
    );
  }
}
