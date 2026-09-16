import 'package:flutter/foundation.dart';

/// Kiểu câu hỏi cho 1 câu hỏi trong "Bài tranh" - KHÁC [QuestionKind] của
/// `LessonController` (bài tranh tập trung vào HIỂU CÂU/miêu tả 1 KHUNG
/// CẢNH nhiều chi tiết, thay vì nhận biết 1 từ vựng đơn như Lesson).
enum SceneQuestionKind {
  /// Trắc nghiệm - bé chạm chọn 1 trong nhiều lựa chọn văn bản.
  choice,

  /// Đúng/Sai - biến thể của [choice] nhưng luôn đúng 2 lựa chọn cố định
  /// "True"/"False", tách riêng để UI hiển thị gọn hơn (2 nút to thay vì
  /// danh sách).
  trueFalse,

  /// Bé NÓI câu trả lời (so khớp giọng nói qua `EvaluateAnswer`) - dùng cho
  /// câu hỏi kiểu "Say the color of the kite in English."
  speak,
}

/// 1 câu hỏi thuộc về 1 [PictureScene].
@immutable
class SceneQuestion {
  final String id;

  /// Câu hỏi tiếng Anh Mimi sẽ đọc to, ví dụ "How many birds are there?".
  final String prompt;

  final SceneQuestionKind kind;

  /// Danh sách lựa chọn hiển thị (đã gồm cả đáp án đúng) - CHỈ dùng cho
  /// [SceneQuestionKind.choice]. Rỗng với `trueFalse`/`speak` (UI tự vẽ 2 nút
  /// True/False, hoặc nút mic tương ứng).
  final List<String> options;

  /// Đáp án đúng:
  /// - `choice`: TRÙNG KHỚP CHÍNH XÁC 1 trong [options] (so sánh nguyên
  ///   văn, xem `ScenePlayController.submitChoice`).
  /// - `trueFalse`: đúng 1 trong 2 giá trị `"True"`/`"False"`.
  /// - `speak`: 1 từ/cụm từ tiếng Anh ngắn, chấm khoan dung qua
  ///   `EvaluateAnswer.call`/`callPhrase` (không cần khớp tuyệt đối).
  final String answer;

  const SceneQuestion({
    required this.id,
    required this.prompt,
    required this.kind,
    this.options = const [],
    required this.answer,
  });
}

/// 1 "bài tranh" - 1 khung cảnh minh hoạ (vector vẽ bằng CustomPainter, xem
/// `scene_illustrations.dart`) kèm nhiều [SceneQuestion] xoay quanh khung
/// cảnh đó. Đây là loại nội dung MỚI (khác [Lesson]) giúp bé luyện HIỂU CÂU/
/// miêu tả cảnh vật bằng tiếng Anh, gần với dạng bài "miêu tả tranh" trong đề
/// thi Cambridge YLE Movers/Flyers, thay vì chỉ nhận biết từ vựng đơn lẻ.
///
/// KHÔNG dùng chung [Lesson]/[Word] vì cấu trúc dữ liệu khác hẳn: 1 [Lesson]
/// là danh sách TỪ ĐƠN LẺ độc lập nhau, còn 1 [PictureScene] là 1 KHUNG CẢNH
/// DUY NHẤT với nhiều câu hỏi cùng xoay quanh nó - "bài tranh" cũng KHÔNG trừ
/// tim khi trả lời sai (xem `ScenePlayController`) vì mục đích là luyện tập/
/// khám phá, không phải kiểm tra như Lesson.
@immutable
class PictureScene {
  final String id;
  final String title;
  final String titleVi;

  /// Id minh hoạ - khớp với 1 key trong `sceneIllustrationPainters`
  /// (`scene_illustrations.dart`). Tách riêng khỏi [id] của chính scene (dù
  /// hiện tại luôn trùng nhau) để về sau có thể nhiều scene dùng chung 1
  /// minh hoạ, hoặc đổi minh hoạ mà không phải đổi id/tiến trình đã lưu.
  final String illustrationId;

  final List<SceneQuestion> questions;

  const PictureScene({
    required this.id,
    required this.title,
    required this.titleVi,
    required this.illustrationId,
    required this.questions,
  });
}
