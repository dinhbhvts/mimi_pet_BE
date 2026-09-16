import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../domain/entities/picture_scene.dart';
import '../../domain/usecases/evaluate_answer.dart';
import '../../services/sound_service.dart';
import '../../services/speech_service.dart';
import '../../services/tts_service.dart';
import 'progress_controller.dart';

/// Các bước trong 1 phiên chơi 1 "Bài tranh": Mimi đọc câu hỏi -> bé trả lời
/// (chạm chọn/nói) -> Mimi chấm -> đúng/sai -> câu tiếp theo.
///
/// KHÁC [LessonSessionState] của `LessonController`: không có các trạng thái
/// chờ theo TỪNG DẠNG BÀI riêng (awaitingChoice/awaitingReorder/...) vì bài
/// tranh chỉ có 2 kiểu tương tác (chạm chọn HOẶC nói) - gộp chung vào
/// [awaitingAnswer], UI tự phân biệt hiển thị theo `currentQuestion.kind`
/// (xem `PictureScenePlayScreen`).
enum ScenePlaySessionState {
  notStarted,

  /// Mimi đang đọc to câu hỏi (TTS) - chưa cho bé trả lời.
  asking,

  /// Đang chờ bé trả lời - UI hiện nút chọn (choice/trueFalse) hoặc nút mic
  /// (speak) tuỳ `currentQuestion.kind`.
  awaitingAnswer,
  listening,
  evaluating,
  correct,
  incorrect,
  finished,
}

/// Điều phối 1 phiên chơi 1 [PictureScene] - đọc câu hỏi, nhận câu trả lời
/// (chạm chọn hoặc nói), chấm đúng/sai, thưởng sao.
///
/// CỐ TÌNH KHÔNG dùng [HeartsController]/trừ tim (khác `LessonController`) -
/// "Bài tranh" mang tính khám phá/luyện hiểu câu qua 1 khung cảnh, không phải
/// bài kiểm tra từ vựng nghiêm ngặt, nên trả lời sai chỉ đơn giản hiện đáp án
/// đúng rồi chuyển tiếp câu hỏi kế (không cho thử lại nhiều lần như Lesson,
/// và không giữ bé lại vì hết tim).
class ScenePlayController extends ChangeNotifier {
  ScenePlayController({
    required this._scene,
    required TtsService ttsService,
    required SpeechService speechService,
    required ProgressController progressController,
    required SoundService soundService,
    EvaluateAnswer evaluateAnswer = const EvaluateAnswer(),
  }) : _tts = ttsService,
       _speech = speechService,
       _progress = progressController,
       _sound = soundService,
       _evaluate = evaluateAnswer;

  final PictureScene _scene;
  final TtsService _tts;
  final SpeechService _speech;
  final ProgressController _progress;
  final SoundService _sound;
  final EvaluateAnswer _evaluate;

  int _index = 0;
  int _correctCount = 0;
  ScenePlaySessionState _state = ScenePlaySessionState.notStarted;
  bool _disposed = false;

  /// Lựa chọn bé vừa chạm (chỉ cho `choice`/`trueFalse`) - dùng để UI tô ĐỎ
  /// đúng lựa chọn bé vừa chọn sai, cùng tinh thần với
  /// `LessonController.selectedWordId` (Vòng 12). null khi sang câu mới.
  String? _selectedOption;

  PictureScene get scene => _scene;
  SceneQuestion get currentQuestion => _scene.questions[_index];
  int get currentIndex => _index;
  int get totalQuestions => _scene.questions.length;
  ScenePlaySessionState get state => _state;
  int get correctCount => _correctCount;
  bool get isFinished => _state == ScenePlaySessionState.finished;
  String? get selectedOption => _selectedOption;

  double get progressFraction =>
      _state == ScenePlaySessionState.finished ? 1.0 : _index / totalQuestions;

  /// Chỉ bấm được nút mic khi đang chờ trả lời VÀ câu hỏi hiện tại là dạng
  /// [SceneQuestionKind.speak] - tránh bấm nhầm lúc Mimi đang đọc câu hỏi
  /// hoặc lúc câu hỏi là dạng chạm chọn.
  bool get canTapTalk =>
      _state == ScenePlaySessionState.awaitingAnswer && currentQuestion.kind == SceneQuestionKind.speak;

  Future<void> start() async {
    _index = 0;
    _correctCount = 0;
    await _presentCurrentQuestion();
  }

  Future<void> _presentCurrentQuestion() async {
    _selectedOption = null;
    _setState(ScenePlaySessionState.asking);
    await _tts.speak(currentQuestion.prompt);
    if (_disposed) return;
    _setState(ScenePlaySessionState.awaitingAnswer);
  }

  /// Bé chạm 1 lựa chọn (dùng cho cả [SceneQuestionKind.choice] lẫn
  /// [SceneQuestionKind.trueFalse] - UI truyền [option] là `"True"`/`"False"`
  /// cho dạng đúng/sai).
  Future<void> submitChoice(String option) async {
    if (_state != ScenePlaySessionState.awaitingAnswer) return;
    if (currentQuestion.kind == SceneQuestionKind.speak) return;

    _selectedOption = option;
    unawaited(HapticFeedback.selectionClick());
    _setState(ScenePlaySessionState.evaluating);
    await Future.delayed(const Duration(milliseconds: 400));
    if (_disposed) return;

    if (option == currentQuestion.answer) {
      await _handleCorrect();
    } else {
      await _handleIncorrect();
    }
  }

  /// Bé bấm mic để nói câu trả lời (chỉ cho [SceneQuestionKind.speak]).
  Future<void> onTalkPressed() async {
    if (!canTapTalk) return;

    _setState(ScenePlaySessionState.listening);

    // BỌC try/catch (nhất quán với quy tắc đã rút ra từ Vòng 11: mọi lời gọi
    // SpeechService.listenOnce() PHẢI xử lý lỗi để không kẹt trạng thái) -
    // ScenePlayController KHÔNG sống app-scoped (bị dispose khi rời màn chơi
    // tranh) nên rủi ro thấp hơn Chat/Dictionary, nhưng vẫn áp dụng cho chắc.
    String recognized = '';
    try {
      final outcome = await _speech.listenOnce(
        listenFor: const Duration(seconds: 6),
        pauseFor: const Duration(seconds: 2),
      );
      recognized = outcome.recognizedText;
    } catch (_) {
      // Bỏ qua - coi như không nghe được gì, chấm như câu trả lời rỗng.
    }
    if (_disposed) return;

    _setState(ScenePlaySessionState.evaluating);
    await Future.delayed(const Duration(milliseconds: 400));
    if (_disposed) return;

    // `answer` HIỆN TẠI luôn là 1 từ đơn (xem scenes.json), nhưng phòng khi
    // nội dung sau này thêm câu trả lời nhiều từ, dùng `callPhrase` (so khớp
    // CẢ CÂU) thay vì `call` (chỉ so khớp TỪNG TOKEN với 1 từ mục tiêu) khi
    // `answer` có khoảng trắng - `call` với mục tiêu nhiều từ có thể chấm
    // đúng nhầm khi bé chỉ nói ĐÚNG 1 TỪ ĐẦU (vì `target.startsWith(token)`).
    final answer = currentQuestion.answer;
    final result = answer.contains(' ')
        ? _evaluate.callPhrase(spokenText: recognized, targetPhrase: answer)
        : _evaluate(spokenText: recognized, targetWord: answer);
    if (result == AnswerResult.correct) {
      await _handleCorrect();
    } else {
      await _handleIncorrect();
    }
  }

  Future<void> _handleCorrect() async {
    _correctCount++;
    unawaited(_sound.playCorrect());
    unawaited(HapticFeedback.mediumImpact());
    _setState(ScenePlaySessionState.correct);

    await _progress.addStars(1);
    if (_disposed) return;
    await Future.delayed(const Duration(milliseconds: 900));
    if (_disposed) return;

    await _goToNext();
  }

  Future<void> _handleIncorrect() async {
    unawaited(_sound.playWrong());
    unawaited(HapticFeedback.heavyImpact());
    _setState(ScenePlaySessionState.incorrect);

    // KHÔNG cho thử lại nhiều lần như Lesson (xem doc comment ở đầu lớp) -
    // chỉ giữ màn hình đủ lâu để bé thấy đáp án đúng UI tô ra (xem
    // `PictureScenePlayScreen`) rồi tự chuyển câu tiếp theo.
    await Future.delayed(const Duration(milliseconds: 1600));
    if (_disposed) return;

    await _goToNext();
  }

  Future<void> _goToNext() async {
    if (_index + 1 >= totalQuestions) {
      _setState(ScenePlaySessionState.finished);
      unawaited(_sound.playComplete());
      return;
    }
    _index++;
    await _presentCurrentQuestion();
  }

  void _setState(ScenePlaySessionState state) {
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

/// "Fire and forget" có chủ đích - xem giải thích tương tự ở cuối
/// `lesson_controller.dart`.
void unawaited(Future<void> future) {}
