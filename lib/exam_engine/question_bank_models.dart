// question_bank_models.dart
//
// Model dữ liệu dùng CHUNG cho ngân hàng câu hỏi của cả 2 track:
//   - YLE  (Cambridge Young Learners: Starters / Movers / Flyers / KET / PET)
//   - TOEIC (Part 1..7)
//
// File này KHÔNG phụ thuộc Flutter (không import package:flutter) nên có thể
// dùng ở bất kỳ tầng nào: local DB (sqflite/Hive), Firestore, hay unit test
// thuần Dart. Copy nguyên file này vào lib/ của app hiện tại là dùng được.

/// Track học tập / thi.
enum ExamTrack { yle, toeic }

/// Kỹ năng được kiểm tra.
enum Skill { vocabulary, grammar, listening, reading, writing, speaking }

/// Loại câu hỏi hỗ trợ. Có thể mở rộng thêm khi cần (ví dụ: dragDrop).
enum QuestionType {
  multipleChoice,
  trueFalse,
  matching,
  ordering,
  fillBlank,
  listenAndColor,
  listenAndNumber,
  shortAnswer,
  speakingPrompt,
}

ExamTrack trackFromString(String value) => ExamTrack.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Track không hợp lệ: $value'),
    );

Skill skillFromString(String value) => Skill.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Skill không hợp lệ: $value'),
    );

QuestionType questionTypeFromString(String value) =>
    QuestionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('QuestionType không hợp lệ: $value'),
    );

/// Media đính kèm câu hỏi (ảnh minh hoạ cho YLE, audio cho phần Listening...).
class MediaAsset {
  final String type; // 'audio' | 'image' | 'none'
  final String? url;

  const MediaAsset({required this.type, this.url});

  factory MediaAsset.none() => const MediaAsset(type: 'none');

  factory MediaAsset.fromJson(Map<String, dynamic> json) => MediaAsset(
        type: json['type'] as String? ?? 'none',
        url: json['url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        if (url != null) 'url': url,
      };
}

/// Một lựa chọn trả lời (dùng cho multipleChoice, matching, ordering...).
class AnswerOption {
  final String id;
  final String text;
  final String? imageUrl;

  const AnswerOption({required this.id, required this.text, this.imageUrl});

  factory AnswerOption.fromJson(Map<String, dynamic> json) => AnswerOption(
        id: json['id'] as String,
        text: json['text'] as String,
        imageUrl: json['imageUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}

/// Một câu hỏi trong ngân hàng câu hỏi dùng chung cho cả YLE và TOEIC.
///
/// [correctAnswer] luôn là `List<String>` để dùng chung được cho nhiều dạng
/// câu hỏi khác nhau:
///  - multipleChoice / trueFalse : 1 phần tử = id lựa chọn đúng
///  - matching                  : các cặp mã hoá "leftId:rightId"
///  - ordering / listenAndColor / listenAndNumber : danh sách id theo đúng
///    thứ tự
///  - fillBlank / shortAnswer   : (các) đáp án chấp nhận được, so khớp không
///    phân biệt hoa/thường sau khi trim
///  - speakingPrompt            : để trống — không chấm tự động, xem thêm
///    ghi chú trong mock_test_engine.dart
class Question {
  final String id;
  final ExamTrack track;
  final String level; // YLE: 'Starters'|'Movers'|'Flyers'|'KET'|'PET'
  // TOEIC: 'Part1'..'Part7'
  final Skill skill;
  final String? topic; // dùng cho YLE, ví dụ 'Animals', 'Food'
  final int? partNumber; // dùng cho TOEIC, 1..7
  final QuestionType questionType;
  final String prompt;
  final MediaAsset media;
  final List<AnswerOption> options;
  final List<String> correctAnswer;
  final String? explanation;
  final int difficulty; // 1 (dễ) .. 5 (khó)
  final List<String> tags;
  final int points;

  /// Nội dung THẬT được đọc bằng TTS cho câu hỏi có `media.type == 'audio'`
  /// (hội thoại, thông báo, mô tả tranh...) - TÁCH RIÊNG khỏi [prompt] vì
  /// [prompt] chỉ chứa phần hiển thị (câu hỏi/hướng dẫn), không được để lộ
  /// nội dung cần NGHE mới biết. Ví dụ Part 3 TOEIC: [prompt] là câu hỏi in
  /// sẵn ("Why is the report delayed?"), [audioScript] là toàn bộ đoạn hội
  /// thoại chỉ nghe được qua nút "Nghe" trên UI. `null` nghĩa là câu hỏi
  /// không có phần nghe riêng (media.type != 'audio').
  final String? audioScript;

  const Question({
    required this.id,
    required this.track,
    required this.level,
    required this.skill,
    this.topic,
    this.partNumber,
    required this.questionType,
    required this.prompt,
    this.media = const MediaAsset(type: 'none'),
    this.options = const [],
    required this.correctAnswer,
    this.explanation,
    this.difficulty = 1,
    this.tags = const [],
    this.points = 1,
    this.audioScript,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        track: trackFromString(json['track'] as String),
        level: json['level'] as String,
        skill: skillFromString(json['skill'] as String),
        topic: json['topic'] as String?,
        partNumber: json['partNumber'] as int?,
        questionType: questionTypeFromString(json['questionType'] as String),
        prompt: json['prompt'] as String,
        media: json['media'] == null
            ? MediaAsset.none()
            : MediaAsset.fromJson(json['media'] as Map<String, dynamic>),
        options: (json['options'] as List<dynamic>? ?? [])
            .map((e) => AnswerOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        correctAnswer: (json['correctAnswer'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        explanation: json['explanation'] as String?,
        difficulty: json['difficulty'] as int? ?? 1,
        tags: (json['tags'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        points: json['points'] as int? ?? 1,
        audioScript: json['audioScript'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'track': track.name,
        'level': level,
        'skill': skill.name,
        if (topic != null) 'topic': topic,
        if (partNumber != null) 'partNumber': partNumber,
        'questionType': questionType.name,
        'prompt': prompt,
        'media': media.toJson(),
        'options': options.map((o) => o.toJson()).toList(),
        'correctAnswer': correctAnswer,
        if (explanation != null) 'explanation': explanation,
        'difficulty': difficulty,
        'tags': tags,
        'points': points,
        if (audioScript != null) 'audioScript': audioScript,
      };
}

/// Ngân hàng câu hỏi — nạp 1 lần từ JSON (asset, API, DB...) rồi truy vấn.
class QuestionBank {
  final List<Question> questions;

  QuestionBank(this.questions);

  factory QuestionBank.fromJsonList(List<dynamic> jsonList) => QuestionBank(
        jsonList
            .map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  List<Question> query({
    ExamTrack? track,
    String? level,
    Skill? skill,
    String? topic,
    int? partNumber,
    QuestionType? questionType,
  }) {
    return questions.where((q) {
      if (track != null && q.track != track) return false;
      if (level != null && q.level != level) return false;
      if (skill != null && q.skill != skill) return false;
      if (topic != null && q.topic != topic) return false;
      if (partNumber != null && q.partNumber != partNumber) return false;
      if (questionType != null && q.questionType != questionType) {
        return false;
      }
      return true;
    }).toList();
  }
}

/// Cấu hình 1 phần thi/luyện tập (ví dụ: "Vocabulary & Grammar",
/// "TOEIC Part 5 - Incomplete Sentences").
class SectionConfig {
  final String name;
  final Skill skill;
  final int? partNumber; // TOEIC
  final List<String>? topics; // YLE - lọc theo chủ đề nếu có
  final int questionCount;
  final int timeLimitSeconds; // 0 = không giới hạn riêng cho section này
  final String? instructions;

  const SectionConfig({
    required this.name,
    required this.skill,
    this.partNumber,
    this.topics,
    required this.questionCount,
    this.timeLimitSeconds = 0,
    this.instructions,
  });

  factory SectionConfig.fromJson(Map<String, dynamic> json) => SectionConfig(
        name: json['name'] as String,
        skill: skillFromString(json['skill'] as String),
        partNumber: json['partNumber'] as int?,
        topics: (json['topics'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        questionCount: json['questionCount'] as int,
        timeLimitSeconds: json['timeLimitSeconds'] as int? ?? 0,
        instructions: json['instructions'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'skill': skill.name,
        if (partNumber != null) 'partNumber': partNumber,
        if (topics != null) 'topics': topics,
        'questionCount': questionCount,
        'timeLimitSeconds': timeLimitSeconds,
        if (instructions != null) 'instructions': instructions,
      };
}

/// Cấu hình 1 track+level, ví dụ "YLE Movers" hoặc "TOEIC Full Test".
/// [scoringStrategyId] tham chiếu tới 1 ScoringStrategy trong
/// mock_test_engine.dart ('yleShield' | 'toeicScaled' | 'rawPercentage').
class TrackLevelConfig {
  final ExamTrack track;
  final String level;
  final String displayName;
  final List<SectionConfig> sections;
  final int totalTimeLimitSeconds; // 0 = tự cộng dồn theo section
  final String scoringStrategyId;

  const TrackLevelConfig({
    required this.track,
    required this.level,
    required this.displayName,
    required this.sections,
    this.totalTimeLimitSeconds = 0,
    required this.scoringStrategyId,
  });

  factory TrackLevelConfig.fromJson(Map<String, dynamic> json) =>
      TrackLevelConfig(
        track: trackFromString(json['track'] as String),
        level: json['level'] as String,
        displayName: json['displayName'] as String,
        sections: (json['sections'] as List<dynamic>)
            .map((e) => SectionConfig.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalTimeLimitSeconds: json['totalTimeLimitSeconds'] as int? ?? 0,
        scoringStrategyId: json['scoringStrategyId'] as String,
      );

  Map<String, dynamic> toJson() => {
        'track': track.name,
        'level': level,
        'displayName': displayName,
        'sections': sections.map((s) => s.toJson()).toList(),
        'totalTimeLimitSeconds': totalTimeLimitSeconds,
        'scoringStrategyId': scoringStrategyId,
      };
}
