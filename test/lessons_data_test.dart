import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mimi_pet/domain/entities/sticker.dart';

/// Kiểm tra DỮ LIỆU THẬT của bài học từ vựng (assets/lessons/lessons.json):
/// bắt lỗi soạn bài trước khi bé gặp trong app (vd câu mẫu "I have ___
/// fingers and toes." nhưng mảnh ghép lại là "I have ten toes").
void main() {
  final lessons = ((jsonDecode(File('assets/lessons/lessons.json').readAsStringSync()) as Map)['lessons'] as List)
      .cast<Map<String, dynamic>>();
  final words = [
    for (final l in lessons)
      for (final w in (l['words'] as List).cast<Map<String, dynamic>>()) (l['id'] as String, w),
  ];

  test('id bài và id từ không trùng', () {
    final lessonIds = lessons.map((l) => l['id']).toList();
    expect(lessonIds.toSet().length, lessonIds.length);
    final wordIds = words.map((e) => e.$2['id']).toList();
    expect(wordIds.toSet().length, wordIds.length);
  });

  test('mỗi bài có ít nhất 6 từ, từ nào cũng có nghĩa tiếng Việt và hình (emoji hoặc màu)', () {
    for (final l in lessons) {
      expect((l['words'] as List).length, greaterThanOrEqualTo(6), reason: '${l['id']}');
    }
    for (final (lessonId, w) in words) {
      expect((w['vi'] as String).trim(), isNotEmpty, reason: '$lessonId/${w['id']}');
      expect(w['emoji'] != null || w['swatchColor'] != null, isTrue, reason: '$lessonId/${w['id']}');
    }
  });

  test('sticker đặc biệt không trùng hình với từ trong bài học (để luôn là hình "hiếm")', () {
    final lessonEmojis = {for (final (_, w) in words) w['emoji']};
    final clashes = [
      for (final s in SpecialSticker.all)
        if (lessonEmojis.contains(s.emoji)) '${s.id} ${s.emoji}',
    ];
    expect(clashes, isEmpty);
  });

  test('câu mẫu có đúng 1 chỗ trống và khớp với các mảnh ghép câu', () {
    final bad = <String>[];
    for (final (lessonId, w) in words) {
      final template = w['sentenceTemplate'] as String?;
      final pieces = (w['sentenceWords'] as List?)?.cast<String>();
      if (template == null) continue;
      if ('___'.allMatches(template).length != 1) {
        bad.add('$lessonId/${w['id']}: $template');
        continue;
      }
      if (pieces == null) continue;
      final expected = template.replaceFirst('___', w['en'] as String).replaceAll(RegExp(r'[.!?]$'), '');
      if (pieces.join(' ') != expected) bad.add('$lessonId/${w['id']}: "$expected" ≠ "${pieces.join(' ')}"');
    }
    expect(bad, isEmpty);
  });
}
