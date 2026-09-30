import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/grammar_lessons.dart';
import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/exam_engine/mock_test_engine.dart';
import 'package:mimi_pet/exam_engine/question_bank_models.dart';
import 'package:mimi_pet/presentation/screens/exam/exam_answer_text.dart';
import 'package:mimi_pet/presentation/screens/grammar/grammar_screens.dart';
import 'package:mimi_pet/services/tts_service.dart';

enum ReviewStatus { correct, wrong, skipped, ungraded }

ReviewStatus reviewStatusOf(Question q, List<String>? answer) {
  if (q.questionType == QuestionType.speakingPrompt) return ReviewStatus.ungraded;
  if (answer == null || answer.isEmpty || answer.every((a) => a.trim().isEmpty)) return ReviewStatus.skipped;
  return isAnswerCorrect(q, answer) ? ReviewStatus.correct : ReviewStatus.wrong;
}

/// "Xem lại bài làm" sau khi nộp: từng câu - đáp án đã chọn, đáp án đúng,
/// giải thích, nghe lại phần nghe (kể cả nghe chậm). Lọc nhanh "chỉ câu sai".
class ExamReviewScreen extends StatefulWidget {
  final String title;
  final List<Question> questions;
  final Map<String, List<String>?> answers;

  const ExamReviewScreen({super.key, required this.title, required this.questions, required this.answers});

  @override
  State<ExamReviewScreen> createState() => _ExamReviewScreenState();
}

class _ExamReviewScreenState extends State<ExamReviewScreen> {
  bool _onlyWrong = false;

  @override
  void initState() {
    super.initState();
    // Mở màn xem lại để chữa bài -> mặc định lọc câu sai nếu có.
    _onlyWrong = widget.questions.any((q) => _isWrongOrSkipped(q));
  }

  bool _isWrongOrSkipped(Question q) {
    final s = reviewStatusOf(q, widget.answers[q.id]);
    return s == ReviewStatus.wrong || s == ReviewStatus.skipped;
  }

  @override
  Widget build(BuildContext context) {
    final indexed = [for (var i = 0; i < widget.questions.length; i++) (i, widget.questions[i])];
    final wrongCount = indexed.where((e) => _isWrongOrSkipped(e.$2)).length;
    final shown = _onlyWrong ? indexed.where((e) => _isWrongOrSkipped(e.$2)).toList() : indexed;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Xem lại bài làm'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(widget.title, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text('Tất cả (${indexed.length})'),
                selected: !_onlyWrong,
                onSelected: (_) => setState(() => _onlyWrong = false),
              ),
              ChoiceChip(
                label: Text('Sai & bỏ trống ($wrongCount)'),
                selected: _onlyWrong,
                onSelected: (_) => setState(() => _onlyWrong = true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('🎉 Không có câu sai nào!', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            ),
          for (final (index, q) in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ReviewItemCard(number: index + 1, question: q, answer: widget.answers[q.id]),
            ),
        ],
      ),
    );
  }
}

class ReviewItemCard extends StatelessWidget {
  final int number;
  final Question question;
  final List<String>? answer;

  const ReviewItemCard({super.key, required this.number, required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final status = reviewStatusOf(question, answer);
    final (icon, color, label) = switch (status) {
      ReviewStatus.correct => (Icons.check_circle_rounded, const Color(0xFF3FAE5A), 'Đúng'),
      ReviewStatus.wrong => (Icons.cancel_rounded, const Color(0xFFE0863C), 'Sai'),
      ReviewStatus.skipped => (Icons.remove_circle_outline_rounded, Colors.grey, 'Bỏ trống'),
      ReviewStatus.ungraded => (Icons.mic_rounded, AppColors.primary, 'Câu nói'),
    };
    final badge = [
      if (question.partNumber != null && question.track == ExamTrack.toeic) 'Part ${question.partNumber}',
      if (question.topic != null) question.topic!,
    ].join(' · ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: color),
          title: Text('Câu $number · $label', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          subtitle: Text(
            badge.isEmpty ? question.prompt : '$badge\n${question.prompt}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (question.imageEmoji != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(question.imageEmoji!, style: const TextStyle(fontSize: 36)),
              ),
            SelectableText(question.prompt, style: const TextStyle(fontSize: 15, height: 1.4)),
            if (question.media.type == 'audio') ...[
              const SizedBox(height: 8),
              _ListenButtons(question: question),
              if (question.audioScript != null) ...[
                const SizedBox(height: 6),
                _ScriptBox(script: question.audioScript!),
              ],
            ],
            if (status != ReviewStatus.ungraded) ...[
              const SizedBox(height: 10),
              _AnswerLine(
                label: 'Bạn trả lời',
                text: status == ReviewStatus.skipped ? '(bỏ trống)' : answerText(question, answer!),
                color: status == ReviewStatus.correct ? const Color(0xFF3FAE5A) : const Color(0xFFE0863C),
              ),
              if (status != ReviewStatus.correct)
                _AnswerLine(label: 'Đáp án đúng', text: correctAnswerText(question), color: const Color(0xFF3FAE5A)),
            ],
            if (question.explanation != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.thinkingBubble.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('💡 ${question.explanation!}'),
              ),
            ],
            if (GrammarLessons.forQuestion(question) case final lesson?)
              GrammarLessonLink(lesson: lesson),
          ],
        ),
      ),
    );
  }
}

class _AnswerLine extends StatelessWidget {
  final String label;
  final String text;
  final Color color;

  const _AnswerLine({required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: '$label: ', style: const TextStyle(color: AppColors.textMuted)),
          TextSpan(text: text, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}

class _ListenButtons extends StatelessWidget {
  final Question question;

  const _ListenButtons({required this.question});

  void _listen(BuildContext context, double speed) {
    context.read<TtsService>().speakScript(
          question.audioScript ?? question.prompt,
          kind: question.track == ExamTrack.toeic ? VoiceKind.toeic : VoiceKind.kid,
          speed: speed,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        TextButton.icon(
          onPressed: () => _listen(context, 1.0),
          icon: const Icon(Icons.volume_up_rounded),
          label: const Text('Nghe lại'),
        ),
        TextButton.icon(
          onPressed: () => _listen(context, 0.75),
          icon: const Text('🐢'),
          label: const Text('Nghe chậm'),
        ),
      ],
    );
  }
}

/// Lời thoại/bài nói đầy đủ - lúc chữa bài mới cho xem (lúc làm bài phải nghe).
class _ScriptBox extends StatelessWidget {
  final String script;

  const _ScriptBox({required this.script});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📝 Nội dung bài nghe', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          for (final line in _lines(script))
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(line, style: const TextStyle(fontSize: 13.5, height: 1.35)),
            ),
        ],
      ),
    );
  }

  /// Hội thoại thì xuống dòng theo người nói cho dễ đọc.
  static List<String> _lines(String script) {
    final dialogue = TtsService.parseDialogue(script);
    if (dialogue.isEmpty) return [script];
    return [for (final l in dialogue) '${l.speaker}: ${l.text}'];
  }
}
