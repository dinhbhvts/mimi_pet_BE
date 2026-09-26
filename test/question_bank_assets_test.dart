import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mimi_pet/exam_engine/mock_test_engine.dart';
import 'package:mimi_pet/exam_engine/question_bank_models.dart';

/// Kiểm tra DỮ LIỆU THẬT trong assets/exam/: mỗi lần mở rộng ngân hàng câu
/// hỏi, test này bắt lỗi soạn đề (đáp án trỏ sai id, trùng id, thiếu câu cho
/// 1 phần thi...) trước khi bé/phụ huynh gặp phải trong app.
void main() {
  List<dynamic> readJson(String path) => jsonDecode(File(path).readAsStringSync()) as List<dynamic>;

  final raw = [
    ...readJson('assets/exam/yle_movers_flyers_seed.json'),
    ...readJson('assets/exam/toeic_seed.json'),
  ];
  final bank = QuestionBank.fromJsonList(raw);
  final configs = readJson('assets/exam/track_configs.json')
      .map((e) => TrackLevelConfig.fromJson(e as Map<String, dynamic>))
      .toList();

  test('id câu hỏi không trùng nhau', () {
    final ids = raw.map((e) => (e as Map<String, dynamic>)['id']).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('đáp án đúng của mọi câu đều trỏ tới lựa chọn có thật', () {
    final problems = <String>[];
    for (final q in bank.questions) {
      final optionIds = q.options.map((o) => o.id).toSet();
      switch (q.questionType) {
        case QuestionType.multipleChoice:
        case QuestionType.trueFalse:
          if (q.correctAnswer.length != 1 || !optionIds.contains(q.correctAnswer.single)) problems.add(q.id);
        case QuestionType.ordering:
        case QuestionType.listenAndColor:
        case QuestionType.listenAndNumber:
          if (q.correctAnswer.toSet().length != q.options.length ||
              !optionIds.containsAll(q.correctAnswer)) {
            problems.add(q.id);
          }
        case QuestionType.matching:
          for (final pair in q.correctAnswer) {
            final parts = pair.split(':');
            if (parts.length != 2 || !optionIds.containsAll(parts)) problems.add(q.id);
          }
        case QuestionType.fillBlank:
        case QuestionType.shortAnswer:
          if (q.correctAnswer.isEmpty || q.correctAnswer.any((a) => a.trim().isEmpty)) problems.add(q.id);
        case QuestionType.speakingPrompt:
          break;
      }
      // Tự kiểm tra lại bằng đúng hàm chấm của app: nộp đáp án đúng phải ra đúng.
      if (q.questionType != QuestionType.speakingPrompt && !isAnswerCorrect(q, q.correctAnswer.take(
          q.questionType == QuestionType.fillBlank || q.questionType == QuestionType.shortAnswer ? 1 : q.correctAnswer.length).toList())) {
        problems.add('${q.id} (tự chấm sai)');
      }
    }
    expect(problems, isEmpty);
  });

  test('mọi đề thi thử đều đủ số câu cho từng phần', () {
    final engine = MockTestEngine(bank);
    for (final config in configs) {
      final expected = config.sections.fold<int>(0, (sum, s) => sum + s.questionCount);
      for (var seed = 0; seed < 5; seed++) {
        final session = engine.startSession(config, mode: TestMode.mockTest, seed: seed);
        expect(session.questions.length, expected, reason: '${config.track.name} ${config.level}');
        expect(session.questions.map((q) => q.id).toSet().length, expected,
            reason: 'trùng câu trong 1 đề ${config.level}');
      }
    }
  });
}
