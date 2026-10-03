/// 1 câu ví dụ song ngữ (dùng cho kết quả tra từ và câu trả lời hỏi đáp).
class BilingualExample {
  final String english;
  final String vietnamese;

  /// false = câu SAI minh hoạ lỗi hay gặp (chỉ có ở phần hỏi đáp ngữ pháp).
  final bool correct;

  const BilingualExample(this.english, this.vietnamese, {this.correct = true});
}

/// Kết quả 1 lượt tra cứu ở tab "Tra cứu" - dịch 2 CHIỀU (Anh<->Việt), tự
/// động phát hiện bé gõ tiếng Anh hay tiếng Việt (xem
/// `GeminiDictionaryService`). Luôn giữ cả 2 phía (Anh + Việt) trong cùng 1
/// kết quả, KHÔNG chỉ lưu bản dịch - vì [english] còn được dùng để phát âm
/// (TTS) và kiểm tra phát âm của bé (luôn kiểm tra phía tiếng Anh, vì đó mới
/// là thứ bé đang học - xem `DictionaryController`).
///
/// MỞ RỘNG (2026-10-03): thêm phiên âm, từ loại, các nghĩa, câu ví dụ, từ
/// đồng nghĩa và ghi chú cách dùng - đều TUỲ CHỌN (rỗng nếu là cả câu, hoặc
/// AI trả về định dạng cũ chỉ có 2 dòng EN/VI).
class DictionaryLookupResult {
  /// Câu/từ gốc bé đã gõ (giữ nguyên, chưa chuẩn hoá) - hiển thị lại cho bé
  /// thấy đúng những gì mình đã tra.
  final String query;

  final String english;
  final String vietnamese;

  /// true nếu là CẢ CÂU (không có phiên âm/từ loại, ghi chú giải thích cấu trúc câu).
  final bool isSentence;

  /// Phiên âm IPA giọng Mỹ, vd "/ˈæp.əl/" - rỗng nếu là câu.
  final String ipa;

  /// Từ loại bằng tiếng Việt, vd "danh từ".
  final String partOfSpeech;

  /// Các nghĩa tiếng Việt khác (ngoài [vietnamese]).
  final List<String> meanings;

  final List<BilingualExample> examples;
  final List<String> synonyms;

  /// Ghi chú cách dùng / mẹo phát âm / cấu trúc câu (tiếng Việt).
  final String note;

  const DictionaryLookupResult({
    required this.query,
    required this.english,
    required this.vietnamese,
    this.isSentence = false,
    this.ipa = '',
    this.partOfSpeech = '',
    this.meanings = const [],
    this.examples = const [],
    this.synonyms = const [],
    this.note = '',
  });
}

/// Ai đang hỏi - quyết định độ sâu của lời giải thích ngữ pháp.
enum GrammarAudience {
  kid('👧 Bé (dễ hiểu)'),
  adult('🧑 Người lớn / TOEIC');

  const GrammarAudience(this.label);
  final String label;
}

/// Câu trả lời của phần "Hỏi đáp ngữ pháp" - giải thích bằng tiếng Việt kèm
/// ví dụ song ngữ, mẹo nhớ, câu hỏi gợi ý tiếp và (nếu có) bài ngữ pháp liên
/// quan trong app.
class GrammarAnswer {
  final String answer;
  final List<BilingualExample> examples;
  final String tip;
  final List<String> followUps;

  /// id bài trong `GrammarLessons.all` liên quan tới câu hỏi (rỗng nếu không có).
  final String relatedLessonId;

  const GrammarAnswer({
    required this.answer,
    this.examples = const [],
    this.tip = '',
    this.followUps = const [],
    this.relatedLessonId = '',
  });
}

/// 1 lượt hỏi - đáp (câu trả lời null = đang chờ hoặc lỗi).
class GrammarQaTurn {
  final String question;
  final GrammarAnswer? answer;

  const GrammarQaTurn(this.question, [this.answer]);
}
