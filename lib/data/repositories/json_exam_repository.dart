import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/repositories/exam_repository.dart';
import '../../exam_engine/question_bank_models.dart';

/// Implementation của [ExamRepository] đọc đề thi thử từ 3 file JSON tĩnh
/// trong assets/exam/ (cấu hình đề + ngân hàng câu hỏi YLE + TOEIC) - cùng
/// pattern với [JsonLessonRepository]. Ngân hàng câu hỏi của 2 track được
/// GỘP CHUNG 1 [QuestionBank] (đủ nhỏ để nạp cùng lúc) rồi lọc theo track
/// lúc truy vấn - xem `QuestionBank.query()`.
class JsonExamRepository implements ExamRepository {
  JsonExamRepository({
    this.trackConfigsAssetPath = 'assets/exam/track_configs.json',
    this.yleSeedAssetPath = 'assets/exam/yle_movers_flyers_seed.json',
    this.toeicSeedAssetPath = 'assets/exam/toeic_seed.json',
  });

  final String trackConfigsAssetPath;
  final String yleSeedAssetPath;
  final String toeicSeedAssetPath;

  List<TrackLevelConfig>? _configsCache;
  QuestionBank? _bankCache;

  @override
  Future<List<TrackLevelConfig>> getTrackConfigs() async {
    if (_configsCache != null) return _configsCache!;
    final raw = await rootBundle.loadString(trackConfigsAssetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    _configsCache = decoded
        .map((e) => TrackLevelConfig.fromJson(e as Map<String, dynamic>))
        .toList();
    return _configsCache!;
  }

  @override
  Future<QuestionBank> getQuestionBank() async {
    if (_bankCache != null) return _bankCache!;
    final yleRaw = await rootBundle.loadString(yleSeedAssetPath);
    final toeicRaw = await rootBundle.loadString(toeicSeedAssetPath);
    final combined = <dynamic>[
      ...jsonDecode(yleRaw) as List<dynamic>,
      ...jsonDecode(toeicRaw) as List<dynamic>,
    ];
    _bankCache = QuestionBank.fromJsonList(combined);
    return _bankCache!;
  }
}
