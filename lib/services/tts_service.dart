import 'package:flutter_tts/flutter_tts.dart';

/// Bọc [FlutterTts] để phần còn lại của app chỉ cần gọi [speak] mà không
/// phải biết chi tiết cấu hình giọng đọc (tốc độ chậm, phù hợp cho bé 8
/// tuổi mới học tiếng Anh).
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await _tts.setLanguage('en-US');
    // Chậm hơn tốc độ mặc định để bé nghe rõ từng âm.
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.15);
    await _tts.setVolume(1.0);
  }

  /// Đọc [text] bằng tiếng Anh và đợi cho tới khi đọc xong.
  ///
  /// [rate]/[pitch] cho phép GHI ĐÈ tạm thời tốc độ/cao độ mặc định (chậm +
  /// cao giọng, hợp với bé 8 tuổi mới học) - dùng khi cần giọng đọc tự nhiên
  /// hơn, ví dụ mô phỏng hội thoại/thông báo trong đề TOEIC (xem
  /// `exam_screen.dart`). Sau khi đọc xong, service tự trả lại tốc độ/cao độ
  /// mặc định để không ảnh hưởng các lượt gọi [speak] khác (Mimi trò
  /// chuyện, bài học...) dùng chung 1 instance này.
  Future<void> speak(String text, {double? rate, double? pitch}) async {
    await _ensureInitialized();
    await _tts.stop();
    await _tts.awaitSpeakCompletion(true);
    if (rate != null) await _tts.setSpeechRate(rate);
    if (pitch != null) await _tts.setPitch(pitch);
    await _tts.speak(text);
    if (rate != null) await _tts.setSpeechRate(0.42);
    if (pitch != null) await _tts.setPitch(1.15);
  }

  Future<void> stop() => _tts.stop();

  void dispose() {
    _tts.stop();
  }
}
