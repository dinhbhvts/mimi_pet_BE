import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

/// Đăng nhập bằng username + mật khẩu - xem `backend/app/routers/auth.py`
/// phía server tương ứng. Token JWT lưu qua `SharedPreferences` (đủ dùng cho
/// app trẻ em không có dữ liệu tài chính/nhạy cảm - KHÔNG dùng
/// `flutter_secure_storage` vì package đó không hỗ trợ tốt trên web, nơi app
/// này cũng cần chạy được).
class AuthService extends ChangeNotifier {
  AuthService(this._apiClient);

  final ApiClient _apiClient;
  static const _keyToken = 'mimi.auth_token';
  static const _keyUsername = 'mimi.auth_username';

  String? _token;
  String? _username;
  bool _loaded = false;

  bool get loaded => _loaded;
  bool get isLoggedIn => _token != null;
  String? get username => _username;

  /// Đọc token đã lưu từ lần đăng nhập trước (nếu có) - gọi 1 lần lúc khởi
  /// động app, TRƯỚC khi quyết định hiện `LoginScreen` hay vào thẳng app
  /// (xem `app.dart`).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_keyToken);
    _username = prefs.getString(_keyUsername);
    _apiClient.setToken(_token);
    _loaded = true;
    notifyListeners();
  }

  /// Đăng nhập bằng [username]/[password] - thành công thì lưu token và coi
  /// như đã đăng nhập; ném [ApiException] nếu sai tên đăng nhập/mật khẩu.
  Future<void> login(String username, String password) async {
    // Timeout DÀI (xem [ApiClient.postJson]) - lần đăng nhập đầu tiên trong
    // ngày dễ đụng lúc backend Render (gói Free) đang "ngủ", cần thời gian
    // thức dậy (xem `boot_screen.dart`) trước khi trả lời được.
    final res = await _apiClient.postJson(
      '/auth/login',
      {'username': username, 'password': password},
      timeout: const Duration(seconds: 100),
    );
    _token = res['token'] as String;
    _username = res['username'] as String;
    _apiClient.setToken(_token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, _token!);
    await prefs.setString(_keyUsername, _username!);
    notifyListeners();
  }

  /// Đổi mật khẩu tài khoản đang đăng nhập - ném [ApiException] nếu mật khẩu
  /// hiện tại sai hoặc mật khẩu mới không hợp lệ (quá ngắn). Không cần cập
  /// nhật lại token/username vì backend không đổi (chỉ đổi
  /// `password_hash`).
  Future<void> changePassword(String oldPassword, String newPassword) => _apiClient.postJson(
        '/me/change-password',
        {'old_password': oldPassword, 'new_password': newPassword},
      );

  Future<void> logout() async {
    _token = null;
    _username = null;
    _apiClient.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUsername);
    notifyListeners();
  }
}
