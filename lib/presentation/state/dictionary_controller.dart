import 'package:flutter/foundation.dart';

import '../../domain/entities/dictionary_lookup.dart';
import '../../domain/usecases/evaluate_answer.dart';
import '../../services/dictionary_service.dart';
import '../../services/speech_service.dart';
import '../../services/tts_service.dart';

/// Kết quả kiểm tra phát âm của bé cho phía tiếng Anh của 1 lượt tra cứu -
/// tách riêng khỏi [AnswerResult] gốc (dù dùng lại [EvaluateAnswer] bên
/// trong) chỉ để đặt tên rõ ràng hơn trong ngữ cảnh tra từ điển.
typedef PronunciationCheck = AnswerResult;

/// Điều phối tab "Từ điển": tra nghĩa 1 từ/câu (2 chiều Anh<->Việt qua
/// [DictionaryService]), đọc to (TTS) phía tiếng Anh, và kiểm tra phát âm
/// của bé cho phía tiếng Anh đó (mic + [EvaluateAnswer.callPhrase] - CÙNG
/// usecase đang dùng cho câu hỏi dạng "nói" ở bài học, xem
/// `LessonController`).
///
/// Lịch sử tra cứu chỉ giữ trong bộ nhớ phiên làm việc hiện tại (KHÔNG lưu
/// SharedPreferences) - giống cách [ChatController] không lưu lịch sử chat,
/// giữ đơn giản cho MVP.
class DictionaryController extends ChangeNotifier {
  DictionaryController({
    required this._service,
    required TtsService ttsService,
    required SpeechService speechService,
  }) : _tts = ttsService,
       _speech = speechService;

  final DictionaryService _service;
  final TtsService _tts;
  final SpeechService _speech;
  final EvaluateAnswer _evaluator = const EvaluateAnswer();

  DictionaryLookupResult? _result;
  bool _isLookingUp = false;
  String? _error;
  bool _isListening = false;
  bool _isSpeaking = false;
  PronunciationCheck? _pronunciationResult;

  /// Kết quả so khớp TỪNG TỪ (song song với [_pronunciationResult] - chỉ 1
  /// verdict cho CẢ CÂU) - dùng để UI tô màu đúng/sai từng từ trong câu tiếng
  /// Anh khi bé kiểm tra phát âm (xem [EvaluateAnswer.wordLevelMatch]). Mang
  /// theo CẢ danh sách từ đã chuẩn hoá dùng để so khớp (xem [WordMatchResult])
  /// để UI hiển thị đúng khớp với kết quả, không tự tách lại câu gốc; null
  /// nghĩa là chưa kiểm tra phát âm lần nào cho kết quả hiện tại.
  WordMatchResult? _pronunciationWordResults;

  /// true nếu ĐÃ có API key Gemini - tính năng này KHÔNG có chế độ offline
  /// (xem [DictionaryService]), nên false nghĩa là tab chưa dùng được, UI
  /// hiện hướng dẫn thay vì ô nhập liệu (xem `dictionary_screen.dart`).
  bool get isConfigured => _service.isConfigured;

  DictionaryLookupResult? get result => _result;
  bool get isLookingUp => _isLookingUp;
  String? get error => _error;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;

  /// null nghĩa là chưa kiểm tra phát âm lần nào cho kết quả hiện tại (hoặc
  /// vừa tra 1 từ/câu MỚI - xem [lookup] tự xoá giá trị cũ).
  PronunciationCheck? get pronunciationResult => _pronunciationResult;

  /// Xem [_pronunciationWordResults].
  WordMatchResult? get pronunciationWordResults => _pronunciationWordResults;

  Future<void> lookup(String text) async {
    final trimmed = text.trim();
    // Chặn cả lúc đang nghe kiểm tra phát âm của kết quả CŨ - tránh trường
    // hợp bé gõ từ mới rồi tra ngay trong lúc mic của từ cũ vẫn đang mở, dẫn
    // tới kết quả phát âm trả về SAU khi đã hiện từ mới, gây hiểu lầm là
    // đang chấm điểm phát âm cho từ đang hiển thị (xem [checkPronunciation]).
    if (trimmed.isEmpty || _isLookingUp || _isListening) return;

    _isLookingUp = true;
    _error = null;
    _pronunciationResult = null;
    _pronunciationWordResults = null;
    notifyListeners();

    final outcome = await _service.lookup(trimmed);

    _isLookingUp = false;
    if (!outcome.isSuccess) {
      _error = outcome.error ?? 'lookup_failed';
      notifyListeners();
      return;
    }
    _result = outcome.result;
    notifyListeners();
  }

  /// Đọc to phía TIẾNG ANH của kết quả hiện tại - luôn đọc tiếng Anh dù bé
  /// gõ vào bằng tiếng Việt, vì mục đích chính là giúp bé nghe/luyện đúng
  /// phía đang học.
  Future<void> playPronunciation() async {
    final english = _result?.english;
    if (english == null || english.isEmpty || _isSpeaking) return;
    _isSpeaking = true;
    notifyListeners();
    try {
      await _tts.speak(english);
    } finally {
      _isSpeaking = false;
      notifyListeners();
    }
  }

  /// Bấm mic để bé đọc thử phía tiếng Anh của kết quả hiện tại, rồi so khớp
  /// với [EvaluateAnswer.callPhrase] - lưu kết quả vào [pronunciationResult]
  /// để UI hiện ✅/❌. Thời gian nghe/im lặng dùng chung mức với Chat (câu có
  /// thể dài hơn 1 từ vựng đơn ở bài học).
  Future<void> checkPronunciation() async {
    final target = _result?.english;
    if (target == null || target.isEmpty || _isListening || _isSpeaking) return;

    _isListening = true;
    _pronunciationResult = null;
    _pronunciationWordResults = null;
    notifyListeners();

    // BỌC try/finally (2026-08-23): nếu `listenOnce` throw (mic bị từ chối
    // quyền, plugin lỗi...) mà không bắt, `_isListening` sẽ kẹt ở true MÃI
    // MÃI vì [DictionaryController] sống ở cấp app -> nút "Kiểm tra phát âm"
    // bị vô hiệu hoá vĩnh viễn (cùng lớp lỗi đã gặp và sửa ở
    // `HomeScreen._handleTalkPressed`/`ChatController.startVoiceInput`).
    String recognizedText = '';
    try {
      final outcome = await _speech.listenOnce(
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 3),
      );
      recognizedText = outcome.recognizedText;
    } catch (_) {
      // Bỏ qua - coi như không nghe được gì, [EvaluateAnswer.callPhrase] bên
      // dưới tự trả về [AnswerResult.empty] cho chuỗi rỗng.
    } finally {
      _isListening = false;
    }
    _pronunciationResult = _evaluator.callPhrase(spokenText: recognizedText, targetPhrase: target);
    _pronunciationWordResults = _evaluator.wordLevelMatch(spokenText: recognizedText, targetPhrase: target);
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

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
        return 'Đang có nhiều lượt tra cứu quá, đợi 1 chút rồi thử lại nhé!';
      case 'blocked':
        return 'Xin lỗi, chưa tra được từ/câu này. Thử từ khác nhé!';
      case 'not_found':
        return 'Không tìm thấy nghĩa của từ/câu này - kiểm tra lại chính tả hoặc thử từ khác nhé!';
      case 'timeout':
      case 'network':
        return 'Không kết nối được internet lúc này. Kiểm tra mạng rồi thử lại nhé!';
      case 'empty_input':
        return 'Bé gõ 1 từ hoặc 1 câu để tra nhé!';
      case 'parse_error':
      case 'empty_response':
      case 'lookup_failed':
      default:
        return 'Chưa tra được từ này lúc này - kiểm tra mạng rồi thử lại nhé!';
    }
  }

  @override
  void dispose() {
    _speech.cancelListening();
    _tts.stop();
    super.dispose();
  }
}
