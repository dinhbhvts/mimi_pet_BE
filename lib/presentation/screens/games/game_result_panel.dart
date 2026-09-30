import 'package:flutter/material.dart';

import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/domain/entities/sticker.dart';
import 'package:mimi_pet/presentation/screens/album/sticker_album_screen.dart';
import 'package:mimi_pet/presentation/state/sticker_controller.dart';
import 'package:mimi_pet/presentation/widgets/emoji_art.dart';

Color rarityColor(StickerRarity rarity) => switch (rarity) {
      StickerRarity.common => const Color(0xFF4FA8E0),
      StickerRarity.rare => const Color(0xFFB07AD1),
      StickerRarity.legendary => const Color(0xFFF2A93B),
    };

/// Màn kết thúc ván: đánh giá 1-3 sao theo độ chính xác + phần thưởng
/// (sao thật nếu còn lượt trong ngày, sticker đặc biệt mới "bật" ra).
class GameResultPanel extends StatelessWidget {
  final String title;
  final String detail;
  final int rating;

  /// null trong lúc đang ghi nhận phần thưởng.
  final GameReward? reward;
  final VoidCallback onReplay;

  const GameResultPanel({
    super.key,
    required this.title,
    required this.detail,
    required this.rating,
    required this.reward,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final reward = this.reward;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(detail, style: const TextStyle(fontSize: 14, color: AppColors.textMuted), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(i < rating ? '⭐' : '☆',
                        style: TextStyle(fontSize: 38, color: i < rating ? null : AppColors.disabled)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (reward == null)
                const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
              else ...[
                if (reward.sticker != null) _StickerReveal(sticker: reward.sticker!),
                if (reward.sticker == null)
                  const Text('Bé đã sưu tập ĐỦ sticker đặc biệt rồi! 🏆',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  reward.stars > 0
                      ? '+${reward.stars} ⭐ thưởng'
                      : 'Hôm nay đã nhận đủ sao từ trò chơi - mai chơi tiếp để nhận sao nhé!',
                  style: TextStyle(
                    fontSize: reward.stars > 0 ? 18 : 13,
                    fontWeight: reward.stars > 0 ? FontWeight.bold : FontWeight.normal,
                    color: reward.stars > 0 ? const Color(0xFF3FAE5A) : AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onReplay,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Chơi ván mới'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StickerAlbumScreen(initialTab: 1)),
                      ),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: const Text('📒 Xem album'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: const Text('Về góc trò chơi'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickerReveal extends StatelessWidget {
  final SpecialSticker sticker;

  const _StickerReveal({required this.sticker});

  @override
  Widget build(BuildContext context) {
    final color = rarityColor(sticker.rarity);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            const Text('🎁 Sticker mới!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            EmojiArt(sticker.emoji, size: 70),
            Text(sticker.nameEn, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(sticker.nameVi, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: Text(sticker.rarity.label,
                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
