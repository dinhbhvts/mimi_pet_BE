import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

/// Đăng nhập KHÔNG mật khẩu (mã 6 số gửi qua email) - xem
/// `backend/app/routers/auth.py` phía server tương ứng. Token JWT lưu qua
/// `SharedPreferences` (đủ dùng cho app trẻ em không có dữ liệu tài
/// chính/nhạy cảm - KHÔNG dùng `flutter_secure_storage` vì package đó không
/// hỗ trợ tốt trên web, nơi app này cũng cần chạy được).
class AuthService extends ChangeNotifier {
  AuthService(this._apiClient);

  final ApiClient _apiClient;
  static const _keyToken = 'mimi.auth_token';
  static const _keyEmail = 'mimi.auth_email';

  String? _token;
  String? _email;
  bool _loaded = false;

  bool get loaded => _loaded;
  bool get isLoggedIn => _token != null;
  String? get email => _email;

  /// Đọc token đã lưu từ lần đăng nhập trước (nếu có) - gọi 1 lần lúc khởi
  /// động app, TRƯỚC khi quyết định hiện `LoginScreen` hay vào thẳng app
  /// (xem `app.dart`).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_keyToken);
    _email = prefs.getString(_keyEmail);
    _apiClient.setToken(_token);
    _loaded = true;
    notifyListeners();
  }

  /// Gửi mã 6 số tới [email]. Ném [ApiException] nếu thất bại (ví dụ gửi lại
  /// quá nhanh trong vòng 60 giây) - `LoginScreen` tự bắt và hiện thông báo
  /// phù hợp.
  Future<void> requestCode(String email) => _apiClient.postJson('/auth/request-code', {'email': email});

  /// Xác nhận mã vừa nhận qua email - thành công thì lưu token và coi như đã
  /// đăng nhập; ném [ApiException] nếu mã sai/hết hạn.
  Future<void> verifyCode(String email, String code) async {
    final res = await _apiClient.postJson('/auth/verify-code', {'email': email, 'code': code});
    _token = res['token'] as String;
    _email = res['email'] as String;
    _apiClient.setToken(_token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, _token!);
    await prefs.setString(_keyEmail, _email!);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _email = null;
    _apiClient.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyEmail);
    notifyListeners();
  }
}
