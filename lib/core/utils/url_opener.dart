import 'url_opener_stub.dart'
    if (dart.library.html) 'url_opener_web.dart' as platform;

/// Opens the specified [url] in a new browser tab or window.
void openUrlInNewTab(String url) {
  platform.openUrlInNewTab(url);
}
