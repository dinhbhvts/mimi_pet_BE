import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../domain/entities/lesson.dart';
import '../../domain/entities/pet_mood.dart';
import '../../domain/entities/word.dart';
import '../../domain/usecases/evaluate_answer.dart';
import '../../services/sound_service.dart';
import '../../services/speech_service.dart';
import '../../services/tts_service.dart';
import 'hearts_controller.dart';
import 'pet_controller.dart';
import 'progress_controller.dart';
import 'streak_controller.dart';

/// Các bước trong một phiên học 1 từ, theo đúng luồng ChatGPT đã thiết kế:
/// Mimi hỏi -> bé trả lời (nói/chọn/gõ/sắp xếp) -> Mimi nghe/chấm -> Mimi
/// "suy nghĩ" -> đúng/sai.
enum LessonSessionState {
  notStarted,
  speakingPrompt,
  readyToListen,

  /// Bé chọn đáp án bằng cách CHẠM (dùng chung cho [QuestionKind.choice] và
  /// [QuestionKind.fillBlank] - cùng cơ chế "chạm 1 trong vài nút", chỉ khác
  /// phần hiển thị câu hỏi).
  awaitingChoice,

  /// Bé chạm các mảnh từ theo đúng thứ tự để ghép câu ([QuestionKind.reorder]).
  awaitingReorder,

  /// Bé gõ bàn phím để trả lời ([QuestionKind.dictation]).
  awaitingTyping,
  listening,
  evaluating,
  correct,
  incorrect,

  /// Bé đã hết tim giữa bài - dừng bài học lại, chờ tim hồi phục.
  outOfHearts,
  finished,
}

/// Kiểu câu hỏi cho 1 từ - xen kẽ nhiều dạng bài tập kiểu Duolingo, không
/// chỉ mỗi "nói" như bản đầu:
enum QuestionKind {
  /// Mimi hỏi (kèm hình/màu), bé NÓI ra từ tiếng Anh - chấm bằng giọng nói.
  speak,

  /// Trắc nghiệm: bé CHỌN đúng từ trong vài lựa chọn.
  choice,

  /// Điền từ vào chỗ trống trong 1 câu ngắn (chọn từ vài lựa chọn, không gõ).
  fillBlank,

  /// Sắp xếp các từ xáo trộn thành 1 câu hoàn chỉnh.
  reorder,

  /// Nghe Mimi đọc từ rồi GÕ lại đúng chính tả.
  dictation,

  /// Luyện phát âm: bé nói theo Mimi, sau đó LUÔN được nghe lại phát âm
  /// chuẩn để so sánh - không chấm điểm nghiêm ngặt, không trừ tim (mục
  /// đích là luyện tập, không phải kiểm tra).
  pronunciation,
}

/// Điều phối toàn bộ luồng chơi 1 bài học: nói câu hỏi (TTS), nghe câu trả
/// lời (STT) / chờ bé chọn / gõ / sắp xếp câu, chấm đúng/sai
/// (EvaluateAnswer), cập nhật mood của Mimi (PetController), cộng sao
/// (ProgressController), trừ/giữ tim (HeartsController), ghi nhận streak
/// (StreakController) và phát âm thanh hiệu ứng (SoundService).
///
/// Đây là nơi chứa "business logic" của bài học - màn hình LessonScreen chỉ
/// việc render theo [state]/[currentWord]/[currentQuestionKind] và gọi các
/// hàm `on*` tương ứng.
class LessonController extends ChangeNotifier {
  LessonController({
    required this._lesson,
    required TtsService ttsService,
    required SpeechService speechService,
    required PetController petController,
    required ProgressController progressController,
    required HeartsController heartsController,
    required StreakController streakController,
    required SoundService soundService,
    EvaluateAnswer evaluateAnswer = const EvaluateAnswer(),
  }) : _tts = ttsService,
       _speech = speechService,
       _pet = petController,
       _progress = progressController,
       _hearts = heartsController,
       _streak = streakController,
       _sound = soundService,
       _evaluate = evaluateAnswer;

  static const int _maxAttemptsBeforeReveal = 2;

  final Lesson _lesson;
  final TtsService _tts;
  final SpeechService _speech;
  final PetController _pet;
  final ProgressController _progress;
  final HeartsController _hearts;
  final StreakController _streak;
  final SoundService _sound;
  final EvaluateAnswer _evaluate;

  int _index = 0;
  int _attemptsForCurrentWord = 0;
  int _starsEarnedThisSession = 0;
  LessonSessionState _state = LessonSessionState.notStarted;
  String _lastHeard = '';
  bool _disposed = false;

  /// Bài ôn lại (bé đã thuộc hết từ trong bài) sẽ không bị trừ tim khi trả
  /// lời sai - chỉ bài học từ mới mới "tính điểm" theo nghĩa mất tim.
  bool _costsHearts = true;

  List<Word> _currentChoiceOptions = const [];
  List<String> _reorderTokens = const [];
  final List<int> _reorderPickedIndices = [];

  /// Id của lựa chọn bé vừa CHẠM ở dạng bài trắc nghiệm/điền từ
  /// ([QuestionKind.choice]/[QuestionKind.fillBlank]) - bổ sung 2026-08-23 để
  /// UI ([_ChoiceButtons]) biết TÔ MÀU ĐỎ đúng lựa chọn bé vừa chọn sai (khác
  /// với đáp án đúng luôn được tô XANH). null nghĩa là chưa chọn gì cho lượt
  /// hiện tại - xoá khi sang từ mới ([_presentCurrentWord]) và khi bé thử lại
  /// cùng từ ([_handleIncorrect]).
  String? _selectedWordId;

  /// Streak MỚI cần báo cho UI ăn mừng (xem `StreakController.recordActivityToday`)
  /// - null nghĩa là không có gì mới (hôm nay đã tính streak rồi, hoặc chưa
  /// tới lúc hoàn thành bài). [consumeStreakCelebration] "lấy rồi xoá" giá
  /// trị này trong CÙNG 1 lần gọi để [LessonScreen] không hiện lặp lại hiệu
  /// ứng ăn mừng nếu widget rebuild nhiều lần liên tiếp cùng 1 khung hình.
  int? _pendingStreakCelebration;

  Lesson get lesson => _lesson;
  Word get currentWord => _lesson.words[_index];
  int get currentIndex => _index;
  int get totalWords => _lesson.words.length;
  LessonSessionState get state => _state;
  String get lastHeard => _lastHeard;
  int get starsEarnedThisSession => _starsEarnedThisSession;
  bool get isFinished => _state == LessonSessionState.finished;
  bool get isOutOfHearts => _state == LessonSessionState.outOfHearts;

  /// Đọc VÀ xoá streak mới cần ăn mừng (nếu có) trong CÙNG 1 lần gọi - xem
  /// [_pendingStreakCelebration]. Gọi 1 lần duy nhất từ `LessonScreen` ngay
  /// sau khi hiện màn "hoàn thành bài".
  int? consumeStreakCelebration() {
    final value = _pendingStreakCelebration;
    _pendingStreakCelebration = null;
    return value;
  }

  /// Các dạng bài khả dụng cho 1 từ - phụ thuộc dữ liệu từ đó có (câu mẫu để
  /// điền từ, câu để sắp xếp...). speak/choice/dictation luôn khả dụng.
  List<QuestionKind> _availableKindsFor(Word word) {
    final kinds = <QuestionKind>[QuestionKind.speak, QuestionKind.choice, QuestionKind.dictation];
    if (word.sentenceTemplate != null) kinds.add(QuestionKind.fillBlank);
    if ((word.sentenceWords?.length ?? 0) >= 3) kinds.add(QuestionKind.reorder);
    return kinds;
  }

  /// Dạng bài cho từ hiện tại - xoay vòng qua các dạng khả dụng theo vị trí
  /// từ trong bài (không ngẫu nhiên, để có thể dự đoán/kiểm tra được). Từ
  /// kiểu "repeat" (hello/goodbye...) LUÔN là [QuestionKind.pronunciation]
  /// vì mục đích của loại từ này là tập phát âm, không phải nhận biết nghĩa.
  QuestionKind get currentQuestionKind {
    if (currentWord.promptType == PromptType.repeat) return QuestionKind.pronunciation;
    final available = _availableKindsFor(currentWord);
    return available[_index % available.length];
  }

  /// Trạng thái chờ-trả-lời tương ứng với 1 dạng bài - dùng cả khi trình bày
  /// câu hỏi lần đầu lẫn khi cho bé thử lại (giữ đúng dạng bài, không đổi
  /// giữa chừng).
  LessonSessionState _stateForKind(QuestionKind kind) {
    switch (kind) {
      case QuestionKind.choice:
      case QuestionKind.fillBlank:
        return LessonSessionState.awaitingChoice;
      case QuestionKind.reorder:
        return LessonSessionState.awaitingReorder;
      case QuestionKind.dictation:
        return LessonSessionState.awaitingTyping;
      case QuestionKind.speak:
      case QuestionKind.pronunciation:
        return LessonSessionState.readyToListen;
    }
  }

  /// Danh sách đáp án trắc nghiệm cho từ hiện tại (dùng cho cả
  /// [QuestionKind.choice] và [QuestionKind.fillBlank] - rỗng nếu không phải
  /// 1 trong 2 dạng đó) - đã xáo trộn thứ tự, giữ nguyên trong suốt các lần
  /// thử lại của cùng 1 từ (chỉ tạo lại khi chuyển sang từ mới).
  List<Word> get choiceOptions => _currentChoiceOptions;

  /// Các mảnh từ (đã xáo trộn) cho dạng bài sắp xếp câu ([QuestionKind.reorder]).
  List<String> get reorderTokens => _reorderTokens;

  /// Vị trí (trong [reorderTokens]) mà bé đã chọn, theo đúng thứ tự bé chạm.
  List<int> get reorderPickedIndices => List.unmodifiable(_reorderPickedIndices);

  /// Xem [_selectedWordId].
  String? get selectedWordId => _selectedWordId;

  // Lưu ý: KHÔNG cho tap khi state == incorrect - lúc đó Mimi còn đang nói
  // "Try again!" (await _tts.speak trong _handleIncorrect). Chỉ cho tap lại
  // khi đã chuyển hẳn về readyToListen, tránh bé bấm 2 lần đè lên nhau khiến
  // 2 phiên nghe/nói chạy chồng chéo.
  bool get canTapTalk => _state == LessonSessionState.readyToListen;

  double get progressFraction =>
      _state == LessonSessionState.finished ? 1.0 : _index / totalWords;

  Future<void> start() async {
    _index = 0;
    _starsEarnedThisSession = 0;
    _costsHearts = _lesson.words.any((w) => !_progress.masteredWordIds.contains(w.id));

    if (!_hearts.hasHearts) {
      _setState(LessonSessionState.outOfHearts);
      return;
    }
    await _presentCurrentWord();
  }

  Future<void> _presentCurrentWord() async {
    _attemptsForCurrentWord = 0;
    _lastHeard = '';
    _reorderPickedIndices.clear();
    _selectedWordId = null;
    _setState(LessonSessionState.speakingPrompt);
    _pet.setMood(PetMood.talking);

    final word = currentWord;
    final kind = currentQuestionKind;
    _currentChoiceOptions = (kind == QuestionKind.choice || kind == QuestionKind.fillBlank)
        ? _buildChoiceOptions()
        : const [];
    _reorderTokens = kind == QuestionKind.reorder
        ? (List<String>.from(word.sentenceWords!)..shuffle())
        : const [];

    switch (kind) {
      case QuestionKind.pronunciation:
        await _tts.speak(word.en);
        if (_disposed) return;
        await Future.delayed(const Duration(milliseconds: 300));
        if (_disposed) return;
        await _tts.speak('Now you say it!');
        break;
      case QuestionKind.fillBlank:
        await _tts.speak('Fill in the blank!');
        break;
      case QuestionKind.reorder:
        await _tts.speak('Put the words in order!');
        break;
      case QuestionKind.dictation:
        await _tts.speak(word.en);
        break;
      case QuestionKind.speak:
      case QuestionKind.choice:
        await _tts.speak(word.promptText);
        break;
    }
    if (_disposed) return;

    _pet.setMood(PetMood.idle);
    _setState(_stateForKind(kind));
  }

  /// Chọn từ hiện tại + 2 từ khác trong cùng bài học làm "mồi nhử", xáo trộn
  /// vị trí. Nếu bài học quá ít từ (hiếm khi xảy ra), có thể trả về ít hơn 3
  /// lựa chọn - UI vẫn hoạt động bình thường với danh sách ngắn hơn.
  List<Word> _buildChoiceOptions() {
    final others = _lesson.words.where((w) => w.id != currentWord.id).toList()..shuffle();
    final distractors = others.take(2).toList();
    final options = [currentWord, ...distractors];
    options.shuffle();
    return options;
  }

  Future<void> onTalkPressed() async {
    if (!canTapTalk) return;

    _setState(LessonSessionState.listening);
    _pet.setMood(PetMood.listening);

    final outcome = await _speech.listenOnce();
    if (_disposed) return;

    await _processAnswerText(outcome.recognizedText);
  }

  /// Fallback KHÔNG dùng giọng nói cho [QuestionKind.speak]/[.pronunciation] -
  /// xem `TypeInsteadOfTalk` (widget) để biết lý do cần cái này (Safari trên
  /// iPhone/iPad hầu như không hỗ trợ speech_to_text). Dùng LẠI ĐÚNG logic
  /// chấm điểm với [onTalkPressed] (xem [_processAnswerText]) - chỉ khác
  /// nguồn lấy chữ (bàn phím thay vì micro).
  Future<void> onTypedAnswerSubmitted(String typed) async {
    if (!canTapTalk) return;
    if (typed.trim().isEmpty) return;
    await _processAnswerText(typed);
  }

  Future<void> _processAnswerText(String text) async {
    final kind = currentQuestionKind;
    _lastHeard = text;
    _setState(LessonSessionState.evaluating);
    _pet.setMood(PetMood.thinking);
    await Future.delayed(const Duration(milliseconds: 500));
    if (_disposed) return;

    if (kind == QuestionKind.pronunciation) {
      await _handlePronunciationPractice();
      return;
    }

    final result = _evaluate(spokenText: _lastHeard, targetWord: currentWord.en);
    if (result == AnswerResult.correct) {
      await _handleCorrect();
    } else {
      await _handleIncorrect();
    }
  }

  /// Luyện phát âm ([QuestionKind.pronunciation]) - KHÔNG chấm đúng/sai
  /// nghiêm ngặt (bé mới tập nói, không nên bị coi là "sai" và mất tim).
  /// Luôn khích lệ, luôn cho nghe lại phát âm chuẩn ngay sau đó để bé so
  /// sánh - đúng ý "đọc từ rồi nghe lại phát âm chuẩn".
  Future<void> _handlePronunciationPractice() async {
    _pet.setMood(PetMood.happy);
    _setState(LessonSessionState.correct);
    _starsEarnedThisSession++;
    unawaited(_sound.playCorrect());
    unawaited(HapticFeedback.mediumImpact());

    await _progress.addStars(1);
    await _progress.markWordMastered(currentWord.id);
    if (_disposed) return;

    await _tts.speak('Great try! Listen again:');
    if (_disposed) return;
    await Future.delayed(const Duration(milliseconds: 300));
    if (_disposed) return;
    await _tts.speak(currentWord.en);
    if (_disposed) return;
    await Future.delayed(const Duration(milliseconds: 500));
    if (_disposed) return;

    await _goToNextWord();
  }

  /// Bé chọn 1 đáp án trong chế độ trắc nghiệm hoặc điền từ ([QuestionKind.choice]
  /// / [QuestionKind.fillBlank]).
  Future<void> onChoiceSelected(Word selected) async {
    if (_state != LessonSessionState.awaitingChoice) return;

    _selectedWordId = selected.id;
    unawaited(HapticFeedback.selectionClick());
    _setState(LessonSessionState.evaluating);
    _pet.setMood(PetMood.thinking);
    await Future.delayed(const Duration(milliseconds: 400));
    if (_disposed) return;

    if (selected.id == currentWord.id) {
      await _handleCorrect();
    } else {
      await _handleIncorrect();
    }
  }

  /// Bé chạm 1 mảnh từ trong dạng bài sắp xếp câu ([QuestionKind.reorder]) -
  /// [tokenIndex] là vị trí trong [reorderTokens]. Tự động chấm khi đã chọn
  /// đủ số mảnh.
  void onReorderTapToken(int tokenIndex) {
    if (_state != LessonSessionState.awaitingReorder) return;
    if (_reorderPickedIndices.contains(tokenIndex)) return;
    if (tokenIndex < 0 || tokenIndex >= _reorderTokens.length) return;

    _reorderPickedIndices.add(tokenIndex);
    unawaited(HapticFeedback.selectionClick());
    notifyListeners();

    if (_reorderPickedIndices.length == _reorderTokens.length) {
      unawaited(_evaluateReorder());
    }
  }

  /// Bỏ mảnh từ được chọn gần nhất - cho bé sửa lại khi lỡ chạm nhầm thứ tự.
  void onReorderUndo() {
    if (_state != LessonSessionState.awaitingReorder) return;
    if (_reorderPickedIndices.isEmpty) return;
    _reorderPickedIndices.removeLast();
    notifyListeners();
  }

  Future<void> _evaluateReorder() async {
    _setState(LessonSessionState.evaluating);
    _pet.setMood(PetMood.thinking);
    await Future.delayed(const Duration(milliseconds: 400));
    if (_disposed) return;

    final answer = _reorderPickedIndices.map((i) => _reorderTokens[i]).join(' ').toLowerCase();
    final target = currentWord.sentenceWords!.join(' ').toLowerCase();

    if (answer == target) {
      await _handleCorrect();
    } else {
      // LƯU Ý (2026-08-23): KHÔNG `_reorderPickedIndices.clear()` ở đây nữa -
      // để nguyên câu bé vừa ghép sai cho UI tô màu đỏ trong lúc `incorrect`
      // (xem `_ReorderBoard`/[_handleIncorrect]), chỉ xoá khi thật sự cho bé
      // ghép lại (trong [_handleIncorrect]) hoặc khi chuyển sang từ mới
      // ([_presentCurrentWord] đã tự xoá).
      await _handleIncorrect();
    }
  }

  /// Bé gõ câu trả lời trong dạng bài chính tả ([QuestionKind.dictation]).
  Future<void> onDictationSubmitted(String typed) async {
    if (_state != LessonSessionState.awaitingTyping) return;
    if (typed.trim().isEmpty) return;

    _setState(LessonSessionState.evaluating);
    _pet.setMood(PetMood.thinking);
    await Future.delayed(const Duration(milliseconds: 300));
    if (_disposed) return;

    final result = _evaluate(spokenText: typed, targetWord: currentWord.en);
    if (result == AnswerResult.correct) {
      await _handleCorrect();
    } else {
      await _handleIncorrect();
    }
  }

  Future<void> _handleCorrect() async {
    _pet.setMood(PetMood.happy);
    _setState(LessonSessionState.correct);
    _starsEarnedThisSession++;
    unawaited(_sound.playCorrect());
    unawaited(HapticFeedback.mediumImpact());

    await _progress.addStars(1);
    await _progress.markWordMastered(currentWord.id);
    if (_disposed) return;

    await _tts.speak(currentWord.praiseText);
    if (_disposed) return;
    await Future.delayed(const Duration(milliseconds: 500));
    if (_disposed) return;

    await _goToNextWord();
  }

  Future<void> _handleIncorrect() async {
    _attemptsForCurrentWord++;
    _pet.setMood(PetMood.encourage);
    _setState(LessonSessionState.incorrect);
    unawaited(_sound.playWrong());
    unawaited(HapticFeedback.heavyImpact());

    if (_costsHearts) {
      await _hearts.loseHeart();
      if (_disposed) return;
      if (!_hearts.hasHearts) {
        unawaited(_sound.playHeartLost());
        await _tts.speak("Oops, out of hearts! Let's rest and try again later.");
        if (_disposed) return;
        _setState(LessonSessionState.outOfHearts);
        return;
      }
    }

    if (_attemptsForCurrentWord >= _maxAttemptsBeforeReveal) {
      await _tts.speak("It's ${currentWord.en}. Let's try the next one!");
      if (_disposed) return;
      await Future.delayed(const Duration(milliseconds: 400));
      if (_disposed) return;
      await _goToNextWord();
    } else {
      await _tts.speak('Try again!');
      if (_disposed) return;
      _pet.setMood(PetMood.idle);
      // Xoá lựa chọn/câu ghép SAI ngay TRƯỚC KHI cho bé thử lại (không xoá
      // sớm hơn - xem ghi chú ở [_evaluateReorder]) - để màu đỏ chỉ hiện
      // trong lúc `incorrect`, biến mất khi bé bắt đầu lượt thử mới.
      final kind = currentQuestionKind;
      if (kind == QuestionKind.reorder) {
        _reorderPickedIndices.clear();
      } else if (kind == QuestionKind.choice || kind == QuestionKind.fillBlank) {
        _selectedWordId = null;
      }
      // Giữ đúng dạng bài khi thử lại - không được vô tình đổi dạng bài
      // giữa chừng (ví dụ đang sắp xếp câu lại nhảy sang chế độ nói).
      _setState(_stateForKind(kind));
    }
  }

  Future<void> _goToNextWord() async {
    if (_index + 1 >= totalWords) {
      _pet.setMood(PetMood.happy, autoIdleAfter: const Duration(seconds: 3));
      _setState(LessonSessionState.finished);
      unawaited(_sound.playComplete());
      final newStreak = await _streak.recordActivityToday();
      if (newStreak != null) {
        _pendingStreakCelebration = newStreak;
        unawaited(_sound.playStreak());
        if (!_disposed) notifyListeners();
      }
      return;
    }
    _index++;
    await _presentCurrentWord();
  }

  void _setState(LessonSessionState state) {
    _state = state;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _speech.cancelListening();
    _tts.stop();
    super.dispose();
  }
}

/// "Fire and forget" có chủ đích cho các Future không cần chờ kết quả (ví
/// dụ phát âm thanh hiệu ứng, hoặc chấm điểm sắp xếp câu không cần UI đợi
/// trực tiếp giá trị trả về) - làm rõ đây là cố ý, không phải quên await.
void unawaited(Future<void> future) {}
