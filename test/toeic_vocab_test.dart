import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mimi_pet/core/toeic_vocab.dart';
import 'package:mimi_pet/presentation/screens/boot/boot_screen.dart';

void main() {
  group('Dữ liệu từ vựng TOEIC', () {
    test('không trùng từ, đủ phiên âm/nghĩa/ví dụ/dịch', () {
      final words = ToeicVocab.all.map((w) => w.word.toLowerCase()).toList();
      expect(words.toSet().length, words.length);
      expect(ToeicVocab.all.length, greaterThanOrEqualTo(850));
      for (final w in ToeicVocab.all) {
        expect(w.ipa, matches(RegExp(r'^/.+/$')), reason: w.word);
        expect(w.meaning.trim(), isNotEmpty, reason: w.word);
        expect(w.example.trim(), isNotEmpty, reason: w.word);
        expect(w.exampleVi.trim(), isNotEmpty, reason: w.word);
        expect(['n', 'v', 'adj', 'adv', 'phr', 'prep'], contains(w.type), reason: w.word);
      }
    });

    test('câu ví dụ nào cũng tô đậm được đúng từ đang học', () {
      final missing = [
        for (final w in ToeicVocab.all)
          if (HighlightedExample.highlightRange(w.example, w.word) == null) w.word,
      ];
      expect(missing, isEmpty);
    });

    test('tô đậm cả dạng đã chia của động từ', () {
      const example = 'He handed in his resignation yesterday.';
      final (start, end) = HighlightedExample.highlightRange(example, 'resignation')!;
      expect(example.substring(start, end), 'resignation');
      const called = 'The picnic was called off because of rain.';
      final (s2, e2) = HighlightedExample.highlightRange(called, 'call off')!;
      expect(called.substring(s2, e2), 'called');
      const stacked = 'Boxes have been stacked on the floor.';
      final (s3, e3) = HighlightedExample.highlightRange(stacked, 'stack')!;
      expect(stacked.substring(s3, e3), 'stacked');
    });
  });

  testWidgets('thẻ từ hiện phiên âm, ví dụ, mẹo và bấm nghe đúng nội dung', (tester) async {
    final word = ToeicVocab.all.firstWhere((w) => w.word == 'receipt');
    final spoken = <String>[];
    var nextTapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: VocabTipCard(word: word, onSpeak: spoken.add, onNext: () => nextTapped = true),
        ),
      ),
    ));
    expect(find.text('receipt'), findsOneWidget);
    expect(find.text('/rɪˈsiːt/'), findsOneWidget);
    expect(find.textContaining('💡'), findsOneWidget);
    expect(find.text(word.exampleVi), findsOneWidget);

    await tester.tap(find.byTooltip('Nghe phát âm'));
    await tester.tap(find.byTooltip('Nghe câu ví dụ'));
    await tester.tap(find.text('Từ tiếp'));
    expect(spoken, ['receipt', word.example]);
    expect(nextTapped, isTrue);
  });
}
