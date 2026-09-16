import 'package:flutter/foundation.dart';

import '../../domain/repositories/progress_repository.dart';

/// Quản lý số sao và danh sách từ bé đã thuộc, đọc/ghi qua
/// [ProgressRepository] (data layer). UI không bao giờ đọc/ghi
/// SharedPreferences trực tiếp - luôn đi qua controller này.
class ProgressController extends ChangeNotifier {
  ProgressController(this._repository);

  final ProgressRepository _repository;

  int _stars = 0;
  Set<String> _masteredWordIds = {};
  bool _loaded = false;

  int get stars => _stars;
  Set<String> get masteredWordIds => _masteredWordIds;
  bool get loaded => _loaded;

  Future<void> load() async {
    _stars = await _repository.getStars();
    _masteredWordIds = await _repository.getMasteredWordIds();
    _loaded = true;
    notifyListeners();
  }

  Future<void> addStars(int amount) async {
    _stars = await _repository.addStars(amount);
    notifyListeners();
  }

  Future<void> markWordMastered(String wordId) async {
    await _repository.markWordMastered(wordId);
    _masteredWordIds = {..._masteredWordIds, wordId};
    notifyListeners();
  }

  Future<void> resetProgress() async {
    await _repository.resetProgress();
    await load();
  }
}
