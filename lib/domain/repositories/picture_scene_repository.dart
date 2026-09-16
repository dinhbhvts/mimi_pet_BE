import '../entities/picture_scene.dart';

/// Nguồn dữ liệu cho "Bài tranh" (xem [PictureScene]) - tách interface riêng
/// theo đúng pattern [LessonRepository] để dễ thay đổi cách lưu trữ sau này
/// (ví dụ SQLite) mà không đụng tới tầng trên.
abstract class PictureSceneRepository {
  Future<List<PictureScene>> getAllScenes();
}
