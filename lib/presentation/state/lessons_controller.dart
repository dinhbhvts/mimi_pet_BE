import 'package:flutter/foundation.dart';

import '../../domain/entities/lesson.dart';
import '../../domain/repositories/lesson_repository.dart';

/// Nạp danh sách bài học (từ JSON, qua [LessonRepository]) một lần khi app
/// khởi động, cung cấp cho PlayScreen/RewardsScreen.
class LessonsController extends ChangeNotifier {
  LessonsController(this._repository);

  final LessonRepository _repository;

  List<Lesson> _lessons = const [];
  bool _loaded = false;
  String? _error;

  List<Lesson> get lessons => _lessons;
  bool get loaded => _loaded;
  String? get error => _error;

  Future<void> load() async {
    try {
      _lessons = await _repository.getAllLessons();
      _error = null;
    } catch (e) {
      _lessons = const [];
      _error = 'Không tải được bài học: $e';
    }
    _loaded = true;
    notifyListeners();
  }
}
