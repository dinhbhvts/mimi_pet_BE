import '../domain/entities/dictionary_lookup.dart';

/// Kết quả 1 lượt gọi [DictionaryService.lookup] - mang theo MÃ LỖI cụ thể
/// khi thất bại (thay vì chỉ trả `null` như bản đầu) để [DictionaryController]
/// hiện đúng thông báo cho từng nguyên nhân (thiếu key, sai key, hết hạn
/// mức, bị chặn an toàn, mất mạng, lỗi phân tích phản hồi...) thay vì luôn
/// hiện chung 1 câu "kiểm tra mạng rồi thử lại" gây khó chẩn đoán khi lỗi lặp
/// lại - cùng nguyên tắc với [ChatReplyResult] (`chat_reply_service.dart`).
class DictionaryLookupOutcome {
  final DictionaryLookupResult? result;
  final String? error;

  const DictionaryLookupOutcome._({this.result, this.error});

  const DictionaryLookupOutcome.success(DictionaryLookupResult result) : this._(result: result);

  const DictionaryLookupOutcome.failure(String error) : this._(error: error);

  bool get isSuccess => result != null;
}

/// Interface cho tính năng tra cứu từ điển Anh<->Việt (tab "Từ điển") - dịch
/// 2 chiều 1 từ hoặc 1 câu bé gõ vào. KHÁC với [ChatReplyService]: không có
/// chatbot offline thay thế, vì dịch nghĩa cần hiểu ngôn ngữ thật sự (không
/// thể đối chiếu từ khoá đơn giản như `OfflineChatService`).
abstract class DictionaryService {
  /// LUÔN true - key Gemini giờ cấu hình phía backend, xem
  /// `GeminiDictionaryService.isConfigured`.
  bool get isConfigured;

  /// Dịch [text] (tự động phát hiện tiếng Anh hay tiếng Việt) sang ngôn ngữ
  /// còn lại. KHÔNG BAO GIỜ throw - mọi lỗi được gói vào
  /// [DictionaryLookupOutcome.failure] với 1 mã lỗi cụ thể.
  Future<DictionaryLookupOutcome> lookup(String text);
}
