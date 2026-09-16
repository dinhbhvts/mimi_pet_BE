import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

/// Nạp/lưu TOÀN BỘ tiến độ của bé (sao, tim, streak, thú cưng đã tuỳ chỉnh,
/// avatar, điểm thi thử...) dưới dạng 1 blob JSON DUY NHẤT, đồng bộ qua
/// backend (`GET`/`PUT /me/state`) - THAY cho việc mỗi loại dữ liệu tự
/// đọc/ghi `SharedPreferences` riêng như trước. Mọi `Cloud*Repository` trong
/// `lib/data/repositories/` chỉ là lớp mỏng đọc/ghi 1-2 key trong store này.
///
/// Chiến lược đồng bộ: "local-first, best-effort push" - mỗi lần [setRaw]/
/// [setMapEntry] cập nhật NGAY vào bộ nhớ + 1 bản sao cục bộ
/// (`SharedPreferences`) để UI phản hồi tức thì và app vẫn dùng tạm được khi
/// mất mạng, đồng thời gửi TOÀN BỘ state lên server ở chế độ "cố gắng hết
/// sức" (debounce 600ms để gộp nhiều thay đổi liên tiếp thành 1 request,
/// không chặn UI chờ kết quả - lỗi thì bỏ qua, lần đổi tiếp theo sẽ lại gửi
/// bản mới nhất). KHÔNG xử lý xung đột khi 2 thiết bị sửa cùng lúc
/// (last-write-wins) - đủ dùng cho quy mô 1 gia đình.
class CloudStateStore {
  CloudStateStore(this._apiClient);

  final ApiClient _apiClient;
  static const _cacheKey = 'mimi.cloud_state_cache';

  Map<String, dynamic> _state = {};
  bool _loaded = false;
  Timer? _pushDebounce;

  bool get loaded => _loaded;

  /// Nạp state - thử lấy bản mới nhất từ server trước, LỖI MẠNG thì rơi về
  /// bản cache cục bộ (nếu có) thay vì chặn app khởi động. Gọi 1 lần ngay
  /// sau khi đăng nhập thành công (xem `app.dart`).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        _state = jsonDecode(cached) as Map<String, dynamic>;
      } catch (_) {
        _state = {};
      }
    }
    try {
      final remote = await _apiClient.getJson('/me/state');
      _state = (remote['state'] as Map<String, dynamic>?) ?? {};
      await prefs.setString(_cacheKey, jsonEncode(_state));
    } catch (_) {
      // Mất mạng/server lỗi - dùng tạm bản cache cục bộ ở trên (có thể rỗng
      // nếu đây là lần đầu mở app trên thiết bị này).
    }
    _loaded = true;
  }

  T? getRaw<T>(String key) => _state[key] as T?;

  void setRaw(String key, dynamic value) {
    _state[key] = value;
    _scheduleSync();
  }

  Map<String, dynamic> getMap(String key) => Map<String, dynamic>.from(_state[key] as Map? ?? const {});

  void setMapEntry(String key, String subKey, dynamic value) {
    final current = getMap(key);
    current[subKey] = value;
    _state[key] = current;
    _scheduleSync();
  }

  void _scheduleSync() {
    _persistLocal();
    _pushDebounce?.cancel();
    _pushDebounce = Timer(const Duration(milliseconds: 600), _pushRemote);
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(_state));
  }

  Future<void> _pushRemote() async {
    try {
      await _apiClient.putJson('/me/state', {'state': _state});
    } catch (_) {
      // Best-effort - lần set tiếp theo sẽ lại thử gửi bản mới nhất.
    }
  }

  void dispose() => _pushDebounce?.cancel();
}
