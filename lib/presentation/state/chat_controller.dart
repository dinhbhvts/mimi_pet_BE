import 'package:flutter/foundation.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/pet_character.dart';
import '../../services/chat_reply_service.dart';
import '../../services/cloud_state_store.dart';
import '../../services/speech_service.dart';
import '../../services/tts_service.dart';
import 'child_name_controller.dart';
import 'pet_character_controller.dart';

/// Bé nhập tin nhắn bằng cách gõ chữ hay bấm mic nói - có thể đổi qua lại
/// bất cứ lúc nào (xem câu hỏi xác nhận với người dùng: "Cả hai: có tab
/// riêng, bé chọn gõ chữ HOẶC nói").
enum ChatInputMode { text, voice }

/// Nơi lưu lịch sử chat - tách interface để test dùng bản trong bộ nhớ.
abstract class ChatHistoryStorage {
  List<dynamic> load();
  void save(List<Map<String, dynamic>> messages);
}

/// Lưu lịch sử chat trong state đồng bộ cloud (cùng chỗ với tiến độ của bé):
/// không mất khi Safari trên iPhone tự đóng tab chạy nền / tải lại trang, và
/// mở trên máy khác vẫn thấy cuộc trò chuyện cũ.
class CloudChatHistoryStorage implements ChatHistoryStorage {
  CloudChatHistoryStorage(this._store);

  final CloudStateStore _store;
  static const key = 'chatHistory';

  @override
  List<dynamic> load() => _store.getRaw<List<dynamic>>(key) ?? const [];

  @override
  void save(List<Map<String, dynamic>> messages) => _store.setRaw(key, messages);
}

/// Điều phối màn "Tâm sự tự do với thú cưng": giữ lịch sử hội thoại (lưu
/// [maxStoredMessages] tin gần nhất qua [ChatHistoryStorage] - trước
/// 2026-10-01 chỉ giữ trong bộ nhớ nên mất sạch mỗi khi Safari iOS đóng tab
/// nền), gọi [ChatReplyService] (thực tế
/// là `CompositeChatService` - tự chọn Gemini thật hoặc chatbot offline), và
/// đọc to câu trả lời của thú cưng qua [TtsService].
class ChatController extends ChangeNotifier {
  ChatController({
    required this._chatService,
    required TtsService ttsService,
    required SpeechService speechService,
    required PetCharacterController petCharacterController,
    required ChildNameController childNameController,
    ChatHistoryStorage? historyStorage,
  }) : _tts = ttsService,
       _speech = speechService,
       _petCharacter = petCharacterController,
       _childName = childNameController,
       _history = historyStorage {
    _restoreHistory();
  }

  final ChatReplyService _chatService;
  final TtsService _tts;
  final SpeechService _speech;
  final PetCharacterController _petCharacter;
  final ChildNameController _childName;
  final ChatHistoryStorage? _history;

  /// Số tin nhắn gần nhất được lưu lại - đủ để bé xem lại buổi trò chuyện,
  /// không làm state đồng bộ phình to theo thời gian.
  static const int maxStoredMessages = 40;

  final List<ChatMessage> _messages = [];

  void _restoreHistory() {
    final stored = _history?.load() ?? const [];
    for (final json in stored) {
      final message = ChatMessage.fromJson(json);
      if (message != null) _messages.add(message);
    }
  }

  void _persistHistory() {
    final history = _history;
    if (history == null) return;
    final start = _messages.length > maxStoredMessages ? _messages.length - maxStoredMessages : 0;
    history.save([for (final m in _messages.skip(start)) m.toJson()]);
  }

  /// Tăng mỗi lần xoá lịch sử - kết quả ngữ pháp/dịch về SAU khi đã xoá
  /// (chỉ số tin nhắn không còn đúng nữa) sẽ bị bỏ qua.
  int _historyEpoch = 0;

  /// Xoá toàn bộ cuộc trò chuyện (nút 🗑 ở màn Chat).
  Future<void> clearHistory() async {
    if (_isSending) return;
    await _tts.stop();
    _historyEpoch++;
    _messages.clear();
    _visibleTranslationIndices.clear();
    _translatingMessageIndex = null;
    _isSpeaking = false;
    _lastError = null;
    _suggestions = const [];
    _voiceDraft = null;
    _persistHistory();
    notifyListeners();
  }

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

  /// Câu gợi ý bé có thể nói tiếp - lấy từ lượt trả lời gần nhất (xem
  /// [ChatReplyResult.suggestions]).
  List<String> _suggestions = const [];

  /// Câu mở đầu khi chưa có tin nhắn nào.
  static const starterSuggestions = ['Hello! How are you?', "What's your name?", 'I like cats.', 'Tell me a joke!'];

  /// Khi đã có lịch sử nhưng chưa có gợi ý (vd vừa mở lại app).
  static const followUpSuggestions = ['Tell me more!', 'What do you like?', "Let's play a game!"];

  /// Nút gợi ý nhanh dưới khung chat - ẩn trong lúc đang chờ trả lời/đang nghe.
  List<String> get suggestions {
    if (_isSending || _isListening) return const [];
    if (_suggestions.isNotEmpty) return _suggestions;
    return _messages.isEmpty ? starterSuggestions : followUpSuggestions;
  }

  /// Chữ mic nghe được (chế độ nói) đang CHỜ bé xem lại/sửa rồi mới gửi -
  /// trước 2026-10-01 nghe xong là gửi luôn, nghe sai bé không sửa được.
  String? _voiceDraft;
  String? get voiceDraft => _voiceDraft;

  /// Chữ đang nghe được TRONG LÚC bé nói (hiện ngay trên nút mic).
  String _partialTranscript = '';
  String get partialTranscript => _partialTranscript;

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
    final epoch = _historyEpoch;
    _voiceDraft = null;
    _suggestions = const [];
    _isSending = true;
    _persistHistory();
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
          // Bản dịch có sẵn trong cùng lượt -> bấm 🌐 hiện ngay, không gọi AI.
          translatedText: result.translation,
        ),
      );
      _suggestions = result.suggestions;
      final tip = result.grammarTip;
      if (result.grammarChecked && tip != null && tip.trim().isNotEmpty) {
        _messages[userMessageIndex] = _messages[userMessageIndex].copyWith(grammarNote: tip.trim());
      }
      _persistHistory();
      notifyListeners();
      // Đọc to câu trả lời cho bé nghe - không cần chờ để không làm treo UI
      // (isSending đã về false ngay từ trên, bé có thể gõ tiếp trong lúc thú
      // cưng đang đọc).
      unawaited(_speakReply(reply));
      // Chưa kiểm tra ngữ pháp trong cùng lượt (chatbot offline, hoặc Gemini
      // trả chữ thường thay vì JSON) -> kiểm tra riêng "âm thầm" như cách cũ,
      // không chặn UI (xem [_checkGrammar]).
      if (!result.grammarChecked) unawaited(_checkGrammar(trimmed, userMessageIndex, epoch));
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
  Future<void> _checkGrammar(String childText, int messageIndex, int epoch) async {
    final note = await _chatService.checkGrammar(childText);
    if (note == null || note.trim().isEmpty || epoch != _historyEpoch) return;
    if (messageIndex < 0 || messageIndex >= _messages.length) return;
    final original = _messages[messageIndex];
    // Phòng hờ chỉ số bị lệch (không nên xảy ra với logic hiện tại) - chỉ
    // gắn gợi ý vào đúng tin nhắn CỦA BÉ, không bao giờ vào tin nhắn của thú
    // cưng.
    if (original.role != ChatRole.user) return;
    _messages[messageIndex] = original.copyWith(grammarNote: note.trim());
    _persistHistory();
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
    final epoch = _historyEpoch;
    notifyListeners();

    final translated = await _chatService.translateToVietnamese(message.text);
    if (epoch != _historyEpoch) return; // đã xoá lịch sử trong lúc chờ dịch

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
    _persistHistory();
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
    _voiceDraft = null;
    _partialTranscript = '';
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
        onPartial: (text) {
          _partialTranscript = text;
          notifyListeners();
        },
      );
      recognizedText = outcome.recognizedText;
    } catch (_) {
      // Bỏ qua - coi như không nghe được gì, giống hành vi "hết giờ, không
      // nhận diện được" (recognizedText rỗng bên dưới sẽ tự return).
    } finally {
      _isListening = false;
      _partialTranscript = '';
      // Không gửi ngay: đưa vào bản nháp để bé xem lại, sửa nếu mic nghe sai,
      // rồi mới bấm gửi (xem [sendVoiceDraft]).
      final heard = recognizedText.trim();
      if (heard.isNotEmpty) _voiceDraft = heard;
      notifyListeners();
    }
  }

  /// Gửi bản nháp giọng nói - [edited] là chữ bé đã sửa (nếu có).
  Future<void> sendVoiceDraft(String edited) async {
    final text = edited.trim();
    _voiceDraft = null;
    if (text.isEmpty) {
      notifyListeners();
      return;
    }
    await sendText(text);
  }

  /// Bỏ bản nháp giọng nói (bé muốn nói lại).
  void discardVoiceDraft() {
    if (_voiceDraft == null) return;
    _voiceDraft = null;
    notifyListeners();
  }

  /// Bé chạm 1 câu gợi ý: Mimi đọc mẫu câu đó cho bé nghe; ở chế độ nói thì
  /// đưa vào bản nháp (bé có thể tự nói lại hoặc gửi luôn), ở chế độ gõ thì
  /// màn Chat tự điền vào ô nhập (xem `chat_screen.dart`).
  void useSuggestion(String text) {
    if (_isSending || _isListening) return;
    if (_inputMode == ChatInputMode.voice) {
      _voiceDraft = text;
      notifyListeners();
    }
    unawaited(_speakReply(text));
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
