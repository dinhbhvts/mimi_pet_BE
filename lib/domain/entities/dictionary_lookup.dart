/// Kết quả 1 lượt tra cứu ở tab "Từ điển" - dịch 2 CHIỀU (Anh<->Việt), tự
/// động phát hiện bé gõ tiếng Anh hay tiếng Việt (xem
/// `GeminiDictionaryService`). Luôn giữ cả 2 phía (Anh + Việt) trong cùng 1
/// kết quả, KHÔNG chỉ lưu bản dịch - vì [english] còn được dùng để phát âm
/// (TTS) và kiểm tra phát âm của bé (luôn kiểm tra phía tiếng Anh, vì đó mới
/// là thứ bé đang học - xem `DictionaryController`).
class DictionaryLookupResult {
  /// Câu/từ gốc bé đã gõ (giữ nguyên, chưa chuẩn hoá) - hiển thị lại cho bé
  /// thấy đúng những gì mình đã tra.
  final String query;

  final String english;
  final String vietnamese;

  const DictionaryLookupResult({
    required this.query,
    required this.english,
    required this.vietnamese,
  });
}
