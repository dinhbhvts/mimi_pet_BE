import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/domain/entities/picture_scene.dart';
import 'package:mimi_pet/presentation/state/scene_play_controller.dart';
import 'package:mimi_pet/presentation/widgets/scene_illustrations.dart';
import 'package:mimi_pet/presentation/widgets/speech_bubble.dart';
import 'package:mimi_pet/presentation/widgets/talk_button.dart';

/// Màn hình chơi 1 "Bài tranh" - hiện tranh minh hoạ CỐ ĐỊNH suốt phiên chơi,
/// bên dưới lần lượt hiện từng câu hỏi ([ScenePlayController.currentQuestion])
/// dạng chạm chọn/đúng-sai/nói, chấm xong chuyển câu tiếp theo tự động.
///
/// [ScenePlayController] phải được cung cấp qua ChangeNotifierProvider phía
/// trên route này (xem `PictureScenesScreen._openScene`) và đã gọi `start()`.
class PictureScenePlayScreen extends StatelessWidget {
  const PictureScenePlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ScenePlayController>();

    if (ctrl.state == ScenePlaySessionState.notStarted) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (ctrl.isFinished) {
      return _SceneCompleteView(ctrl: ctrl);
    }

    return const _ScenePlayBody();
  }
}

class _ScenePlayBody extends StatelessWidget {
  const _ScenePlayBody();

  Widget _buildAnswerArea(ScenePlayController ctrl) {
    final question = ctrl.currentQuestion;
    switch (question.kind) {
      case SceneQuestionKind.choice:
        return _SceneChoiceButtons(
          options: question.options,
          enabled: ctrl.state == ScenePlaySessionState.awaitingAnswer,
          onSelected: ctrl.submitChoice,
          state: ctrl.state,
          correctAnswer: question.answer,
          selectedOption: ctrl.selectedOption,
        );
      case SceneQuestionKind.trueFalse:
        return _SceneChoiceButtons(
          options: const ['True', 'False'],
          enabled: ctrl.state == ScenePlaySessionState.awaitingAnswer,
          onSelected: ctrl.submitChoice,
          state: ctrl.state,
          correctAnswer: question.answer,
          selectedOption: ctrl.selectedOption,
        );
      case SceneQuestionKind.speak:
        final isListening = ctrl.state == ScenePlaySessionState.listening;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TalkButton(
              isListening: isListening,
              enabled: ctrl.canTapTalk,
              onTap: ctrl.onTalkPressed,
              label: isListening ? 'Listening...' : 'Tap to talk',
            ),
            if (ctrl.state == ScenePlaySessionState.incorrect) ...[
              const SizedBox(height: 12),
              _AnswerRevealChip(answer: question.answer),
            ],
          ],
        );
    }
  }

  String _statusTextFor(ScenePlaySessionState state) {
    switch (state) {
      case ScenePlaySessionState.asking:
        return 'Mimi đang hỏi...';
      case ScenePlaySessionState.listening:
        return 'Mimi đang nghe...';
      case ScenePlaySessionState.evaluating:
        return 'Mimi đang suy nghĩ...';
      case ScenePlaySessionState.correct:
        return 'Đúng rồi, giỏi quá! 🎉';
      case ScenePlaySessionState.incorrect:
        return 'Chưa đúng - xem đáp án nhé!';
      case ScenePlaySessionState.awaitingAnswer:
      case ScenePlaySessionState.notStarted:
      case ScenePlaySessionState.finished:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ScenePlayController>();
    final statusText = _statusTextFor(ctrl.state);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LinearProgressIndicator(
                                  value: ctrl.progressFraction,
                                  minHeight: 10,
                                  backgroundColor: Colors.white,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${ctrl.currentIndex + 1}/${ctrl.totalQuestions}',
                              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '⭐ ${ctrl.correctCount}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SceneIllustration(illustrationId: ctrl.scene.illustrationId),
                        const SizedBox(height: 16),
                        SpeechBubble(text: ctrl.currentQuestion.prompt),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 20,
                          child: statusText.isEmpty
                              ? null
                              : Text(
                                  statusText,
                                  style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
                                ),
                        ),
                        const SizedBox(height: 8),
                        _buildAnswerArea(ctrl),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Hàng nút trắc nghiệm / đúng-sai - tô XANH đáp án đúng, tô ĐỎ lựa chọn bé
/// vừa chọn sai, khi đã có kết quả (correct/incorrect) - cùng phong cách với
/// `_ChoiceButtons` ở `lesson_screen.dart` (Vòng 12).
class _SceneChoiceButtons extends StatelessWidget {
  final List<String> options;
  final bool enabled;
  final ValueChanged<String> onSelected;
  final ScenePlaySessionState state;
  final String correctAnswer;
  final String? selectedOption;

  const _SceneChoiceButtons({
    required this.options,
    required this.enabled,
    required this.onSelected,
    required this.state,
    required this.correctAnswer,
    required this.selectedOption,
  });

  static const _correctColor = Color(0xFF3FAE5A);
  static const _incorrectColor = Color(0xFFE0554A);

  @override
  Widget build(BuildContext context) {
    final showResult = state == ScenePlaySessionState.correct || state == ScenePlaySessionState.incorrect;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: options.map((option) {
        final isCorrectOption = option == correctAnswer;
        final isSelectedOption = option == selectedOption;

        Color background = Colors.white;
        Color foreground = AppColors.primary;
        Color border = AppColors.primary;
        IconData? icon;

        if (showResult && isCorrectOption) {
          background = _correctColor;
          foreground = Colors.white;
          border = _correctColor;
          icon = Icons.check_circle;
        } else if (showResult && isSelectedOption) {
          background = _incorrectColor;
          foreground = Colors.white;
          border = _incorrectColor;
          icon = Icons.cancel;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: enabled ? () => onSelected(option) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: background,
                foregroundColor: foreground,
                disabledBackgroundColor: background == Colors.white ? Colors.white.withValues(alpha: 0.6) : background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: border, width: 1.5),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(option, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 20, color: Colors.white),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Hiện đáp án đúng cho câu hỏi dạng NÓI khi bé trả lời sai (không có nút để
/// tô màu như choice/trueFalse, nên cần 1 cách khác để bé biết đáp án đúng).
class _AnswerRevealChip extends StatelessWidget {
  final String answer;

  const _AnswerRevealChip({required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE0554A).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '👉 It\'s "$answer"',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFE0554A)),
      ),
    );
  }
}

class _SceneCompleteView extends StatelessWidget {
  final ScenePlayController ctrl;

  const _SceneCompleteView({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🖼️🎉', style: TextStyle(fontSize: 70)),
              const SizedBox(height: 16),
              const Text(
                'Great job!',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Bé đã xong bài tranh "${ctrl.scene.title}"',
                style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '⭐ ${ctrl.correctCount}/${ctrl.totalQuestions} câu đúng',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'Back to Bài tranh',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
