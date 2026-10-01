import 'package:flutter/foundation.dart';

import 'standalone_stub.dart' if (dart.library.js_interop) 'standalone_web.dart' as standalone;

/// Thông tin nền tảng mà nhiều nơi trong app cần để xử lý riêng bản web
/// chạy trên iPhone/iPad - nơi MỌI trình duyệt (kể cả Chrome cho iOS) đều
/// dùng chung engine WebKit của Apple với các giới hạn riêng về mic, giọng
/// đọc và âm thanh (xem `deployment.md` mục Safari).
class PlatformInfo {
  PlatformInfo._();

  /// Ghi đè cho test (trong `flutter test` luôn là `kIsWeb == false`).
  static bool? debugIsIosWebOverride;

  /// true khi đang chạy bản WEB trên iPhone/iPad. Flutter web tự nhận iPad
  /// đời mới (Safari giả danh "Macintosh") là iOS qua số điểm chạm.
  static bool get isIosWeb => debugIsIosWebOverride ?? (kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

  /// true khi bản web đang mở từ icon ở Màn hình chính (chế độ app toàn màn
  /// hình, không có thanh địa chỉ) thay vì trong tab trình duyệt.
  static bool get isStandaloneWebApp => kIsWeb && standalone.isStandaloneDisplay();
}
