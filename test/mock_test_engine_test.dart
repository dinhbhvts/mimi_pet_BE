import 'package:flutter_test/flutter_test.dart';

import 'package:mimi_pet/exam_engine/mock_test_engine.dart';
import 'package:mimi_pet/exam_engine/question_bank_models.dart';

Question _ordering(List<String> words) => Question(
      id: 'q',
      track: ExamTrack.yle,
      level: 'Flyers',
      skill: Skill.writing,
      questionType: QuestionType.ordering,
      prompt: 'Put the words in order.',
      options: [
        for (var i = 0; i < words.length; i++) AnswerOption(id: 'w${i + 1}', text: words[i]),
      ],
      correctAnswer: [for (var i = 0; i < words.length; i++) 'w${i + 1}'],
    );

void main() {
  group('isAnswerCorrect - ordering', () {
    final q = _ordering(['Before', 'we', 'left', ',', 'we', 'checked']);

    test('đúng thứ tự id là đúng', () {
      expect(isAnswerCorrect(q, ['w1', 'w2', 'w3', 'w4', 'w5', 'w6']), isTrue);
    });

    test('đổi chỗ 2 mảnh trùng chữ vẫn ra đúng câu nên vẫn đúng', () {
      expect(isAnswerCorrect(q, ['w1', 'w5', 'w3', 'w4', 'w2', 'w6']), isTrue);
    });

    test('sai thứ tự chữ là sai', () {
      expect(isAnswerCorrect(q, ['w2', 'w1', 'w3', 'w4', 'w5', 'w6']), isFalse);
    });
  });

  test('câu gõ: bỏ qua hoa/thường, khoảng trắng thừa, dấu chấm cuối và dấu nháy cong của bàn phím iPhone', () {
    expect(normalizeTypedAnswer('  Don’t   Water. '), "don't water");
    expect(normalizeTypedAnswer("won't she"), normalizeTypedAnswer('Won‘t she!'));
    expect(normalizeTypedAnswer('7 P.M.'), normalizeTypedAnswer('7 p.m'));
  });
}
