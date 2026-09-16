import '../../exam_engine/question_bank_models.dart';

/// Interface (tầng domain) mô tả cách app đọc ngân hàng câu hỏi + cấu hình
/// đề thi thử (YLE/TOEIC) - không quan tâm nội dung nằm trong file JSON,
/// SQLite hay nguồn khác. Cùng tinh thần với [LessonRepository].
abstract class ExamRepository {
  Future<List<TrackLevelConfig>> getTrackConfigs();
  Future<QuestionBank> getQuestionBank();
}
