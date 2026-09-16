import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/exam_engine/mock_test_engine.dart';
import 'package:mimi_pet/exam_engine/question_bank_models.dart';
import 'package:mimi_pet/presentation/screens/exam/exam_screen.dart';
import 'package:mimi_pet/presentation/state/exam_catalog_controller.dart';
import 'package:mimi_pet/presentation/state/exam_session_controller.dart';
import 'package:mimi_pet/services/cloud_state_store.dart';

/// Danh sách đề thi thử có sẵn (YLE Movers/Flyers, TOEIC Full Test) - bé chọn
/// 1 đề rồi chọn "Luyện tập" (không giới hạn giờ) hoặc "Thi thử có giờ"
/// (đúng thời gian như đề thật, xem [TrackLevelConfig.totalTimeLimitSeconds]).
///
/// Mở từ [HomeScreen] qua 1 thẻ lối vào riêng (cùng cách mở "Bài tranh") thay
/// vì thêm tab thứ 6 ở thanh dưới - tránh lặp lại vấn đề tràn ngang đã gặp
/// khi thêm tab thứ 5.
class ExamHomeScreen extends StatelessWidget {
  const ExamHomeScreen({super.key});

  void _start(BuildContext context, TrackLevelConfig config, TestMode mode) {
    final bank = context.read<ExamCatalogController>().bank!;
    final cloudStore = context.read<CloudStateStore>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<ExamSessionController>(
          create: (_) => ExamSessionController(
            bank: bank,
            config: config,
            mode: mode,
            // Đồng bộ điểm lên cloud ngay khi nộp bài (best-effort, không
            // chặn UI) - xem `CloudStateStore.setMapEntry`.
            onFinished: (score) => cloudStore.setMapEntry(
              'examResults',
              '${config.track.name}_${config.level}',
              score.toJson(),
            ),
          ),
          child: const ExamScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<ExamCatalogController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Thi thử'),
      ),
      body: SafeArea(
        child: !catalog.loaded
            ? const Center(child: CircularProgressIndicator())
            : catalog.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(catalog.error!, textAlign: TextAlign.center),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Chọn 1 đề để luyện tập hoặc thi thử. Đây là đề MẪU để '
                        'kiểm chứng, chưa đủ số câu như đề thật.',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 16),
                      for (final config in catalog.configs) ...[
                        _ExamConfigCard(
                          config: config,
                          onStart: (mode) => _start(context, config, mode),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _ExamConfigCard extends StatelessWidget {
  final TrackLevelConfig config;
  final ValueChanged<TestMode> onStart;

  const _ExamConfigCard({required this.config, required this.onStart});

  int get _totalQuestions =>
      config.sections.fold<int>(0, (sum, s) => sum + s.questionCount);

  String get _emoji => config.track == ExamTrack.yle ? '🏅' : '💼';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  config.displayName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$_totalQuestions câu · ${config.sections.length} phần',
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onStart(TestMode.practice),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Luyện tập'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onStart(TestMode.mockTest),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Thi thử có giờ', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
