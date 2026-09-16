/// Interface (tầng domain) mô tả cách app lưu/đọc số tim (lives) của bé và
/// thời điểm bắt đầu hồi phục tim gần nhất - không quan tâm lưu ở đâu.
/// Cùng nguyên tắc với [ProgressRepository]/[PetCharacterRepository].
abstract class HeartsRepository {
  Future<int> getHearts();

  Future<void> setHearts(int hearts);

  /// Thời điểm bé mất tim gần nhất mà tính từ đó vẫn còn tim đang chờ hồi
  /// phục - null nghĩa là tim đang đầy (không có gì để hồi phục).
  Future<DateTime?> getLastLostAt();

  Future<void> setLastLostAt(DateTime? time);
}
