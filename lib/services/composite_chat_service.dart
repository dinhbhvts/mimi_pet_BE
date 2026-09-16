import '../domain/entities/chat_message.dart';
import 'chat_reply_service.dart';
import 'gemini_chat_service.dart';
import 'offline_chat_service.dart';

/// Mã lỗi từ [GeminiChatService] coi là "tạm thời" (mất mạng, hết hạn mức,
/// server Google đang lỗi...) - những lỗi này KHÔNG phải do cấu hình sai
/// hay nội dung bị chặn, nên [CompositeChatService] tự động dùng tạm
/// [OfflineChatService] cho lượt chat đó thay vì bắt bé chờ/thấy lỗi.
bool _isTemporaryGeminiError(String? errorCode) {
  if (errorCode == null) return false;
  // 'missing_key' (2026-09-16): trước đây client TỰ BIẾT trước khi gọi mạng
  // (không có key thì không gọi Gemini) nên KHÔNG cần liệt vào đây - giờ key
  // nằm ở backend, 'missing_key' chỉ phát hiện được SAU 1 lượt gọi mạng thất
  // bại (HTTP 503) và nghĩa là NGƯỜI VẬN HÀNH (không phải bé) quên cấu hình
  // `GEMINI_API_KEY` trên Render - vẫn nên coi là lỗi tạm thời/phía vận hành,
  // dùng tạm offline thay vì bắt bé thấy lỗi kỹ thuật giữa lúc trò chuyện.
  if (errorCode == 'network' || errorCode == 'timeout' || errorCode == 'rate_limited' || errorCode == 'missing_key') {
    return true;
  }
  // http_500, http_502, http_503... - lỗi phía server Google, không phải lỗi
  // cấu hình của app (khác với http_400/403 = invalid_key, đã xử lý riêng).
  return errorCode.startsWith('http_5');
}

/// "Bộ não" chat thật sự được [ChatController] sử dụng - tự động CHỌN giữa
/// [GeminiChatService] (AI thật, qua backend proxy) và [OfflineChatService]
/// (câu trả lời có sẵn), theo đúng lựa chọn của người dùng: "Tự động - dùng
/// Gemini nếu có key, offline nếu chưa có key" (2026-08-21).
///
/// CẬP NHẬT (2026-09-16): key giờ cấu hình phía backend (không còn 1 cờ
/// client biết trước được), nên chỉ còn 1 tình huống dùng offline: Gemini
/// trả lỗi (bao gồm cả trường hợp backend thiếu key - lỗi HTTP 503, xem
///    [_isTemporaryGeminiError]) - dùng tạm offline CHO ĐÚNG LƯỢT ĐÓ, để bé
///    luôn nhận được phản hồi thay vì màn hình lỗi. Các lỗi KHÔNG tạm thời
///    (key sai/hết hạn, nội dung bị chặn an toàn) vẫn được báo thật cho phụ
///    huynh qua `ChatController.friendlyErrorMessage`, KHÔNG âm thầm che đi.
class CompositeChatService implements ChatReplyService {
  CompositeChatService({required GeminiChatService gemini, required OfflineChatService offline})
    : _gemini = gemini,
      _offline = offline;

  final GeminiChatService _gemini;
  final OfflineChatService _offline;

  @override
  Future<ChatReplyResult> sendMessage({
    required String petDisplayName,
    String? childName,
    required List<ChatMessage> history,
  }) async {
    if (!_gemini.isConfigured) {
      return _offline.sendMessage(petDisplayName: petDisplayName, childName: childName, history: history);
    }

    final result = await _gemini.sendMessage(
      petDisplayName: petDisplayName,
      childName: childName,
      history: history,
    );
    if (result.isSuccess) return result;

    if (_isTemporaryGeminiError(result.error)) {
      return _offline.sendMessage(petDisplayName: petDisplayName, childName: childName, history: history);
    }
    return result;
  }

  /// Chỉ kiểm tra ngữ pháp được khi ĐÃ cấu hình Gemini thật (offline không
  /// có khả năng hiểu ngôn ngữ - xem [OfflineChatService.checkGrammar]).
  /// Không cần biết lượt CHAT chính vừa rồi có phải dùng tạm offline hay
  /// không (do Gemini tạm lỗi) - [GeminiChatService.checkGrammar] tự an
  /// toàn (trả về null) nếu bản thân nó gặp lỗi/mất mạng lúc gọi.
  @override
  Future<String?> checkGrammar(String childText) {
    if (!_gemini.isConfigured) return Future.value(null);
    return _gemini.checkGrammar(childText);
  }

  /// Chỉ dịch được khi ĐÃ cấu hình Gemini thật (offline không hiểu ngôn ngữ -
  /// xem [OfflineChatService.translateToVietnamese]).
  @override
  Future<String?> translateToVietnamese(String englishText) {
    if (!_gemini.isConfigured) return Future.value(null);
    return _gemini.translateToVietnamese(englishText);
  }
}
