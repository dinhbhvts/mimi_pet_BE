import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../exam_engine/mock_test_engine.dart';
import '../../exam_engine/question_bank_models.dart';

/// Điều khiển 1 LƯỢT làm đề thi thử - tạo qua ChangeNotifierProvider ngay
/// lúc push route (cùng pattern với [LessonController], KHÔNG đăng ký toàn
/// cục ở app.dart) vì mỗi lượt làm bài độc lập, không cần sống sót khi bé
/// chuyển tab.
///
/// Đúng tinh thần [ExamScreen] (dùng 1 màn hình DUY NHẤT, tự chuyển giữa
/// "đang làm bài" <-> "kết quả" theo [isFinished] - giống cách [LessonScreen]
/// tự chuyển "đang chơi" <-> "hoàn thành" - KHÔNG Navigator.push thêm route
/// mới), controller này không cần lo việc chia sẻ state qua nhiều route.
class ExamSessionController extends ChangeNotifier {
  ExamSessionController({
    required QuestionBank bank,
    required TrackLevelConfig config,
    required TestMode mode,
    void Function(TestScore score)? onFinished,
  })  : _engine = MockTestEngine(bank),
        config = config,
        mode = mode,
        _onFinished = onFinished {
    _session = _engine.startSession(config, mode: mode);
    if (_session.timeLimitSeconds > 0) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    }
  }

  final MockTestEngine _engine;
  final TrackLevelConfig config;
  final TestMode mode;
  // Gọi 1 LẦN khi vừa nộp bài xong (xem [finish]) - dùng để đồng bộ điểm lên
  // CloudStateStore (xem `exam_home_screen.dart`/`exam_screen.dart`), TÁCH
  // RIÊNG khỏi engine để file này không cần biết gì về cloud/backend.
  final void Function(TestScore score)? _onFinished;
  late final TestSession _session;
  Timer? _ticker;

  int _currentIndex = 0;
  TestScore? _score;
  Map<String, dynamic>? _report;

  /// true SAU KHI bé bấm "Kiểm tra đáp án" cho câu ĐANG HIỂN THỊ (xem
  /// [checkAnswer]) - chỉ có ý nghĩa ở chế độ luyện tập ([isPracticeMode]),
  /// tự tắt lại khi chuyển câu ([goNext]/[goBack]) hoặc khi bé đổi câu trả
  /// lời sau khi đã xem đáp án ([answerCurrent]) để không hiện đáp án cũ lộ
  /// ra trước khi bé tự thử lại.
  bool _showFeedback = false;

  List<Question> get questions => _session.questions;
  int get currentIndex => _currentIndex;
  int get totalQuestions => _session.questions.length;
  bool get hasQuestions => _session.questions.isNotEmpty;
  Question get currentQuestion => _session.questions[_currentIndex];
  bool get isLastQuestion => _currentIndex == totalQuestions - 1;

  /// Chế độ luyện tập mới có "Kiểm tra đáp án"/giải thích ngay từng câu -
  /// chế độ thi thử có giờ giữ nguyên trải nghiệm thi thật (chỉ biết đúng/sai
  /// sau khi nộp CẢ bài), xem [checkAnswer].
  bool get isPracticeMode => mode == TestMode.practice;

  /// -1 = không giới hạn giờ (chế độ luyện tập).
  int get remainingSeconds => _session.remainingSeconds;

  bool get isFinished => _score != null;
  TestScore? get score => _score;
  Map<String, dynamic>? get report => _report;

  List<String>? answerFor(String questionId) => _session.answers[questionId];

  bool get showFeedback => _showFeedback;

  /// null = chưa trả lời (chưa có gì để chấm) hoặc câu nói (không chấm tự
  /// động được) - UI dựa vào đây để tô xanh/đỏ sau khi [checkAnswer].
  bool? get isCurrentAnswerCorrect {
    if (currentQuestion.questionType == QuestionType.speakingPrompt) return null;
    final answer = answerFor(currentQuestion.id);
    if (answer == null || answer.isEmpty) return null;
    return isAnswerCorrect(currentQuestion, answer);
  }

  /// Bé bấm "Kiểm tra đáp án" - chỉ HIỆN kết quả/giải thích cho câu hiện tại,
  /// KHÔNG ảnh hưởng gì tới điểm số cuối cùng (điểm vẫn tính lại từ đầu lúc
  /// [finish], không phụ thuộc bé đã "kiểm tra" bao nhiêu câu).
  void checkAnswer() {
    if (isFinished || answerFor(currentQuestion.id) == null) return;
    _showFeedback = true;
    notifyListeners();
  }

  void _onTick() {
    if (_session.isTimeUp && !isFinished) {
      finish();
      return;
    }
    notifyListeners();
  }

  void answerCurrent(List<String> answer) {
    if (isFinished) return;
    _session.submitAnswer(currentQuestion.id, answer);
    // Đổi đáp án sau khi đã xem giải thích - ẩn lại panel cũ, tránh bé thấy
    // "Đúng/Sai" của lựa chọn TRƯỚC đó lẫn với lựa chọn MỚI vừa đổi.
    _showFeedback = false;
    notifyListeners();
  }

  void goNext() {
    if (isFinished) return;
    if (isLastQuestion) {
      finish();
    } else {
      _currentIndex++;
      _showFeedback = false;
      notifyListeners();
    }
  }

  void goBack() {
    if (isFinished || _currentIndex == 0) return;
    _currentIndex--;
    _showFeedback = false;
    notifyListeners();
  }

  void finish() {
    if (isFinished) return;
    _ticker?.cancel();
    _score = _engine.finishAndScore(_session, config);
    _report = buildReport(_score!);
    _onFinished?.call(_score!);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
