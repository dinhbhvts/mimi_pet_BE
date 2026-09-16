import 'package:flutter/material.dart';

/// Kiểu prompt cho một từ vựng trong bài học.
enum PromptType {
  /// Mimi hỏi "What's this?" kèm hình/màu, bé phải nói ra từ tiếng Anh.
  identify,

  /// Mimi đọc mẫu từ trước, bé lặp lại theo (dùng cho hello/goodbye...).
  repeat,
}

/// Một từ vựng tiếng Anh trong bài học.
///
/// Word chỉ chứa dữ liệu thuần (entity) - không biết gì về UI hay logic
/// đánh giá đúng/sai (việc đó thuộc [EvaluateAnswer] ở tầng usecase).
@immutable
class Word {
  final String id;
  final String en;
  final String vi;

  /// Emoji minh hoạ, dùng khi [swatchColor] là null.
  final String? emoji;

  /// Dùng cho các từ chỉ màu sắc (red/blue/yellow...) - hiển thị 1 khối màu
  /// thay vì emoji.
  final Color? swatchColor;

  final PromptType promptType;

  /// Câu mẫu có chỗ trống, dùng cho dạng bài "Điền từ"
  /// (`QuestionKind.fillBlank` trong `LessonController`) - đánh dấu vị trí
  /// cần điền bằng `___` (3 dấu gạch dưới liền nhau), ví dụ `"I have a ___."`.
  /// Null nghĩa là từ này CHƯA có câu mẫu -> sẽ không bao giờ xuất hiện dạng
  /// bài điền từ (tự động bỏ qua, không lỗi).
  final String? sentenceTemplate;

  /// Câu hoàn chỉnh (đã tách sẵn thành từng từ) dùng cho dạng bài
  /// "Sắp xếp câu" (`QuestionKind.reorder`), ví dụ
  /// `['I', 'have', 'a', 'cat']`. Null hoặc ít hơn 3 từ thì từ này sẽ không
  /// xuất hiện dạng bài sắp xếp câu.
  final List<String>? sentenceWords;

  const Word({
    required this.id,
    required this.en,
    required this.vi,
    this.emoji,
    this.swatchColor,
    this.promptType = PromptType.identify,
    this.sentenceTemplate,
    this.sentenceWords,
  }) : assert(
         emoji != null || swatchColor != null,
         'Word cần ít nhất emoji hoặc swatchColor để hiển thị',
       );

  /// Câu Mimi sẽ hỏi trước khi bé trả lời (dạng bài nói/chọn trắc nghiệm).
  String get promptText {
    switch (promptType) {
      case PromptType.identify:
        return "What's this?";
      case PromptType.repeat:
        return 'Say this with me: $en!';
    }
  }

  /// Câu khen khi bé trả lời đúng.
  String get praiseText => 'Yes! ${en.toUpperCase()}! Great job!';

  /// Tách [sentenceTemplate] thành 2 nửa quanh chỗ trống `___`, để UI render
  /// "<nửa trước> [ô trống] <nửa sau>". Trả về `['', '']` nếu chưa có câu
  /// mẫu, hoặc `[sentenceTemplate!, '']` nếu câu mẫu không đúng định dạng
  /// (không chứa `___`) - phòng lỗi dữ liệu JSON thay vì crash app.
  List<String> get sentenceHalves {
    final template = sentenceTemplate;
    if (template == null) return const ['', ''];
    final parts = template.split('___');
    if (parts.length != 2) return [template, ''];
    return parts;
  }
}
