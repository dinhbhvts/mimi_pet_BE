import 'package:flutter/foundation.dart';

import '../../domain/repositories/exam_repository.dart';
import '../../exam_engine/question_bank_models.dart';

/// Nạp danh sách đề thi thử (YLE Movers/Flyers, TOEIC Full Test) + ngân hàng
/// câu hỏi một lần khi app khởi động - cung cấp cho ExamHomeScreen. Cùng
/// tinh thần với [LessonsController], tách riêng vì đây là 1 domain khác
/// (đề thi thử) chứ không phải bài học từ vựng thường ngày.
class ExamCatalogController extends ChangeNotifier {
  ExamCatalogController(this._repository);

  final ExamRepository _repository;

  List<TrackLevelConfig> _configs = const [];
  QuestionBank? _bank;
  bool _loaded = false;
  String? _error;

  List<TrackLevelConfig> get configs => _configs;
  QuestionBank? get bank => _bank;
  bool get loaded => _loaded;
  String? get error => _error;

  Future<void> load() async {
    try {
      _configs = await _repository.getTrackConfigs();
      _bank = await _repository.getQuestionBank();
      _error = null;
    } catch (e) {
      _configs = const [];
      _bank = null;
      _error = 'Không tải được đề thi: $e';
    }
    _loaded = true;
    notifyListeners();
  }
}
