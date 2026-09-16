/// Kết quả đánh giá câu trả lời của bé.
enum AnswerResult { correct, incorrect, empty }

/// Kết quả [EvaluateAnswer.wordLevelMatch] - đi kèm [words] (danh sách từ
/// MỤC TIÊU đã được CHUẨN HOÁ - cùng danh sách dùng để so khớp bên trong,
/// xem [EvaluateAnswer._normalize]) thay vì chỉ trả `List<bool>` đơn thuần.
///
/// SỬA LỖI (2026-08-23): bản đầu chỉ trả `List<bool>`, buộc UI (`DictionaryScreen`)
/// phải tự tách lại câu tiếng Anh GỐC (chưa chuẩn hoá) thành từng từ để ghép
/// với danh sách bool đó theo CHỈ SỐ - nhưng `_normalize` loại bỏ ký tự
/// không phải a-z (kể cả dấu nháy đơn), nên 1 từ có dấu nháy đơn như "it's"
/// tách thành 2 token ("it", "s") sau chuẩn hoá nhưng vẫn là 1 token ở câu
/// gốc ("it's") - làm SỐ TỪ 2 bên lệch nhau, khiến kết quả đúng/sai bị gán
/// NHẦM sang từ khác khi UI hiển thị. [words] giải quyết triệt để bằng cách
/// UI hiển thị TRỰC TIẾP từ trong [words] (đã đảm bảo cùng số lượng, cùng
/// thứ tự với [matches]) thay vì tự tách câu gốc.
class WordMatchResult {
  final List<String> words;
  final List<bool> matches;

  const WordMatchResult({required this.words, required this.matches});
}

/// Usecase: so khớp câu bé nói (nhận diện giọng nói trả về, có thể lẫn nhiều
/// từ như "it's a cat") với từ tiếng Anh đang được hỏi.
///
/// Cố tình khoan dung (không bắt buộc khớp tuyệt đối) vì:
/// - Bé 8 tuổi phát âm chưa chuẩn.
/// - speech_to_text đôi khi nhận thêm từ thừa ("a", "it's"...).
class EvaluateAnswer {
  const EvaluateAnswer();

  AnswerResult call({required String spokenText, required String targetWord}) {
    final spoken = _normalize(spokenText);
    final target = _normalize(targetWord);

    if (spoken.isEmpty) return AnswerResult.empty;

    final spokenTokens = spoken.split(' ');
    if (spokenTokens.contains(target)) return AnswerResult.correct;

    // Cho phép sai lệch nhỏ (phát âm/nhận diện chưa hoàn hảo), ví dụ
    // "ret" thay vì "red", "bananas" thay vì "banana".
    for (final token in spokenTokens) {
      if (token.length < 2) continue;
      if (token.startsWith(target) || target.startsWith(token)) {
        return AnswerResult.correct;
      }
      if (_levenshtein(token, target) <= _toleranceFor(target)) {
        return AnswerResult.correct;
      }
    }

    return AnswerResult.incorrect;
  }

  int _toleranceFor(String target) => target.length <= 4 ? 1 : 2;

  /// Biến thể của [call] dùng cho mục tra cứu từ điển (xem
  /// `DictionaryController`), khi [targetWord] có thể là 1 CÂU nhiều từ chứ
  /// không chỉ 1 từ đơn - KHÁC với [call] (dùng cho bài học, [targetWord]
  /// luôn là 1 từ vựng đơn, nên có thể so khớp từng token nhận diện được với
  /// đúng 1 từ mục tiêu). Ở đây so khớp CẢ CÂU đã chuẩn hoá với nhau bằng
  /// khoảng cách chỉnh sửa tổng thể, khoan dung hơn theo độ dài câu (câu càng
  /// dài càng cho phép lệch nhiều ký tự hơn, vì tổng số ký tự nhiều hơn).
  AnswerResult callPhrase({required String spokenText, required String targetPhrase}) {
    final spoken = _normalize(spokenText);
    final target = _normalize(targetPhrase);

    if (spoken.isEmpty) return AnswerResult.empty;
    if (spoken == target) return AnswerResult.correct;

    final tolerance = (target.length / 4).ceil().clamp(1, 6);
    if (_levenshtein(spoken, target) <= tolerance) return AnswerResult.correct;

    return AnswerResult.incorrect;
  }

  /// So khớp CHI TIẾT theo TỪNG TỪ giữa câu bé nói và câu mục tiêu - dùng để
  /// hiển thị từ nào bé đọc đúng/chưa đúng (xem `DictionaryScreen`), khác với
  /// [callPhrase] (chỉ trả về 1 kết quả DUY NHẤT cho CẢ CÂU). Trả về
  /// [WordMatchResult] gồm CẢ danh sách từ mục tiêu đã dùng để so khớp (SAU
  /// khi chuẩn hoá) LẪN kết quả đúng/sai tương ứng - xem doc comment của
  /// [WordMatchResult] để hiểu vì sao cần trả kèm danh sách từ thay vì chỉ
  /// `List<bool>` (SỬA LỖI 2026-08-23: tránh lệch vị trí tô màu ở UI).
  ///
  /// Thuật toán: với mỗi từ mục tiêu (theo đúng thứ tự), tìm 1 từ bé nói
  /// CHƯA được dùng cho từ mục tiêu nào khác mà khớp gần đúng (giống hệt,
  /// bắt đầu bằng nhau, hoặc lệch trong ngưỡng cho phép của [_toleranceFor])
  /// - đánh dấu từ đó đã dùng để tránh 1 từ bé nói được tính trùng cho 2 vị
  /// trí mục tiêu khác nhau (ví dụ bé chỉ nói "cat" 1 lần nhưng câu mục tiêu
  /// có 2 từ trùng nhau).
  WordMatchResult wordLevelMatch({required String spokenText, required String targetPhrase}) {
    final spokenWords = _normalize(spokenText).split(' ').where((w) => w.isNotEmpty).toList();
    final targetWords = _normalize(targetPhrase).split(' ').where((w) => w.isNotEmpty).toList();
    final usedSpokenIndices = <int>{};

    final matches = targetWords.map((target) {
      for (var i = 0; i < spokenWords.length; i++) {
        if (usedSpokenIndices.contains(i)) continue;
        final token = spokenWords[i];
        if (token.isEmpty) continue;
        final isMatch = token == target ||
            (token.length >= 2 && (token.startsWith(target) || target.startsWith(token))) ||
            _levenshtein(token, target) <= _toleranceFor(target);
        if (isMatch) {
          usedSpokenIndices.add(i);
          return true;
        }
      }
      return false;
    }).toList(growable: false);

    return WordMatchResult(words: targetWords, matches: matches);
  }

  String _normalize(String input) {
    final lower = input.toLowerCase().trim();
    final cleaned = lower.replaceAll(RegExp(r"[^a-z\s]"), ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Khoảng cách chỉnh sửa (edit distance) đơn giản giữa 2 chuỗi ngắn.
  int _levenshtein(String a, String b) {
    final la = a.length;
    final lb = b.length;
    if (la == 0) return lb;
    if (lb == 0) return la;

    var previousRow = List<int>.generate(lb + 1, (j) => j);

    for (var i = 0; i < la; i++) {
      final currentRow = List<int>.filled(lb + 1, 0);
      currentRow[0] = i + 1;
      for (var j = 0; j < lb; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        currentRow[j + 1] = [
          currentRow[j] + 1,
          previousRow[j + 1] + 1,
          previousRow[j] + cost,
        ].reduce((v, e) => v < e ? v : e);
      }
      previousRow = currentRow;
    }

    return previousRow[lb];
  }
}
