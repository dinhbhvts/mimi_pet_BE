import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Hiệu ứng ăn mừng khi bé đạt 1 mốc streak MỚI (xem
/// `StreakController.recordActivityToday` + `LessonController.consumeStreakCelebration`)
/// - 1 overlay giữa màn hình, có vài "hạt" lấp lánh (⭐✨🔥🎉) bay toả ra từ
/// tâm để tạo cảm giác "confetti" đơn giản mà KHÔNG cần thêm package ngoài
/// (giữ đúng nguyên tắc hạn chế thêm dependency mới, tránh rủi ro lỗi build
/// như từng gặp với `speech_to_text` cũ). Tự đóng khi bấm ra ngoài hoặc bấm
/// nút "Tuyệt vời!".
Future<void> showStreakCelebration(BuildContext context, int streak) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'streak-celebration',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (context, animation, secondaryAnimation) => _StreakCelebrationDialog(streak: streak),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.elasticOut);
      return Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.6 + curved.value * 0.4, child: child),
      );
    },
  );
}

class _StreakCelebrationDialog extends StatefulWidget {
  final int streak;

  const _StreakCelebrationDialog({required this.streak});

  @override
  State<_StreakCelebrationDialog> createState() => _StreakCelebrationDialogState();
}

class _StreakCelebrationDialogState extends State<_StreakCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burstCtrl;
  late final List<_Particle> _particles;
  final _random = Random();

  static const _particleEmojis = ['⭐', '✨', '🔥', '🎉'];

  @override
  void initState() {
    super.initState();
    _burstCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _particles = List.generate(10, (i) {
      final angle = (i / 10) * 2 * pi + _random.nextDouble() * 0.3;
      final distance = 70.0 + _random.nextDouble() * 45;
      return _Particle(
        angle: angle,
        distance: distance,
        emoji: _particleEmojis[_random.nextInt(_particleEmojis.length)],
        delay: _random.nextDouble() * 0.25,
      );
    });
  }

  @override
  void dispose() {
    _burstCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: _burstCtrl,
              builder: (context, _) => Stack(
                alignment: Alignment.center,
                children: _particles.map((p) {
                  final t = ((_burstCtrl.value - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
                  final eased = Curves.easeOut.transform(t);
                  final dx = cos(p.angle) * p.distance * eased;
                  final dy = sin(p.angle) * p.distance * eased;
                  final opacity = (1.0 - t).clamp(0.0, 1.0);
                  return Transform.translate(
                    offset: Offset(dx, dy),
                    child: Opacity(
                      opacity: opacity,
                      child: Text(p.emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(growable: false),
              ),
            ),
            Container(
              width: 260,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 8),
                  Text(
                    'Streak ${widget.streak} ngày!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bé học liên tục không bỏ ngày nào - tuyệt vời quá!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    ),
                    child: const Text(
                      'Tuyệt vời! 🎉',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double distance;
  final String emoji;
  final double delay;

  const _Particle({required this.angle, required this.distance, required this.emoji, required this.delay});
}
