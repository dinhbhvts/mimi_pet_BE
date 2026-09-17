// mock_test_engine.dart
//
// Engine "làm đề thi thử" TỔNG QUÁT — dùng chung cho cả track YLE và TOEIC.
// Không phụ thuộc Flutter/UI: nhận vào 1 QuestionBank + 1 TrackLevelConfig,
// trả ra 1 TestSession để UI hiển thị, rồi chấm điểm khi nộp bài.
//
// Cách UI dùng (gợi ý):
//   final engine = MockTestEngine(bank);
//   final session = engine.startSession(config, mode: TestMode.mockTest);
//   // ... UI render session.questions[i], gọi session.submitAnswer(...) mỗi khi
//   //     user chọn đáp án, theo dõi session.remainingSeconds cho đồng hồ đếm ngược
//   final score = engine.finishAndScore(session, config);
//   final report = buildReport(score, lessonRecommendationsByTag: {...});

import 'dart:math';

import 'question_bank_models.dart';

/// Chế độ làm bài.
enum TestMode { practice, mockTest }

/// 1 phiên làm bài do engine tạo ra, độc lập theo user/lượt làm.
class TestSession {
  final String sessionId;
  final ExamTrack track;
  final String level;
  final TestMode mode;
  final List<Question> questions;
  final Map<String, List<String>> answers = {}; // questionId -> đáp án user
  final DateTime startedAt;
  DateTime? submittedAt;
  final int timeLimitSeconds; // 0 = không giới hạn (luôn đúng khi mode=practice)

  TestSession({
    required this.sessionId,
    required this.track,
    required this.level,
    required this.mode,
    required this.questions,
    required this.timeLimitSeconds,
  }) : startedAt = DateTime.now();

  int get elapsedSeconds =>
      (submittedAt ?? DateTime.now()).difference(startedAt).inSeconds;

  /// -1 nghĩa là không giới hạn giờ (chế độ luyện tập).
  int get remainingSeconds =>
      timeLimitSeconds <= 0 ? -1 : max(0, timeLimitSeconds - elapsedSeconds);

  bool get isTimeUp => timeLimitSeconds > 0 && remainingSeconds <= 0;

  void submitAnswer(String questionId, List<String> answer) {
    answers[questionId] = answer;
  }

  void finish() {
    submittedAt ??= DateTime.now();
  }
}

/// Kết quả chấm điểm — dùng chung cho cả 2 track, phần không áp dụng để null.
class TestScore {
  final int rawCorrect;
  final int rawTotal; // không tính các câu speaking (xem [ungradedCount])
  final int ungradedCount; // số câu speaking cần người chấm thủ công
  final Map<Skill, double> accuracyBySkill; // 0.0 - 1.0
  final Map<String, double> accuracyByTag; // theo topic/tag -> tìm điểm yếu
  final Map<Skill, int>? shieldsBySkill; // YLE: 1-5 khiên
  final Map<String, int>? toeicScaledScore; // {listening, reading, total}
  final List<String> weakTags; // tag có accuracy thấp nhất -> gợi ý ôn lại

  const TestScore({
    required this.rawCorrect,
    required this.rawTotal,
    this.ungradedCount = 0,
    required this.accuracyBySkill,
    required this.accuracyByTag,
    this.shieldsBySkill,
    this.toeicScaledScore,
    required this.weakTags,
  });

  double get percentage => rawTotal == 0 ? 0 : rawCorrect / rawTotal;

  Map<String, dynamic> toJson() => {
        'rawCorrect': rawCorrect,
        'rawTotal': rawTotal,
        'ungradedCount': ungradedCount,
        'percentage': percentage,
        'accuracyBySkill': accuracyBySkill.map((k, v) => MapEntry(k.name, v)),
        'accuracyByTag': accuracyByTag,
        if (shieldsBySkill != null)
          'shieldsBySkill':
              shieldsBySkill!.map((k, v) => MapEntry(k.name, v)),
        if (toeicScaledScore != null) 'toeicScaledScore': toeicScaledScore,
        'weakTags': weakTags,
      };
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Chấm 1 câu trả lời của user so với đáp án đúng trong ngân hàng câu hỏi -
/// PUBLIC (không còn `_isCorrect` riêng tư) vì [ExamSessionController] cũng
/// cần dùng lại đúng logic này để hiện "Đúng/Sai" NGAY khi bé bấm "Kiểm tra
/// đáp án" ở chế độ luyện tập, không đợi tới lúc nộp cả bài.
bool isAnswerCorrect(Question q, List<String>? userAnswer) {
  if (userAnswer == null || userAnswer.isEmpty) return false;
  switch (q.questionType) {
    case QuestionType.multipleChoice:
    case QuestionType.trueFalse:
      return userAnswer.length == 1 &&
          userAnswer.first == q.correctAnswer.first;
    case QuestionType.ordering:
    case QuestionType.listenAndColor:
    case QuestionType.listenAndNumber:
      return _listEquals(userAnswer, q.correctAnswer);
    case QuestionType.matching:
      return userAnswer.length == q.correctAnswer.length &&
          Set.from(userAnswer).containsAll(q.correctAnswer);
    case QuestionType.fillBlank:
    case QuestionType.shortAnswer:
      final normalizedUser = userAnswer.first.trim().toLowerCase();
      return q.correctAnswer
          .map((a) => a.trim().toLowerCase())
          .contains(normalizedUser);
    case QuestionType.speakingPrompt:
      // Speaking không chấm tự động trong engine này — xem _baseScore().
      return false;
  }
}

/// Interface cho các cách quy đổi điểm khác nhau theo từng track.
abstract class ScoringStrategy {
  TestScore score(TestSession session);
}

/// Tính % đúng theo từng skill + theo tag, KHÔNG quy đổi thang điểm riêng.
/// Dùng làm fallback hoặc cho luyện tập tự do khi chưa cần thang điểm chính thức.
class RawPercentageScoring implements ScoringStrategy {
  @override
  TestScore score(TestSession session) => _baseScore(session);
}

/// Quy đổi ra "khiên" (shield) 1-5 theo từng skill, phỏng theo cách Cambridge
/// YLE báo kết quả bằng khiên thay vì điểm số đỗ/trượt.
///
/// LƯU Ý: đây là thang quy đổi TỰ THIẾT KẾ cho mục đích luyện tập trong app,
/// KHÔNG phải thang điểm chính thức của Cambridge English (thang thật không
/// được công bố công khai dưới dạng công thức đơn giản).
class YleShieldScoringStrategy implements ScoringStrategy {
  @override
  TestScore score(TestSession session) {
    final base = _baseScore(session);
    final shields = <Skill, int>{
      for (final entry in base.accuracyBySkill.entries)
        entry.key: _accuracyToShield(entry.value),
    };
    return TestScore(
      rawCorrect: base.rawCorrect,
      rawTotal: base.rawTotal,
      ungradedCount: base.ungradedCount,
      accuracyBySkill: base.accuracyBySkill,
      accuracyByTag: base.accuracyByTag,
      shieldsBySkill: shields,
      weakTags: base.weakTags,
    );
  }

  int _accuracyToShield(double acc) {
    if (acc >= 0.90) return 5;
    if (acc >= 0.75) return 4;
    if (acc >= 0.60) return 3;
    if (acc >= 0.40) return 2;
    return 1;
  }
}

/// Quy đổi GẦN ĐÚNG ra thang điểm TOEIC 10-990 (mỗi phần Listening/Reading
/// 5-495, theo cấu trúc 100 câu/phần đúng chuẩn kỳ thi thật).
///
/// LƯU Ý QUAN TRỌNG: ETS không công bố công thức quy đổi chính thức — điểm
/// thật được cân bằng độ khó (equating) riêng theo từng đề. Đây là xấp xỉ
/// TUYẾN TÍNH đơn giản (đúng 0 câu → 5 điểm, đúng hết 100 câu → 495 điểm) để
/// người học ước lượng trình độ khi luyện tập trong app — KHÔNG dùng để suy
/// ra điểm thi thật một cách chính xác. Nên ghi rõ điều này trên UI kết quả.
class ToeicScaledScoringStrategy implements ScoringStrategy {
  @override
  TestScore score(TestSession session) {
    final base = _baseScore(session);

    final listeningQs =
        session.questions.where((q) => q.skill == Skill.listening).toList();
    final readingQs =
        session.questions.where((q) => q.skill == Skill.reading).toList();

    final listeningCorrect =
        listeningQs.where((q) => isAnswerCorrect(q, session.answers[q.id])).length;
    final readingCorrect =
        readingQs.where((q) => isAnswerCorrect(q, session.answers[q.id])).length;

    int scale(int correct, int total) {
      if (total == 0) return 0;
      return (5 + (correct / total) * 490).round();
    }

    final listeningScore = scale(listeningCorrect, listeningQs.length);
    final readingScore = scale(readingCorrect, readingQs.length);

    return TestScore(
      rawCorrect: base.rawCorrect,
      rawTotal: base.rawTotal,
      ungradedCount: base.ungradedCount,
      accuracyBySkill: base.accuracyBySkill,
      accuracyByTag: base.accuracyByTag,
      toeicScaledScore: {
        'listening': listeningScore,
        'reading': readingScore,
        'total': listeningScore + readingScore,
      },
      weakTags: base.weakTags,
    );
  }
}

/// Tính điểm thô + accuracy theo skill/tag. Câu hỏi dạng speakingPrompt được
/// TÁCH RIÊNG (đếm vào [TestScore.ungradedCount]) vì không thể chấm đúng/sai
/// tự động — tránh làm sai lệch % chính xác của các kỹ năng chấm được.
TestScore _baseScore(TestSession session) {
  int correct = 0;
  int ungraded = 0;
  final bySkillCorrect = <Skill, int>{};
  final bySkillTotal = <Skill, int>{};
  final byTagCorrect = <String, int>{};
  final byTagTotal = <String, int>{};

  for (final q in session.questions) {
    if (q.questionType == QuestionType.speakingPrompt) {
      ungraded++;
      continue;
    }

    final isRight = isAnswerCorrect(q, session.answers[q.id]);
    if (isRight) correct++;

    bySkillTotal[q.skill] = (bySkillTotal[q.skill] ?? 0) + 1;
    if (isRight) bySkillCorrect[q.skill] = (bySkillCorrect[q.skill] ?? 0) + 1;

    final tags = [if (q.topic != null) q.topic!, ...q.tags];
    for (final tag in tags) {
      byTagTotal[tag] = (byTagTotal[tag] ?? 0) + 1;
      if (isRight) byTagCorrect[tag] = (byTagCorrect[tag] ?? 0) + 1;
    }
  }

  final gradedTotal = session.questions.length - ungraded;

  final accuracyBySkill = <Skill, double>{
    for (final skill in bySkillTotal.keys)
      skill: (bySkillCorrect[skill] ?? 0) / bySkillTotal[skill]!,
  };

  final accuracyByTag = <String, double>{
    for (final tag in byTagTotal.keys)
      tag: (byTagCorrect[tag] ?? 0) / byTagTotal[tag]!,
  };

  final sortedTags = accuracyByTag.keys.toList()
    ..sort((a, b) => accuracyByTag[a]!.compareTo(accuracyByTag[b]!));
  final weakTags =
      sortedTags.where((t) => accuracyByTag[t]! < 0.6).take(5).toList();

  return TestScore(
    rawCorrect: correct,
    rawTotal: gradedTotal,
    ungradedCount: ungraded,
    accuracyBySkill: accuracyBySkill,
    accuracyByTag: accuracyByTag,
    weakTags: weakTags,
  );
}

/// Engine tổng quát: dùng 1 QuestionBank + 1 TrackLevelConfig để tạo phiên
/// làm bài (practice hoặc mock test), nhận đáp án, và chấm điểm.
/// Không phụ thuộc UI/Flutter — có thể unit-test độc lập.
class MockTestEngine {
  final QuestionBank bank;
  final Map<String, ScoringStrategy> strategies;

  MockTestEngine(this.bank, {Map<String, ScoringStrategy>? strategies})
      : strategies = strategies ??
            {
              'rawPercentage': RawPercentageScoring(),
              'yleShield': YleShieldScoringStrategy(),
              'toeicScaled': ToeicScaledScoringStrategy(),
            };

  /// Tạo 1 phiên làm bài mới theo config.
  /// [seed] cố định để tái tạo đúng 1 đề khi cần (demo, test tự động...).
  TestSession startSession(
    TrackLevelConfig config, {
    required TestMode mode,
    int? seed,
  }) {
    final random = Random(seed);
    final selected = <Question>[];

    for (final section in config.sections) {
      var pool = bank.query(
        track: config.track,
        level: config.level,
        skill: section.skill,
        partNumber: section.partNumber,
      );
      if (section.topics != null && section.topics!.isNotEmpty) {
        pool = pool.where((q) => section.topics!.contains(q.topic)).toList();
      }
      pool.shuffle(random);

      if (pool.length <= section.questionCount) {
        // Ngân hàng câu hỏi chưa đủ cho section này — lấy hết những gì có
        // thay vì throw, để không chặn luồng làm bài. Nên log cảnh báo ở
        // tầng gọi (ví dụ Sentry/analytics) khi rơi vào trường hợp này.
        selected.addAll(pool);
      } else {
        selected.addAll(pool.take(section.questionCount));
      }
    }

    final totalTime = config.totalTimeLimitSeconds > 0
        ? config.totalTimeLimitSeconds
        : config.sections.fold<int>(0, (sum, s) => sum + s.timeLimitSeconds);

    return TestSession(
      sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      track: config.track,
      level: config.level,
      mode: mode,
      questions: selected,
      // Chế độ luyện tập mặc định KHÔNG giới hạn giờ dù config có set thời gian.
      timeLimitSeconds: mode == TestMode.practice ? 0 : totalTime,
    );
  }

  TestScore finishAndScore(TestSession session, TrackLevelConfig config) {
    session.finish();
    final strategy =
        strategies[config.scoringStrategyId] ?? RawPercentageScoring();
    return strategy.score(session);
  }
}

/// Sinh báo cáo dễ hiển thị lên UI (ví dụ màn hình "Kết quả bài thi thử").
/// [lessonRecommendationsByTag] nên được điền dần theo nội dung thật của app
/// (map tag/topic yếu -> id bài học tương ứng để tạo nút "Ôn lại ngay").
Map<String, dynamic> buildReport(
  TestScore score, {
  Map<String, String> lessonRecommendationsByTag = const {},
}) {
  return {
    'score': score.toJson(),
    'recommendedLessons': [
      for (final tag in score.weakTags)
        lessonRecommendationsByTag[tag] ?? 'lesson_review_$tag',
    ],
  };
}
