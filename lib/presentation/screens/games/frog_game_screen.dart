import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/domain/entities/word.dart';
import 'package:mimi_pet/presentation/screens/games/game_result_panel.dart';
import 'package:mimi_pet/presentation/state/games/frog_game_controller.dart';
import 'package:mimi_pet/presentation/state/progress_controller.dart';
import 'package:mimi_pet/presentation/state/sticker_controller.dart';
import 'package:mimi_pet/presentation/widgets/emoji_art.dart';
import 'package:mimi_pet/services/sound_service.dart';
import 'package:mimi_pet/services/tts_service.dart';

/// Minigame "Ếch nhảy qua sông" (luyện NGHE nhanh): Mimi đọc 1 từ, bé chạm
/// đúng lá sen có hình của từ đó để ếch nhảy lên - đủ bước là qua sông.
class FrogGameScreen extends StatefulWidget {
  final List<Word> Function() pickWords;
  final FrogDifficulty difficulty;

  const FrogGameScreen({super.key, required this.pickWords, this.difficulty = FrogDifficulty.normal});

  @override
  State<FrogGameScreen> createState() => _FrogGameScreenState();
}

class _FrogGameScreenState extends State<FrogGameScreen> with SingleTickerProviderStateMixin {
  late FrogGameController _ctrl;
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  int _spokenRound = -1;
  GameReward? _reward;
  bool _claimed = false;
  bool _hideWord = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _newGame();
  }

  void _newGame() {
    _ctrl = FrogGameController(words: widget.pickWords(), difficulty: widget.difficulty)..addListener(_onChanged);
    _reward = null;
    _claimed = false;
    _spokenRound = -1;
    _last = Duration.zero;
    if (_ticker.isActive) _ticker.stop();
    _ticker.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakTargetIfNew());
  }

  void _replay() {
    _ctrl
      ..removeListener(_onChanged)
      ..dispose();
    setState(_newGame);
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    // Chặn bước nhảy lớn (tab bị ẩn rồi quay lại) làm hết giờ tức thì.
    _ctrl.tick(dt.clamp(0.0, 0.05));
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    if (_ctrl.phase == FrogPhase.won && !_claimed) {
      _claimed = true;
      _ticker.stop();
      final progress = context.read<ProgressController>();
      context.read<SoundService>().playComplete();
      context.read<StickerController>().claimGameWin(progress).then((reward) {
        if (mounted) setState(() => _reward = reward);
      });
    } else if (_ctrl.phase == FrogPhase.lost) {
      _ticker.stop();
    } else {
      _speakTargetIfNew();
    }
  }

  void _speakTargetIfNew() {
    if (!mounted || _ctrl.isOver || _spokenRound == _ctrl.targetRound) return;
    _spokenRound = _ctrl.targetRound;
    context.read<TtsService>().speak(_ctrl.target.en);
  }

  void _onTapPad(int index) {
    final result = _ctrl.tap(index);
    final sound = context.read<SoundService>();
    if (result == FrogTapResult.correct) {
      HapticFeedback.mediumImpact();
      sound.playCorrect();
    } else if (result == FrogTapResult.wrong) {
      HapticFeedback.heavyImpact();
      sound.playWrong();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _ctrl
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Ếch nhảy qua sông 🐸', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: switch (_ctrl.phase) {
          FrogPhase.won => GameResultPanel(
              title: 'Ếch qua sông rồi! 🎉',
              detail: 'Bé giúp ếch nhảy ${_ctrl.stepsToWin} bước trong '
                  '${_ctrl.elapsedSeconds.round()} giây, sai ${_ctrl.mistakes} lần.',
              rating: _ctrl.rating,
              reward: _reward,
              onReplay: _replay,
            ),
          FrogPhase.lost => _LostPanel(
              step: _ctrl.step,
              steps: _ctrl.stepsToWin,
              onReplay: _replay,
            ),
          _ => Column(
              children: [
                _topBar(),
                Expanded(child: _river()),
              ],
            ),
        },
      ),
    );
  }

  Widget _topBar() {
    final limit = _ctrl.timeLimit;
    final left = _ctrl.timeLeft;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Column(
          children: [
            Row(
              children: [
                IconButton.filled(
                  onPressed: () => context.read<TtsService>().speak(_ctrl.target.en),
                  icon: const Icon(Icons.volume_up_rounded),
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                  tooltip: 'Nghe lại',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nhảy tới lá sen:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      Text(
                        _hideWord ? '🔊 Nghe và chọn nhé!' : _ctrl.target.en,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${'❤️' * _ctrl.lives}${'🤍' * (FrogGameController.startLives - _ctrl.lives)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _hideWord = !_hideWord),
                      child: Text(
                        _hideWord ? 'Hiện chữ' : 'Ẩn chữ (khó hơn)',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.primary, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _StepTrack(step: _ctrl.step, steps: _ctrl.stepsToWin),
            if (limit != null && left != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (left / limit).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEDE7F7),
                  color: left < 2 ? const Color(0xFFE0863C) : const Color(0xFF3FAE5A),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _river() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final n = _ctrl.row.length;
        final padRadius = min(w / (n * 2.6), 58.0);
        final rowY = h * 0.40;
        final frogY = h * 0.80;
        final frogSize = padRadius * 1.15;

        double padX(int i) => w * (i + 1) / (n + 1);

        // Vị trí ếch: đứng ở dưới, hoặc đang bay theo vòng cung lên lá sen.
        var fx = w / 2, fy = frogY, frogScale = 1.0;
        final hopTo = _ctrl.hopTo;
        if (hopTo != null) {
          final p = Curves.easeInOut.transform(_ctrl.hopProgress.clamp(0.0, 1.0));
          fx = w / 2 + (padX(hopTo) - w / 2) * p;
          fy = frogY + (rowY - frogY) * p - sin(p * pi) * h * 0.12;
          frogScale = 1 + 0.35 * sin(p * pi);
        }

        return ClipRect(
          child: Stack(
            children: [
              const Positioned.fill(child: CustomPaint(painter: _RiverPainter())),
              // Bờ bên kia (đích) ở trên cùng.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: h * 0.13,
                child: const _Bank(label: '🏁 Bờ bên kia', top: true),
              ),
              // Chỗ ếch đang đứng: bờ xuất phát (bước 0) hoặc lá sen vừa nhảy tới.
              if (_ctrl.step == 0)
                // Bờ xuất phát cao tới ngang chỗ ếch đứng để ếch đứng TRÊN bờ.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: h * 0.27,
                  child: const _Bank(label: '', top: false),
                )
              else
                Positioned(
                  left: w / 2 - padRadius,
                  top: frogY - padRadius * 0.55,
                  width: padRadius * 2,
                  height: padRadius * 1.1,
                  child: const _LilyPad(),
                ),
              // Hàng lá sen để chọn - hiện dần mỗi bước mới.
              for (var i = 0; i < n; i++)
                Positioned(
                  key: ValueKey('pad-${_ctrl.step}-$i'),
                  left: padX(i) - padRadius,
                  top: rowY - padRadius,
                  width: padRadius * 2,
                  height: padRadius * 2,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 350),
                    builder: (context, t, child) => Opacity(
                      opacity: t,
                      child: Transform.translate(offset: Offset(0, -18 * (1 - t)), child: child),
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => _onTapPad(i),
                      child: _ChoicePad(
                        word: _ctrl.row[i],
                        radius: padRadius,
                        sunk: _ctrl.isSunk(i),
                        chosen: hopTo == i,
                      ),
                    ),
                  ),
                ),
              // Con ếch.
              Positioned(
                left: fx - frogSize / 2,
                top: fy - frogSize * 0.85,
                width: frogSize,
                height: frogSize,
                child: IgnorePointer(
                  child: Transform.scale(scale: frogScale, child: EmojiArt('🐸', size: frogSize)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Thanh tiến độ dạng "hòn đá kê chân": mỗi bước 1 chấm, chấm đã qua tô xanh.
class _StepTrack extends StatelessWidget {
  final int step;
  final int steps;

  const _StepTrack({required this.step, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('🐸', textScaler: TextScaler.noScaling, style: TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < steps; i++)
                Expanded(
                  child: Container(
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: i < step ? const Color(0xFF3FAE5A) : const Color(0xFFDCEBDD),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text('$step/$steps', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ChoicePad extends StatelessWidget {
  final Word word;
  final double radius;
  final bool sunk;
  final bool chosen;

  const _ChoicePad({required this.word, required this.radius, required this.sunk, required this.chosen});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: sunk ? 0.7 : 1,
      duration: const Duration(milliseconds: 300),
      child: AnimatedOpacity(
        opacity: sunk ? 0.35 : 1,
        duration: const Duration(milliseconds: 300),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _LilyPad(highlight: chosen),
            EmojiArt(word.emoji ?? '⭐', size: radius * 0.95),
            if (sunk) EmojiArt('💦', size: radius * 0.8),
          ],
        ),
      ),
    );
  }
}

/// Lá sen: hình tròn xanh có 1 khe hình nêm (vẽ bằng CustomPaint).
class _LilyPad extends StatelessWidget {
  final bool highlight;

  const _LilyPad({this.highlight = false});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.infinite,
        painter: _LilyPadPainter(highlight: highlight),
      );
}

class _LilyPadPainter extends CustomPainter {
  final bool highlight;

  const _LilyPadPainter({required this.highlight});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.12);
    canvas.drawOval(rect.shift(const Offset(0, 4)), shadow);
    final fill = Paint()
      ..shader = RadialGradient(
        colors: highlight
            ? const [Color(0xFFB8F5A2), Color(0xFF5BBF4A)]
            : const [Color(0xFF9EE08A), Color(0xFF3F9E3A)],
      ).createShader(rect);
    // Khe hình nêm (từ tâm ra mép trên-phải) như lá sen thật.
    canvas.drawArc(rect, -pi / 2 + 0.35, 2 * pi - 0.7, true, fill);
    final vein = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (var k = 0; k < 5; k++) {
      final a = -pi / 2 + 0.9 + k * 1.1;
      canvas.drawLine(
          center, center + Offset(cos(a) * size.width * 0.4, sin(a) * size.height * 0.4), vein);
    }
    if (highlight) {
      canvas.drawOval(
          rect.deflate(1),
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(_LilyPadPainter old) => old.highlight != highlight;
}

class _RiverPainter extends CustomPainter {
  const _RiverPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF8FD3F7), Color(0xFF4FA8E0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
    );
    // Vài gợn sóng trang trí.
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rnd = Random(7);
    for (var i = 0; i < 14; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = size.height * (0.15 + rnd.nextDouble() * 0.7);
      final path = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + 10, y - 5, x + 20, y)
        ..quadraticBezierTo(x + 30, y + 5, x + 40, y);
      canvas.drawPath(path, wave);
    }
  }

  @override
  bool shouldRepaint(_RiverPainter oldDelegate) => false;
}

class _Bank extends StatelessWidget {
  final String label;
  final bool top;

  const _Bank({required this.label, required this.top});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: const [Color(0xFF8BCB6A), Color(0xFF6DB04F)],
          begin: top ? Alignment.topCenter : Alignment.bottomCenter,
          end: top ? Alignment.bottomCenter : Alignment.topCenter,
        ),
        borderRadius: top
            ? const BorderRadius.vertical(bottom: Radius.circular(28))
            : const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      alignment: Alignment.center,
      child: label.isEmpty
          ? null
          : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }
}

/// Thua: ếch rơi xuống sông - khuyến khích chơi lại (không có thưởng).
class _LostPanel extends StatelessWidget {
  final int step;
  final int steps;
  final VoidCallback onReplay;

  const _LostPanel({required this.step, required this.steps, required this.onReplay});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmojiArt('🌊', size: 80),
            const SizedBox(height: 8),
            const Text('Ôi! Ếch rơi xuống sông rồi 💦',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Ếch đã nhảy được $step/$steps bước. Nghe kỹ Mimi đọc rồi thử lại nhé - bé làm được mà! 💪',
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onReplay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Chơi lại 🐸', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Về Góc trò chơi')),
          ],
        ),
      ),
    );
  }
}
