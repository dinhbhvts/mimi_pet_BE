import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/grammar_lessons.dart';
import 'package:mimi_pet/domain/repositories/exam_repository.dart';
import 'package:mimi_pet/exam_engine/question_bank_models.dart';
import 'package:mimi_pet/presentation/screens/grammar/grammar_screens.dart';
import 'package:mimi_pet/presentation/state/exam_catalog_controller.dart';
import 'package:mimi_pet/presentation/state/mistake_book_controller.dart';
import 'package:mimi_pet/services/tts_service.dart';

QuestionBank _realBank() {
  List<dynamic> read(String p) => jsonDecode(File(p).readAsStringSync()) as List<dynamic>;
  return QuestionBank.fromJsonList([
    ...read('assets/exam/yle_movers_flyers_seed.json'),
    ...read('assets/exam/toeic_seed.json'),
  ]);
}

class _FakeRepo implements ExamRepository {
  _FakeRepo(this.bank);
  final QuestionBank bank;
  @override
  Future<List<TrackLevelConfig>> getTrackConfigs() async => const [];
  @override
  Future<QuestionBank> getQuestionBank() async => bank;
}

class _MemStorage implements MistakeStorage {
  final data = <String, dynamic>{};
  @override
  Map<String, dynamic> loadAll() => Map.of(data);
  @override
  void save(String questionId, Map<String, dynamic> json) => data[questionId] = json;
  @override
  void remove(String questionId) => data.remove(questionId);
}

void main() {
  final bank = _realBank();

  test('id bài không trùng; mỗi bài có đủ ví dụ và ít nhất 20 câu luyện trong ngân hàng', () {
    final ids = GrammarLessons.all.map((l) => l.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final lesson in GrammarLessons.all) {
      expect(lesson.points, isNotEmpty, reason: lesson.id);
      expect(lesson.examples.where((e) => e.correct).length, greaterThanOrEqualTo(2), reason: lesson.id);
      final count = bank.questions.where(lesson.matches).length;
      expect(count, greaterThanOrEqualTo(20), reason: '${lesson.id} chỉ có $count câu luyện');
    }
  });

  test('mọi chủ đề luyện của bài đều có thật trong ngân hàng (không gõ sai tên chủ đề)', () {
    final topics = bank.questions.map((q) => q.topic).toSet();
    for (final lesson in GrammarLessons.all) {
      for (final t in lesson.practiceTopics) {
        expect(topics, contains(t), reason: '${lesson.id}: $t');
      }
    }
  });

  test('có bài cho cả 3 cấp và câu hỏi tìm được bài liên quan', () {
    expect(GrammarLessons.forLevel(ExamTrack.yle, 'Movers'), hasLength(11));
    expect(GrammarLessons.forLevel(ExamTrack.yle, 'Flyers'), hasLength(11));
    expect(GrammarLessons.forLevel(ExamTrack.toeic, 'Standard'), hasLength(12));
    final pastSimple = bank.questions.firstWhere((q) => q.level == 'Movers' && q.topic == 'Past Simple');
    expect(GrammarLessons.forQuestion(pastSimple)!.id, 'mov_past');
    final wordForm = bank.questions.firstWhere((q) => q.topic == 'Word form');
    expect(GrammarLessons.forQuestion(wordForm)!.id, 'toeic_word_form');
    final vocab = bank.questions.firstWhere((q) => q.skill == Skill.vocabulary);
    expect(GrammarLessons.forQuestion(vocab), isNull);
  });

  testWidgets('màn bài học hiện công thức, ví dụ, nút luyện và nút ôn câu sai của chủ đề', (tester) async {
    // Màn hình cao để cả bài hiện một lượt (ListView chỉ dựng phần đang thấy).
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final catalog = ExamCatalogController(_FakeRepo(bank));
    await catalog.load();
    final book = MistakeBookController(_MemStorage());
    final lesson = GrammarLessons.all.firstWhere((l) => l.id == 'mov_past');
    final wrongQ = bank.questions.firstWhere(lesson.matches);
    book.recordResult(wrongQ, false);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: catalog),
        ChangeNotifierProvider.value(value: book),
        Provider<TtsService>(create: (_) => TtsService()),
      ],
      child: MaterialApp(home: GrammarLessonScreen(lesson: lesson)),
    ));
    expect(find.text('Động từ bất quy tắc'), findsOneWidget);
    expect(find.textContaining('Luyện 10 câu'), findsOneWidget);
    expect(find.textContaining('Ôn lại 1 câu sai'), findsOneWidget);
    // Câu ví dụ SAI không có nút nghe.
    expect(find.byTooltip('Nghe câu ví dụ'), findsNWidgets(lesson.examples.where((e) => e.correct).length));
  });
}
