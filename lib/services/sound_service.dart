import 'package:audioplayers/audioplayers.dart';

/// Phát hiệu ứng âm thanh ngắn (đúng/sai/hoàn thành bài/mất tim).
///
/// Tạo 1 [AudioPlayer] MỚI cho mỗi lần phát thay vì dùng chung 1 player -
/// vì các hiệu ứng này rất ngắn và có thể chồng lên nhau (ví dụ bé chọn sai
/// liên tiếp), dùng chung 1 player sẽ làm âm sau cắt ngang âm trước.
/// Player tự giải phóng (`dispose`) ngay sau khi phát xong.
///
/// Toàn bộ file .wav trong assets/sounds/ do app TỰ TỔNG HỢP bằng script
/// Python (xem README) - không dùng âm thanh có bản quyền của bên thứ ba.
class SoundService {
  SoundService({this._enabled = true});

  bool _enabled;

  bool get enabled => _enabled;
  set enabled(bool value) => _enabled = value;

  Future<void> _play(String assetFileName) async {
    if (!_enabled) return;
    try {
      final player = AudioPlayer();
      // "Fire and forget" có chủ đích: không await việc dispose, để không
      // trì hoãn hàm _play khi âm thanh đang phát.
      player.onPlayerComplete.first.then((_) => player.dispose()).catchError((_) {});
      await player.play(AssetSource('sounds/$assetFileName'));
    } catch (_) {
      // Thiết bị không phát được âm thanh (bị tắt tiếng, thiếu codec...) -
      // bỏ qua, không được làm gián đoạn luồng học của bé.
    }
  }

  Future<void> playCorrect() => _play('correct.wav');
  Future<void> playWrong() => _play('wrong.wav');
  Future<void> playComplete() => _play('complete.wav');
  Future<void> playHeartLost() => _play('heart_lost.wav');

  /// Âm thanh riêng khi bé đạt 1 mốc streak MỚI (xem
  /// `StreakController.recordActivityToday`/`showStreakCelebration`) - khác
  /// `playComplete()` (phát cho MỌI lần hoàn thành bài, kể cả không có gì
  /// mới về streak) để lúc streak tăng cảm giác đặc biệt/nổi bật hơn hẳn.
  Future<void> playStreak() => _play('streak.wav');
}
