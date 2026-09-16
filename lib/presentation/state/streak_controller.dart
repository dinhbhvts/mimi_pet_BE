import 'package:flutter/foundation.dart';

import '../../domain/repositories/streak_repository.dart';

/// Quản lý chuỗi ngày học liên tiếp (streak) của bé - cùng nguyên tắc với
/// [ProgressController]/[HeartsController]: UI không đọc/ghi SharedPreferences
/// trực tiếp, luôn đi qua controller này.
class StreakController extends ChangeNotifier {
  StreakController(this._repository);

  final StreakRepository _repository;

  int _streak = 0;
  String? _lastActiveDate;
  bool _loaded = false;

  int get streak => _streak;
  bool get loaded => _loaded;

  Future<void> load() async {
    _streak = await _repository.getCurrentStreak();
    _lastActiveDate = await _repository.getLastActiveDate();
    _loaded = true;
    notifyListeners();
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Gọi khi bé hoàn thành 1 bài học - cập nhật streak theo luật:
  /// - Hôm nay đã tính rồi (đã học lần trước trong ngày) -> không đổi, trả
  ///   về `null` (không có gì mới để ăn mừng).
  /// - Hôm qua có học -> streak + 1 (nối chuỗi).
  /// - Bỏ lỡ ít nhất 1 ngày (hoặc lần đầu học) -> streak về 1 (chuỗi mới).
  ///
  /// Trả về streak MỚI (sau khi cập nhật) nếu hôm nay là lần đầu ghi nhận -
  /// dùng để [LessonController] biết khi nào cần báo cho UI hiện hiệu ứng ăn
  /// mừng streak mới (xem `LessonController._goToNextWord`).
  Future<int?> recordActivityToday() async {
    if (!_loaded) return null;
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    if (_lastActiveDate == todayKey) return null;

    if (_lastActiveDate != null) {
      final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));
      _streak = (_lastActiveDate == yesterdayKey) ? _streak + 1 : 1;
    } else {
      _streak = 1;
    }
    _lastActiveDate = todayKey;
    notifyListeners();
    await _repository.setCurrentStreak(_streak);
    await _repository.setLastActiveDate(_lastActiveDate);
    return _streak;
  }
}
