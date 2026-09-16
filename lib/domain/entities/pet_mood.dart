/// Các "tâm trạng" (biểu cảm) mà pet Mimi có thể có.
///
/// Đây là state machine trung tâm khiến Mimi "có cảm giác sống" khi tương
/// tác với bé. UI (PetAvatar) chỉ cần lắng nghe [PetMood] hiện tại để vẽ
/// đúng biểu cảm/hoạt ảnh — không cần biết vì sao Mimi lại ở trạng thái đó.
enum PetMood {
  /// Đứng yên, thở nhẹ - trạng thái mặc định khi không làm gì.
  idle,

  /// Đang lắng nghe bé nói (micro đang mở).
  listening,

  /// Đang "suy nghĩ" để đánh giá câu trả lời của bé.
  thinking,

  /// Đang nói (đọc câu hỏi / đọc từ / giải thích).
  talking,

  /// Bé trả lời đúng - vui mừng, nhảy lên.
  happy,

  /// Bé trả lời chưa đúng - Mimi động viên nhẹ nhàng để bé thử lại.
  /// (Cố tình không dùng "sad"/buồn để không tạo cảm giác tiêu cực cho bé.)
  encourage,
}

/// Thông tin hiển thị cho từng [PetMood].
///
/// [assetPath] là ảnh nhân vật thật (character sheet Mimi từ ChatGPT, đã
/// tách riêng từng pose - xem `assets/images/README.md`). [emoji] chỉ còn
/// dùng làm phương án dự phòng nếu ảnh lỗi/thiếu (xem `PetAvatar`).
class PetMoodVisual {
  final String assetPath;
  final String emoji;
  final String label;

  const PetMoodVisual({
    required this.assetPath,
    required this.emoji,
    required this.label,
  });

  static const Map<PetMood, PetMoodVisual> values = {
    PetMood.idle: PetMoodVisual(
      assetPath: 'assets/images/mimi_idle.png',
      emoji: '🐰',
      label: 'idle',
    ),
    PetMood.listening: PetMoodVisual(
      assetPath: 'assets/images/mimi_listening.png',
      emoji: '👂',
      label: 'listening',
    ),
    PetMood.thinking: PetMoodVisual(
      assetPath: 'assets/images/mimi_thinking.png',
      emoji: '🤔',
      label: 'thinking',
    ),
    PetMood.talking: PetMoodVisual(
      assetPath: 'assets/images/mimi_talking.png',
      emoji: '🗣️',
      label: 'talking',
    ),
    PetMood.happy: PetMoodVisual(
      assetPath: 'assets/images/mimi_happy.png',
      emoji: '🎉',
      label: 'happy',
    ),
    // Dùng lại pose Idle (bình tĩnh, trung tính) thay vì 1 pose "buồn" -
    // giữ đúng nguyên tắc không tạo cảm giác tiêu cực cho bé khi trả lời sai.
    PetMood.encourage: PetMoodVisual(
      assetPath: 'assets/images/mimi_encourage.png',
      emoji: '🐰',
      label: 'encourage',
    ),
  };
}
