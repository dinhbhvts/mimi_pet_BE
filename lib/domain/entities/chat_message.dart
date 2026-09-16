import 'package:flutter/foundation.dart';

/// Ai là người gửi 1 tin nhắn trong màn "Tâm sự với thú cưng".
enum ChatRole { user, pet }

/// 1 tin nhắn trong cuộc trò chuyện tự do giữa bé và thú cưng.
@immutable
class ChatMessage {
  final ChatRole role;
  final String text;
  final DateTime sentAt;

  /// Chỉ có ý nghĩa với tin nhắn của pet (role == pet): true nếu câu trả
  /// lời này đến từ chatbot OFFLINE thay vì Gemini thật - xem
  /// `CompositeChatService`. Dùng để UI hiện ghi chú nhỏ cho phụ huynh biết
  /// khi nào 1 câu trả lời không phải AI thật (ví dụ lúc mất mạng).
  final bool viaOffline;

  /// Chỉ có ý nghĩa với tin nhắn CỦA BÉ (role == user): gợi ý sửa lỗi NGỮ
  /// PHÁP nhẹ nhàng cho câu bé vừa gõ/nói (KHÔNG phân tích phát âm - xem lựa
  /// chọn đã xác nhận của phụ huynh, phát âm để dành riêng cho bài học). null
  /// nghĩa là chưa phân tích xong (phân tích chạy "âm thầm" SAU khi tin nhắn
  /// đã hiển thị - xem `ChatController._checkGrammar`), không có lỗi đáng
  /// chú ý, hoặc đang dùng chatbot offline (không có khả năng phân tích ngôn
  /// ngữ thật). Tin nhắn của thú cưng luôn có giá trị null.
  final String? grammarNote;

  /// Chỉ có ý nghĩa với tin nhắn CỦA PET (role == pet): bản dịch tiếng Việt
  /// của câu thoại, được dịch "theo yêu cầu" khi bé nhấn nút dịch 🌐 (KHÔNG
  /// tự động dịch hết mọi tin nhắn để tiết kiệm request - xem
  /// `ChatController.toggleTranslate`). null nghĩa là CHƯA dịch (bé chưa
  /// nhấn nút, hoặc dịch thất bại/không khả dụng - ví dụ đang dùng chatbot
  /// offline không có khả năng dịch thật).
  final String? translatedText;

  const ChatMessage({
    required this.role,
    required this.text,
    required this.sentAt,
    this.viaOffline = false,
    this.grammarNote,
    this.translatedText,
  });

  /// Tạo bản sao với [grammarNote] và/hoặc [translatedText] mới - dùng để
  /// "gắn" kết quả phân tích ngữ pháp/dịch vào ĐÚNG tin nhắn đã gửi trước đó
  /// (xem `ChatController._checkGrammar`/`toggleTranslate`), vì [ChatMessage]
  /// là immutable nên không thể sửa trực tiếp field của tin nhắn đã có trong
  /// lịch sử.
  ChatMessage copyWith({String? grammarNote, String? translatedText}) => ChatMessage(
    role: role,
    text: text,
    sentAt: sentAt,
    viaOffline: viaOffline,
    grammarNote: grammarNote ?? this.grammarNote,
    translatedText: translatedText ?? this.translatedText,
  );
}
