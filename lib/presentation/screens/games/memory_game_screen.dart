import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/domain/entities/word.dart';
import 'package:mimi_pet/presentation/screens/games/game_result_panel.dart';
import 'package:mimi_pet/presentation/state/games/memory_game_controller.dart';
import 'package:mimi_pet/presentation/state/progress_controller.dart';
import 'package:mimi_pet/presentation/state/sticker_controller.dart';
import 'package:mimi_pet/services/sound_service.dart';
import 'package:mimi_pet/services/tts_service.dart';

/// Minigame "Lật thẻ tìm cặp": mỗi từ có 1 thẻ hình + 1 thẻ chữ, lật 2 thẻ
/// một lượt, trùng cặp thì giữ mở và Mimi đọc to từ đó.
class MemoryGameScreen extends StatefulWidget {
  /// Gọi lại mỗi ván để lấy bộ từ mới.
  final List<Word> Function() pickWords;

  const MemoryGameScreen({super.key, required this.pickWords});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  late MemoryGameController _ctrl;
  GameReward? _reward;
  bool _claimed = false;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    _ctrl = MemoryGameController(words: widget.pickWords())..addListener(_onChanged);
    _reward = null;
    _claimed = false;
  }

  void _replay() {
    _ctrl
      ..removeListener(_onChanged)
      ..dispose();
    setState(_newGame);
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    if (_ctrl.isComplete && !_claimed) {
      _claimed = true;
      final progress = context.read<ProgressController>();
      context.read<SoundService>().playComplete();
      context.read<StickerController>().claimGameWin(progress).then((reward) {
        if (mounted) setState(() => _reward = reward);
      });
    }
  }

  void _onTapCard(int index) {
    final result = _ctrl.flip(index);
    final sound = context.read<SoundService>();
    switch (result) {
      case MemoryFlipResult.match:
        HapticFeedback.mediumImpact();
        sound.playCorrect();
        context.read<TtsService>().speak(_ctrl.cards[index].word.en);
      case MemoryFlipResult.mismatch:
        sound.playWrong();
      case MemoryFlipResult.firstOfPair:
        HapticFeedback.selectionClick();
      case MemoryFlipResult.ignored:
        break;
    }
  }

  @override
  void dispose() {
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
        title: const Text('Lật thẻ tìm cặp 🃏', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: _ctrl.isComplete
            ? GameResultPanel(
                title: 'Giỏi quá! 🎉',
                detail: 'Bé ghép đủ ${_ctrl.pairCount} cặp sau ${_ctrl.moves} lượt lật.',
                rating: _ctrl.rating,
                reward: _reward,
                onReplay: _replay,
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Row(
                      children: [
                        _Chip(icon: '🔁', text: 'Lượt: ${_ctrl.moves}'),
                        const Spacer(),
                        _Chip(icon: '✅', text: 'Cặp: ${_ctrl.matchedPairs}/${_ctrl.pairCount}'),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Lật 2 thẻ: tìm HÌNH và CHỮ tiếng Anh giống nghĩa nhau nhé!',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: _buildGrid()),
                ],
              ),
      ),
    );
  }

  Widget _buildGrid() {
    const columns = 4;
    const gap = 10.0;
    final rows = (_ctrl.cards.length / columns).ceil();
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = min(constraints.maxWidth, 520.0) - 32;
        final cardW = (maxW - gap * (columns - 1)) / columns;
        final cardH = min(cardW * 1.2, (constraints.maxHeight - 24 - gap * (rows - 1)) / rows);
        return Center(
          child: SizedBox(
            width: maxW,
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < _ctrl.cards.length; i++)
                  SizedBox(
                    width: cardW,
                    height: cardH,
                    child: _FlipCard(card: _ctrl.cards[i], onTap: () => _onTapCard(i)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String icon;
  final String text;

  const _Chip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Text('$icon $text', style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _FlipCard extends StatelessWidget {
  final MemoryCard card;
  final VoidCallback onTap;

  const _FlipCard({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final faceUp = card.revealed || card.matched;
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: faceUp ? pi : 0),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        builder: (context, angle, _) {
          final showFront = angle > pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: _front(),
                  )
                : _back(),
          );
        },
      ),
    );
  }

  Widget _back() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C84F0), Color(0xFF7A5AE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      alignment: Alignment.center,
      child: const Text('?', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _front() {
    final matchedColor = const Color(0xFF3FAE5A);
    return Container(
      decoration: BoxDecoration(
        color: card.matched ? const Color(0xFFE9F7EC) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: card.matched ? matchedColor : const Color(0xFFD8C6F7), width: 2),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: card.face == MemoryCardFace.picture
            ? Text(card.word.emoji ?? '⭐', style: const TextStyle(fontSize: 44))
            : Text(
                card.word.en,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: card.matched ? matchedColor : AppColors.primary,
                ),
              ),
      ),
    );
  }
}
