import 'package:flutter/foundation.dart';

import '../../exam_engine/question_bank_models.dart';
import '../../services/cloud_state_store.dart';

/// 1 câu trong "Sổ câu sai".
class MistakeEntry {
  final String questionId;
  final ExamTrack track;
  final String level;
  final int wrongCount;

  /// Số lần làm ĐÚNG liên tiếp kể từ lần sai gần nhất.
  final int streak;
  final DateTime dueAt;
  final DateTime lastWrongAt;

  const MistakeEntry({
    required this.questionId,
    required this.track,
    required this.level,
    required this.wrongCount,
    required this.streak,
    required this.dueAt,
    required this.lastWrongAt,
  });

  bool isDue(DateTime now) => !dueAt.isAfter(now);

  Map<String, dynamic> toJson() => {
        'track': track.name,
        'level': level,
        'wrong': wrongCount,
        'streak': streak,
        'due': dueAt.millisecondsSinceEpoch,
        'lastWrong': lastWrongAt.millisecondsSinceEpoch,
      };

  static MistakeEntry? fromJson(String id, Object? raw) {
    if (raw is! Map) return null;
    try {
      return MistakeEntry(
        questionId: id,
        track: trackFromString(raw['track'] as String),
        level: raw['level'] as String,
        wrongCount: (raw['wrong'] as num).toInt(),
        streak: (raw['streak'] as num).toInt(),
        dueAt: DateTime.fromMillisecondsSinceEpoch((raw['due'] as num).toInt()),
        lastWrongAt: DateTime.fromMillisecondsSinceEpoch((raw['lastWrong'] as num).toInt()),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Nơi lưu sổ câu sai - tách interface để test không cần backend thật.
abstract class MistakeStorage {
  Map<String, dynamic> loadAll();
  void save(String questionId, Map<String, dynamic> json);
  void remove(String questionId);
}

/// Lưu trong blob state đồng bộ cloud (key `mistakeBook`) - làm sai trên
/// điện thoại thì ôn lại được trên web và ngược lại.
class CloudMistakeStorage implements MistakeStorage {
  CloudMistakeStorage(this._store);

  final CloudStateStore _store;
  static const key = 'mistakeBook';

  @override
  Map<String, dynamic> loadAll() => _store.getMap(key);

  @override
  void save(String questionId, Map<String, dynamic> json) => _store.setMapEntry(key, questionId, json);

  @override
  void remove(String questionId) => _store.removeMapEntry(key, questionId);
}

/// "Sổ câu sai" + lịch ôn giãn cách: làm sai câu nào (ở luyện tập hay thi
/// thử) thì câu đó vào sổ, đến hạn ôn sau 1 ngày; ôn đúng thì hẹn 3 ngày sau
/// ôn lại lần nữa; đúng [masteredStreak] lần LIÊN TIẾP thì coi là đã thuộc và
/// rời sổ. Sai lại ở bất kỳ lần nào thì quay về đầu (1 ngày).
class MistakeBookController extends ChangeNotifier {
  MistakeBookController(this._storage) {
    for (final e in _storage.loadAll().entries) {
      final entry = MistakeEntry.fromJson(e.key, e.value);
      if (entry != null) _entries[e.key] = entry;
    }
  }

  final MistakeStorage _storage;
  final Map<String, MistakeEntry> _entries = {};

  static const firstReviewDelay = Duration(days: 1);
  static const nextReviewDelay = Duration(days: 3);
  static const masteredStreak = 2;

  bool contains(String questionId) => _entries.containsKey(questionId);
  MistakeEntry? entryFor(String questionId) => _entries[questionId];

  /// Ghi nhận kết quả chấm 1 câu. Câu nói (không chấm tự động) bị bỏ qua.
  /// Trả về true nếu câu vừa RỜI sổ (đã thuộc).
  bool recordResult(Question q, bool correct, {DateTime? now}) {
    if (q.questionType == QuestionType.speakingPrompt) return false;
    final t = now ?? DateTime.now();
    final existing = _entries[q.id];
    if (!correct) {
      final entry = MistakeEntry(
        questionId: q.id,
        track: q.track,
        level: q.level,
        wrongCount: (existing?.wrongCount ?? 0) + 1,
        streak: 0,
        dueAt: t.add(firstReviewDelay),
        lastWrongAt: t,
      );
      _entries[q.id] = entry;
      _storage.save(q.id, entry.toJson());
      notifyListeners();
      return false;
    }
    if (existing == null) return false;
    final streak = existing.streak + 1;
    if (streak >= masteredStreak) {
      _entries.remove(q.id);
      _storage.remove(q.id);
      notifyListeners();
      return true;
    }
    final entry = MistakeEntry(
      questionId: q.id,
      track: existing.track,
      level: existing.level,
      wrongCount: existing.wrongCount,
      streak: streak,
      dueAt: t.add(nextReviewDelay),
      lastWrongAt: existing.lastWrongAt,
    );
    _entries[q.id] = entry;
    _storage.save(q.id, entry.toJson());
    notifyListeners();
    return false;
  }

  List<MistakeEntry> entriesFor(ExamTrack track, String level) =>
      _entries.values.where((e) => e.track == track && e.level == level).toList();

  int countFor(ExamTrack track, String level) => entriesFor(track, level).length;

  int dueCountFor(ExamTrack track, String level, {DateTime? now}) {
    final t = now ?? DateTime.now();
    return entriesFor(track, level).where((e) => e.isDue(t)).length;
  }

  /// Câu hỏi để ôn: câu đến hạn trước, rồi câu sai nhiều lần trước. Bỏ qua câu
  /// không còn trong ngân hàng (đã bị sửa/xoá id).
  List<Question> questionsToReview(
    QuestionBank bank,
    ExamTrack track,
    String level, {
    bool dueOnly = false,
    int limit = 20,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final byId = {for (final q in bank.questions) q.id: q};
    final entries = entriesFor(track, level).where((e) => !dueOnly || e.isDue(t)).toList()
      ..sort((a, b) {
        final due = (b.isDue(t) ? 1 : 0).compareTo(a.isDue(t) ? 1 : 0);
        if (due != 0) return due;
        final wrong = b.wrongCount.compareTo(a.wrongCount);
        if (wrong != 0) return wrong;
        return a.dueAt.compareTo(b.dueAt);
      });
    return [
      for (final e in entries)
        if (byId[e.questionId] != null) byId[e.questionId]!,
    ].take(limit).toList();
  }
}
