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

  group('Chất lượng đề (rà soát tự động)', () {
    final mcq = bank.questions.where((q) => q.questionType == QuestionType.multipleChoice).toList();

    test('Part 1/2: lời đọc chứa đúng các lựa chọn A/B/C(/D) theo thứ tự đang hiển thị', () {
      final bad = <String>[];
      for (final q in mcq.where((q) => q.isAudioOnlyChoice)) {
        final suffix = q.options.map((o) => '${o.id.toUpperCase()}. ${o.text}').join(' ');
        if (!(q.audioScript ?? '').endsWith(suffix)) bad.add(q.id);
      }
      expect(bad, isEmpty);
    });

    test('Part 1/2: giải thích không nhắc chữ cái đáp án (vị trí đáp án được xáo)', () {
      final letterRef = RegExp(r'(^|[\s(;,.])[A-D]\s*(là|bẫy|lặp|sai|nhầm)');
      final bad = [
        for (final q in mcq.where((q) => q.isAudioOnlyChoice))
          if (letterRef.hasMatch(q.explanation ?? '')) q.id,
      ];
      expect(bad, isEmpty);
    });

    test('TOEIC: đáp án đúng KHÔNG thường xuyên là lựa chọn dài nhất (<= 40% mỗi Part)', () {
      final hits = <int, int>{}, totals = <int, int>{};
      for (final q in mcq.where((q) => q.track == ExamTrack.toeic && q.options.length >= 3)) {
        final lens = q.options.map((o) => o.text.length).toList();
        final maxLen = lens.reduce((a, b) => a > b ? a : b);
        if (lens.where((l) => l == maxLen).length > 1) continue;
        if (q.options.every((o) => RegExp(r'^\[\d\]$').hasMatch(o.text))) continue;
        final part = q.partNumber!;
        totals[part] = (totals[part] ?? 0) + 1;
        final correct = q.options.firstWhere((o) => o.id == q.correctAnswer.single);
        if (correct.text.length == maxLen) hits[part] = (hits[part] ?? 0) + 1;
      }
      for (final part in totals.keys) {
        final ratio = (hits[part] ?? 0) / totals[part]!;
        expect(ratio, lessThanOrEqualTo(0.40), reason: 'Part $part: ${(ratio * 100).round()}%');
      }
    });

    test('vị trí đáp án đúng phân bố đều (không vị trí nào quá 35% với câu 4 lựa chọn)', () {
      final counts = <String, int>{};
      var total = 0;
      for (final q in mcq.where((q) => q.options.length == 4)) {
        if (q.options.every((o) => RegExp(r'^\[\d\]$').hasMatch(o.text))) continue;
        counts[q.correctAnswer.single] = (counts[q.correctAnswer.single] ?? 0) + 1;
        total++;
      }
      for (final e in counts.entries) {
        expect(e.value / total, lessThanOrEqualTo(0.35), reason: 'vị trí ${e.key}');
      }
    });

    test('không có 2 câu trùng hệt nhau (cùng đề + cùng bộ lựa chọn)', () {
      String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();
      final seen = <String, String>{};
      final dups = <String>[];
      for (final q in mcq) {
        final opts = q.options.map((o) => norm(o.text)).toList()..sort();
        final key = '${q.track.name}|${q.level}|${q.partNumber}|${norm(q.audioScript ?? q.prompt)}|${opts.join('/')}';
        final prev = seen[key];
        if (prev != null) {
          dups.add('$prev = ${q.id}');
        } else {
          seen[key] = q.id;
        }
      }
      expect(dups, isEmpty);
    });
  });
}
