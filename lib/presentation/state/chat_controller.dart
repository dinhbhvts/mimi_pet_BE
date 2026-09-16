import 'package:flutter/foundation.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/pet_character.dart';
import '../../services/chat_reply_service.dart';
import '../../services/speech_service.dart';
import '../../services/tts_service.dart';
import 'child_name_controller.dart';
import 'pet_character_controller.dart';

/// Bé nhập tin nhắn bằng cách gõ chữ hay bấm mic nói - có thể đổi qua lại
/// bất cứ lúc nào (xem câu hỏi xác nhận với người dùng: "Cả hai: có tab
/// riêng, bé chọn gõ chữ HOẶC nói").
enum ChatInputMode { text, voice }

/// Điều phối màn "Tâm sự tự do với thú cưng": giữ lịch sử hội thoại (chỉ
/// trong bộ nhớ phiên làm việc hiện tại - KHÔNG lưu SharedPreferences, để
/// đơn giản và giảm thiểu dữ liệu lưu trữ), gọi [ChatReplyService] (thực tế
/// là `CompositeChatService` - tự chọn Gemini thật hoặc chatbot offline), và
/// đọc to câu trả lời của thú cưng qua [TtsService].
class ChatController extends ChangeNotifier {
  ChatController({
    required ChatReplyService chatService,
    required TtsService ttsService,
    required SpeechService speechService,
    required PetCharacterController petCharacterController,
    required ChildNameController childNameController,
  }) : _chatService = chatService,
       _tts = ttsService,
       _speech = speechService,
       _petCharacter = petCharacterController,
       _childName = childNameController;

  final ChatReplyService _chatService;
  final TtsService _tts;
  final SpeechService _speech;
  final PetCharacterController _petCharacter;
  final ChildNameController _childName;

  final List<ChatMessage> _messages = [];
  ChatInputMode _inputMode = ChatInputMode.text;
  bool _isSending = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String? _lastError;

  /// Chỉ số (trong [_messages]) của các tin nhắn PET đang HIỆN bản dịch tiếng
  /// Việt - bấm nút dịch 🌐 lần nữa sẽ ẩn đi (không xoá [ChatMessage.
  /// translatedText] đã dịch, chỉ ẩn/hiện, để bấm lại không tốn thêm request
  /// - xem [toggleTranslate]).
  final Set<int> _visibleTranslationIndices = {};

  /// Chỉ số tin nhắn ĐANG dịch (chờ Gemini trả lời) - null nếu không có tin
  /// nhắn nào đang dịch. Dùng để UI hiện trạng thái loading đúng nút, đồng
  /// thời chặn bấm dịch nhiều tin nhắn cùng lúc (giữ đơn giản, giống cách
  /// [_isSending] chặn gửi nhiều tin nhắn cùng lúc).
  int? _translatingMessageIndex;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  ChatInputMode get inputMode => _inputMode;
  bool get isSending => _isSending;
  bool get isListening => _isListening;
  bool isTranslationVisible(int index) => _visibleTranslationIndices.contains(index);
  bool isTranslating(int index) => _translatingMessageIndex == index;

  /// true trong lúc thú cưng ĐANG ĐỌC TO (TTS) 1 câu trả lời - dùng để màn
  /// Chat hiện đúng animation "đang nói" (xem [ChatScreen] - hoàn toàn tách
  /// biệt với [isSending], vì đọc to xảy ra SAU KHI đã có câu trả lời, còn
  /// [isSending] là lúc đang CHỜ câu trả lời từ AI/offline).
  bool get isSpeaking => _isSpeaking;
  String? get lastError => _lastError;

  /// LUÔN true kể từ khi API key Gemini chuyển sang cấu hình phía backend
  /// (biến môi trường `GEMINI_API_KEY` trên Render) - client không còn cách
  /// nào biết TRƯỚC (không gọi mạng) server đã cấu hình key hay chưa, nên
  /// coi như luôn "đã cấu hình"; nếu backend thật sự
  /// thiếu key, `CompositeChatService` vẫn tự rơi về chatbot offline cho
  /// từng lượt như bình thường (xem [showOfflineTag] ở từng tin nhắn).
  bool get isAiConfigured => true;

  void setInputMode(ChatInputMode mode) {
    if (_inputMode == mode) return;
    _inputMode = mode;
    notifyListeners();
  }

  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    _lastError = null;
    _messages.add(ChatMessage(role: ChatRole.user, text: trimmed, sentAt: DateTime.now()));
    // Vị trí tin nhắn của bé vừa thêm - dùng để "gắn" gợi ý ngữ pháp vào
    // ĐÚNG tin nhắn này sau khi phân tích xong (xem [_checkGrammar]). An
    // toàn vì chỉ có thao tác APPEND vào cuối danh sách, không có gì xoá/
    // chèn ở giữa làm lệch chỉ số này trước khi phân tích xong.
    final userMessageIndex = _messages.length - 1;
    _isSending = true;
    notifyListeners();

    final petName = PetCharacterInfo.all[_petCharacter.character]!.displayName;
    final result = await _chatService.sendMessage(
      petDisplayName: petName,
      childName: _childName.name,
      history: _messages,
    );

    _isSending = false;
    if (result.isSuccess) {
      final reply = result.reply!;
      _messages.add(
        ChatMessage(
          role: ChatRole.pet,
          text: reply,
          sentAt: DateTime.now(),
          viaOffline: result.viaOffline,
        ),
      );
      notifyListeners();
      // Đọc to câu trả lời cho bé nghe - không cần chờ để không làm treo UI
      // (isSending đã về false ngay từ trên, bé có thể gõ tiếp trong lúc thú
      // cưng đang đọc).
      unawaited(_speakReply(reply));
      // Kiểm tra ngữ pháp câu bé vừa gửi - hoàn toàn "âm thầm" phía sau,
      // không chặn UI, không ảnh hưởng gì tới luồng chat chính dù kết quả
      // thế nào (xem [_checkGrammar]).
      unawaited(_checkGrammar(trimmed, userMessageIndex));
    } else {
      _lastError = result.error;
      notifyListeners();
    }
  }

  /// Âm thầm kiểm tra lỗi NGỮ PHÁP (không phải phát âm - xem lựa chọn đã xác
  /// nhận: "Chỉ làm phần ngữ pháp, phát âm để dành cho bài học") cho tin
  /// nhắn CỦA BÉ vừa gửi, rồi gắn gợi ý (nếu có) vào đúng tin nhắn đó qua
  /// [ChatMessage.copyWith]. Chạy SAU khi đã có câu trả lời trò chuyện chính
  /// nên không làm bé phải chờ thêm mới thấy phản hồi của thú cưng. Chỉ có
  /// tác dụng khi đang dùng AI thật (xem [ChatReplyService.checkGrammar]) -
  /// chatbot offline không có khả năng phân tích ngôn ngữ.
  Future<void> _checkGrammar(String childText, int messageIndex) async {
    final note = await _chatService.checkGrammar(childText);
    if (note == null || note.trim().isEmpty) return;
    if (messageIndex < 0 || messageIndex >= _messages.length) return;
    final original = _messages[messageIndex];
    // Phòng hờ chỉ số bị lệch (không nên xảy ra với logic hiện tại) - chỉ
    // gắn gợi ý vào đúng tin nhắn CỦA BÉ, không bao giờ vào tin nhắn của thú
    // cưng.
    if (original.role != ChatRole.user) return;
    _messages[messageIndex] = original.copyWith(grammarNote: note.trim());
    notifyListeners();
  }

  /// Đọc to [text] + bật/tắt [isSpeaking] quanh lúc đọc - dùng chung cho cả
  /// lượt trả lời MỚI (trong [sendText]) lẫn bấm "Nghe lại" ([replay]) một
  /// tin nhắn CŨ.
  Future<void> _speakReply(String text) async {
    _isSpeaking = true;
    notifyListeners();
    try {
      await _tts.speak(text);
    } finally {
      _isSpeaking = false;
      notifyListeners();
    }
  }

  /// Đọc lại 1 tin nhắn CỦA THÚ CƯNG đã có sẵn trong lịch sử - dùng cho nút
  /// "Nghe lại" (🔁) ở mỗi tin nhắn (xem `chat_screen.dart`). CHỈ phát lại
  /// giọng đọc + animation (qua [isSpeaking]), KHÔNG gọi lại
  /// [ChatReplyService] - tin nhắn không đổi, không tốn thêm 1 lượt gọi AI.
  Future<void> replay(ChatMessage message) async {
    if (message.role != ChatRole.pet || _isSpeaking) return;
    await _speakReply(message.text);
  }

  /// Bấm nút dịch 🌐 ở 1 tin nhắn CỦA THÚ CƯNG: nếu đã dịch xong trước đó
  /// (`ChatMessage.translatedText != null`) chỉ cần ẩn/hiện lại, KHÔNG gọi
  /// lại AI; nếu chưa dịch, gọi [ChatReplyService.translateToVietnamese] rồi
  /// lưu kết quả vào đúng tin nhắn đó (giống cách [_checkGrammar] "gắn" gợi ý
  /// ngữ pháp vào tin nhắn của bé). Không dịch được (offline/lỗi mạng) thì
  /// giữ nguyên `_lastError` = 'translate_unavailable' để UI hiện thông báo
  /// ngắn, không ảnh hưởng gì tới lịch sử chat.
  Future<void> toggleTranslate(int messageIndex) async {
    if (messageIndex < 0 || messageIndex >= _messages.length) return;
    final message = _messages[messageIndex];
    if (message.role != ChatRole.pet) return;

    // Đã hiện sẵn -> bấm lại để ẨN đi.
    if (_visibleTranslationIndices.contains(messageIndex)) {
      _visibleTranslationIndices.remove(messageIndex);
      notifyListeners();
      return;
    }

    // Đã dịch xong từ trước -> chỉ cần hiện lại, không tốn thêm request.
    if (message.translatedText != null) {
      _visibleTranslationIndices.add(messageIndex);
      notifyListeners();
      return;
    }

    if (_translatingMessageIndex != null) return;
    _translatingMessageIndex = messageIndex;
    notifyListeners();

    final translated = await _chatService.translateToVietnamese(message.text);

    _translatingMessageIndex = null;
    if (translated == null || translated.trim().isEmpty) {
      _lastError = 'translate_unavailable';
      notifyListeners();
      return;
    }
    if (messageIndex >= _messages.length || _messages[messageIndex].role != ChatRole.pet) {
      notifyListeners();
      return;
    }
    _messages[messageIndex] = _messages[messageIndex].copyWith(translatedText: translated.trim());
    _visibleTranslationIndices.add(messageIndex);
    notifyListeners();
  }

  /// Bấm mic nói thay vì gõ chữ - dùng lại [SpeechService] đã có sẵn cho
  /// tính năng học từ vựng, NHƯNG với thời gian nghe dài hơn hẳn (xem
  /// [_voiceListenFor]/[_voicePauseFor]) vì đây là hội thoại TỰ DO nhiều từ,
  /// khác hẳn 1 từ vựng đơn hay câu chào ngắn ở Home/bài học.
  ///
  /// SỬA LỖI (2026-08-23): trước đây dùng `listenFor: 8s` với `pauseFor` mặc
  /// định 2s của [SpeechService] - với 1 câu tự do, bé 8 tuổi mới học tiếng
  /// Anh thường NGẬP NGỪNG hơn 2 giây giữa câu để nghĩ từ tiếp theo, khiến
  /// việc nhận diện DỪNG NGANG giữa chừng và chỉ nhận được 1 phần câu nói.
  ///
  /// CẬP NHẬT (2026-09-08): tăng `pauseFor` lên 4 giây ở trên thực ra KHÔNG
  /// giải quyết dứt điểm được vấn đề trên Android - tài liệu chính thức của
  /// package `speech_to_text` xác nhận Android có giới hạn cứng ở tầng hệ
  /// điều hành ("system imposed pause of from one to three seconds that
  /// cannot be overridden"), tức app xin `pauseFor` bao nhiêu cũng vậy, máy
  /// Android vẫn có thể tự dừng nghe sau ~1-3 giây im lặng. Phần sửa THẬT SỰ
  /// (tự động mở lại phiên nghe và nối câu khi bị dừng sớm) nay nằm trong
  /// [SpeechService.listenOnce] - xem doc comment ở đó. `_voicePauseFor` ở
  /// dưới vẫn giữ 4 giây vì không hại gì (vẫn có tác dụng thật trên
  /// iOS/desktop, nơi `pauseFor` được tôn trọng đúng như app yêu cầu).
  Future<void> startVoiceInput() async {
    if (_isSending || _isListening) return;
    _lastError = null;
    _isListening = true;
    notifyListeners();

    // BỌC try/finally (2026-08-23): nếu `listenOnce` throw (mic bị từ chối
    // quyền, plugin lỗi...) mà không bắt, `_isListening` sẽ kẹt ở true MÃI
    // MÃI vì [ChatController] sống ở cấp app (không bị dispose/tạo lại khi
    // chuyển tab) -> nút mic ở Chat bị vô hiệu hoá vĩnh viễn (đúng lớp lỗi
    // đã gặp và sửa ở `HomeScreen._handleTalkPressed` bằng try/catch/finally
    // tương tự - xem `home_screen.dart`).
    String recognizedText = '';
    try {
      final outcome = await _speech.listenOnce(
        listenFor: _voiceListenFor,
        pauseFor: _voicePauseFor,
        // true vì đây là hội thoại tự do nhiều câu - cần [SpeechService] tự
        // mở lại phiên nghe khi bị hệ điều hành (Android) dừng sớm giữa
        // chừng do bé ngập ngừng nghĩ từ tiếp theo (xem SỬA LỖI 2026-09-08 ở
        // `speech_service.dart`). Các nơi dùng giọng nói khác trong app (học
        // từ vựng, tra từ điển...) không truyền cờ này vì chỉ cần 1 từ/câu
        // ngắn, không cần - và không nên - chờ thêm.
        allowContinuation: true,
      );
      recognizedText = outcome.recognizedText;
    } catch (_) {
      // Bỏ qua - coi như không nghe được gì, giống hành vi "hết giờ, không
      // nhận diện được" (recognizedText rỗng bên dưới sẽ tự return).
    } finally {
      _isListening = false;
      notifyListeners();
    }

    if (recognizedText.trim().isEmpty) return;
    await sendText(recognizedText);
  }

  /// Bé bấm lại nút mic trong lúc ĐANG NÓI để chủ động báo "nói xong rồi",
  /// không cần đợi hết [_voiceListenFor] hay im lặng đủ [_voicePauseFor] -
  /// hữu ích khi câu nói ngắn hơn nhiều so với thời gian tối đa cho phép.
  /// Việc dừng ghi thật sự + lấy transcript vẫn diễn ra bên trong
  /// `listenOnce()` đang chạy dở trong [startVoiceInput] - từ bản sửa lỗi
  /// "cắt cụt câu" (2026-09-08), `listenOnce()` có thể đang chạy NHIỀU phiên
  /// nghe nối tiếp nhau bên trong (xem doc comment [SpeechService]), nhưng
  /// việc gọi [SpeechService.stopListening] ở đây vẫn luôn dừng hẳn được vì
  /// nó đặt cờ báo dừng TRƯỚC khi dừng phiên hiện tại, khiến vòng lặp bên
  /// trong không mở phiên mới nữa.
  Future<void> stopVoiceInput() async {
    if (!_isListening) return;
    await _speech.stopListening();
  }

  /// Tổng thời gian tối đa cho phép mic mở khi bé nói tự do ở Chat - đủ dài
  /// cho 1 câu nhiều từ, khác với 5s ở Home (chỉ chào hỏi ngắn) hay mặc định
  /// 6s ở bài học phát âm (chỉ 1 từ vựng).
  static const Duration _voiceListenFor = Duration(seconds: 20);

  /// Thời gian im lặng tối đa TRONG LÚC nói trước khi coi là "nói xong" -
  /// tăng từ mặc định 2s lên 4s để không cắt ngang lúc bé ngập ngừng nghĩ từ
  /// tiếp theo giữa câu (xem ghi chú sửa lỗi ở [startVoiceInput]).
  static const Duration _voicePauseFor = Duration(seconds: 4);

  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    notifyListeners();
  }

  /// Dịch mã lỗi kỹ thuật (xem [ChatReplyResult.error]) sang thông báo thân
  /// thiện, dễ hiểu cho bé/phụ huynh - KHÔNG hiện lỗi kỹ thuật thô.
  static String friendlyErrorMessage(String code) {
    switch (code) {
      case 'missing_key':
        return 'Chưa kết nối được AI - cần khai biến môi trường GEMINI_API_KEY trên Render '
            '(xem backend/README.md), không phải sửa trong app.';
      case 'invalid_key':
        return 'API key Gemini có vẻ chưa đúng hoặc đã hết hạn - kiểm tra lại biến môi trường '
            'GEMINI_API_KEY trên Render nhé.';
      case 'model_not_found':
        return 'Tên model Gemini không đúng/không còn hỗ trợ - đổi biến môi trường GEMINI_MODEL '
            'trên Render sang tên model còn hỗ trợ (xem deployment.md).';
      case 'rate_limited':
        return 'Mimi đang bận nghe nhiều bạn quá, đợi 1 chút rồi hỏi lại nhé!';
      case 'blocked':
        return 'Xin lỗi, mình chưa trả lời được câu này. Hỏi Mimi điều gì khác nhé!';
      case 'timeout':
      case 'network':
        return 'Không kết nối được internet lúc này. Kiểm tra mạng rồi thử lại nhé!';
      case 'translate_unavailable':
        return 'Chưa dịch được câu này lúc này - kiểm tra mạng hoặc thử lại nhé!';
      default:
        return 'Mimi hơi bối rối, bé thử hỏi lại nhé!';
    }
  }

  @override
  void dispose() {
    _speech.cancelListening();
    _tts.stop();
    super.dispose();
  }
}

/// "Fire and forget" có chủ đích - đọc to câu trả lời không cần chặn UI chờ
/// kết quả.
void unawaited(Future<void> future) {}
