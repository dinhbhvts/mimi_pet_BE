import '../entities/lesson.dart';

/// Interface (tầng domain) mô tả cách app đọc danh sách bài học - không
/// quan tâm nội dung nằm trong file JSON, SQLite hay nguồn khác.
abstract class LessonRepository {
  Future<List<Lesson>> getAllLessons();
}
