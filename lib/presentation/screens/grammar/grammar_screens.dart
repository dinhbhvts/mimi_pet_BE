import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/grammar_lessons.dart';
import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/exam_engine/mock_test_engine.dart';
import 'package:mimi_pet/exam_engine/question_bank_models.dart';
import 'package:mimi_pet/presentation/screens/exam/exam_launcher.dart';
import 'package:mimi_pet/presentation/state/exam_catalog_controller.dart';
import 'package:mimi_pet/presentation/state/mistake_book_controller.dart';
import 'package:mimi_pet/services/tts_service.dart';
import 'package:mimi_pet/presentation/widgets/emoji_art.dart';

/// Số câu trong ngân hàng thuộc bài [lesson] và số câu trong đó đang nằm
/// trong Sổ câu sai.
(int available, List<Question> mistakes) _lessonStats(BuildContext context, GrammarLesson lesson) {
  final bank = context.read<ExamCatalogController>().bank;
  final book = context.watch<MistakeBookController>();
  if (bank == null) return (0, const []);
  final matching = bank.questions.where(lesson.matches).toList();
  return (matching.length, matching.where((q) => book.contains(q.id)).toList());
}

void openGrammarLesson(BuildContext context, GrammarLesson lesson) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GrammarLessonScreen(lesson: lesson)));
}

/// Danh sách bài ngữ pháp theo chủ đề - 3 tab: Movers, Flyers (cho bé) và
/// TOEIC (Part 5).
class GrammarHomeScreen extends StatelessWidget {
  final int initialTab;

  const GrammarHomeScreen({super.key, this.initialTab = 0});

  static const _tabs = [
    (ExamTrack.yle, 'Movers', '🧒 Movers'),
    (ExamTrack.yle, 'Flyers', '🧒 Flyers'),
    (ExamTrack.toeic, 'Standard', '💼 TOEIC'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Text('Ngữ pháp theo chủ đề'),
          bottom: TabBar(
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: [for (final t in _tabs) Tab(text: t.$3)],
          ),
        ),
        body: TabBarView(
          children: [
            for (final (track, level, _) in _tabs)
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final lesson in GrammarLessons.forLevel(track, level))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LessonTile(lesson: lesson),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final GrammarLesson lesson;

  const _LessonTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final (available, mistakes) = _lessonStats(context, lesson);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openGrammarLesson(context, lesson),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              EmojiArt(lesson.emoji, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(lesson.summary, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Pill('$available câu luyện', AppColors.idleBubble),
                        if (mistakes.isNotEmpty) _Pill('📕 ${mistakes.length} câu sai', const Color(0xFFFFE3CF)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
    );
  }
}

/// 1 bài ngữ pháp: công thức, dấu hiệu, ví dụ đúng/sai (nghe được), bẫy hay
/// gặp + nút luyện ngay các câu cùng chủ đề và ôn câu sai của chủ đề này.
class GrammarLessonScreen extends StatelessWidget {
  final GrammarLesson lesson;

  const GrammarLessonScreen({super.key, required this.lesson});

  static const practiceCount = 10;

  VoiceKind get _voice => lesson.track == ExamTrack.toeic ? VoiceKind.toeic : VoiceKind.kid;

  void _practice(BuildContext context, int available) {
    openExamSession(
      context,
      config: topicPracticeConfig(
        track: lesson.track,
        level: lesson.level,
        skill: lesson.practiceSkill,
        partNumber: lesson.practicePart,
        topics: lesson.practiceTopics,
        title: '${lesson.emoji} ${lesson.title}',
        questionCount: min(practiceCount, available),
      ),
      mode: TestMode.practice,
      saveScore: false,
    );
  }

  void _reviewMistakes(BuildContext context, List<Question> mistakes) {
    openExamSession(
      context,
      config: mistakeReviewConfig(lesson.track, lesson.level),
      mode: TestMode.practice,
      fixedQuestions: mistakes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (available, mistakes) = _lessonStats(context, lesson);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('${lesson.emoji} ${lesson.title}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(lesson.summary, style: const TextStyle(fontSize: 15, height: 1.4)),
          const SizedBox(height: 14),
          for (final p in lesson.points) ...[
            _PointCard(point: p),
            const SizedBox(height: 10),
          ],
          if (lesson.signals.isNotEmpty) ...[
            const SizedBox(height: 6),
            _Section(
              title: '🔎 Dấu hiệu nhận biết',
              color: const Color(0xFFE6F4FF),
              children: [for (final s in lesson.signals) _Bullet(s)],
            ),
          ],
          const SizedBox(height: 12),
          _Section(
            title: '💬 Ví dụ',
            color: Colors.white,
            children: [
              for (final e in lesson.examples)
                _ExampleRow(example: e, onSpeak: () => context.read<TtsService>().speak(e.en, kind: _voice)),
            ],
          ),
          if (lesson.traps.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Section(
              title: '⚠️ Bẫy hay gặp',
              color: AppColors.thinkingBubble.withValues(alpha: 0.7),
              children: [for (final t in lesson.traps) _Bullet(t)],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: available == 0 ? null : () => _practice(context, available),
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: Text(
                available == 0
                    ? 'Chưa có câu luyện cho chủ đề này'
                    : 'Luyện ${min(practiceCount, available)} câu chủ đề này',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Câu được bốc ngẫu nhiên từ các chủ đề: ${lesson.practiceTopics.join(', ')} ($available câu có sẵn).',
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          if (mistakes.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _reviewMistakes(context, mistakes),
                icon: const Text('📕'),
                label: Text('Ôn lại ${mistakes.length} câu sai của chủ đề này'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD0662A),
                  side: const BorderSide(color: Color(0xFFD0662A)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PointCard extends StatelessWidget {
  final GrammarPoint point;

  const _PointCard({required this.point});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(point.heading, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFF6F0FF), borderRadius: BorderRadius.circular(10)),
            child: Text(point.formula, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.35)),
          ),
          if (point.note != null) ...[
            const SizedBox(height: 6),
            Text(point.note!, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.35)),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Color color;
  final List<Widget> children;

  const _Section({required this.title, required this.color, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  final GrammarExample example;
  final VoidCallback onSpeak;

  const _ExampleRow({required this.example, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(example.correct ? '✅' : '❌', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  example.en,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    decoration: example.correct ? null : TextDecoration.lineThrough,
                    color: example.correct ? Colors.black87 : const Color(0xFFD0662A),
                  ),
                ),
                Text(example.vi, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          // Không đọc câu SAI - tránh bé nghe quen tai lỗi sai.
          if (example.correct)
            IconButton(
              tooltip: 'Nghe câu ví dụ',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.volume_up_rounded, size: 20, color: AppColors.primary),
              onPressed: onSpeak,
            ),
        ],
      ),
    );
  }
}

/// Nút "📘 Xem bài ngữ pháp: ..." khi chữa bài - mở đúng bài lý thuyết của
/// chủ đề câu vừa làm (xem [GrammarLessons.forQuestion]).
class GrammarLessonLink extends StatelessWidget {
  final GrammarLesson lesson;

  const GrammarLessonLink({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => openGrammarLesson(context, lesson),
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
        icon: const Text('📘'),
        label: Text('Xem bài ngữ pháp: ${lesson.title}'),
      ),
    );
  }
}
