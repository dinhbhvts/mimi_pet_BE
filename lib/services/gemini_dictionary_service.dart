import 'dart:async';

import '../domain/entities/dictionary_lookup.dart';
import 'api_client.dart';
import 'dictionary_service.dart';

/// Implementation THẬT của [DictionaryService] dùng Gemini API qua PROXY của
/// backend (`POST /me/gemini/generate`, xem `backend/app/routers/gemini.py`)
/// - KHÔNG gọi thẳng Google kèm API key như trước (2026-09-16, cùng lý do với
/// `GeminiChatService`: key không được lộ ra client khi app public trên
/// web).
///
/// Dùng ĐỊNH DẠNG PHẢN HỒI CỐ ĐỊNH 2 DÒNG (giống cách `checkGrammar` dùng
/// "TIP:"/"OK") thay vì bắt model trả JSON - dễ phân tích chắc chắn hơn, ít
/// rủi ro model trả JSON lồng markdown code fence hay lỗi cú pháp JSON nhỏ
/// làm hỏng cả kết quả.
class GeminiDictionaryService implements DictionaryService {
  GeminiDictionaryService(this._apiClient);

  final ApiClient _apiClient;

  /// LUÔN true - key giờ cấu hình phía backend, xem
  /// `GeminiChatService.isConfigured`.
  @override
  bool get isConfigured => true;

  static const String _systemPrompt = '''
You will receive ONE short piece of text: either a single English or Vietnamese word, or a short English or Vietnamese sentence, typed by an 8-year-old Vietnamese child learning English.

Task: detect whether it is English or Vietnamese, then translate it into the OTHER language. Keep translations natural, simple and suitable for a child.

Respond with EXACTLY this format, on 2 SEPARATE lines, nothing else, no extra words, no markdown, no bullet points, no bold/asterisks:
EN: <the English version>
VI: <the Vietnamese version>

If the input already is English, "EN:" should just repeat it (corrected for obvious typos if needed), and "VI:" is the Vietnamese translation. If the input is Vietnamese, "VI:" repeats it and "EN:" is the English translation. If the text is empty, nonsense, or not a real word/sentence in either language, respond with exactly these 2 lines: "EN: -" then "VI: -".
''';

  @override
  Future<DictionaryLookupOutcome> lookup(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const DictionaryLookupOutcome.failure('empty_input');

    final body = <String, dynamic>{
      'systemInstruction': {
        'parts': [
          {'text': _systemPrompt},
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
        'maxOutputTokens': 300,
        'thinkingConfig': {'thinkingLevel': 'minimal'},
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_LOW_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_LOW_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_LOW_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_LOW_AND_ABOVE'},
      ],
    };

    try {
      final decoded = await _apiClient.postJson('/me/gemini/generate', body).timeout(const Duration(seconds: 12));

      final candidates = decoded['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return const DictionaryLookupOutcome.failure('blocked');
      }
      final candidate = candidates.first as Map<String, dynamic>;
      if (candidate['finishReason'] == 'SAFETY') {
        return const DictionaryLookupOutcome.failure('blocked');
      }
      final content = candidate['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final raw = parts
          ?.where((p) => (p as Map<String, dynamic>)['thought'] != true)
          .map((p) => (p as Map<String, dynamic>)['text'] as String? ?? '')
          .join()
          .trim();
      if (raw == null || raw.isEmpty) {
        return const DictionaryLookupOutcome.failure('empty_response');
      }

      final parsed = _parse(trimmed, raw);
      if (parsed == null) return const DictionaryLookupOutcome.failure('parse_error');
      if (parsed.english == '-' && parsed.vietnamese == '-') {
        return const DictionaryLookupOutcome.failure('not_found');
      }
      return DictionaryLookupOutcome.success(parsed);
    } on ApiException catch (e) {
      if (e.statusCode == 429) return const DictionaryLookupOutcome.failure('rate_limited');
      if (e.statusCode == 503) return const DictionaryLookupOutcome.failure('missing_key');
      if (e.statusCode == 400 || e.statusCode == 403) return const DictionaryLookupOutcome.failure('invalid_key');
      if (e.statusCode == 404) return const DictionaryLookupOutcome.failure('model_not_found');
      return DictionaryLookupOutcome.failure('http_${e.statusCode}');
    } on TimeoutException {
      return const DictionaryLookupOutcome.failure('timeout');
    } catch (_) {
      return const DictionaryLookupOutcome.failure('network');
    }
  }

  /// Phân tích định dạng cố định "EN: .../VI: ..." - KHOAN DUNG với cả 2
  /// tình huống hay gặp trong thực tế: (a) model trả đúng 2 DÒNG riêng như
  /// dặn, (b) model GỘP cả 2 phần trên CÙNG 1 DÒNG (bỏ qua hướng dẫn xuống
  /// dòng). Cũng tự loại bỏ markdown (`*`, `_`, `` ` ``) trước khi nhận diện
  /// tiền tố, đề phòng model chèn `**EN:**` dù đã dặn "no markdown". Trả về
  /// null nếu KHÔNG tìm đủ cả 2 trường "EN"/"VI" - lúc đó coi là model trả
  /// sai định dạng, không đoán mò.
  DictionaryLookupResult? _parse(String query, String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[*_`]'), '');

    // Trường hợp (a): 2 dòng riêng biệt (có thể có dòng trống/khoảng trắng
    // xen giữa) - dùng RegExp đa dòng, khoan dung khoảng trắng quanh dấu ":".
    var match = RegExp(
      r'EN\s*:\s*(.*?)[ \t]*(?:\r?\n)+[ \t]*VI\s*:\s*(.*)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(cleaned);

    // Trường hợp (b): gộp chung 1 dòng, ví dụ "EN: cat VI: con mèo".
    match ??= RegExp(
      r'EN\s*:\s*(.*?)[ \t]*VI\s*:\s*(.*)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(cleaned);

    String? english = match?.group(1)?.trim();
    String? vietnamese = match?.group(2)?.trim();

    // Chỉ lấy DÒNG ĐẦU TIÊN của mỗi phần (phòng khi model vẫn lỡ thêm ghi
    // chú/giải thích thừa ở dòng sau dù đã dặn "nothing else").
    english = english?.split('\n').first.trim();
    vietnamese = vietnamese?.split('\n').first.trim();

    if (english == null || vietnamese == null || english.isEmpty || vietnamese.isEmpty) {
      return null;
    }
    return DictionaryLookupResult(query: query, english: english, vietnamese: vietnamese);
  }
}
