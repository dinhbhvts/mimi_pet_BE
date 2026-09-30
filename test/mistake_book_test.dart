import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/exam_engine/mock_test_engine.dart';
import 'package:mimi_pet/exam_engine/question_bank_models.dart';
import 'package:mimi_pet/presentation/screens/exam/exam_answer_text.dart';
import 'package:mimi_pet/presentation/screens/exam/exam_review_screen.dart';
import 'package:mimi_pet/presentation/state/exam_session_controller.dart';
import 'package:mimi_pet/presentation/state/mistake_book_controller.dart';
import 'package:mimi_pet/services/tts_service.dart';

class _MemStorage implements MistakeStorage {
  final data = <String, dynamic>{};
  @override
  Map<String, dynamic> loadAll() => Map.of(data);
  @override
  void save(String questionId, Map<String, dynamic> json) => data[questionId] = json;
  @override
  void remove(String questionId) => data.remove(questionId);
}

Question _mc(String id, {String level = 'Movers', String topic = 'Animals'}) => Question(
      id: id,
      track: ExamTrack.yle,
      level: level,
      skill: Skill.vocabulary,
      topic: topic,
      questionType: QuestionType.multipleChoice,
      prompt: 'Question $id',
      options: const [AnswerOption(id: 'a', text: 'cat'), AnswerOption(id: 'b', text: 'dog')],
      correctAnswer: const ['a'],
      explanation: 'Giải thích $id',
    );

void main() {
  final t0 = DateTime(2026, 10, 1, 9);

  group('MistakeBookController', () {
    test('sai -> vào sổ, đến hạn sau 1 ngày; đúng -> 3 ngày; đúng 2 lần liền -> rời sổ', () {
      final storage = _MemStorage();
      final book = MistakeBookController(storage);
      final q = _mc('q1');

      book.recordResult(q, false, now: t0);
      expect(book.contains('q1'), isTrue);
      expect(book.dueCountFor(ExamTrack.yle, 'Movers', now: t0), 0);
      expect(book.dueCountFor(ExamTrack.yle, 'Movers', now: t0.add(const Duration(days: 1))), 1);

      final t1 = t0.add(const Duration(days: 1));
      expect(book.recordResult(q, true, now: t1), isFalse);
      expect(book.entryFor('q1')!.streak, 1);
      expect(book.entryFor('q1')!.dueAt, t1.add(const Duration(days: 3)));

      expect(book.recordResult(q, true, now: t1.add(const Duration(days: 3))), isTrue);
      expect(book.contains('q1'), isFalse);
      expect(storage.data, isEmpty);
    });

    test('sai lại giữa chừng thì quay về đầu và tăng số lần sai', () {
      final book = MistakeBookController(_MemStorage());
      final q = _mc('q1');
      book.recordResult(q, false, now: t0);
      book.recordResult(q, true, now: t0);
      book.recordResult(q, false, now: t0);
      expect(book.entryFor('q1')!.streak, 0);
      expect(book.entryFor('q1')!.wrongCount, 2);
    });

    test('làm đúng câu không có trong sổ thì không thêm vào sổ; câu nói bị bỏ qua', () {
      final book = MistakeBookController(_MemStorage());
      book.recordResult(_mc('q1'), true, now: t0);
      expect(book.contains('q1'), isFalse);
      const speaking = Question(
        id: 's1',
        track: ExamTrack.yle,
        level: 'Movers',
        skill: Skill.speaking,
        questionType: QuestionType.speakingPrompt,
        prompt: 'Tell me about your family.',
        correctAnswer: [],
      );
      book.recordResult(speaking, false, now: t0);
      expect(book.contains('s1'), isFalse);
    });

    test('nạp lại từ nơi lưu (đồng bộ giữa các thiết bị)', () {
      final storage = _MemStorage();
      MistakeBookController(storage).recordResult(_mc('q1'), false, now: t0);
      final reloaded = MistakeBookController(storage);
      expect(reloaded.contains('q1'), isTrue);
      expect(reloaded.entryFor('q1')!.wrongCount, 1);
    });

    test('câu ôn: câu đến hạn trước, sai nhiều trước; lọc đúng level; bỏ câu không còn trong ngân hàng', () {
      final book = MistakeBookController(_MemStorage());
      final a = _mc('a'), b = _mc('b'), c = _mc('c'), flyers = _mc('f', level: 'Flyers');
      book.recordResult(a, false, now: t0);
      book.recordResult(b, false, now: t0);
      book.recordResult(b, false, now: t0);
      book.recordResult(c, false, now: t0.add(const Duration(days: 5)));
      book.recordResult(flyers, false, now: t0);
      book.recordResult(_mc('gone'), false, now: t0);
      final bank = QuestionBank([a, b, c, flyers]);
      final now = t0.add(const Duration(days: 2));

      final all = book.questionsToReview(bank, ExamTrack.yle, 'Movers', now: now);
      expect(all.map((q) => q.id), ['b', 'a', 'c']);
      final due = book.questionsToReview(bank, ExamTrack.yle, 'Movers', dueOnly: true, now: now);
      expect(due.map((q) => q.id), ['b', 'a']);
    });
  });

  group('ExamSessionController ghi nhận kết quả', () {
    const config = TrackLevelConfig(
      track: ExamTrack.yle,
      level: 'Movers',
      displayName: 'Ôn câu sai',
      sections: [],
      scoringStrategyId: 'rawPercentage',
    );

    test('mỗi câu chỉ tính 1 lần: sửa đáp án rồi kiểm tra lại không được tính', () {
      final graded = <(String, bool)>[];
      final q1 = _mc('q1'), q2 = _mc('q2'), q3 = _mc('q3');
      final ctrl = ExamSessionController(
        bank: QuestionBank([q1, q2, q3]),
        config: config,
        mode: TestMode.practice,
        fixedQuestions: [q1, q2, q3],
        onAnswerGraded: (q, correct) => graded.add((q.id, correct)),
      );
      expect(ctrl.questions.map((q) => q.id), ['q1', 'q2', 'q3']);

      ctrl.answerCurrent(['b']);
      ctrl.checkAnswer();
      ctrl.answerCurrent(['a']);
      ctrl.checkAnswer();
      expect(graded, [('q1', false)]);

      ctrl.goNext();
      ctrl.answerCurrent(['a']); // q2 trả lời nhưng không bấm kiểm tra
      ctrl.goNext(); // q3 bỏ trống
      ctrl.finish();
      expect(graded, [('q1', false), ('q2', true)]);
      ctrl.dispose();
    });
  });

  test('đổi đáp án thành chữ dễ đọc', () {
    final q = _mc('q1');
    expect(answerText(q, ['b']), 'dog');
    expect(correctAnswerText(q), 'cat');
    expect(reviewStatusOf(q, null), ReviewStatus.skipped);
    expect(reviewStatusOf(q, ['b']), ReviewStatus.wrong);
    expect(reviewStatusOf(q, ['a']), ReviewStatus.correct);
  });

  testWidgets('màn xem lại: mặc định lọc câu sai, mở ra thấy đáp án đúng và giải thích', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final questions = [_mc('q1'), _mc('q2'), _mc('q3')];
    await tester.pumpWidget(Provider<TtsService>(
      create: (_) => TtsService(),
      child: MaterialApp(
        home: ExamReviewScreen(
          title: 'Movers',
          questions: questions,
          answers: const {'q1': ['a'], 'q2': ['b'], 'q3': null},
        ),
      ),
    ));
    expect(find.text('Câu 1 · Đúng'), findsNothing);
    expect(find.text('Câu 2 · Sai'), findsOneWidget);
    expect(find.text('Câu 3 · Bỏ trống'), findsOneWidget);

    await tester.tap(find.text('Câu 2 · Sai'));
    await tester.pumpAndSettle();
    expect(find.textContaining('dog'), findsOneWidget);
    expect(find.textContaining('cat'), findsOneWidget);
    expect(find.text('💡 Giải thích q2'), findsOneWidget);

    await tester.tap(find.text('Tất cả (3)'));
    await tester.pumpAndSettle();
    expect(find.text('Câu 1 · Đúng'), findsOneWidget);
  });
}
