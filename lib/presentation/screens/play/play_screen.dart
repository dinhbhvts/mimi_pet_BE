import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/domain/entities/lesson.dart';
import 'package:mimi_pet/domain/entities/pet_character.dart';
import 'package:mimi_pet/presentation/screens/lesson/lesson_screen.dart';
import 'package:mimi_pet/presentation/state/hearts_controller.dart';
import 'package:mimi_pet/presentation/state/lesson_controller.dart';
import 'package:mimi_pet/presentation/state/lessons_controller.dart';
import 'package:mimi_pet/presentation/state/pet_character_controller.dart';
import 'package:mimi_pet/presentation/state/pet_controller.dart';
import 'package:mimi_pet/presentation/state/progress_controller.dart';
import 'package:mimi_pet/presentation/state/streak_controller.dart';
import 'package:mimi_pet/services/sound_service.dart';
import 'package:mimi_pet/services/speech_service.dart';
import 'package:mimi_pet/services/tts_service.dart';

/// Tab "Play": bản đồ các bài học kiểu Duolingo - mỗi bài học là 1 điểm
/// dừng trên con đường ngoằn ngoèo (thay cho danh sách thẻ đơn giản trước
/// đây).
class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  /// MỞ KHOÁ TẤT CẢ BÀI HỌC (2026-08-21, theo yêu cầu của người dùng): bé đã
  /// đạt trình độ Mover nên được tự do chọn bài học bất kỳ trên con đường,
  /// KHÔNG cần hoàn thành bài trước mới mở bài sau nữa - "chưa cần khoá ở
  /// giai đoạn này" (nguyên văn). Cơ chế khoá tuần tự cũ (mở bài kế tiếp khi
  /// hoàn thành bài trước) VẪN CÒN NGUYÊN trong code bên dưới, chỉ bị tắt
  /// bằng cờ này - muốn bật lại (ví dụ khi có thêm nhiều bài học hơn nữa và
  /// muốn định hướng thứ tự học) chỉ cần đổi giá trị này thành `true`.
  static const bool _sequentialLockingEnabled = false;

  void _openLesson(BuildContext context, Lesson lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => ChangeNotifierProvider<LessonController>(
          create: (providerContext) => LessonController(
            lesson: lesson,
            ttsService: providerContext.read<TtsService>(),
            speechService: providerContext.read<SpeechService>(),
            petController: providerContext.read<PetController>(),
            progressController: providerContext.read<ProgressController>(),
            heartsController: providerContext.read<HeartsController>(),
            streakController: providerContext.read<StreakController>(),
            soundService: providerContext.read<SoundService>(),
          )..start(),
          child: const LessonScreen(),
        ),
      ),
    );
  }

  void _handleTapLocked(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hoàn thành bài trước để mở khoá bài này nhé! 🔒'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleOutOfHearts(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hết tim rồi! 💔'),
        content: const Text(
          'Tim sẽ hồi phục sau một thời gian. Bé chờ chút rồi quay lại học tiếp nhé!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessonsCtrl = context.watch<LessonsController>();
    final progress = context.watch<ProgressController>();
    final hearts = context.watch<HeartsController>();
    final characterName =
        PetCharacterInfo.all[context.watch<PetCharacterController>().character]!.displayName;

    if (!lessonsCtrl.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (lessonsCtrl.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            lessonsCtrl.error!,
            style: const TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final lessons = lessonsCtrl.lessons;
    bool previousCompleted = true;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cùng học nào! 🎮',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Đi theo con đường - $characterName sẽ hỏi, bé trả lời bằng tiếng Anh nhé.',
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 28),
          ...List.generate(lessons.length, (i) {
            final lesson = lessons[i];
            final total = lesson.words.length;
            final masteredCount =
                lesson.words.where((w) => progress.masteredWordIds.contains(w.id)).length;
            final isCompleted = total > 0 && masteredCount == total;
            // Xem doc comment của `_sequentialLockingEnabled` phía trên -
            // khi tắt (mặc định hiện tại), isLocked luôn false, bé chọn bài
            // học bất kỳ trên con đường tuỳ ý.
            final isLocked = _sequentialLockingEnabled && !previousCompleted;
            previousCompleted = isCompleted;

            // Ngoằn ngoèo trái - giữa - phải - giữa - lặp lại, giống con
            // đường bài học của Duolingo (không vẽ đường nối để giảm rủi ro
            // lệch hình vì không có cách xem trước app thật chạy).
            final Alignment align;
            switch (i % 4) {
              case 0:
                align = Alignment.centerLeft;
                break;
              case 1:
                align = Alignment.center;
                break;
              case 2:
                align = Alignment.centerRight;
                break;
              default:
                align = Alignment.center;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Align(
                alignment: align,
                child: _LessonNode(
                  lesson: lesson,
                  masteredCount: masteredCount,
                  total: total,
                  isCompleted: isCompleted,
                  isLocked: isLocked,
                  onTap: () {
                    if (isLocked) {
                      _handleTapLocked(context);
                    } else if (!hearts.hasHearts) {
                      _handleOutOfHearts(context);
                    } else {
                      _openLesson(context, lesson);
                    }
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LessonNode extends StatelessWidget {
  final Lesson lesson;
  final int masteredCount;
  final int total;
  final bool isCompleted;
  final bool isLocked;
  final VoidCallback onTap;

  const _LessonNode({
    required this.lesson,
    required this.masteredCount,
    required this.total,
    required this.isCompleted,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = isLocked
        ? AppColors.disabled.withValues(alpha: 0.35)
        : (isCompleted ? const Color(0xFFFFD166) : AppColors.primary);

    return Column(
      children: [
        Material(
          color: bg,
          shape: const CircleBorder(),
          elevation: isLocked ? 0 : 4,
          shadowColor: Colors.black.withValues(alpha: 0.2),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 84,
              height: 84,
              child: Center(
                child: isLocked
                    ? const Icon(Icons.lock_rounded, color: Colors.white, size: 32)
                    : Text(lesson.emoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 112,
          child: Column(
            children: [
              Text(
                lesson.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              if (!isLocked)
                Text(
                  isCompleted ? 'Hoàn thành! ⭐' : '$masteredCount/$total từ',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
