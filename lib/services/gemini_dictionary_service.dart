import 'dart:async';
import 'dart:convert';

import '../core/grammar_lessons.dart';
import '../domain/entities/dictionary_lookup.dart';
import 'api_client.dart';
import 'dictionary_service.dart';

/// Implementation THẬT của [DictionaryService] dùng Gemini API qua PROXY của
/// backend (`POST /me/gemini/generate`, xem `backend/app/routers/gemini.py`)
/// - KHÔNG gọi thẳng Google kèm API key (2026-09-16, cùng lý do với
/// `GeminiChatService`: key không được lộ ra client khi app public trên web).
///
/// NÂNG CẤP (2026-10-03): tra từ trả về JSON (phiên âm, từ loại, các nghĩa,
/// câu ví dụ song ngữ, từ đồng nghĩa, ghi chú) thay cho 2 dòng "EN:/VI:" -
/// vẫn đọc được định dạng 2 dòng cũ làm dự phòng; thêm [askGrammar] cho phần
/// "Hỏi đáp ngữ pháp" (giải thích bằng tiếng Việt).
class GeminiDictionaryService implements DictionaryService {
  GeminiDictionaryService(this._apiClient);

  final ApiClient _apiClient;

  /// LUÔN true - key giờ cấu hình phía backend, xem
  /// `GeminiChatService.isConfigured`.
  @override
  bool get isConfigured => true;

  static const _safety = [
    {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_LOW_AND_ABOVE'},
    {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_LOW_AND_ABOVE'},
    {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_LOW_AND_ABOVE'},
    {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_LOW_AND_ABOVE'},
  ];

  static const _exampleSchema = {
    'type': 'OBJECT',
    'properties': {
      'en': {'type': 'STRING'},
      'vi': {'type': 'STRING'},
      'correct': {'type': 'BOOLEAN'},
    },
    'required': ['en', 'vi'],
  };

  // ------------------------------------------------------------ tra từ

  static const String _lookupPrompt = '''
You are a bilingual English-Vietnamese learner's dictionary for Vietnamese learners (an 8-year-old child and a TOEIC learner).
You receive ONE short input: an English or Vietnamese word, phrase or sentence (it may contain typos).
Detect the language and translate it into the other language.

Answer with ONE JSON object:
- "kind": "word" (a single word, short phrase, idiom or phrasal verb), "sentence" (a full sentence), or "unknown" (empty, nonsense, or not English/Vietnamese).
- "english": the English word/phrase/sentence (fix obvious typos; for Vietnamese input give the most common English equivalent).
- "vietnamese": the main Vietnamese meaning or translation (short and natural).
- For "word" only (otherwise use empty values): "ipa": American IPA such as "/ˈæp.əl/"; "part_of_speech": in Vietnamese (danh từ, động từ, tính từ, trạng từ, giới từ, cụm từ...); "meanings": up to 3 OTHER common Vietnamese meanings (may be empty); "synonyms": up to 4 common English synonyms (may be empty).
- "examples": for "word": 2-3 natural, simple example sentences that use the English word (everyday or workplace situations), each {"en": ..., "vi": Vietnamese translation}. For "sentence": an empty list.
- "note": in Vietnamese, ONE short useful note - for a word: a usage tip, common collocation, easily confused word or pronunciation trap; for a sentence: a short explanation of its grammar/structure. Use "" if there is nothing useful.
Keep everything safe and appropriate for children.
''';

  static const _lookupSchema = {
    'type': 'OBJECT',
    'properties': {
      'kind': {'type': 'STRING'},
      'english': {'type': 'STRING'},
      'vietnamese': {'type': 'STRING'},
      'ipa': {'type': 'STRING'},
      'part_of_speech': {'type': 'STRING'},
      'meanings': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
      'examples': {'type': 'ARRAY', 'items': _exampleSchema},
      'synonyms': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
      'note': {'type': 'STRING'},
    },
    'required': ['kind', 'english', 'vietnamese'],
  };

  @override
  Future<DictionaryLookupOutcome> lookup(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const DictionaryLookupOutcome.failure('empty_input');

    final body = <String, dynamic>{
      'systemInstruction': {
        'parts': [
          {'text': _lookupPrompt},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': trimmed},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 1200,
        'thinkingConfig': {'thinkingLevel': 'minimal'},
        'responseMimeType': 'application/json',
        'responseSchema': _lookupSchema,
      },
      'safetySettings': _safety,
    };

    final (raw, error) = await _generate(body, timeout: const Duration(seconds: 20));
    if (error != null) return DictionaryLookupOutcome.failure(error);
    return parseLookup(trimmed, raw!);
  }

  /// Đọc kết quả tra từ (JSON, hoặc 2 dòng EN/VI kiểu cũ). Hàm thuần - test được.
  static DictionaryLookupOutcome parseLookup(String query, String raw) {
    final json = _decodeJson(raw);
    if (json != null) {
      final kind = (json['kind'] as String? ?? '').trim().toLowerCase();
      final english = _str(json['english']);
      final vietnamese = _str(json['vietnamese']);
      if (kind == 'unknown' || english.isEmpty || english == '-' || vietnamese.isEmpty) {
        return const DictionaryLookupOutcome.failure('not_found');
      }
      final isSentence = kind == 'sentence';
      return DictionaryLookupOutcome.success(DictionaryLookupResult(
        query: query,
        english: english,
        vietnamese: vietnamese,
        isSentence: isSentence,
        ipa: isSentence ? '' : _normalizeIpa(_str(json['ipa'])),
        partOfSpeech: isSentence ? '' : _str(json['part_of_speech']),
        meanings: _strings(json['meanings'], max: 3).where((m) => m.toLowerCase() != vietnamese.toLowerCase()).toList(),
        examples: isSentence ? const [] : _examples(json['examples'], max: 3),
        synonyms: _strings(json['synonyms'], max: 4),
        note: _str(json['note']),
      ));
    }
    final legacy = _parseLegacy(query, raw);
    if (legacy == null) return const DictionaryLookupOutcome.failure('parse_error');
    if (legacy.english == '-' && legacy.vietnamese == '-') return const DictionaryLookupOutcome.failure('not_found');
    return DictionaryLookupOutcome.success(legacy);
  }

  /// Định dạng 2 dòng cũ "EN: .../VI: ..." - KHOAN DUNG với cả 2 dòng riêng
  /// lẫn gộp chung 1 dòng, tự bỏ markdown. null nếu không đủ cả 2 trường.
  static DictionaryLookupResult? _parseLegacy(String query, String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[*_`]'), '');
    var match = RegExp(
      r'EN\s*:\s*(.*?)[ \t]*(?:\r?\n)+[ \t]*VI\s*:\s*(.*)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(cleaned);
    match ??= RegExp(
      r'EN\s*:\s*(.*?)[ \t]*VI\s*:\s*(.*)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(cleaned);
    final english = match?.group(1)?.trim().split('\n').first.trim();
    final vietnamese = match?.group(2)?.trim().split('\n').first.trim();
    if (english == null || vietnamese == null || english.isEmpty || vietnamese.isEmpty) return null;
    return DictionaryLookupResult(query: query, english: english, vietnamese: vietnamese);
  }

  /// Bọc IPA trong /.../ nếu AI quên dấu gạch.
  static String _normalizeIpa(String ipa) {
    if (ipa.isEmpty) return '';
    final core = ipa.replaceAll(RegExp(r'^[/\[]+|[/\]]+$'), '').trim();
    return core.isEmpty ? '' : '/$core/';
  }

  // ------------------------------------------------------------ hỏi đáp ngữ pháp

  static String _grammarPrompt(GrammarAudience audience) {
    final lessons = GrammarLessons.all.map((l) => '  ${l.id}: ${l.title} (${l.level})').join('\n');
    final who = audience == GrammarAudience.kid
        ? 'the CHILD (8 years old): use very simple, warm Vietnamese, short sentences, fun comparisons, and easy A1-A2 English examples.'
        : 'an ADULT TOEIC learner (target 650): be precise, name the rule/structure, mention common TOEIC traps (Part 5/6), and use B1 workplace English examples.';
    return '''
You are "Cô Mimi", a patient English teacher for a Vietnamese family: an 8-year-old child preparing for Cambridge YLE (Movers/Flyers) and the child's parent preparing for TOEIC.
This answer is for $who

Rules:
- Explain in natural, friendly VIETNAMESE. Keep English words and structures in English. If the learner writes the whole question in English, answer in simple English and end with a one-sentence Vietnamese summary.
- Topics: English grammar, vocabulary and word usage, pronunciation, spelling, checking or correcting the learner's own English sentences, and exam tips. If a question is not about learning English, kindly say you can only help with English and suggest an English question instead.
- If the learner gives an English sentence to check, say clearly whether it is correct, give the corrected sentence and explain why.
- Never invent rules. If British and American English differ, say so briefly.
- Be safe and kind; never ask for personal information.

Answer with ONE JSON object:
- "answer": the explanation in Vietnamese: 2-6 short paragraphs separated by a blank line; you may start list lines with "• "; no markdown symbols such as ** or #.
- "examples": 2-4 example sentences {"en": English sentence, "vi": Vietnamese translation, "correct": true}; you may add ONE common wrong sentence with "correct": false where "vi" briefly says why it is wrong.
- "tip": one short memory tip in Vietnamese, or "".
- "follow_ups": 2-3 short follow-up questions IN VIETNAMESE that the learner might ask next.
- "related_lesson_id": the id of the most related lesson in this list, or "" if none fits:
$lessons
''';
  }

  static const _grammarSchema = {
    'type': 'OBJECT',
    'properties': {
      'answer': {'type': 'STRING'},
      'examples': {'type': 'ARRAY', 'items': _exampleSchema},
      'tip': {'type': 'STRING'},
      'follow_ups': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
      'related_lesson_id': {'type': 'STRING'},
    },
    'required': ['answer'],
  };

  /// Số lượt hỏi - đáp gần nhất gửi kèm làm ngữ cảnh.
  static const int maxHistoryTurns = 6;

  @override
  Future<GrammarAnswerOutcome> askGrammar({
    required String question,
    List<GrammarQaTurn> history = const [],
    GrammarAudience audience = GrammarAudience.kid,
  }) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return const GrammarAnswerOutcome.failure('empty_input');
    final recent = history.where((t) => t.answer != null).toList();
    final context = recent.length > maxHistoryTurns ? recent.sublist(recent.length - maxHistoryTurns) : recent;

    final body = <String, dynamic>{
      'systemInstruction': {
        'parts': [
          {'text': _grammarPrompt(audience)},
        ],
      },
      'contents': [
        for (final turn in context) ...[
          {
            'role': 'user',
            'parts': [
              {'text': turn.question},
            ],
          },
          {
            'role': 'model',
            'parts': [
              {'text': turn.answer!.answer},
            ],
          },
        ],
        {
          'role': 'user',
          'parts': [
            {'text': trimmed},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.4,
        'maxOutputTokens': 2000,
        'thinkingConfig': {'thinkingLevel': 'minimal'},
        'responseMimeType': 'application/json',
        'responseSchema': _grammarSchema,
      },
      'safetySettings': _safety,
    };

    final (raw, error) = await _generate(body, timeout: const Duration(seconds: 30));
    if (error != null) return GrammarAnswerOutcome.failure(error);
    return parseGrammarAnswer(raw!, validLessonIds: GrammarLessons.all.map((l) => l.id).toSet());
  }

  /// Đọc câu trả lời hỏi đáp (JSON; chữ thường thì dùng nguyên văn; JSON
  /// cắt dở thì cố lấy trường "answer" - không bao giờ hiện JSON thô).
  static GrammarAnswerOutcome parseGrammarAnswer(String raw, {Set<String> validLessonIds = const {}}) {
    final json = _decodeJson(raw);
    if (json == null) {
      final text = raw.trim();
      if (!text.startsWith('{')) {
        return text.isEmpty
            ? const GrammarAnswerOutcome.failure('empty_response')
            : GrammarAnswerOutcome.success(GrammarAnswer(answer: text));
      }
      final match = RegExp(r'"answer"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(text);
      if (match == null) return const GrammarAnswerOutcome.failure('parse_error');
      try {
        final answer = (jsonDecode('"${match.group(1)}"') as String).trim();
        return answer.isEmpty
            ? const GrammarAnswerOutcome.failure('empty_response')
            : GrammarAnswerOutcome.success(GrammarAnswer(answer: answer));
      } catch (_) {
        return const GrammarAnswerOutcome.failure('parse_error');
      }
    }
    final answer = _str(json['answer']).replaceAll(RegExp(r'\*\*|##+ ?'), '');
    if (answer.isEmpty) return const GrammarAnswerOutcome.failure('empty_response');
    final lessonId = _str(json['related_lesson_id']);
    return GrammarAnswerOutcome.success(GrammarAnswer(
      answer: answer,
      examples: _examples(json['examples'], max: 4),
      tip: _str(json['tip']),
      followUps: _strings(json['follow_ups'], max: 3),
      relatedLessonId: validLessonIds.contains(lessonId) ? lessonId : '',
    ));
  }

  // ------------------------------------------------------------ dùng chung

  /// Gọi Gemini, trả về (chữ trả lời, mã lỗi). Gặp lỗi 400 (model/tài khoản
  /// không nhận responseSchema) thì gọi lại 1 lần ở chế độ chữ thường.
  Future<(String?, String?)> _generate(Map<String, dynamic> body, {required Duration timeout}) async {
    try {
      Map<String, dynamic> decoded;
      try {
        decoded = await _apiClient.postJson('/me/gemini/generate', body).timeout(timeout);
      } on ApiException catch (e) {
        if (e.statusCode != 400) rethrow;
        final config = Map<String, dynamic>.of(body['generationConfig'] as Map<String, dynamic>)
          ..remove('responseMimeType')
          ..remove('responseSchema');
        decoded = await _apiClient.postJson('/me/gemini/generate', {...body, 'generationConfig': config}).timeout(timeout);
      }
      final candidates = decoded['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return (null, 'blocked');
      final candidate = candidates.first as Map<String, dynamic>;
      if (candidate['finishReason'] == 'SAFETY') return (null, 'blocked');
      final content = candidate['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final raw = parts
          ?.where((p) => (p as Map<String, dynamic>)['thought'] != true)
          .map((p) => (p as Map<String, dynamic>)['text'] as String? ?? '')
          .join()
          .trim();
      if (raw == null || raw.isEmpty) return (null, 'empty_response');
      return (raw, null);
    } on ApiException catch (e) {
      if (e.statusCode == 429) return (null, 'rate_limited');
      if (e.statusCode == 503) return (null, 'missing_key');
      if (e.statusCode == 400 || e.statusCode == 403) return (null, 'invalid_key');
      if (e.statusCode == 404) return (null, 'model_not_found');
      return (null, 'http_${e.statusCode}');
    } on TimeoutException {
      return (null, 'timeout');
    } catch (_) {
      return (null, 'network');
    }
  }

  static Map<String, dynamic>? _decodeJson(String raw) {
    var text = raw.trim();
    final fenced = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$').firstMatch(text);
    if (fenced != null) text = fenced.group(1)!.trim();
    try {
      final decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static String _str(Object? v) => v is String ? v.trim() : '';

  static List<String> _strings(Object? v, {required int max}) {
    if (v is! List) return const [];
    final out = <String>[];
    for (final item in v) {
      final s = _str(item);
      if (s.isNotEmpty && !out.any((o) => o.toLowerCase() == s.toLowerCase())) out.add(s);
      if (out.length == max) break;
    }
    return out;
  }

  static List<BilingualExample> _examples(Object? v, {required int max}) {
    if (v is! List) return const [];
    final out = <BilingualExample>[];
    for (final item in v) {
      if (item is! Map) continue;
      final en = _str(item['en']);
      final vi = _str(item['vi']);
      if (en.isEmpty) continue;
      out.add(BilingualExample(en, vi, correct: item['correct'] != false));
      if (out.length == max) break;
    }
    return out;
  }
}
