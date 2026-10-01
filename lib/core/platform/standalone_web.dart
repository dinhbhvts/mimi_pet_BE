import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// iOS dùng `navigator.standalone` (riêng của Safari); các trình duyệt khác
/// dùng media query `display-mode: standalone` theo chuẩn PWA.
bool isStandaloneDisplay() {
  try {
    final navigator = globalContext['navigator'] as JSObject?;
    final iosStandalone = navigator?['standalone'];
    if (iosStandalone != null && iosStandalone.isA<JSBoolean>() && (iosStandalone as JSBoolean).toDart) {
      return true;
    }
    final query = globalContext.callMethod<JSObject?>('matchMedia'.toJS, '(display-mode: standalone)'.toJS);
    final matches = query?['matches'];
    return matches != null && matches.isA<JSBoolean>() && (matches as JSBoolean).toDart;
  } catch (_) {
    return false;
  }
}
