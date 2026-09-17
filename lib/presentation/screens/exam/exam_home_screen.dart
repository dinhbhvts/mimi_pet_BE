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
            // chặn UI) - xem `CloudStateStore.setMapEntry`. Dùng ĐÚNG
            // track/level của đề GỐC (không phải đề đã tuỳ chỉnh phần/chủ đề
            // ở [_openPracticeSetup]) để điểm luyện tập tuỳ chỉnh vẫn gộp
            // chung lịch sử với đề đầy đủ, không tách vụn theo từng lần
            // chọn phần khác nhau.
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

  /// Mở bottom sheet cho bé CHỦ ĐỘNG chọn phần/chủ đề muốn luyện tập (thay vì
  /// luôn phải làm ĐỦ mọi phần như "Thi thử có giờ") - xem [_PracticeSetupSheet].
  /// "Thi thử có giờ" KHÔNG đi qua đây, giữ nguyên cấu trúc đề đầy đủ đúng
  /// thật để còn ý nghĩa mô phỏng thi thật.
  void _openPracticeSetup(BuildContext context, TrackLevelConfig config) {
    final bank = context.read<ExamCatalogController>().bank!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _PracticeSetupSheet(
        config: config,
        bank: bank,
        onStart: (customConfig) {
          Navigator.of(sheetContext).pop();
          _start(context, customConfig, TestMode.practice);
        },
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
                          onPractice: () => _openPracticeSetup(context, config),
                          onMockTest: () => _start(context, config, TestMode.mockTest),
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
  final VoidCallback onPractice;
  final VoidCallback onMockTest;

  const _ExamConfigCard({required this.config, required this.onPractice, required this.onMockTest});

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
                  onPressed: onPractice,
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
                  onPressed: onMockTest,
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

/// Bottom sheet cho bé CHỦ ĐỘNG chọn phần (skill/TOEIC Part) và (nếu có) chủ
/// đề cụ thể muốn luyện, thay vì luôn phải làm đủ MỌI phần của đề như trước.
/// Mặc định TẤT CẢ phần đều được chọn sẵn (giữ nguyên hành vi "Luyện tập" cũ
/// nếu bé không đổi gì) - bé bỏ chọn bớt phần không cần, hoặc mở rộng 1 phần
/// ra để chọn thêm chủ đề con (chỉ hiện nếu ngân hàng câu hỏi có từ 2 chủ đề
/// khác nhau trở lên cho đúng phần đó, ví dụ Vocabulary có Animals/Food/...).
class _PracticeSetupSheet extends StatefulWidget {
  final TrackLevelConfig config;
  final QuestionBank bank;
  final ValueChanged<TrackLevelConfig> onStart;

  const _PracticeSetupSheet({required this.config, required this.bank, required this.onStart});

  @override
  State<_PracticeSetupSheet> createState() => _PracticeSetupSheetState();
}

class _PracticeSetupSheetState extends State<_PracticeSetupSheet> {
  late final Set<int> _selectedSections;
  late final Map<int, List<String>> _availableTopicsBySection;
  late final Map<int, Set<String>> _selectedTopicsBySection;

  @override
  void initState() {
    super.initState();
    _selectedSections = {for (var i = 0; i < widget.config.sections.length; i++) i};
    _availableTopicsBySection = {};
    _selectedTopicsBySection = {};
    for (var i = 0; i < widget.config.sections.length; i++) {
      final section = widget.config.sections[i];
      final topics = widget.bank.questions
          .where((q) =>
              q.track == widget.config.track &&
              q.level == widget.config.level &&
              q.skill == section.skill &&
              (section.partNumber == null || q.partNumber == section.partNumber))
          .map((q) => q.topic)
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();
      _availableTopicsBySection[i] = topics;
      // Tập rỗng = KHÔNG lọc theo chủ đề (lấy hết, đúng hành vi mặc định).
      _selectedTopicsBySection[i] = {};
    }
  }

  void _toggleSection(int index) {
    setState(() {
      if (_selectedSections.contains(index)) {
        _selectedSections.remove(index);
      } else {
        _selectedSections.add(index);
      }
    });
  }

  void _toggleTopic(int sectionIndex, String topic) {
    setState(() {
      final set = _selectedTopicsBySection[sectionIndex]!;
      if (set.contains(topic)) {
        set.remove(topic);
      } else {
        set.add(topic);
      }
    });
  }

  void _submit() {
    final sections = [
      for (final i in _selectedSections)
        SectionConfig(
          name: widget.config.sections[i].name,
          skill: widget.config.sections[i].skill,
          partNumber: widget.config.sections[i].partNumber,
          topics: _selectedTopicsBySection[i]!.isEmpty
              ? widget.config.sections[i].topics
              : _selectedTopicsBySection[i]!.toList(),
          questionCount: widget.config.sections[i].questionCount,
          instructions: widget.config.sections[i].instructions,
        ),
    ];
    widget.onStart(
      TrackLevelConfig(
        track: widget.config.track,
        level: widget.config.level,
        displayName: widget.config.displayName,
        sections: sections,
        scoringStrategyId: widget.config.scoringStrategyId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canStart = _selectedSections.isNotEmpty;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn phần muốn luyện tập 🎯',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bỏ chọn phần không cần, hoặc mở rộng 1 phần ra để chọn thêm chủ đề cụ thể.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var i = 0; i < widget.config.sections.length; i++)
                      _SectionSelectTile(
                        section: widget.config.sections[i],
                        selected: _selectedSections.contains(i),
                        onToggle: () => _toggleSection(i),
                        availableTopics: _availableTopicsBySection[i]!,
                        selectedTopics: _selectedTopicsBySection[i]!,
                        onToggleTopic: (t) => _toggleTopic(i, t),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canStart ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Bắt đầu luyện tập',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 1 dòng chọn/bỏ chọn 1 phần (section) trong [_PracticeSetupSheet] - khi
/// phần đang được chọn VÀ có sẵn nhiều chủ đề trong ngân hàng câu hỏi, hiện
/// thêm hàng chip chủ đề bên dưới để lọc hẹp hơn nữa (không bắt buộc).
class _SectionSelectTile extends StatelessWidget {
  final SectionConfig section;
  final bool selected;
  final VoidCallback onToggle;
  final List<String> availableTopics;
  final Set<String> selectedTopics;
  final ValueChanged<String> onToggleTopic;

  const _SectionSelectTile({
    required this.section,
    required this.selected,
    required this.onToggle,
    required this.availableTopics,
    required this.selectedTopics,
    required this.onToggleTopic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF6F0FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? AppColors.primary.withValues(alpha: 0.4) : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: selected,
            onChanged: (_) => onToggle(),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
            title: Text(section.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${section.questionCount} câu', style: const TextStyle(fontSize: 12)),
          ),
          if (selected && availableTopics.length > 1) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: availableTopics.map((topic) {
                  final isSelected = selectedTopics.contains(topic);
                  return FilterChip(
                    label: Text(topic, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (_) => onToggleTopic(topic),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
