import 'package:flutter/foundation.dart';

import '../../domain/entities/picture_scene.dart';
import '../../domain/repositories/picture_scene_repository.dart';

/// Nạp danh sách "Bài tranh" (từ JSON, qua [PictureSceneRepository]) một lần
/// khi app khởi động - CÙNG PATTERN với `LessonsController`.
class PictureScenesController extends ChangeNotifier {
  PictureScenesController(this._repository);

  final PictureSceneRepository _repository;

  List<PictureScene> _scenes = const [];
  bool _loaded = false;
  String? _error;

  List<PictureScene> get scenes => _scenes;
  bool get loaded => _loaded;
  String? get error => _error;

  Future<void> load() async {
    try {
      _scenes = await _repository.getAllScenes();
      _error = null;
    } catch (e) {
      _scenes = const [];
      _error = 'Không tải được bài tranh: $e';
    }
    _loaded = true;
    notifyListeners();
  }
}
