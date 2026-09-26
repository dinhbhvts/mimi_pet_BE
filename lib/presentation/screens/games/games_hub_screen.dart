import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/domain/entities/lesson.dart';
import 'package:mimi_pet/domain/entities/sticker.dart';
import 'package:mimi_pet/domain/entities/word.dart';
import 'package:mimi_pet/presentation/screens/album/sticker_album_screen.dart';
import 'package:mimi_pet/presentation/screens/games/bubble_game_screen.dart';
import 'package:mimi_pet/presentation/screens/games/memory_game_screen.dart';
import 'package:mimi_pet/presentation/state/games/game_words.dart';
import 'package:mimi_pet/presentation/state/lessons_controller.dart';
import 'package:mimi_pet/presentation/state/progress_controller.dart';
import 'package:mimi_pet/presentation/state/sticker_controller.dart';

enum _GameKind { memory, bubble }

/// "Góc trò chơi": minigame dùng lại từ vựng trong các bài học. Thắng mỗi ván
/// được 1 sticker đặc biệt (+ sao trong giới hạn mỗi ngày, xem
/// [StickerController.maxStarRewardsPerDay]).
class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key});

  Future<void> _openSetup(BuildContext context, _GameKind kind) async {
    final lessons = context.read<LessonsController>().lessons;
    final mastered = context.read<ProgressController>().masteredWordIds;
    final choice = await showModalBottomSheet<_GameSetup>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _GameSetupSheet(kind: kind, lessons: gameFriendlyLessons(lessons), masteredCount: mastered.length),
    );
    if (choice == null || !context.mounted) return;

    List<Word> pick() => pickGameWords(
          lessons: lessons,
          masteredWordIds: context.read<ProgressController>().masteredWordIds,
          source: choice.source,
          lessonId: choice.lessonId,
          count: choice.wordCount,
        );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => kind == _GameKind.memory
            ? MemoryGameScreen(pickWords: pick)
            : BubbleGameScreen(pickWords: pick),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stickers = context.watch<StickerController>();
    final lessonsCtrl = context.watch<LessonsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Góc trò chơi 🎲', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: !lessonsCtrl.loaded || !stickers.loaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                children: [
                  const Text(
                    'Chơi mà học: mỗi ván thắng được 1 sticker đặc biệt!',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            stickers.starRewardsLeftToday > 0
                                ? 'Hôm nay còn ${stickers.starRewardsLeftToday} ván được thưởng '
                                    '+${StickerController.starsPerGameWin} sao'
                                : 'Hôm nay đã nhận đủ sao từ trò chơi - vẫn được sticker nhé!',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _GameCard(
                    emoji: '🃏',
                    title: 'Lật thẻ tìm cặp',
                    subtitle: 'Ghép HÌNH với CHỮ tiếng Anh đúng nghĩa',
                    color: const Color(0xFFEDE6FF),
                    border: const Color(0xFFCBB8F5),
                    onTap: () => _openSetup(context, _GameKind.memory),
                  ),
                  const SizedBox(height: 12),
                  _GameCard(
                    emoji: '🎈',
                    title: 'Chạm bong bóng',
                    subtitle: 'Nghe Mimi đọc từ, chạm đúng bong bóng có hình đó',
                    color: const Color(0xFFE2F4FF),
                    border: const Color(0xFFA9D7F5),
                    onTap: () => _openSetup(context, _GameKind.bubble),
                  ),
                  const SizedBox(height: 12),
                  _GameCard(
                    emoji: '📒',
                    title: 'Album sticker',
                    subtitle: '${stickers.ownedSpecialIds.length}/${SpecialSticker.all.length} sticker đặc biệt đã sưu tập',
                    color: const Color(0xFFFFF1DC),
                    border: const Color(0xFFF0C98A),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StickerAlbumScreen()),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final Color border;
  final VoidCallback onTap;

  const _GameCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameSetup {
  final GameWordSource source;
  final String? lessonId;
  final int wordCount;

  const _GameSetup(this.source, this.lessonId, this.wordCount);
}

class _GameSetupSheet extends StatefulWidget {
  final _GameKind kind;
  final List<Lesson> lessons;
  final int masteredCount;

  const _GameSetupSheet({required this.kind, required this.lessons, required this.masteredCount});

  @override
  State<_GameSetupSheet> createState() => _GameSetupSheetState();
}

class _GameSetupSheetState extends State<_GameSetupSheet> {
  late GameWordSource _source =
      widget.masteredCount >= 4 ? GameWordSource.mastered : GameWordSource.random;
  String? _lessonId;
  int _pairs = 6;

  static const _sizes = {4: 'Dễ · 4 cặp', 6: 'Vừa · 6 cặp', 8: 'Khó · 8 cặp'};

  Widget _chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(onTap),
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
      );

  @override
  Widget build(BuildContext context) {
    final isMemory = widget.kind == _GameKind.memory;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isMemory ? 'Lật thẻ tìm cặp 🃏' : 'Chạm bong bóng 🎈',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              const Text('Chọn từ để chơi', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.masteredCount >= 4)
                    _chip('🌟 Ôn từ bé đã thuộc', _source == GameWordSource.mastered, () {
                      _source = GameWordSource.mastered;
                      _lessonId = null;
                    }),
                  _chip('🎲 Ngẫu nhiên', _source == GameWordSource.random, () {
                    _source = GameWordSource.random;
                    _lessonId = null;
                  }),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Hoặc chọn 1 chủ đề', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final lesson in widget.lessons)
                    _chip('${lesson.emoji} ${lesson.title}', _lessonId == lesson.id, () {
                      _source = GameWordSource.lesson;
                      _lessonId = lesson.id;
                    }),
                ],
              ),
              if (isMemory) ...[
                const SizedBox(height: 16),
                const Text('Độ khó', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final e in _sizes.entries) _chip(e.value, _pairs == e.key, () => _pairs = e.key),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(
                    _GameSetup(_source, _lessonId, isMemory ? _pairs : 8),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Chơi thôi! ▶', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
