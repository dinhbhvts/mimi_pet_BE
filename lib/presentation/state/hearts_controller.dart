import 'package:flutter/foundation.dart';

import '../../domain/repositories/hearts_repository.dart';

/// Quản lý số tim (lives) của bé - tim mất khi trả lời sai, hồi phục dần
/// theo thời gian (không bắt bé phải trả tiền/xem quảng cáo để có thêm tim,
/// khác với cơ chế thương mại hoá của Duolingo - phù hợp app học cho bé).
///
/// Cùng nguyên tắc với [ProgressController]: UI không bao giờ đọc/ghi
/// SharedPreferences trực tiếp, luôn đi qua controller này.
class HeartsController extends ChangeNotifier {
  HeartsController(this._repository);

  final HeartsRepository _repository;

  // TĂNG (2026-08-23) theo yêu cầu "không quá cần thiết phải giới hạn bé":
  // maxHearts 5 -> 10 (bé có nhiều lượt thử hơn trước khi hết tim), và
  // regenInterval 2 giờ -> 15 phút (hồi tim nhanh hơn RẤT NHIỀU, gần như
  // không còn cảm giác bị chặn) - vẫn giữ CƠ CHẾ tim (không bỏ hẳn) để bé còn
  // có động lực trả lời cẩn thận, nhưng không còn tính "giới hạn" khắt khe
  // như trước. Nhớ đồng bộ giá trị mặc định lần đầu đăng nhập trong
  // `CloudHeartsRepository.getHearts()` (`?? 10`) nếu đổi `maxHearts` nữa.
  static const int maxHearts = 10;
  static const Duration regenInterval = Duration(minutes: 15);

  int _hearts = maxHearts;
  DateTime? _lastLostAt;
  bool _loaded = false;

  int get hearts => _hearts;
  int get max => maxHearts;
  bool get loaded => _loaded;
  bool get isFull => _hearts >= maxHearts;
  bool get hasHearts => _hearts > 0;

  /// Thời gian còn lại tới khi có thêm 1 tim, null nếu đang đầy tim hoặc
  /// chưa từng mất tim.
  Duration? get timeUntilNextHeart {
    if (isFull || _lastLostAt == null) return null;
    final remaining = _lastLostAt!.add(regenInterval).difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> load() async {
    _hearts = await _repository.getHearts();
    _lastLostAt = await _repository.getLastLostAt();
    await _applyRegen();
    _loaded = true;
    notifyListeners();
  }

  /// Gọi định kỳ từ UI (ví dụ HeartsBadge) để cập nhật tim hồi phục theo
  /// thời gian thực, kể cả khi bé không rời khỏi màn hình đang xem.
  Future<void> refreshRegen() async {
    if (!_loaded) return;
    final changed = await _applyRegen();
    if (changed) notifyListeners();
  }

  Future<bool> _applyRegen() async {
    if (_lastLostAt == null || _hearts >= maxHearts) return false;
    final elapsedMs = DateTime.now().difference(_lastLostAt!).inMilliseconds;
    final regenerated = elapsedMs ~/ regenInterval.inMilliseconds;
    if (regenerated <= 0) return false;

    final updated = _hearts + regenerated;
    if (updated >= maxHearts) {
      _hearts = maxHearts;
      _lastLostAt = null;
    } else {
      _hearts = updated;
      // Giữ phần dư thời gian chưa đủ 1 khoảng hồi phục, thay vì reset hẳn
      // về "bây giờ" - tránh bé bị thiệt nếu app không mở đúng lúc tim vừa
      // hồi phục xong.
      _lastLostAt = _lastLostAt!.add(regenInterval * regenerated);
    }
    await _repository.setHearts(_hearts);
    await _repository.setLastLostAt(_lastLostAt);
    return true;
  }

  Future<void> loseHeart() async {
    if (!_loaded || _hearts <= 0) return;
    _hearts -= 1;
    _lastLostAt ??= DateTime.now();
    notifyListeners();
    await _repository.setHearts(_hearts);
    await _repository.setLastLostAt(_lastLostAt);
  }

  /// Dùng cho mục đích gỡ lỗi/cài đặt (ví dụ nút "hồi đầy tim" trong màn
  /// Settings nếu cần) - hiện chưa có UI gọi tới, để sẵn cho tương lai.
  Future<void> refillFull() async {
    _hearts = maxHearts;
    _lastLostAt = null;
    notifyListeners();
    await _repository.setHearts(_hearts);
    await _repository.setLastLostAt(null);
  }
}
