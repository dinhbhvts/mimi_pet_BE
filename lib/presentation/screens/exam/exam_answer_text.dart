import 'package:mimi_pet/exam_engine/question_bank_models.dart';

/// Chuyển 1 câu trả lời (toàn ID nội bộ, hoặc chữ bé gõ với câu điền từ)
/// thành chữ DỄ ĐỌC - mỗi dạng câu hỏi "dịch" khác nhau (xem ý nghĩa
/// `correctAnswer` theo từng [QuestionType] trong `question_bank_models.dart`).
/// Dùng chung cho panel giải thích lúc luyện tập và màn "Xem lại bài làm".
String answerText(Question q, List<String> answer) {
  String textOf(String id) => q.options
      .firstWhere((o) => o.id == id, orElse: () => AnswerOption(id: id, text: id))
      .text;

  switch (q.questionType) {
    case QuestionType.multipleChoice:
    case QuestionType.trueFalse:
      // Part 1/2 TOEIC ẩn chữ lúc làm bài (xem [Question.isAudioOnlyChoice])
      // nên cần kèm CHỮ CÁI để đối chiếu với nút đã bấm.
      if (q.isAudioOnlyChoice) {
        return answer.map((id) => '${id.toUpperCase()}. ${textOf(id)}').join(', ');
      }
      return answer.map(textOf).join(', ');
    case QuestionType.ordering:
    case QuestionType.listenAndColor:
    case QuestionType.listenAndNumber:
      return answer.map(textOf).join(' → ');
    case QuestionType.matching:
      return answer.map((pair) {
        final parts = pair.split(':');
        if (parts.length != 2) return pair;
        return '${textOf(parts[0])} - ${textOf(parts[1])}';
      }).join(', ');
    case QuestionType.fillBlank:
    case QuestionType.shortAnswer:
      return answer.join(' / ');
    case QuestionType.speakingPrompt:
      return '';
  }
}

String correctAnswerText(Question q) => answerText(q, q.correctAnswer);
