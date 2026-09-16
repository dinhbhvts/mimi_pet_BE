import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/domain/entities/word.dart';
import 'package:mimi_pet/presentation/state/hearts_controller.dart';
import 'package:mimi_pet/presentation/state/lesson_controller.dart';
import 'package:mimi_pet/presentation/state/pet_character_controller.dart';
import 'package:mimi_pet/presentation/state/pet_controller.dart';
import 'package:mimi_pet/presentation/state/pet_inventory_controller.dart';
import 'package:mimi_pet/presentation/state/pet_palette_controller.dart';
import 'package:mimi_pet/presentation/widgets/pet_avatar.dart';
import 'package:mimi_pet/presentation/widgets/speech_bubble.dart';
import 'package:mimi_pet/presentation/widgets/streak_celebration.dart';
import 'package:mimi_pet/presentation/widgets/talk_button.dart';
import 'package:mimi_pet/presentation/widgets/type_instead_of_talk.dart';

/// Màn hình chơi 1 bài học - Mimi hỏi (nhiều KIỂU: nói/chọn/điền từ/sắp xếp
/// câu/chính tả/luyện phát âm, xem [QuestionKind]) -> bé trả lời -> Mimi
/// đánh giá -> khen + thưởng sao -> từ tiếp theo.
///
/// [LessonController] phải được cung cấp qua ChangeNotifierProvider phía
/// trên route này (xem PlayScreen._openLesson) và đã gọi `start()`.
class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lessonCtrl = context.watch<LessonController>();
    final hearts = context.watch<HeartsController>();

    if (lessonCtrl.state == LessonSessionState.notStarted) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (lessonCtrl.isOutOfHearts) {
      return _OutOfHeartsView(hearts: hearts);
    }

    if (lessonCtrl.isFinished) {
      return _LessonCompleteView(lessonCtrl: lessonCtrl);
    }

    return const _LessonPlayView();
  }
}

/// Phần "đang chơi" của [LessonScreen] - tách thành StatefulWidget riêng
/// (2026-08-23, phần của hiệu ứng UIUX bổ sung) để có thể theo dõi các lần
/// CHUYỂN trạng thái của [LessonController] (so [_prevState] với
/// `lessonCtrl.state` mỗi lần build) và kích hoạt animation "lắc" khi sai
/// (`_shakeController`) / "nảy" khi đúng (`_popController`) ĐÚNG 1 LẦN cho
/// mỗi lần chuyển - không kích hoạt lặp lại khi widget chỉ rebuild lại cùng
/// 1 trạng thái (ví dụ do Provider khác đổi giá trị) - cùng tinh thần với
/// "lấy rồi xoá" của [LessonController.consumeStreakCelebration].
class _LessonPlayView extends StatefulWidget {
  const _LessonPlayView();

  @override
  State<_LessonPlayView> createState() => _LessonPlayViewState();
}

class _LessonPlayViewState extends State<_LessonPlayView> with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final AnimationController _popController;
  LessonSessionState? _prevState;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _popController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _popController.dispose();
    super.dispose();
  }

  /// Xem có vừa CHUYỂN sang [LessonSessionState.incorrect]/`correct` không -
  /// nếu có thì phát animation tương ứng. Chạy sau khung hình hiện tại
  /// (`addPostFrameCallback`, cùng idiom `_LessonCompleteView._maybeCelebrateStreak`)
  /// để tránh gọi `AnimationController.forward` ngay giữa `build`.
  void _maybeAnimateTransition(LessonSessionState state) {
    final previous = _prevState;
    _prevState = state;
    if (previous == null || previous == state) return;
    if (state == LessonSessionState.incorrect) {
      _shakeController.forward(from: 0);
    } else if (state == LessonSessionState.correct) {
      _popController.forward(from: 0);
    }
  }

  String _bubbleTextFor(LessonController ctrl) {
    final word = ctrl.currentWord;
    switch (ctrl.currentQuestionKind) {
      case QuestionKind.fillBlank:
        return 'Fill in the blank!';
      case QuestionKind.reorder:
        return 'Put the words in order!';
      case QuestionKind.dictation:
        return 'Listen and type the word!';
      case QuestionKind.pronunciation:
        return 'Say this with me: ${word.en}!';
      case QuestionKind.speak:
      case QuestionKind.choice:
        return word.promptText;
    }
  }

  Widget _buildVisual(LessonController ctrl) {
    final kind = ctrl.currentQuestionKind;
    if (kind == QuestionKind.fillBlank) {
      // SỬA LỖI (2026-08-31): trước đây chỉ hiện câu có chỗ trống, KHÔNG có
      // hình minh hoạ - nếu 2 lựa chọn cùng "hợp lý" trong câu (ví dụ "I like
      // the ___." thì "apple" hay "cat" đều đúng ngữ pháp), bé không có cách
      // nào biết chắc đáp án mà Mimi mong đợi, gây câu hỏi lấp lửng. Thêm lại
      // hình/màu minh hoạ của ĐÚNG từ mục tiêu (giống hệt dạng bài trắc
      // nghiệm) phía trên câu - đáp án luôn RÕ RÀNG DUY NHẤT (khớp hình), bé
      // vẫn phải đọc hiểu câu để biết ĐẶT từ đó vào đâu/viết thế nào, không
      // làm mất hẳn giá trị luyện đọc của dạng bài này.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WordPromptVisual(word: ctrl.currentWord),
          const SizedBox(height: 16),
          _FillBlankSentence(word: ctrl.currentWord),
        ],
      );
    }
    if (kind == QuestionKind.reorder) {
      // Câu cần sắp xếp CHÍNH LÀ nội dung chính (hiển thị ở khu vực trả lời
      // bên dưới) - không cần thêm hình minh hoạ ở đây, tránh rối mắt.
      return const SizedBox.shrink();
    }
    return _WordPromptVisual(word: ctrl.currentWord);
  }

  Widget _buildAnswerArea(LessonController ctrl) {
    switch (ctrl.currentQuestionKind) {
      case QuestionKind.choice:
      case QuestionKind.fillBlank:
        return _ChoiceButtons(
          options: ctrl.choiceOptions,
          enabled: ctrl.state == LessonSessionState.awaitingChoice,
          onSelected: ctrl.onChoiceSelected,
          state: ctrl.state,
          correctWordId: ctrl.currentWord.id,
          selectedWordId: ctrl.selectedWordId,
        );
      case QuestionKind.reorder:
        return _ReorderBoard(
          tokens: ctrl.reorderTokens,
          pickedIndices: ctrl.reorderPickedIndices,
          enabled: ctrl.state == LessonSessionState.awaitingReorder,
          onTapToken: ctrl.onReorderTapToken,
          onUndo: ctrl.onReorderUndo,
          state: ctrl.state,
        );
      case QuestionKind.dictation:
        return _DictationInput(
          key: ValueKey(ctrl.currentIndex),
          enabled: ctrl.state == LessonSessionState.awaitingTyping,
          onSubmitted: ctrl.onDictationSubmitted,
          state: ctrl.state,
        );
      case QuestionKind.speak:
      case QuestionKind.pronunciation:
        final isListening = ctrl.state == LessonSessionState.listening;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TalkButton(
              isListening: isListening,
              enabled: ctrl.canTapTalk,
              onTap: ctrl.onTalkPressed,
              label: isListening ? 'Listening...' : 'Tap to talk',
            ),
            const SizedBox(height: 8),
            // Fallback cho Safari trên iPhone/iPad (hầu như không hỗ trợ
            // speech_to_text) - xem `TypeInsteadOfTalk`.
            TypeInsteadOfTalk(
              enabled: ctrl.canTapTalk,
              onSubmitted: ctrl.onTypedAnswerSubmitted,
              hintText: 'Gõ từ tiếng Anh...',
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonCtrl = context.watch<LessonController>();
    final pet = context.watch<PetController>();
    final character = context.watch<PetCharacterController>().character;
    final palette = context.watch<PetPaletteController>().paletteFor(character);
    final inventory = context.watch<PetInventoryController>();
    final hearts = context.watch<HeartsController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeAnimateTransition(lessonCtrl.state);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          // Nhiều dạng bài mới (sắp xếp câu, chính tả...) cao thấp khác nhau
          // tuỳ nội dung - bọc LayoutBuilder + SingleChildScrollView +
          // ConstrainedBox + IntrinsicHeight (cùng idiom đã dùng ở
          // HomeScreen) để nội dung canh giữa khi vừa khung, tự cuộn khi dài
          // hơn khung, tránh lỗi tràn/che mất nút bấm trên máy màn hình nhỏ.
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
                                  value: lessonCtrl.progressFraction,
                                  minHeight: 10,
                                  backgroundColor: Colors.white,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('❤️ ${hearts.hearts}', style: const TextStyle(fontSize: 15)),
                            const SizedBox(width: 10),
                            Text(
                              '⭐ ${lessonCtrl.starsEarnedThisSession}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // "Nảy" nhẹ khi vừa trả lời ĐÚNG (xem [_maybeAnimateTransition])
                        // - dùng Curves.elasticOut cho cảm giác vui tươi, phù hợp bé nhỏ
                        // tuổi hơn là 1 hiệu ứng "phẳng" khô khan.
                        AnimatedBuilder(
                          animation: _popController,
                          builder: (context, child) {
                            final t = Curves.elasticOut.transform(_popController.value);
                            final scale = 1.0 + (t * 0.18);
                            return Transform.scale(scale: scale, child: child);
                          },
                          child: PetAvatar(
                            mood: pet.mood,
                            character: character,
                            palette: palette,
                            headAccessory: inventory.equippedHead,
                            neckAccessory: inventory.equippedNeck,
                            size: 130,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SpeechBubble(text: _bubbleTextFor(lessonCtrl)),
                        const SizedBox(height: 16),
                        _buildVisual(lessonCtrl),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 20,
                          child: _StatusHint(
                            state: lessonCtrl.state,
                            kind: lessonCtrl.currentQuestionKind,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // "Lắc" nhẹ khu vực trả lời khi vừa SAI (xem
                        // [_maybeAnimateTransition]) - dao động giảm dần (nhân với
                        // `1 - value`) để hiệu ứng tắt dần tự nhiên thay vì dừng khựng.
                        AnimatedBuilder(
                          animation: _shakeController,
                          builder: (context, child) {
                            final v = _shakeController.value;
                            final offset = sin(v * pi * 6) * 10 * (1 - v);
                            return Transform.translate(offset: Offset(offset, 0), child: child);
                          },
                          child: _buildAnswerArea(lessonCtrl),
                        ),
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

class _StatusHint extends StatelessWidget {
  final LessonSessionState state;
  final QuestionKind kind;

  const _StatusHint({required this.state, required this.kind});

  @override
  Widget build(BuildContext context) {
    String? text;
    switch (state) {
      case LessonSessionState.listening:
        text = 'Mimi đang nghe...';
        break;
      case LessonSessionState.evaluating:
        text = 'Mimi đang suy nghĩ...';
        break;
      case LessonSessionState.correct:
        text = 'Đúng rồi, giỏi quá! 🎉';
        break;
      case LessonSessionState.incorrect:
        text = 'Gần đúng rồi, thử lại nhé!';
        break;
      case LessonSessionState.awaitingChoice:
        text = kind == QuestionKind.fillBlank ? 'Điền từ còn thiếu nhé!' : 'Chọn đáp án đúng nhé!';
        break;
      case LessonSessionState.awaitingReorder:
        text = 'Chạm các từ theo đúng thứ tự nhé!';
        break;
      case LessonSessionState.awaitingTyping:
        text = 'Gõ từ bé vừa nghe nhé!';
        break;
      default:
        text = null;
    }
    if (text == null) return const SizedBox.shrink();
    return Text(text, style: const TextStyle(fontSize: 15, color: AppColors.textMuted));
  }
}

/// Hàng nút trắc nghiệm - dùng chung cho câu hỏi dạng chọn
/// ([QuestionKind.choice]) và điền từ ([QuestionKind.fillBlank]) - bé nhìn
/// hình/câu ở trên rồi chọn từ tiếng Anh đúng trong 2-3 lựa chọn.
class _ChoiceButtons extends StatelessWidget {
  final List<Word> options;
  final bool enabled;
  final ValueChanged<Word> onSelected;

  /// [state]/[correctWordId]/[selectedWordId] (bổ sung 2026-08-23): dùng để tô
  /// màu XANH đáp án đúng và màu ĐỎ đáp án bé vừa chọn (nếu sai) ngay khi đã
  /// có kết quả (`correct`/`incorrect`) - giúp bé thấy rõ đúng/sai thay vì chỉ
  /// nghe Mimi nói, cùng tinh thần với [_WordLevelFeedback] bên tab Từ điển.
  final LessonSessionState state;
  final String correctWordId;
  final String? selectedWordId;

  const _ChoiceButtons({
    required this.options,
    required this.enabled,
    required this.onSelected,
    required this.state,
    required this.correctWordId,
    required this.selectedWordId,
  });

  static const _correctColor = Color(0xFF3FAE5A);
  static const _incorrectColor = Color(0xFFE0554A);

  @override
  Widget build(BuildContext context) {
    final showResult = state == LessonSessionState.correct || state == LessonSessionState.incorrect;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: options.map((option) {
        final isCorrectOption = option.id == correctWordId;
        final isSelectedOption = option.id == selectedWordId;

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
                  Text(
                    option.en.toUpperCase(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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

/// Câu mẫu có chỗ trống cho dạng bài "Điền từ" ([QuestionKind.fillBlank]).
class _FillBlankSentence extends StatelessWidget {
  final Word word;

  const _FillBlankSentence({required this.word});

  @override
  Widget build(BuildContext context) {
    final halves = word.sentenceHalves;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(halves[0], style: const TextStyle(fontSize: 19)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 2),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.primary, width: 3)),
            ),
          ),
          Text(halves[1], style: const TextStyle(fontSize: 19)),
        ],
      ),
    );
  }
}

/// Bảng sắp xếp câu ([QuestionKind.reorder]) - hàng trên là câu đang ghép,
/// hàng dưới là "ngân hàng từ" xáo trộn để bé chạm chọn theo đúng thứ tự.
class _ReorderBoard extends StatelessWidget {
  final List<String> tokens;
  final List<int> pickedIndices;
  final bool enabled;
  final ValueChanged<int> onTapToken;
  final VoidCallback onUndo;

  /// Bổ sung 2026-08-23: tô màu khung câu đang ghép XANH/ĐỎ theo kết quả
  /// chấm điểm, cho bé thấy rõ đúng/sai ngay trên chính câu bé vừa ghép.
  final LessonSessionState state;

  const _ReorderBoard({
    required this.tokens,
    required this.pickedIndices,
    required this.enabled,
    required this.onTapToken,
    required this.onUndo,
    required this.state,
  });

  Widget _chip(String text, {required bool filled, bool dimmed = false, VoidCallback? onTap}) {
    final borderColor = filled
        ? AppColors.primary
        : AppColors.primary.withValues(alpha: dimmed ? 0.15 : 0.4);
    final textColor = filled
        ? Colors.white
        : (dimmed ? AppColors.textMuted.withValues(alpha: 0.4) : AppColors.primary);

    return Material(
      color: filled ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            text,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color assembledBg = Colors.white.withValues(alpha: 0.6);
    Color assembledBorder = AppColors.primary.withValues(alpha: 0.3);
    double assembledBorderWidth = 1;
    if (state == LessonSessionState.correct) {
      assembledBg = const Color(0xFF3FAE5A).withValues(alpha: 0.14);
      assembledBorder = const Color(0xFF3FAE5A);
      assembledBorderWidth = 2;
    } else if (state == LessonSessionState.incorrect) {
      assembledBg = const Color(0xFFE0554A).withValues(alpha: 0.14);
      assembledBorder = const Color(0xFFE0554A);
      assembledBorderWidth = 2;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: assembledBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: assembledBorder, width: assembledBorderWidth),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pickedIndices.map((i) => _chip(tokens[i], filled: true)).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: enabled && pickedIndices.isNotEmpty ? onUndo : null,
            icon: const Icon(Icons.backspace_outlined, size: 18),
            label: const Text('Xoá'),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: List.generate(tokens.length, (i) {
            final used = pickedIndices.contains(i);
            return _chip(
              tokens[i],
              filled: false,
              dimmed: used,
              onTap: enabled && !used ? () => onTapToken(i) : null,
            );
          }),
        ),
      ],
    );
  }
}

/// Ô nhập chính tả ([QuestionKind.dictation]) - dùng key theo chỉ số từ
/// (xem `LessonScreen._buildAnswerArea`) để TextField tự làm mới khi chuyển
/// sang từ mới, nhưng GIỮ NGUYÊN nội dung đã gõ khi chỉ đang thử lại cùng 1
/// từ (để bé thấy và sửa lại chỗ gõ sai thay vì phải gõ lại từ đầu).
class _DictationInput extends StatefulWidget {
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  /// Bổ sung 2026-08-23: tô viền ô nhập XANH/ĐỎ theo kết quả chấm điểm, cùng
  /// tinh thần với [_ChoiceButtons]/[_ReorderBoard].
  final LessonSessionState state;

  const _DictationInput({
    super.key,
    required this.enabled,
    required this.onSubmitted,
    required this.state,
  });

  @override
  State<_DictationInput> createState() => _DictationInputState();
}

class _DictationInputState extends State<_DictationInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!widget.enabled) return;
    widget.onSubmitted(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    Color? resultColor;
    if (widget.state == LessonSessionState.correct) resultColor = const Color(0xFF3FAE5A);
    if (widget.state == LessonSessionState.incorrect) resultColor = const Color(0xFFE0554A);
    final resultBorder = resultColor == null
        ? BorderSide.none
        : BorderSide(color: resultColor, width: 2);

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: widget.enabled,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Gõ từ bé vừa nghe...',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: resultBorder,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: resultBorder,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: resultColor == null
                    ? const BorderSide(color: AppColors.primary, width: 2)
                    : resultBorder,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.enabled ? _submit : null,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Icon(Icons.check_rounded, color: Colors.white, size: 26),
            ),
          ),
        ),
      ],
    );
  }
}

class _WordPromptVisual extends StatelessWidget {
  final Word word;

  const _WordPromptVisual({required this.word});

  @override
  Widget build(BuildContext context) {
    if (word.swatchColor != null) {
      return Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: word.swatchColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
          ],
        ),
      );
    }
    return Text(word.emoji ?? '❓', style: const TextStyle(fontSize: 70));
  }
}

class _LessonCompleteView extends StatelessWidget {
  final LessonController lessonCtrl;

  const _LessonCompleteView({required this.lessonCtrl});

  /// Nếu vừa đạt 1 mốc streak MỚI (xem `LessonController.consumeStreakCelebration`),
  /// hiện hiệu ứng ăn mừng SAU khi khung hình này vẽ xong (không gọi
  /// `showDialog` ngay trong `build` - cùng idiom `addPostFrameCallback` đã
  /// dùng ở `ChatScreen._scrollToBottomSoon`). `consumeStreakCelebration()`
  /// "lấy rồi xoá" trong 1 lần gọi nên dù `build()` chạy lại nhiều lần, hiệu
  /// ứng chỉ hiện ĐÚNG 1 LẦN cho mỗi lần hoàn thành bài.
  void _maybeCelebrateStreak(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final streak = lessonCtrl.consumeStreakCelebration();
      if (streak != null && context.mounted) {
        showStreakCelebration(context, streak);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _maybeCelebrateStreak(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 90)),
              const SizedBox(height: 16),
              const Text(
                'Great job!',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Bé đã học xong "${lessonCtrl.lesson.title}"',
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
                  '⭐ +${lessonCtrl.starsEarnedThisSession} sao',
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
                  'Back to Play',
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

/// Hiển thị khi bé hết tim giữa bài - dừng lại, không cho học tiếp cho tới
/// khi có tim mới, tránh cảm giác thất bại nặng nề (không ép mua/xem quảng
/// cáo để hồi tim, khác Duolingo).
class _OutOfHeartsView extends StatelessWidget {
  final HeartsController hearts;

  const _OutOfHeartsView({required this.hearts});

  String _formatWait(Duration? wait) {
    if (wait == null) return '';
    final totalMinutes = (wait.inSeconds / 60).ceil();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h > 0) return 'khoảng ${h}h ${m}p nữa';
    return 'khoảng ${m} phút nữa';
  }

  @override
  Widget build(BuildContext context) {
    final wait = hearts.timeUntilNextHeart;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💔', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 16),
              const Text(
                'Hết tim rồi!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                wait != null
                    ? 'Tim sẽ hồi phục ${_formatWait(wait)}. Bé nghỉ chút rồi quay lại nhé!'
                    : 'Tim đang hồi phục. Bé nghỉ chút rồi quay lại nhé!',
                style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
                textAlign: TextAlign.center,
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
                  'Back to Play',
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
