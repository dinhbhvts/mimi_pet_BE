import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/pet_mood.dart';

/// Điều khiển "tâm trạng" hiện tại của Mimi. Mọi widget hiển thị Mimi
/// (PetAvatar) chỉ cần lắng nghe [mood] qua Provider - không cần biết vì sao
/// mood thay đổi (bài học, mini-game, hay chỉ vuốt ve trên Home).
class PetController extends ChangeNotifier {
  PetMood _mood = PetMood.idle;
  Timer? _autoIdleTimer;
  bool _disposed = false;

  PetMood get mood => _mood;

  /// Đổi mood. Nếu truyền [autoIdleAfter], Mimi sẽ tự quay lại trạng thái
  /// idle sau khoảng thời gian đó (hữu ích cho các mood tức thời như
  /// happy/encourage khi không có ai chủ động set lại).
  void setMood(PetMood mood, {Duration? autoIdleAfter}) {
    _autoIdleTimer?.cancel();
    _mood = mood;
    if (!_disposed) notifyListeners();

    if (autoIdleAfter != null) {
      _autoIdleTimer = Timer(autoIdleAfter, () {
        if (_disposed) return;
        _mood = PetMood.idle;
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _autoIdleTimer?.cancel();
    super.dispose();
  }
}
