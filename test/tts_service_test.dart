import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mimi_pet/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parseDialogue', () {
    test('tách hội thoại A/B', () {
      final lines = TtsService.parseDialogue('A: Hi, Tom. How are you? B: Fine, thanks. A: Great!');
      expect(lines.map((l) => l.speaker), ['A', 'B', 'A']);
      expect(lines.first.text, 'Hi, Tom. How are you?');
      expect(lines[1].text, 'Fine, thanks.');
    });

    test('nhãn là tên người, kể cả khi tên xuất hiện ngay sau dấu chấm', () {
      final lines = TtsService.parseDialogue(
          'Man: Thanks for joining, Maria and Ken. Maria: Happy to be here. Ken: I agree.');
      expect(lines.map((l) => l.speaker), ['Man', 'Maria', 'Ken']);
    });

    test('hội thoại 3 người kiểu TOEIC: "Woman 1" / "Woman 2" là 2 người khác nhau, đều là nữ', () {
      final lines = TtsService.parseDialogue('Woman 1: Have you heard? Man: Yes. Woman 2: Great news. Woman 1: Indeed.');
      expect(lines.map((l) => l.speaker), ['Woman 1', 'Man', 'Woman 2', 'Woman 1']);
      expect(TtsService.genderOfLabel('Woman 2'), SpeakerGender.female);
      final a = TtsService.assignVoices(lines.map((l) => l.speaker).toList(), const [
        {'name': 'Microsoft David - English (United States)', 'locale': 'en-US'},
        {'name': 'Microsoft Zira - English (United States)', 'locale': 'en-US'},
      ]);
      expect(a['Woman 1']!.voice!['name'], contains('Zira'));
      expect(a['Woman 2']!.voice!['name'], contains('Zira'));
      expect(a['Woman 2']!.pitch, isNot(a['Woman 1']!.pitch), reason: 'cùng giọng thì lệch cao độ để phân biệt');
    });

    test('độc thoại hoặc câu có giờ giấc/nhãn đáp án thì không coi là hội thoại', () {
      expect(TtsService.parseDialogue('Attention shoppers. The store closes at 9:30 tonight.'), isEmpty);
      expect(TtsService.parseDialogue('Where is the bank? A. Next to the park. B. At noon. C. Yes.'), isEmpty);
      expect(TtsService.parseDialogue('A: Hello there. A: Anyone home?'), isEmpty);
    });

    test('mọi hội thoại Part 3 trong ngân hàng câu hỏi đều tách được, không mất chữ', () {
      final bank = jsonDecode(File('assets/exam/toeic_seed.json').readAsStringSync()) as List<dynamic>;
      final scripts = {
        for (final q in bank.cast<Map<String, dynamic>>())
          if (q['partNumber'] == 3 && q['audioScript'] != null) q['audioScript'] as String,
      };
      expect(scripts, isNotEmpty);
      for (final script in scripts) {
        final lines = TtsService.parseDialogue(script);
        expect(lines.length, greaterThanOrEqualTo(2), reason: script);
        final joined = lines.map((l) => '${l.speaker}: ${l.text}').join(' ');
        expect(joined.replaceAll(RegExp(r'\s+'), ' '), script.trim().replaceAll(RegExp(r'\s+'), ' '),
            reason: script);
      }
    });
  });

  group('Giới tính giọng', () {
    test('đoán theo nhãn người nói', () {
      expect(TtsService.genderOfLabel('Woman'), SpeakerGender.female);
      expect(TtsService.genderOfLabel('Mum'), SpeakerGender.female);
      expect(TtsService.genderOfLabel('Ken'), SpeakerGender.male);
      expect(TtsService.genderOfLabel('A'), SpeakerGender.unknown);
    });

    test('đoán theo tên giọng của máy - "female" không bị nhầm thành "male"', () {
      expect(TtsService.genderOfVoice('Google UK English Female'), SpeakerGender.female);
      expect(TtsService.genderOfVoice('Google UK English Male'), SpeakerGender.male);
      expect(TtsService.genderOfVoice('Microsoft Zira - English (United States)'), SpeakerGender.female);
      expect(TtsService.genderOfVoice('Microsoft David - English (United States)'), SpeakerGender.male);
      expect(TtsService.genderOfVoice('en-us-x-sfg-local'), SpeakerGender.unknown);
    });
  });

  group('assignVoices', () {
    const voices = [
      {'name': 'Google UK English Male', 'locale': 'en-GB'},
      {'name': 'Microsoft David - English (United States)', 'locale': 'en-US'},
      {'name': 'Microsoft Zira - English (United States)', 'locale': 'en-US'},
    ];

    test('A/B luân phiên nam - nữ, ưu tiên giọng Mỹ', () {
      final a = TtsService.assignVoices(['A', 'B', 'A'], voices);
      expect(a['A']!.voice!['name'], contains('David'));
      expect(a['B']!.voice!['name'], contains('Zira'));
    });

    test('nhãn có giới tính rõ thì theo nhãn', () {
      final a = TtsService.assignVoices(['Woman', 'Man'], voices);
      expect(a['Woman']!.voice!['name'], contains('Zira'));
      expect(a['Man']!.voice!['name'], contains('David'));
    });

    test('máy không có giọng rõ giới tính thì đổi cao độ để phân biệt', () {
      final a = TtsService.assignVoices(['A', 'B'], const [
        {'name': 'en-us-x-sfg-local', 'locale': 'en-US'},
      ]);
      expect(a['A']!.voice, isNull);
      expect(a['B']!.voice, isNull);
      expect(a['A']!.pitch, lessThan(1.0));
      expect(a['B']!.pitch, greaterThan(1.0));
    });

    test('2 người cùng giới dùng chung 1 giọng thì lệch cao độ', () {
      final a = TtsService.assignVoices(['Woman', 'Maria'], const [
        {'name': 'Microsoft Zira', 'locale': 'en-US'},
      ]);
      expect(a['Woman']!.voice, a['Maria']!.voice);
      expect(a['Woman']!.pitch, isNot(a['Maria']!.pitch));
    });
  });

  test('tốc độ = gốc x hồ sơ x hệ số lượt đọc, kẹp trong 0.1..1.0', () {
    final tts = TtsService();
    expect(tts.rateFor(VoiceKind.toeic), closeTo(0.5, 1e-9));
    expect(tts.rateFor(VoiceKind.toeic, speed: 0.75), closeTo(0.375, 1e-9));
    expect(tts.rateFor(VoiceKind.kid, speed: 10), 1.0);
  });
}
