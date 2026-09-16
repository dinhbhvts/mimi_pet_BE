import '../domain/entities/chat_message.dart';

/// Kết quả trả lời từ 1 "bộ não" chat của thú cưng - có thể là AI thật
/// ([GeminiChatService]) hoặc chatbot offline có sẵn câu trả lời
/// ([OfflineChatService]). [CompositeChatService] tự chọn giữa 2 cái này.
class ChatReplyResult {
  final String? reply;
  final String? error;

  /// true nếu câu trả lời này đến từ chatbot OFFLINE (không phải Gemini) -
  /// dùng để UI hiện ghi chú nhỏ cho phụ huynh biết, đặc biệt hữu ích khi
  /// Gemini ĐANG được cấu hình (có key) nhưng tạm thời không gọi được (mất
  /// mạng, hết hạn mức...) nên phải dùng tạm câu có sẵn cho đúng lượt này.
  final bool viaOffline;

  const ChatReplyResult._({this.reply, this.error, this.viaOffline = false});

  const ChatReplyResult.success(String reply, {bool viaOffline = false})
    : this._(reply: reply, viaOffline: viaOffline);

  const ChatReplyResult.failure(String error) : this._(error: error);

  bool get isSuccess => reply != null;
}

/// Interface chung cho "bộ não" trả lời chat của thú cưng - tách riêng
/// (thay vì [ChatController] phụ thuộc cứng vào [GeminiChatService]) để có
/// thể thay thế/kết hợp nhiều cách trả lời khác nhau:
/// - [GeminiChatService]: AI thật (Gemini), cần API key + mạng, trả lời tự
///   do theo System Prompt.
/// - [OfflineChatService]: chatbot offline, đối chiếu từ khoá với câu trả
///   lời có sẵn, KHÔNG cần mạng/key, luôn hoạt động được.
/// - [CompositeChatService]: tự động chọn giữa 2 cái trên (dùng Gemini nếu
///   có key, tự chuyển sang offline nếu chưa có key hoặc Gemini tạm lỗi).
abstract class ChatReplyService {
  /// [childName]: tên riêng của bé NẾU đã đặt trong Cài đặt (xem
  /// `ChildNameController.name`), hoặc null nếu chưa đặt - mỗi implementation
  /// tự chọn cách xưng hô mặc định phù hợp khi null (ví dụ [OfflineChatService]
  /// dùng "there" kiểu "Hi there!", [GeminiChatService] không thêm hướng dẫn
  /// gọi tên gì thêm). Dùng để thú cưng có thể gọi tên bé khi trò chuyện,
  /// thân thiện và cá nhân hoá hơn.
  Future<ChatReplyResult> sendMessage({
    required String petDisplayName,
    String? childName,
    required List<ChatMessage> history,
  });

  /// Kiểm tra lỗi NGỮ PHÁP (không phải phát âm - phát âm để dành cho bài
  /// học) trong 1 câu bé vừa gõ/nói - trả về gợi ý sửa ngắn gọn nếu có lỗi
  /// đáng chú ý, hoặc null nếu không có lỗi, câu quá ngắn để đánh giá, hoặc
  /// không có khả năng phân tích (chatbot offline, mất mạng, lỗi bất kỳ).
  /// KHÔNG BAO GIỜ throw - luôn an toàn để gọi "âm thầm" song song mà không
  /// ảnh hưởng luồng chat chính (xem [ChatController.sendText]).
  Future<String?> checkGrammar(String childText);

  /// Dịch 1 câu thoại của PET (tiếng Anh) sang tiếng Việt - dùng cho nút dịch
  /// 🌐 trong màn Chat (bé nhấn để xem nghĩa câu pet vừa nói). Trả về null
  /// nếu không dịch được (chatbot offline không có khả năng dịch thật, mất
  /// mạng, lỗi bất kỳ) - KHÔNG BAO GIỜ throw, để UI có thể hiện thông báo
  /// "không dịch được" thay vì crash (xem [ChatController.toggleTranslate]).
  Future<String?> translateToVietnamese(String englishText);
}
