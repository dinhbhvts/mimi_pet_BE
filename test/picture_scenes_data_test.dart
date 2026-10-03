import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mimi_pet/presentation/widgets/scene_illustrations.dart';

void main() {
  final scenes = (jsonDecode(File('assets/scenes/scenes.json').readAsStringSync()) as Map<String, dynamic>)['scenes']
      as List<dynamic>;

  test('mọi bài tranh đều có hình vẽ thật (không rơi vào hình trống) và đủ câu cho nhiều lượt chơi', () {
    expect(scenes.length, greaterThanOrEqualTo(18));
    for (final s in scenes.cast<Map<String, dynamic>>()) {
      expect(SceneIllustration.supportedIds, contains(s['illustrationId']), reason: s['id'] as String);
      expect((s['questions'] as List).length, greaterThanOrEqualTo(10), reason: s['id'] as String);
      expect((s['titleVi'] as String).isNotEmpty, isTrue);
    }
  });

  test('mã câu hỏi không trùng; đáp án hợp lệ theo từng loại câu', () {
    final ids = <String>{};
    for (final s in scenes.cast<Map<String, dynamic>>()) {
      final prompts = <String>{};
      for (final q in (s['questions'] as List).cast<Map<String, dynamic>>()) {
        expect(ids.add(q['id'] as String), isTrue, reason: 'trùng mã ${q['id']}');
        expect(prompts.add((q['prompt'] as String).toLowerCase()), isTrue, reason: 'trùng câu hỏi ${q['prompt']}');
        switch (q['kind']) {
          case 'choice':
            final options = (q['options'] as List).cast<String>();
            expect(options.length, inInclusiveRange(2, 4), reason: q['id'] as String);
            expect(options.toSet().length, options.length, reason: q['id'] as String);
            expect(options, contains(q['answer']), reason: q['id'] as String);
          case 'trueFalse':
            expect(['True', 'False'], contains(q['answer']), reason: q['id'] as String);
          case 'speak':
            expect((q['answer'] as String).trim(), isNotEmpty, reason: q['id'] as String);
          default:
            fail('loại câu lạ: ${q['kind']}');
        }
      }
    }
  });
}
