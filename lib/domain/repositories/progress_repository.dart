/// Interface (tầng domain) mô tả những gì app cần lưu/đọc để theo dõi tiến
/// độ của bé - không quan tâm dữ liệu được lưu ở đâu (SharedPreferences,
/// file, cloud...). Tầng `data` sẽ cung cấp implementation thật.
abstract class ProgressRepository {
  Future<int> getStars();

  Future<int> addStars(int amount);

  Future<Set<String>> getMasteredWordIds();

  /// Đánh dấu 1 từ là bé đã trả lời đúng (dùng để tô sao/huy hiệu trong
  /// màn Rewards và để không hỏi lại quá nhiều từ bé đã thuộc).
  Future<void> markWordMastered(String wordId);

  Future<void> resetProgress();
}
