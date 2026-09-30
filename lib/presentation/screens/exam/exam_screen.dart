import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/grammar_lessons.dart';
import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/exam_engine/mock_test_engine.dart';
import 'package:mimi_pet/exam_engine/question_bank_models.dart';
import 'package:mimi_pet/presentation/screens/exam/exam_answer_text.dart';
import 'package:mimi_pet/presentation/screens/exam/exam_launcher.dart';
import 'package:mimi_pet/presentation/screens/exam/exam_review_screen.dart';
import 'package:mimi_pet/presentation/screens/grammar/grammar_screens.dart';
import 'package:mimi_pet/presentation/state/exam_session_controller.dart';
import 'package:mimi_pet/services/tts_service.dart';

/// Màn hình LÀM BÀI + KẾT QUẢ cho 1 lượt thi thử - dùng 1 route DUY NHẤT, tự
/// chuyển "đang làm bài" <-> "kết quả" theo [ExamSessionController.isFinished]
/// (cùng cách [LessonScreen] tự chuyển "đang chơi" <-> "hoàn thành"), KHÔNG
/// push thêm route mới khi nộp bài - nhờ vậy Provider chỉ cần bọc quanh route
/// NÀY (xem ExamHomeScreen._start), không phải chia sẻ controller qua nhiều
/// route.
class ExamScreen extends StatelessWidget {
  const ExamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ExamSessionController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: !ctrl.hasQuestions
            ? _EmptyBankView(config: ctrl.config)
            : ctrl.isFinished
                ? _ExamResultView(ctrl: ctrl)
                : _ExamQuizView(ctrl: ctrl),
      ),
    );
  }
}

class _EmptyBankView extends StatelessWidget {
  final TrackLevelConfig config;

  const _EmptyBankView({required this.config});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 70)),
          const SizedBox(height: 16),
          Text(
            'Chưa có đủ câu hỏi cho "${config.displayName}"',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ngân hàng câu hỏi mẫu hiện còn ít - hãy quay lại sau khi có thêm nội dung nhé!',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Quay lại', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ExamQuizView extends StatelessWidget {
  final ExamSessionController ctrl;

  const _ExamQuizView({required this.ctrl});

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final question = ctrl.currentQuestion;
    final remaining = ctrl.remainingSeconds;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: (ctrl.currentIndex + 1) / ctrl.totalQuestions,
                    minHeight: 10,
                    backgroundColor: Colors.white,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (remaining >= 0) ...[
                const SizedBox(width: 12),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(_formatTime(remaining), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Câu ${ctrl.currentIndex + 1}/${ctrl.totalQuestions}',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _QuestionCard(question: question, practiceMode: ctrl.isPracticeMode),
                  const SizedBox(height: 16),
                  _AnswerArea(ctrl: ctrl, question: question),
                  // Panel "Đúng/Sai" + giải thích - CHỈ ở chế độ luyện tập
                  // (giữ nguyên trải nghiệm thi thật cho "Thi thử có giờ": chỉ
                  // biết điểm sau khi nộp CẢ bài, xem [ExamSessionController.
                  // isPracticeMode]) và chỉ sau khi bé bấm "Kiểm tra đáp án".
                  if (ctrl.isPracticeMode && ctrl.showFeedback) ...[
                    const SizedBox(height: 16),
                    _FeedbackPanel(ctrl: ctrl, question: question),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (ctrl.currentIndex > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: ctrl.goBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Câu trước'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: _PrimaryActionButton(ctrl: ctrl, question: question),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Nút hành động chính - Ở CHẾ ĐỘ LUYỆN TẬP, bấm lần đầu (đã chọn đáp án
/// nhưng chưa xem giải thích) sẽ "Kiểm tra đáp án" trước (hiện [_FeedbackPanel]
/// ngay tại chỗ), bấm lần 2 mới thật sự sang câu tiếp theo - giống cách các
/// app luyện thi phổ biến làm, ép bé nhìn thấy đúng/sai + giải thích trước
/// khi lướt qua câu khác thay vì bỏ qua luôn. Câu nói (speakingPrompt, không
/// chấm tự động được) và chế độ "Thi thử có giờ" bỏ qua bước này, giữ nguyên
/// hành vi "Câu tiếp theo"/"Nộp bài" như cũ.
class _PrimaryActionButton extends StatelessWidget {
  final ExamSessionController ctrl;
  final Question question;

  const _PrimaryActionButton({required this.ctrl, required this.question});

  @override
  Widget build(BuildContext context) {
    final needsCheck = ctrl.isPracticeMode &&
        question.questionType != QuestionType.speakingPrompt &&
        !ctrl.showFeedback &&
        ctrl.answerFor(question.id) != null &&
        ctrl.answerFor(question.id)!.isNotEmpty;

    return ElevatedButton(
      onPressed: needsCheck ? ctrl.checkAnswer : ctrl.goNext,
      style: ElevatedButton.styleFrom(
        backgroundColor: needsCheck ? const Color(0xFF3FAE5A) : AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        needsCheck ? 'Kiểm tra đáp án' : (ctrl.isLastQuestion ? 'Nộp bài' : 'Câu tiếp theo'),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Panel hiện NGAY sau khi bé bấm "Kiểm tra đáp án" - tô xanh/đỏ theo đúng
/// [ExamSessionController.isCurrentAnswerCorrect], luôn hiện đáp án đúng
/// (kể cả khi bé làm đúng, để củng cố lại) + giải thích nếu ngân hàng câu hỏi
/// có sẵn ([Question.explanation] - không phải câu nào cũng có).
class _FeedbackPanel extends StatelessWidget {
  final ExamSessionController ctrl;
  final Question question;

  const _FeedbackPanel({required this.ctrl, required this.question});

  @override
  Widget build(BuildContext context) {
    final isCorrect = ctrl.isCurrentAnswerCorrect ?? false;
    final color = isCorrect ? const Color(0xFF3FAE5A) : const Color(0xFFE0863C);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Chính xác!' : 'Chưa đúng',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 8),
            Text(
              'Đáp án đúng: ${correctAnswerText(question)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
          if (question.explanation != null) ...[
            const SizedBox(height: 8),
            Text(question.explanation!, style: const TextStyle(color: AppColors.textMuted)),
          ],
          if (GrammarLessons.forQuestion(question) case final lesson?)
            GrammarLessonLink(lesson: lesson),
        ],
      ),
    );
  }
}

/// "Ảnh" TOEIC Part 1 - ghép vài emoji lớn trong khung viền như 1 tấm ảnh
/// thật (xem doc comment [Question.imageEmoji] để biết lý do không dùng ảnh
/// chụp thật). Nền/viền tối giản để emoji là trọng tâm, giống cách 1 khung
/// ảnh thật nổi bật trên nền trắng của đề thi.
class _PhotoCard extends StatelessWidget {
  final String emoji;

  const _PhotoCard({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(emoji, textScaler: TextScaler.noScaling, style: const TextStyle(fontSize: 56)),
      ),
    );
  }
}

/// Đề câu hỏi. Câu TOEIC dạng bảng biểu có định dạng
/// `Look at the graphic. [Tiêu đề] dòng 1 | dòng 2 | ... | dòng cuối. Câu hỏi?`
/// được vẽ thành bảng giống đề thật thay vì 1 dòng chữ dài.
class _PromptText extends StatelessWidget {
  final String prompt;

  const _PromptText({required this.prompt});

  static final _graphic = RegExp(r'^Look at the graphic\.\s*\[([^\]]+)\]\s*(.+)$');
  static const _style = TextStyle(fontSize: 17, height: 1.4);

  @override
  Widget build(BuildContext context) {
    final m = _graphic.firstMatch(prompt);
    if (m == null) return Text(prompt, style: _style);
    final rows = m.group(2)!.split(' | ');
    final last = rows.removeLast();
    final cut = last.indexOf('. ');
    if (cut < 0) return Text(prompt, style: _style);
    rows.add(last.substring(0, cut));
    final questionText = last.substring(cut + 2);

    List<String> cells(String row) {
      for (final sep in [': ', ' – ', ' - ']) {
        final i = row.indexOf(sep);
        if (i > 0) return [row.substring(0, i), row.substring(i + sep.length)];
      }
      final space = row.indexOf(' ');
      return space > 0 ? [row.substring(0, space), row.substring(space + 1)] : [row, ''];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Look at the graphic.', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Text(m.group(1)!, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              for (final row in rows)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black12))),
                  child: Row(
                    children: [
                      Expanded(child: Text(cells(row)[0], style: const TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(child: Text(cells(row)[1])),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(questionText, style: _style),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Question question;
  final bool practiceMode;

  const _QuestionCard({required this.question, required this.practiceMode});

  /// Hệ số tốc độ của nút "Nghe chậm" (nhân thêm vào tốc độ đã chỉnh trong
  /// Cài đặt, không thay đổi cấu hình đã lưu).
  static const slowSpeed = 0.75;

  static final _audioButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.primary, width: 1.5),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  );

  void _listen(BuildContext context, {double speed = 1.0}) {
    context.read<TtsService>().speakScript(
          question.audioScript ?? question.prompt,
          // TOEIC dùng giọng người lớn tự nhiên, YLE dùng giọng chậm của bé.
          kind: question.track == ExamTrack.toeic ? VoiceKind.toeic : VoiceKind.kid,
          speed: speed,
        );
  }

  @override
  Widget build(BuildContext context) {
    final badge = question.topic ??
        (question.partNumber != null ? 'Part ${question.partNumber}' : question.skill.name);

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.idleBubble,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(badge, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          // "Ảnh" cho TOEIC Part 1 (Photographs) - xem doc comment
          // [Question.imageEmoji]. Đặt TRƯỚC câu hỏi, giống bố cục đề thật
          // (nhìn ảnh trước, sau đó mới nghe 4 mô tả A/B/C/D).
          if (question.imageEmoji != null) ...[
            _PhotoCard(emoji: question.imageEmoji!),
            const SizedBox(height: 12),
          ],
          _PromptText(prompt: question.prompt),
          // media.type == 'audio' xảy ra ở CẢ 2 trường hợp: đã có url thật lẫn
          // url == null (chưa có file audio thật, xem THIET_KE_SCHEMA_CHUNG.md
          // mục 5/10) - khi chưa có url, dùng TTS đọc [audioScript] (nội dung
          // THẬT cần nghe - hội thoại/thông báo/mô tả tranh, KHÁC với
          // [prompt] chỉ là câu hỏi/hướng dẫn hiển thị) làm giải pháp thay
          // audio thật. TOEIC dùng giọng tự nhiên hơn (rate/pitch riêng, xem
          // TtsService.speak) thay vì giọng chậm + cao kiểu trẻ con mặc định
          // (hợp với bé nhỏ tuổi ở track YLE, không hợp ngữ cảnh công sở).
          if (question.media.type == 'audio') ...[
            const SizedBox(height: 10),
            // Bấm được NHIỀU LẦN (TtsService tự dừng lượt đọc trước đó rồi đọc
            // lại từ đầu) - nghe lại thoải mái, không giới hạn số lần như thi
            // thật. Hội thoại (A:/B:, Man:/Woman:...) được đọc mỗi người 1
            // giọng - xem TtsService.speakScript.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _listen(context),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: Text(
                    question.audioScript != null
                        ? '🔊 Nghe lại nội dung'
                        : '🔊 Nghe lại (giọng đọc tạm thay audio thật)',
                  ),
                  style: _audioButtonStyle,
                ),
                // Chỉ ở chế độ luyện tập - thi thử giữ đúng tốc độ như thi thật.
                if (practiceMode)
                  OutlinedButton.icon(
                    onPressed: () => _listen(context, speed: slowSpeed),
                    icon: const Text('🐢'),
                    label: const Text('Nghe chậm 0.75x'),
                    style: _audioButtonStyle,
                  ),
              ],
            ),
            if (question.isAudioOnlyChoice) ...[
              const SizedBox(height: 8),
              const Text(
                '🎧 Đề thật KHÔNG in chữ đáp án ở Part này - bé nghe kỹ rồi chọn A, B, C hoặc D bên dưới nhé.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _AnswerArea extends StatelessWidget {
  final ExamSessionController ctrl;
  final Question question;

  const _AnswerArea({required this.ctrl, required this.question});

  @override
  Widget build(BuildContext context) {
    switch (question.questionType) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        return _ChoiceAnswer(key: ValueKey(question.id), ctrl: ctrl, question: question);
      case QuestionType.fillBlank:
      case QuestionType.shortAnswer:
        return _TextAnswer(key: ValueKey(question.id), ctrl: ctrl, question: question);
      case QuestionType.ordering:
      case QuestionType.listenAndColor:
      case QuestionType.listenAndNumber:
        return _OrderingAnswer(key: ValueKey(question.id), ctrl: ctrl, question: question);
      case QuestionType.matching:
        return _MatchingAnswer(key: ValueKey(question.id), ctrl: ctrl, question: question);
      case QuestionType.speakingPrompt:
        return _SpeakingAnswer(key: ValueKey(question.id), question: question);
    }
  }
}

class _ChoiceAnswer extends StatelessWidget {
  final ExamSessionController ctrl;
  final Question question;

  const _ChoiceAnswer({super.key, required this.ctrl, required this.question});

  @override
  Widget build(BuildContext context) {
    // trueFalse không có sẵn trong đề mẫu hiện tại, nhưng vẫn xử lý phòng khi
    // câu hỏi không kèm options - mặc định hiện True/False.
    final options = question.options.isNotEmpty
        ? question.options
        : const [
            AnswerOption(id: 'true', text: 'True'),
            AnswerOption(id: 'false', text: 'False'),
          ];
    final answer = ctrl.answerFor(question.id);
    final selectedId = (answer != null && answer.isNotEmpty) ? answer.first : null;

    // TOEIC Part 1/2 - đề thật không in chữ đáp án (chỉ đọc qua loa), nên
    // hiện dạng nút chữ cái A/B/C/D thay vì in nguyên câu lúc đang làm bài
    // (xem [Question.isAudioOnlyChoice]). Sau khi bấm "Kiểm tra đáp án" ở
    // chế độ luyện tập (ctrl.showFeedback), MỚI hiện đầy đủ text kèm chữ cái
    // để bé đối chiếu phần đã nghe với phần giải thích - nút "Nghe lại nội
    // dung" ở trên vẫn bấm lại được bình thường lúc này.
    final revealText = !question.isAudioOnlyChoice || (ctrl.isPracticeMode && ctrl.showFeedback);

    if (!revealText) {
      return Row(
        children: options.map((option) {
          final selected = option.id == selectedId;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: AspectRatio(
                aspectRatio: 1,
                child: OutlinedButton(
                  onPressed: () => ctrl.answerCurrent([option.id]),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected ? AppColors.primary : Colors.white,
                    foregroundColor: selected ? Colors.white : AppColors.primary,
                    side: BorderSide(color: AppColors.primary, width: selected ? 2 : 1.5),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    option.id.toUpperCase(),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    // showFeedback CHỈ true ở chế độ luyện tập sau khi bấm "Kiểm tra đáp án"
    // (xem _PrimaryActionButton) - lúc đó tô thêm xanh/đỏ để bé thấy ngay
    // đáp án đúng nằm ở đâu, giống cách [_FeedbackPanel] bên dưới đang làm.
    final showFeedback = ctrl.isPracticeMode && ctrl.showFeedback;

    return Column(
      children: options.map((option) {
        final selected = option.id == selectedId;
        final isCorrectOption = question.correctAnswer.contains(option.id);
        Color bg = selected ? AppColors.primary : Colors.white;
        Color fg = selected ? Colors.white : AppColors.primary;
        Color border = AppColors.primary;
        if (showFeedback) {
          if (isCorrectOption) {
            bg = const Color(0xFF3FAE5A);
            fg = Colors.white;
            border = const Color(0xFF3FAE5A);
          } else if (selected) {
            bg = const Color(0xFFE0863C);
            fg = Colors.white;
            border = const Color(0xFFE0863C);
          } else {
            bg = Colors.white;
            fg = AppColors.textMuted;
            border = AppColors.textMuted.withValues(alpha: 0.3);
          }
        }
        final label = question.isAudioOnlyChoice
            ? '${option.id.toUpperCase()}. ${option.text}'
            : option.text;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => ctrl.answerCurrent([option.id]),
              style: OutlinedButton.styleFrom(
                backgroundColor: bg,
                foregroundColor: fg,
                side: BorderSide(color: border, width: selected || (showFeedback && isCorrectOption) ? 2 : 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                alignment: Alignment.centerLeft,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(label, style: const TextStyle(fontSize: 16)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TextAnswer extends StatefulWidget {
  final ExamSessionController ctrl;
  final Question question;

  const _TextAnswer({super.key, required this.ctrl, required this.question});

  @override
  State<_TextAnswer> createState() => _TextAnswerState();
}

class _TextAnswerState extends State<_TextAnswer> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final existing = widget.ctrl.answerFor(widget.question.id);
    _controller = TextEditingController(
      text: existing != null && existing.isNotEmpty ? existing.first : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (text) => widget.ctrl.answerCurrent([text]),
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: 'Gõ câu trả lời...',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Bảng sắp xếp (ordering/listenAndColor/listenAndNumber - cả 3 đều chấm bằng
/// so khớp DANH SÁCH ID theo đúng thứ tự, xem `_isCorrect` trong
/// mock_test_engine.dart) - bé chạm các thẻ theo đúng thứ tự mong muốn, có
/// thể "Xoá" để bỏ thẻ cuối cùng vừa chọn. Thứ tự hiển thị các thẻ được XÁO
/// TRỘN lúc khởi tạo (engine không tự xáo) để bài tập có ý nghĩa.
class _OrderingAnswer extends StatefulWidget {
  final ExamSessionController ctrl;
  final Question question;

  const _OrderingAnswer({super.key, required this.ctrl, required this.question});

  @override
  State<_OrderingAnswer> createState() => _OrderingAnswerState();
}

class _OrderingAnswerState extends State<_OrderingAnswer> {
  late final List<AnswerOption> _shuffled;
  late List<String> _picked;

  @override
  void initState() {
    super.initState();
    _shuffled = List<AnswerOption>.from(widget.question.options)..shuffle();
    final existing = widget.ctrl.answerFor(widget.question.id);
    _picked = existing != null ? List<String>.from(existing) : <String>[];
  }

  void _tap(String id) {
    if (_picked.contains(id)) return;
    setState(() => _picked = [..._picked, id]);
    widget.ctrl.answerCurrent(_picked);
  }

  void _undo() {
    if (_picked.isEmpty) return;
    setState(() => _picked = _picked.sublist(0, _picked.length - 1));
    widget.ctrl.answerCurrent(_picked);
  }

  String _textOf(String id) =>
      widget.question.options.firstWhere((o) => o.id == id).text;

  Widget _chip(String text, {required bool filled, bool dimmed = false, VoidCallback? onTap}) {
    return Material(
      color: filled ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: dimmed ? 0.2 : 0.5)),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: filled
                  ? Colors.white
                  : (dimmed ? AppColors.textMuted.withValues(alpha: 0.4) : AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _picked.map((id) => _chip(_textOf(id), filled: true)).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _picked.isNotEmpty ? _undo : null,
            icon: const Icon(Icons.backspace_outlined, size: 18),
            label: const Text('Xoá'),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _shuffled.map((o) {
            final used = _picked.contains(o.id);
            return _chip(o.text, filled: false, dimmed: used, onTap: used ? null : () => _tap(o.id));
          }).toList(),
        ),
      ],
    );
  }
}

/// Bảng nối cặp (matching) - suy ra cột trái/phải từ chính các cặp trong
/// [Question.correctAnswer] (định dạng "leftId:rightId", xem comment trong
/// question_bank_models.dart) CHỈ để biết id nào thuộc cột nào, KHÔNG dùng để
/// lộ đáp án đúng (không tiết lộ CẶP nào khớp nhau). Bé chạm 1 mục cột trái
/// rồi 1 mục cột phải để nối; chạm lại mục trái đã nối để gỡ.
class _MatchingAnswer extends StatefulWidget {
  final ExamSessionController ctrl;
  final Question question;

  const _MatchingAnswer({super.key, required this.ctrl, required this.question});

  @override
  State<_MatchingAnswer> createState() => _MatchingAnswerState();
}

class _MatchingAnswerState extends State<_MatchingAnswer> {
  late final List<AnswerOption> _left;
  late final List<AnswerOption> _right;
  String? _selectedLeft;
  late Map<String, String> _pairs;

  @override
  void initState() {
    super.initState();
    final leftIds = widget.question.correctAnswer.map((p) => p.split(':').first).toSet();
    final rightIds = widget.question.correctAnswer.map((p) => p.split(':').last).toSet();
    _left = widget.question.options.where((o) => leftIds.contains(o.id)).toList();
    _right = List<AnswerOption>.from(widget.question.options.where((o) => rightIds.contains(o.id)))
      ..shuffle();

    final existing = widget.ctrl.answerFor(widget.question.id) ?? const [];
    _pairs = {
      for (final p in existing) p.split(':').first: p.split(':').last,
    };
  }

  void _submit() {
    widget.ctrl.answerCurrent(_pairs.entries.map((e) => '${e.key}:${e.value}').toList());
  }

  void _tapLeft(String id) {
    setState(() => _selectedLeft = _selectedLeft == id ? null : id);
  }

  void _tapRight(String id) {
    if (_selectedLeft == null) return;
    setState(() {
      _pairs.removeWhere((_, v) => v == id); // 1 mục phải chỉ nối với 1 mục trái
      _pairs[_selectedLeft!] = id;
      _selectedLeft = null;
    });
    _submit();
  }

  void _removePair(String leftId) {
    setState(() => _pairs.remove(leftId));
    _submit();
  }

  Widget _leftTile(AnswerOption o) {
    final matched = _pairs.containsKey(o.id);
    final selected = _selectedLeft == o.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => matched ? _removePair(o.id) : _tapLeft(o.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: matched ? AppColors.primary : (selected ? AppColors.idleBubble : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: selected ? 2 : 1),
          ),
          child: Text(
            matched ? '${o.text} ✓' : o.text,
            style: TextStyle(
              color: matched ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _rightTile(AnswerOption o) {
    final used = _pairs.containsValue(o.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _tapRight(o.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: used ? AppColors.primary.withValues(alpha: 0.15) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: used ? 0.4 : 0.7)),
          ),
          child: Text(o.text, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: _left.map(_leftTile).toList())),
        const SizedBox(width: 16),
        Expanded(child: Column(children: _right.map(_rightTile).toList())),
      ],
    );
  }
}

/// Câu nói - KHÔNG chấm tự động (xem `_isCorrect`/`_baseScore` trong
/// mock_test_engine.dart, tách riêng vào `TestScore.ungradedCount`) - chỉ hiện
/// nhắc phụ huynh nghe trực tiếp + nút nghe lại câu hỏi bằng TTS.
class _SpeakingAnswer extends StatelessWidget {
  final Question question;

  const _SpeakingAnswer({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.happyBubble,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🎤', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Câu nói - phụ huynh nghe bé trả lời trực tiếp, không chấm tự động.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.read<TtsService>().speak(question.prompt),
            icon: const Icon(Icons.volume_up_rounded, size: 18),
            label: const Text('Nghe lại câu hỏi'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamResultView extends StatelessWidget {
  final ExamSessionController ctrl;

  const _ExamResultView({required this.ctrl});

  void _retry(BuildContext context) {
    openExamSession(
      context,
      config: ctrl.config,
      mode: ctrl.mode,
      fixedQuestions: ctrl.fixedQuestions,
      // Cấu hình "rawPercentage" = phiên tự tạo (ôn câu sai, luyện 1 chủ đề)
      // - không lưu vào lịch sử điểm đề thi thử.
      saveScore: ctrl.config.scoringStrategyId != 'rawPercentage',
      replace: true,
    );
  }

  void _openReview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExamReviewScreen(
          title: ctrl.config.displayName,
          questions: ctrl.questions,
          answers: {for (final q in ctrl.questions) q.id: ctrl.answerFor(q.id)},
        ),
      ),
    );
  }

  void _practiceTopic(BuildContext context, Question sample) {
    final topic = sample.topic!;
    openExamSession(
      context,
      config: topicPracticeConfig(
        track: sample.track,
        level: sample.level,
        skill: sample.skill,
        partNumber: sample.track == ExamTrack.toeic ? sample.partNumber : null,
        topics: [topic],
        title: 'Luyện thêm: $topic',
      ),
      mode: TestMode.practice,
      saveScore: false,
    );
  }

  bool _isRight(Question q) {
    final answer = ctrl.answerFor(q.id);
    return answer != null && answer.isNotEmpty && isAnswerCorrect(q, answer);
  }

  /// Chủ đề có từ 2 câu sai trở lên (nhiều nhất trước, tối đa 4) - mỗi chủ
  /// đề giữ 1 câu mẫu để biết skill/part khi mở phiên luyện thêm.
  static List<(Question, int)> _topicsByMistakes(List<Question> wrong) {
    final counts = <String, (Question, int)>{};
    for (final q in wrong) {
      final topic = q.topic;
      if (topic == null) continue;
      final key = '${q.skill.name}|${q.partNumber}|$topic';
      final current = counts[key];
      counts[key] = (current?.$1 ?? q, (current?.$2 ?? 0) + 1);
    }
    final list = counts.values.where((e) => e.$2 >= 2).toList()..sort((a, b) => b.$2.compareTo(a.$2));
    return list.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final score = ctrl.score!;
    final percent = (score.percentage * 100).round();
    final wrong = [
      for (final q in ctrl.questions)
        if (q.questionType != QuestionType.speakingPrompt && !_isRight(q)) q,
    ];
    final wrongCount = wrong.length;
    // Chỉ câu ĐÃ trả lời mà sai mới vào Sổ câu sai (câu bỏ trống thì không).
    final answeredWrong = wrong.where((q) => ctrl.answerFor(q.id)?.isNotEmpty ?? false).length;
    final weakTopics = _topicsByMistakes(wrong);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(percent >= 60 ? '🎉' : '💪', style: const TextStyle(fontSize: 70)),
          const SizedBox(height: 8),
          Text(
            ctrl.config.displayName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Đúng $percent% (${score.rawCorrect}/${score.rawTotal} câu)',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          if (score.ungradedCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              '+ ${score.ungradedCount} câu nói cần phụ huynh nghe và chấm riêng',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          if (score.shieldsBySkill != null) _ShieldsCard(shields: score.shieldsBySkill!),
          if (score.toeicScaledScore != null) ...[
            const SizedBox(height: 16),
            _ToeicScoreCard(scaled: score.toeicScaledScore!),
          ],
          if (score.weakTags.isNotEmpty) ...[
            const SizedBox(height: 16),
            _WeakTagsCard(tags: score.weakTags),
          ],
          if (weakTopics.isNotEmpty) ...[
            const SizedBox(height: 16),
            _WeakTopicsCard(
              topics: weakTopics,
              onPractice: (sample) => _practiceTopic(context, sample),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openReview(context),
              icon: const Icon(Icons.fact_check_rounded),
              label: Text(wrongCount > 0 ? 'Xem lại bài làm ($wrongCount câu sai/bỏ trống)' : 'Xem lại bài làm'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (answeredWrong > 0) ...[
            const SizedBox(height: 6),
            Text(
              '📕 $answeredWrong câu làm sai đã được thêm vào Sổ câu sai - vào mục Thi thử để ôn lại theo lịch.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Về danh sách đề'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _retry(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Làm lại', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShieldsCard extends StatelessWidget {
  final Map<Skill, int> shields;

  const _ShieldsCard({required this.shields});

  String _skillLabel(Skill s) {
    switch (s) {
      case Skill.vocabulary:
        return 'Từ vựng';
      case Skill.grammar:
        return 'Ngữ pháp';
      case Skill.listening:
        return 'Nghe';
      case Skill.reading:
        return 'Đọc';
      case Skill.writing:
        return 'Viết';
      case Skill.speaking:
        return 'Nói';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Khiên theo kỹ năng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          ...shields.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(width: 90, child: Text(_skillLabel(e.key))),
                  Text('🛡️' * e.value),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Thang khiên tự thiết kế cho luyện tập, không phải thang điểm chính thức của Cambridge English.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _ToeicScoreCard extends StatelessWidget {
  final Map<String, int> scaled;

  const _ToeicScoreCard({required this.scaled});

  Widget _scoreColumn(String label, int value) {
    return Column(
      children: [
        Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Điểm TOEIC ước lượng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _scoreColumn('Listening', scaled['listening'] ?? 0),
              _scoreColumn('Reading', scaled['reading'] ?? 0),
              _scoreColumn('Tổng', scaled['total'] ?? 0),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Điểm quy đổi tuyến tính gần đúng để ước lượng trình độ khi luyện tập - KHÔNG phải '
            'điểm thi TOEIC thật (ETS không công bố công thức quy đổi chính thức).',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _WeakTagsCard extends StatelessWidget {
  final List<String> tags;

  const _WeakTagsCard({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nên ôn lại', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((t) => Chip(label: Text(t), backgroundColor: AppColors.idleBubble)).toList(),
          ),
        ],
      ),
    );
  }
}

/// Chủ đề làm sai nhiều trong lượt này + nút luyện ngay 10 câu cùng chủ đề.
class _WeakTopicsCard extends StatelessWidget {
  final List<(Question, int)> topics;
  final ValueChanged<Question> onPractice;

  const _WeakTopicsCard({required this.topics, required this.onPractice});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chủ đề hay sai - luyện ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (sample, count) in topics)
                ActionChip(
                  avatar: const Icon(Icons.play_arrow_rounded, size: 18, color: AppColors.primary),
                  label: Text('${sample.topic} · $count câu chưa đúng'),
                  backgroundColor: AppColors.idleBubble,
                  onPressed: () => onPractice(sample),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
