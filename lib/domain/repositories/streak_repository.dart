/// Interface (tầng domain) mô tả cách app lưu/đọc chuỗi ngày học liên tiếp
/// (streak) của bé - không quan tâm lưu ở đâu.
abstract class StreakRepository {
  Future<int> getCurrentStreak();

  Future<void> setCurrentStreak(int days);

  /// Ngày gần nhất bé hoàn thành ít nhất 1 bài học, dạng 'yyyy-MM-dd' (chỉ
  /// so ngày, không quan tâm giờ/múi giờ) - null nếu chưa học ngày nào.
  Future<String?> getLastActiveDate();

  Future<void> setLastActiveDate(String? date);
}
