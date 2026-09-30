import 'dart:js_interop';

@JS('window.open')
external void _jsWindowOpen(JSString url, JSString target);

/// Web implementation using JS interop window.open to open URLs in a new browser tab.
void openUrlInNewTab(String url) {
  if (url.isNotEmpty) {
    _jsWindowOpen(url.toJS, '_blank'.toJS);
  }
}
