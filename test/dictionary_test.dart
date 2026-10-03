import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/domain/entities/dictionary_lookup.dart';
import 'package:mimi_pet/presentation/screens/dictionary/dictionary_screen.dart';
import 'package:mimi_pet/presentation/state/dictionary_controller.dart';
import 'package:mimi_pet/services/dictionary_service.dart';
import 'package:mimi_pet/services/gemini_dictionary_service.dart';
import 'package:mimi_pet/services/speech_service.dart';
import 'package:mimi_pet/services/tts_service.dart';

void main() {
  group('Đọc kết quả tra từ', () {
    test('JSON đầy đủ: phiên âm (tự thêm /.../), từ loại, nghĩa khác (bỏ trùng nghĩa chính), ví dụ, đồng nghĩa', () {
      final out = GeminiDictionaryService.parseLookup('deadline', '''
{"kind":"word","english":"deadline","vietnamese":"hạn chót","ipa":"ˈded.laɪn","part_of_speech":"danh từ",
 "meanings":["hạn chót","thời hạn cuối"],"examples":[{"en":"The deadline is Friday.","vi":"Hạn chót là thứ Sáu."},{"en":""}],
 "synonyms":["due date","time limit","due date"],"note":"meet a deadline = kịp hạn"}''');
      final r = out.result!;
      expect(r.ipa, '/ˈded.laɪn/');
      expect(r.partOfSpeech, 'danh từ');
      expect(r.meanings, ['thời hạn cuối']);
      expect(r.examples.single.english, 'The deadline is Friday.');
      expect(r.synonyms, ['due date', 'time limit']);
      expect(r.note, contains('meet a deadline'));
      expect(r.isSentence, isFalse);
    });

    test('câu: không có phiên âm/ví dụ, ghi chú là cấu trúc câu', () {
      final r = GeminiDictionaryService.parseLookup('Tôi thích mèo', '{"kind":"sentence","english":"I like cats.",'
          '"vietnamese":"Tôi thích mèo.","ipa":"/aɪ/","examples":[{"en":"x","vi":"y"}],"note":"S + like + N"}').result!;
      expect(r.isSentence, isTrue);
      expect(r.ipa, isEmpty);
      expect(r.examples, isEmpty);
      expect(r.note, 'S + like + N');
    });

    test('vô nghĩa -> not_found; định dạng 2 dòng cũ vẫn đọc được; rác -> parse_error', () {
      expect(GeminiDictionaryService.parseLookup('asdf', '{"kind":"unknown","english":"-","vietnamese":"-"}').error,
          'not_found');
      final legacy = GeminiDictionaryService.parseLookup('cat', '**EN:** cat\nVI: con mèo').result!;
      expect(legacy.english, 'cat');
      expect(legacy.vietnamese, 'con mèo');
      expect(GeminiDictionaryService.parseLookup('x', 'hello').error, 'parse_error');
    });
  });

  group('Đọc câu trả lời hỏi đáp ngữ pháp', () {
    test('JSON đầy đủ; bỏ markdown; id bài lạ thì bỏ qua', () {
      final out = GeminiDictionaryService.parseGrammarAnswer(
        '{"answer":"**Since** đi với mốc thời gian.","examples":[{"en":"I have lived here since 2020.","vi":"...","correct":true},'
        '{"en":"I have lived here since 3 years.","vi":"Sai: 3 years là khoảng thời gian","correct":false}],'
        '"tip":"since = mốc","follow_ups":["Còn ago thì sao?"],"related_lesson_id":"toeic_tenses"}',
        validLessonIds: {'toeic_tenses'},
      );
      final a = out.answer!;
      expect(a.answer, 'Since đi với mốc thời gian.');
      expect(a.examples.length, 2);
      expect(a.examples.last.correct, isFalse);
      expect(a.followUps, ['Còn ago thì sao?']);
      expect(a.relatedLessonId, 'toeic_tenses');
      final unknownLesson = GeminiDictionaryService.parseGrammarAnswer('{"answer":"Ok","related_lesson_id":"xyz"}');
      expect(unknownLesson.answer!.relatedLessonId, isEmpty);
    });

    test('chữ thường dùng nguyên văn; JSON cắt dở chỉ lấy phần answer', () {
      expect(GeminiDictionaryService.parseGrammarAnswer('Dùng "an" trước nguyên âm.').answer!.answer,
          'Dùng "an" trước nguyên âm.');
      final cut = GeminiDictionaryService.parseGrammarAnswer('{"answer":"Dùng \\"a\\" trước phụ âm.","examples":[{"en":"a ca');
      expect(cut.answer!.answer, 'Dùng "a" trước phụ âm.');
    });
  });

  group('DictionaryController', () {
    test('tra từ: lưu "đã tra gần đây" (mới nhất trước, không trùng, tối đa 8)', () async {
      final c = _controller(_FakeDictionary());
      for (final w in ['a', 'b', 'A', 'c']) {
        await c.lookup(w);
      }
      expect(c.recentLookups, ['c', 'A', 'b']);
      for (var i = 0; i < 10; i++) {
        await c.lookup('w$i');
      }
      expect(c.recentLookups.length, DictionaryController.maxRecent);
      expect(c.recentLookups.first, 'w9');
    });

    test('hỏi đáp: hỏi tiếp có gửi kèm lượt trước; lỗi thì bỏ câu hỏi treo và báo lỗi', () async {
      final fake = _FakeDictionary();
      final c = _controller(fake);
      await c.ask('Since và for khác gì?');
      await c.ask('Còn ago?');
      expect(fake.lastHistory.single.question, 'Since và for khác gì?');
      expect(c.qaTurns.length, 2);
      expect(c.qaTurns.last.answer!.answer, 'Trả lời: Còn ago?');

      fake.failNext = true;
      await c.ask('Câu lỗi');
      expect(c.qaTurns.length, 2);
      expect(c.askError, 'network');

      c.setAudience(GrammarAudience.adult);
      await c.ask('TOEIC?');
      expect(fake.lastAudience, GrammarAudience.adult);
      c.clearQa();
      expect(c.qaTurns, isEmpty);
    });

    test('câu hỏi mẫu đổi theo đối tượng', () {
      final c = _controller(_FakeDictionary());
      final kid = c.starterQuestions;
      c.setAudience(GrammarAudience.adult);
      expect(c.starterQuestions, isNot(kid));
    });
  });

  testWidgets('màn Tra cứu: thẻ kết quả có phiên âm, ví dụ, đồng nghĩa; chế độ hỏi đáp hiện câu trả lời',
      (tester) async {
    final fake = _FakeDictionary();
    final c = _controller(fake);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: c,
      child: const MaterialApp(home: Scaffold(body: DictionaryScreen())),
    ));
    expect(find.text('📖 Tra từ'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'deadline');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('/ˈded.laɪn/'), findsOneWidget);
    expect(find.text('danh từ'), findsOneWidget);
    expect(find.text('The deadline is Friday.'), findsOneWidget);
    expect(find.text('due date'), findsOneWidget);

    await tester.tap(find.text('💬 Hỏi ngữ pháp'));
    await tester.pumpAndSettle();
    final starter = c.starterQuestions.first;
    await tester.tap(find.text('❓ $starter'));
    await tester.pumpAndSettle();
    expect(find.text('Trả lời: $starter'), findsOneWidget);
    expect(find.textContaining('Xem bài ngữ pháp'), findsOneWidget);
    expect(find.text('Hỏi thêm?'), findsOneWidget);
  });
}

DictionaryController _controller(DictionaryService service) =>
    DictionaryController(service: service, ttsService: _SilentTts(), speechService: SpeechService());

class _FakeDictionary implements DictionaryService {
  List<GrammarQaTurn> lastHistory = const [];
  GrammarAudience? lastAudience;
  bool failNext = false;

  @override
  bool get isConfigured => true;

  @override
  Future<DictionaryLookupOutcome> lookup(String text) async => DictionaryLookupOutcome.success(DictionaryLookupResult(
        query: text,
        english: text,
        vietnamese: 'hạn chót',
        ipa: '/ˈded.laɪn/',
        partOfSpeech: 'danh từ',
        examples: const [BilingualExample('The deadline is Friday.', 'Hạn chót là thứ Sáu.')],
        synonyms: const ['due date'],
        note: 'meet a deadline',
      ));

  @override
  Future<GrammarAnswerOutcome> askGrammar({
    required String question,
    List<GrammarQaTurn> history = const [],
    GrammarAudience audience = GrammarAudience.kid,
  }) async {
    lastHistory = history;
    lastAudience = audience;
    if (failNext) {
      failNext = false;
      return const GrammarAnswerOutcome.failure('network');
    }
    return GrammarAnswerOutcome.success(GrammarAnswer(
      answer: 'Trả lời: $question',
      examples: const [BilingualExample('I have a cat.', 'Tôi có một con mèo.')],
      tip: 'Nhớ nhé',
      followUps: const ['Hỏi thêm?'],
      relatedLessonId: 'mov_articles_this',
    ));
  }
}

class _SilentTts extends TtsService {
  @override
  Future<void> speak(String text, {VoiceKind kind = VoiceKind.kid, double speed = 1.0}) async {}

  @override
  Future<void> stop() async {}
}
