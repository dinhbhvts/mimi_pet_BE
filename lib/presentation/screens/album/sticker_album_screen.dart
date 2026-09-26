import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/domain/entities/lesson.dart';
import 'package:mimi_pet/domain/entities/sticker.dart';
import 'package:mimi_pet/domain/entities/word.dart';
import 'package:mimi_pet/presentation/screens/games/game_result_panel.dart';
import 'package:mimi_pet/presentation/state/lessons_controller.dart';
import 'package:mimi_pet/presentation/state/progress_controller.dart';
import 'package:mimi_pet/presentation/state/sticker_controller.dart';
import 'package:mimi_pet/services/tts_service.dart';

/// Album sticker: tab "Từ vựng" (mỗi bài học là 1 trang, sticker mở khi bé
/// thuộc từ) và tab "Đặc biệt" (sticker nhận khi thắng minigame).
class StickerAlbumScreen extends StatefulWidget {
  final int initialTab;

  const StickerAlbumScreen({super.key, this.initialTab = 0});

  @override
  State<StickerAlbumScreen> createState() => _StickerAlbumScreenState();
}

class _StickerAlbumScreenState extends State<StickerAlbumScreen> {
  /// Chụp lại lúc MỞ album: những sticker còn gắn nhãn MỚI trong lượt xem này.
  /// Ngay sau đó đánh dấu đã xem để lần mở sau không còn nhãn nữa.
  late final Set<String> _newKeys;

  @override
  void initState() {
    super.initState();
    final stickers = context.read<StickerController>();
    final owned = {
      for (final id in context.read<ProgressController>().masteredWordIds) StickerController.wordKey(id),
      for (final id in stickers.ownedSpecialIds) StickerController.specialKey(id),
    };
    _newKeys = owned.difference(stickers.seenIds);
    WidgetsBinding.instance.addPostFrameCallback((_) => stickers.markSeen(owned));
  }

  void _say(String en, String vi) {
    context.read<TtsService>().speak(en);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('$en = $vi', style: const TextStyle(fontSize: 16)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final lessons = context.watch<LessonsController>().lessons;
    final mastered = context.watch<ProgressController>().masteredWordIds;
    final stickers = context.watch<StickerController>();
    final totalWords = lessons.fold<int>(0, (s, l) => s + l.words.length);
    final ownedWords = lessons.expand((l) => l.words).where((w) => mastered.contains(w.id)).length;

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          foregroundColor: Colors.black87,
          title: const Text('Album sticker 📒', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Từ vựng ($ownedWords/$totalWords)'),
              Tab(text: 'Đặc biệt ✨ (${stickers.ownedSpecialIds.length}/${SpecialSticker.all.length})'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _WordPages(lessons: lessons, mastered: mastered, newKeys: _newKeys, onTap: _say),
              _SpecialPage(owned: stickers.ownedSpecialIds, newKeys: _newKeys, onTap: _say),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: const Color(0xFFE84C3D), borderRadius: BorderRadius.circular(8)),
      child: const Text('MỚI', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}

/// 1 ô sticker: đã có thì hiện hình + chữ, chưa có thì hiện "?" mờ.
class _StickerSlot extends StatelessWidget {
  final Widget? art;
  final String label;
  final bool owned;
  final bool isNew;
  final Color ring;
  final VoidCallback? onTap;

  const _StickerSlot({
    required this.art,
    required this.label,
    required this.owned,
    required this.isNew,
    required this.ring,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: owned ? onTap : null,
      child: SizedBox(
        width: 78,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 78,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: owned ? Colors.white : const Color(0xFFF0EEF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: owned ? ring : Colors.transparent, width: 2),
                boxShadow: owned ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)] : null,
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 36,
                    child: Center(
                      child: owned
                          ? art
                          : const Text('?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFBDB6CC))),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    owned ? label : '???',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: owned ? Colors.black87 : AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (isNew) const Positioned(top: -6, right: -4, child: _NewBadge()),
          ],
        ),
      ),
    );
  }
}

class _WordPages extends StatelessWidget {
  final List<Lesson> lessons;
  final Set<String> mastered;
  final Set<String> newKeys;
  final void Function(String en, String vi) onTap;

  const _WordPages({required this.lessons, required this.mastered, required this.newKeys, required this.onTap});

  Widget _art(Word w) => w.swatchColor != null
      ? Container(width: 30, height: 30, decoration: BoxDecoration(color: w.swatchColor, shape: BoxShape.circle))
      : Text(w.emoji ?? '⭐', style: const TextStyle(fontSize: 30));

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: lessons.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Text(
            'Mỗi từ bé thuộc trong tab Play sẽ thành 1 sticker. Sưu tập đủ trang để nhận cúp 🏆!',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          );
        }
        final lesson = lessons[index - 1];
        final owned = lesson.words.where((w) => mastered.contains(w.id)).length;
        final complete = owned == lesson.words.length;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: complete ? const Color(0xFFFFF6DA) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: complete ? const Color(0xFFF2C14E) : const Color(0xFFEDE7F7), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(lesson.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(lesson.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Text(complete ? '🏆 Đủ trang!' : '$owned/${lesson.words.length}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: complete ? const Color(0xFFC98A1F) : AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: [
                  for (final w in lesson.words)
                    _StickerSlot(
                      art: _art(w),
                      label: w.en,
                      owned: mastered.contains(w.id),
                      isNew: newKeys.contains(StickerController.wordKey(w.id)),
                      ring: const Color(0xFFCBB8F5),
                      onTap: () => onTap(w.en, w.vi),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpecialPage extends StatelessWidget {
  final Set<String> owned;
  final Set<String> newKeys;
  final void Function(String en, String vi) onTap;

  const _SpecialPage({required this.owned, required this.newKeys, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        const Text(
          'Thắng 1 ván ở Góc trò chơi 🎲 để nhận 1 sticker đặc biệt. Sticker Huyền thoại rất hiếm đó!',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        for (final rarity in StickerRarity.values.reversed) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: rarityColor(rarity), borderRadius: BorderRadius.circular(12)),
                child: Text(rarity.label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Text(
                '${SpecialSticker.all.where((s) => s.rarity == rarity && owned.contains(s.id)).length}'
                '/${SpecialSticker.all.where((s) => s.rarity == rarity).length}',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              for (final s in SpecialSticker.all.where((s) => s.rarity == rarity))
                _StickerSlot(
                  art: Text(s.emoji, style: const TextStyle(fontSize: 30)),
                  label: s.nameEn,
                  owned: owned.contains(s.id),
                  isNew: newKeys.contains(StickerController.specialKey(s.id)),
                  ring: rarityColor(s.rarity),
                  onTap: () => onTap(s.nameEn, s.nameVi),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
