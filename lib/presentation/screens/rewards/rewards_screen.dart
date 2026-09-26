import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/domain/entities/pet_accessory.dart';
import 'package:mimi_pet/domain/entities/sticker.dart';
import 'package:mimi_pet/domain/entities/word.dart';
import 'package:mimi_pet/presentation/screens/album/sticker_album_screen.dart';
import 'package:mimi_pet/presentation/state/gem_reward_controller.dart';
import 'package:mimi_pet/presentation/state/lessons_controller.dart';
import 'package:mimi_pet/presentation/state/pet_inventory_controller.dart';
import 'package:mimi_pet/presentation/state/progress_controller.dart';
import 'package:mimi_pet/presentation/state/sticker_controller.dart';

/// Tab "Rewards": tổng số sao, "Cửa hàng phụ kiện" (mở khoá dần bằng sao tích
/// luỹ, mặc được cho thú cưng - xem `pet_accessory.dart`), mốc "Ngọc thưởng"
/// (mốc LỚN quy đổi tiền thật, xem `gem_reward_controller.dart`), và các từ
/// bé đã thuộc, hiển thị như một bộ sưu tập nhãn dán để tạo động lực học tiếp.
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  /// Bé chạm vào 1 phụ kiện CHƯA đủ sao mở khoá - báo còn thiếu bao nhiêu
  /// sao, KHÔNG cho mặc (xem [_AccessoryTile]).
  void _handleTapLocked(BuildContext context, int missingStars) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cần thêm $missingStars ⭐ nữa để mở khoá món này!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final lessonsCtrl = context.watch<LessonsController>();
    final inventory = context.watch<PetInventoryController>();
    final gems = context.watch<GemRewardController>();
    final stickers = context.watch<StickerController>();

    if (!lessonsCtrl.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final allWords = lessonsCtrl.lessons.expand((lesson) => lesson.words).toList();
    final mastered = allWords.where((w) => progress.masteredWordIds.contains(w.id)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kho báu của bé 🎁',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.happyBubble, AppColors.idleBubble],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 50)),
                const SizedBox(height: 4),
                Text(
                  '${progress.stars}',
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
                const Text('tổng số sao', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Cửa hàng phụ kiện 👗',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Dùng sao tích luỹ để mở khoá, chạm vào để mặc/cởi cho thú cưng - '
            'mặc gì sẽ thấy ngay ở Home!',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            // SỬA LỖI (2026-08-31): mặc định `WrapAlignment.start` dồn các
            // thẻ về SÁT TRÁI - nếu hàng cuối không đủ lấp đầy chiều ngang
            // (ví dụ 6 phụ kiện chia 4+2, hàng 2 chỉ có 2 thẻ), phần trống
            // bên phải tạo cảm giác "lệch trái" toàn khối. Đổi sang `center`
            // để mỗi hàng (kể cả hàng cuối chưa đầy) luôn canh giữa - hàng đã
            // đầy đủ thì kết quả hiển thị giống hệt như cũ (không đổi gì).
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: PetAccessoryInfo.orderedByUnlock.map((info) {
              final unlocked = progress.stars >= info.unlockStars;
              final equipped = inventory.equippedFor(info.slot) == info.id;
              return _AccessoryTile(
                info: info,
                unlocked: unlocked,
                equipped: equipped,
                onTap: unlocked
                    ? () => inventory.equip(info.id)
                    : () => _handleTapLocked(context, info.unlockStars - progress.stars),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 24),
          _GemRewardSection(gems: gems, stars: progress.stars),
          const SizedBox(height: 24),
          _AlbumEntryCard(
            ownedWords: mastered,
            totalWords: allWords.length,
            ownedSpecial: stickers.ownedSpecialIds.length,
            newCount: stickers.newCount(progress.masteredWordIds),
          ),
        ],
      ),
    );
  }
}

/// 1 thẻ phụ kiện trong "Cửa hàng phụ kiện" - có 3 trạng thái hiển thị khác
/// nhau (xem code màu/nhãn bên dưới): khoá (chưa đủ sao), đã mở khoá nhưng
/// chưa mặc, và ĐANG mặc (viền tím đậm + dấu ✓, giống cách Home đánh dấu
/// nhân vật/màu đang chọn - xem `home_screen.dart`).
class _AccessoryTile extends StatelessWidget {
  final PetAccessoryInfo info;
  final bool unlocked;
  final bool equipped;
  final VoidCallback onTap;

  const _AccessoryTile({
    required this.info,
    required this.unlocked,
    required this.equipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: unlocked ? Colors.white : AppColors.disabled.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: equipped
              ? Border.all(color: const Color(0xFF8B6FD9), width: 2.5)
              : Border.all(color: Colors.transparent, width: 2.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
          ],
        ),
        child: Column(
          children: [
            Text(
              info.emoji,
              style: TextStyle(fontSize: 30, color: unlocked ? null : AppColors.disabled),
            ),
            const SizedBox(height: 6),
            Text(
              info.displayName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: unlocked ? Colors.black87 : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            if (!unlocked)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Text(
                    '${info.unlockStars}⭐',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              )
            else
              Text(
                equipped ? 'Đang mặc ✓' : 'Chạm để mặc',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: equipped ? FontWeight.bold : FontWeight.normal,
                  color: equipped ? const Color(0xFF8B6FD9) : AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Thêm dấu chấm ngăn cách hàng nghìn kiểu Việt Nam cho số tiền hiển thị
/// (ví dụ 100000 -> "100.000") - không thêm package `intl` chỉ để làm 1 việc
/// nhỏ này, tự viết bằng cách chèn dấu chấm sau mỗi 3 chữ số từ phải sang.
String _formatVnd(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write('.');
  }
  return buffer.toString();
}

/// Mục "Ngọc thưởng 💎" - mốc LỚN quy đổi tiền thật (xem doc comment
/// [GemRewardController]), nằm giữa "Cửa hàng phụ kiện" và "Từ đã thuộc".
/// Có 2 trạng thái hiển thị: CÒN viên ngọc chờ nhận thưởng (hiện từng thẻ +
/// nút "Đã nhận thưởng") hoặc CHƯA đạt mốc tiếp theo (hiện thanh tiến độ).
class _GemRewardSection extends StatelessWidget {
  final GemRewardController gems;
  final int stars;

  const _GemRewardSection({required this.gems, required this.stars});

  @override
  Widget build(BuildContext context) {
    final pending = gems.pendingCountFor(stars);
    final claimed = gems.claimedCount;
    final untilNext = gems.starsUntilNextGem(stars);
    final progressInCurrentGem = 1 - (untilNext / GemRewardController.starsPerGem);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ngọc thưởng 💎',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Cứ ${GemRewardController.starsPerGem} sao tích luỹ, bé được thêm 1 '
          'viên ngọc - mỗi viên bố thưởng ${_formatVnd(GemRewardController.moneyPerGemVnd)}đ '
          '(thưởng ngoài app nhé)!',
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        if (claimed > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1DC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0C98A)),
              ),
              child: Text(
                'Đã nhận: $claimed viên (~${_formatVnd(claimed * GemRewardController.moneyPerGemVnd)}đ)',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        if (pending > 0)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              pending,
              (_) => _GemPendingCard(onClaim: () => gems.claimOne(stars)),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Còn $untilNext ⭐ nữa tới viên ngọc tiếp theo!',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progressInCurrentGem.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: const Color(0xFFEDEDED),
                    color: const Color(0xFF3FAE5A),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 1 viên ngọc ĐÃ ĐẠT MỐC nhưng bố mẹ CHƯA bấm nhận - hiện nút "Đã nhận
/// thưởng ✅" để đánh dấu, tránh app nhắc lại mốc đã trả tiền rồi.
class _GemPendingCard extends StatelessWidget {
  final VoidCallback onClaim;

  const _GemPendingCard({required this.onClaim});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4FC3E0), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💎', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 4),
          Text(
            '${_formatVnd(GemRewardController.moneyPerGemVnd)}đ',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC3E0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Đã nhận thưởng ✅',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lối vào Album sticker - thay cho lưới "Từ đã thuộc" trước đây (album
/// hiển thị chính các từ đó, chia trang theo bài học, kèm sticker đặc biệt).
class _AlbumEntryCard extends StatelessWidget {
  final List<Word> ownedWords;
  final int totalWords;
  final int ownedSpecial;
  final int newCount;

  const _AlbumEntryCard({
    required this.ownedWords,
    required this.totalWords,
    required this.ownedSpecial,
    required this.newCount,
  });

  @override
  Widget build(BuildContext context) {
    final preview = ownedWords.reversed.take(6).toList();
    return Material(
      color: const Color(0xFFFFF1DC),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StickerAlbumScreen())),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0C98A), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('📒', style: TextStyle(fontSize: 30)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Album sticker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          'Từ vựng ${ownedWords.length}/$totalWords · Đặc biệt $ownedSpecial/${SpecialSticker.all.length}',
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  if (newCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFE84C3D), borderRadius: BorderRadius.circular(12)),
                      child: Text('$newCount MỚI',
                          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFC98A3F)),
                ],
              ),
              const SizedBox(height: 10),
              if (preview.isEmpty)
                const Text('Học từ ở tab Play hoặc chơi ở Góc trò chơi để nhận sticker nhé! 🎮',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted))
              else
                Wrap(
                  spacing: 6,
                  children: [
                    for (final w in preview)
                      w.swatchColor != null
                          ? Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(color: w.swatchColor, shape: BoxShape.circle),
                            )
                          : Text(w.emoji ?? '⭐', style: const TextStyle(fontSize: 28)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
