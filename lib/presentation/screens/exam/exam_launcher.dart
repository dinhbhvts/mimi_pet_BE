import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/exam_engine/mock_test_engine.dart';
import 'package:mimi_pet/exam_engine/question_bank_models.dart';
import 'package:mimi_pet/presentation/screens/exam/exam_screen.dart';
import 'package:mimi_pet/presentation/state/exam_catalog_controller.dart';
import 'package:mimi_pet/presentation/state/exam_session_controller.dart';
import 'package:mimi_pet/presentation/state/mistake_book_controller.dart';
import 'package:mimi_pet/services/cloud_state_store.dart';

/// Mở 1 lượt làm bài - MỌI lối vào (đề thi thử, luyện tập tuỳ chọn, ôn Sổ
/// câu sai, luyện theo chủ đề ngữ pháp, "Làm lại") đều đi qua đây để luôn
/// cập nhật Sổ câu sai giống nhau.
///
/// [saveScore]: lưu điểm vào lịch sử `examResults` (chỉ đề/luyện tập theo
/// cấu hình đề thật; phiên ôn câu sai/luyện 1 chủ đề thì không, tránh làm
/// lệch lịch sử điểm). [replace] thay route hiện tại (nút "Làm lại").
void openExamSession(
  BuildContext context, {
  required TrackLevelConfig config,
  required TestMode mode,
  List<Question>? fixedQuestions,
  bool saveScore = true,
  bool replace = false,
}) {
  final bank = context.read<ExamCatalogController>().bank!;
  final cloudStore = context.read<CloudStateStore>();
  final mistakes = context.read<MistakeBookController>();
  final route = MaterialPageRoute<void>(
    builder: (_) => ChangeNotifierProvider<ExamSessionController>(
      create: (_) => ExamSessionController(
        bank: bank,
        config: config,
        mode: mode,
        fixedQuestions: fixedQuestions,
        // Đồng bộ điểm lên cloud ngay khi nộp bài (best-effort) - dùng ĐÚNG
        // track/level của đề gốc để luyện tập tuỳ chỉnh vẫn gộp chung lịch sử.
        onFinished: saveScore && fixedQuestions == null
            ? (score) => cloudStore.setMapEntry(
                  'examResults',
                  '${config.track.name}_${config.level}',
                  score.toJson(),
                )
            : null,
        onAnswerGraded: (question, correct) => mistakes.recordResult(question, correct),
      ),
      child: const ExamScreen(),
    ),
  );
  if (replace) {
    Navigator.of(context).pushReplacement(route);
  } else {
    Navigator.of(context).push(route);
  }
}

/// Cấu hình cho phiên ôn câu sai (danh sách câu truyền riêng qua
/// `fixedQuestions`) - chấm % thô, không quy đổi khiên/điểm TOEIC.
TrackLevelConfig mistakeReviewConfig(ExamTrack track, String level) => TrackLevelConfig(
      track: track,
      level: level,
      displayName: '📕 Ôn câu sai · ${track == ExamTrack.toeic ? 'TOEIC' : level}',
      sections: const [],
      scoringStrategyId: 'rawPercentage',
    );

/// Cấu hình luyện nhanh 1 chủ đề (vd "Word form", "Past Simple").
TrackLevelConfig topicPracticeConfig({
  required ExamTrack track,
  required String level,
  required Skill skill,
  int? partNumber,
  required List<String> topics,
  required String title,
  int questionCount = 10,
}) =>
    TrackLevelConfig(
      track: track,
      level: level,
      displayName: title,
      sections: [
        SectionConfig(
          name: title,
          skill: skill,
          partNumber: partNumber,
          topics: topics,
          questionCount: questionCount,
        ),
      ],
      scoringStrategyId: 'rawPercentage',
    );
