import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/domain/entities/word.dart';
import 'package:mimi_pet/presentation/screens/games/game_result_panel.dart';
import 'package:mimi_pet/presentation/state/games/bubble_game_controller.dart';
import 'package:mimi_pet/presentation/state/progress_controller.dart';
import 'package:mimi_pet/presentation/state/sticker_controller.dart';
import 'package:mimi_pet/services/sound_service.dart';
import 'package:mimi_pet/services/tts_service.dart';

/// Minigame "Chạm bong bóng" (luyện NGHE): Mimi đọc 1 từ tiếng Anh, bé chạm
/// đúng bong bóng có hình của từ đó trong lúc các bong bóng bay lên.
class BubbleGameScreen extends StatefulWidget {
  final List<Word> Function() pickWords;

  const BubbleGameScreen({super.key, required this.pickWords});

  @override
  State<BubbleGameScreen> createState() => _BubbleGameScreenState();
}

class _BubbleGameScreenState extends State<BubbleGameScreen> with SingleTickerProviderStateMixin {
  late BubbleGameController _ctrl;
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  int _spokenRound = -1;
  GameReward? _reward;
  bool _claimed = false;

  /// Ẩn chữ để bé chỉ NGHE (khó hơn) - mặc định hiện chữ cho dễ.
  bool _hideWord = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _newGame();
  }

  void _newGame() {
    _ctrl = BubbleGameController(words: widget.pickWords())..addListener(_onChanged);
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
    // Chặn bước nhảy lớn (tab bị ẩn rồi quay lại) làm bong bóng "dịch chuyển tức thời".
    _ctrl.tick(dt.clamp(0.0, 0.05));
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    if (_ctrl.isComplete && !_claimed) {
      _claimed = true;
      _ticker.stop();
      final progress = context.read<ProgressController>();
      context.read<SoundService>().playComplete();
      context.read<StickerController>().claimGameWin(progress).then((reward) {
        if (mounted) setState(() => _reward = reward);
      });
    } else {
      _speakTargetIfNew();
    }
  }

  void _speakTargetIfNew() {
    if (!mounted || _ctrl.isComplete || _spokenRound == _ctrl.targetRound) return;
    _spokenRound = _ctrl.targetRound;
    context.read<TtsService>().speak(_ctrl.target.en);
  }

  void _onTapBubble(Bubble bubble) {
    final result = _ctrl.tap(bubble.id);
    final sound = context.read<SoundService>();
    if (result == BubbleTapResult.correct) {
      HapticFeedback.mediumImpact();
      sound.playCorrect();
    } else if (result == BubbleTapResult.wrong) {
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
        title: const Text('Chạm bong bóng 🎈', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: _ctrl.isComplete
            ? GameResultPanel(
                title: 'Tuyệt vời! 🎉',
                detail: 'Bé chạm đúng ${_ctrl.score} bong bóng trong '
                    '${_ctrl.elapsedSeconds.round()} giây, sai ${_ctrl.mistakes} lần.',
                rating: _ctrl.rating,
                reward: _reward,
                onReplay: _replay,
              )
            : Column(
                children: [
                  _targetBar(),
                  Expanded(child: _playArea()),
                ],
              ),
      ),
    );
  }

  Widget _targetBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Row(
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
                  const Text('Tìm bong bóng:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text(
                    _hideWord ? '🔊 Nghe và tìm nhé!' : _ctrl.target.en,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('🎈 ${_ctrl.score}/${_ctrl.targetsToWin}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                GestureDetector(
                  onTap: () => setState(() => _hideWord = !_hideWord),
                  child: Text(
                    _hideWord ? 'Hiện chữ' : 'Ẩn chữ (khó hơn)',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _playArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final radius = min(w / 10, 48.0);
        return ClipRect(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE3F4FF), Color(0xFFBFE3FA)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                for (final b in _ctrl.bubbles)
                  Positioned(
                    left: b.x * w - radius + sin(b.shake * pi * 6) * 8 * b.shake,
                    top: b.y * h - radius,
                    width: radius * 2,
                    height: radius * 2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => _onTapBubble(b),
                      child: _BubbleView(bubble: b, radius: radius),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BubbleView extends StatelessWidget {
  final Bubble bubble;
  final double radius;

  const _BubbleView({required this.bubble, required this.radius});

  @override
  Widget build(BuildContext context) {
    final pop = bubble.popProgress;
    return Opacity(
      opacity: (1 - pop).clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 1 + pop * 0.6,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.4),
              colors: [
                Colors.white.withValues(alpha: 0.95),
                (bubble.shake > 0 ? const Color(0xFFFFB4B4) : const Color(0xFFBEE3FF)).withValues(alpha: 0.75),
              ],
            ),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
          ),
          alignment: Alignment.center,
          child: Text(bubble.word.emoji ?? '⭐', textScaler: TextScaler.noScaling, style: TextStyle(fontSize: radius * 0.9)),
        ),
      ),
    );
  }
}
