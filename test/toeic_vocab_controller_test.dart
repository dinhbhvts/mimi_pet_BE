import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/toeic_vocab.dart';
import 'package:mimi_pet/presentation/screens/exam/toeic_vocab_screen.dart';
import 'package:mimi_pet/presentation/state/toeic_vocab_controller.dart';
import 'package:mimi_pet/services/tts_service.dart';

ToeicWord _w(String word) => ToeicWord(word, '/x/', 'n', 'nghĩa $word', 'A $word here.', 'Một $word.');

final _topics = [
  ToeicVocabTopic('a', '🅰️', 'Topic A', [_w('alpha'), _w('apple'), _w('arrow')]),
  ToeicVocabTopic('b', '🅱️', 'Topic B', [_w('bravo'), _w('banana')]),
];

class _MemStorage implements VocabStorage {
  List<String> known = [];
  Map<String, dynamic> prefs = {};

  @override
  List<String> loadKnown() => known;
  @override
  void saveKnown(List<String> words) => known = words;
  @override
  Map<String, dynamic> loadPrefs() => prefs;
  @override
  void savePrefs(Map<String, dynamic> p) => prefs = p;
}

class _SilentTts extends TtsService {
  final spoken = <String>[];

  @override
  Future<void> speak(String text, {VoiceKind kind = VoiceKind.kid, double speed = 1.0}) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

void main() {
  group('Dữ liệu chủ đề', () {
    test('mọi từ thuộc đúng 1 chủ đề; đủ 29 chủ đề và hơn 850 từ', () {
      expect(ToeicVocab.topics.length, greaterThanOrEqualTo(29));
      expect(ToeicVocab.all.length, greaterThanOrEqualTo(850));
      final ids = ToeicVocab.topics.map((t) => t.id).toSet();
      expect(ids.length, ToeicVocab.topics.length);
      for (final t in ToeicVocab.topics) {
        expect(t.words.length, greaterThanOrEqualTo(10), reason: '${t.id} quá ít từ');
      }
    });
  });

  group('ToeicVocabController', () {
    test('lọc chủ đề, tới/lui vòng tròn, không trộn thì giữ thứ tự', () {
      final c = ToeicVocabController(storage: _MemStorage()..prefs = {'shuffle': false}, topics: _topics);
      expect(c.deck.length, 5);
      c.selectTopic('b');
      expect(c.deck.map((w) => w.word), ['bravo', 'banana']);
      c.next();
      expect(c.current!.word, 'banana');
      c.next();
      expect(c.current!.word, 'bravo');
      c.previous();
      expect(c.current!.word, 'banana');
    });

    test('đánh dấu đã thuộc: lưu lại, ẩn khỏi bộ thẻ, thẻ kế tiếp hiện ngay', () {
      final storage = _MemStorage()..prefs = {'shuffle': false};
      final c = ToeicVocabController(storage: storage, topics: _topics);
      c.selectTopic('a');
      c.toggleKnown(c.current!); // alpha
      expect(storage.known, ['alpha']);
      expect(c.deck.map((w) => w.word), ['apple', 'arrow']);
      expect(c.current!.word, 'apple');
      expect(c.knownCount, 1);

      // Mở lại: vẫn nhớ từ đã thuộc.
      final reopened = ToeicVocabController(storage: storage, topics: _topics)..selectTopic('a');
      expect(reopened.deck.map((w) => w.word), ['apple', 'arrow']);
      reopened.setHideKnown(false);
      expect(reopened.deck.length, 3);
      expect(reopened.isKnown(reopened.deck.first), isTrue);
    });

    test('thuộc hết chủ đề thì bộ thẻ rỗng (màn hình báo đã thuộc hết)', () {
      final c = ToeicVocabController(storage: _MemStorage(), topics: _topics)..selectTopic('b');
      c.toggleKnown(c.current!);
      c.toggleKnown(c.current!);
      expect(c.current, isNull);
    });

    test('tuỳ chọn được lưu và nạp lại', () {
      final storage = _MemStorage();
      final c = ToeicVocabController(storage: storage, topics: _topics, random: Random(1));
      c.setCardSeconds(5);
      c.setAutoRead(VocabAutoRead.wordAndExample);
      c.setAutoAdvance(false);
      final again = ToeicVocabController(storage: storage, topics: _topics);
      expect(again.cardSeconds, 5);
      expect(again.autoRead, VocabAutoRead.wordAndExample);
      expect(again.autoAdvance, isFalse);
    });

    test('trộn: hết 1 vòng thì trộn lại, đủ mọi từ', () {
      final c = ToeicVocabController(storage: _MemStorage(), topics: _topics, random: Random(3));
      final seen = <String>{};
      for (var i = 0; i < 5; i++) {
        seen.add(c.current!.word);
        c.next();
      }
      expect(seen.length, 5);
    });
  });

  testWidgets('màn Từ vựng TOEIC: tự đọc, tự chuyển sau đủ giây, tạm dừng, đánh dấu đã thuộc', (tester) async {
    final tts = _SilentTts();
    final vocab = ToeicVocabController(
      storage: _MemStorage()..prefs = {'shuffle': false, 'seconds': 5, 'read': 'word'},
      topics: _topics,
    );
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<TtsService>.value(value: tts),
        ChangeNotifierProvider.value(value: vocab),
      ],
      child: const MaterialApp(home: ToeicVocabScreen()),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.text('alpha'), findsOneWidget);
    expect(tts.spoken, ['alpha']);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 400));
    expect(vocab.current!.word, 'apple', reason: 'tự chuyển sau 5 giây');
    expect(tts.spoken.last, 'apple');

    await tester.tap(find.byTooltip('Tạm dừng tự chuyển'));
    await tester.pump(const Duration(seconds: 8));
    expect(vocab.current!.word, 'apple', reason: 'đang dừng thì không chuyển');

    await tester.tap(find.text('Đã thuộc'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(vocab.isKnown(_topics.first.words[1]), isTrue);
    expect(vocab.current!.word, 'arrow');

    await tester.tap(find.textContaining('Topic B'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(vocab.current!.word, 'bravo');
    await tester.pumpWidget(const SizedBox());
  });
}
