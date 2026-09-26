import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/domain/entities/word.dart';
import 'package:mimi_pet/domain/repositories/progress_repository.dart';
import 'package:mimi_pet/domain/repositories/sticker_repository.dart';
import 'package:mimi_pet/presentation/screens/games/bubble_game_screen.dart';
import 'package:mimi_pet/presentation/state/progress_controller.dart';
import 'package:mimi_pet/presentation/state/sticker_controller.dart';
import 'package:mimi_pet/services/sound_service.dart';
import 'package:mimi_pet/services/tts_service.dart';

class _SilentTts extends TtsService {
  final spoken = <String>[];

  @override
  Future<void> speak(String text, {double? rate, double? pitch}) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

class _MemProgressRepo implements ProgressRepository {
  int stars = 0;
  @override
  Future<int> addStars(int amount) async => stars += amount;
  @override
  Future<Set<String>> getMasteredWordIds() async => {};
  @override
  Future<int> getStars() async => stars;
  @override
  Future<void> markWordMastered(String wordId) async {}
  @override
  Future<void> resetProgress() async {}
}

class _MemStickerRepo implements StickerRepository {
  Set<String> owned = {}, seen = {};
  @override
  Future<Set<String>> getOwnedSpecialIds() async => owned;
  @override
  Future<void> setOwnedSpecialIds(Set<String> ids) async => owned = ids;
  @override
  Future<Set<String>> getSeenIds() async => seen;
  @override
  Future<void> setSeenIds(Set<String> ids) async => seen = ids;
  @override
  Future<(String?, int)> getGameStarRewards() async => (null, 0);
  @override
  Future<void> setGameStarRewards(String day, int count) async {}
}

void main() {
  testWidgets('chạm đúng bong bóng mục tiêu thì được tính điểm', (tester) async {
    const words = [
      Word(id: 'cat', en: 'cat', vi: 'mèo', emoji: '🐱'),
      Word(id: 'dog', en: 'dog', vi: 'chó', emoji: '🐶'),
      Word(id: 'cow', en: 'cow', vi: 'bò', emoji: '🐄'),
    ];
    final tts = _SilentTts();
    final stickers = StickerController(_MemStickerRepo());

    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<TtsService>.value(value: tts),
        Provider<SoundService>.value(value: SoundService(enabled: false)),
        ChangeNotifierProvider(create: (_) => ProgressController(_MemProgressRepo())),
        ChangeNotifierProvider.value(value: stickers),
      ],
      child: MaterialApp(home: BubbleGameScreen(pickWords: () => words)),
    ));

    // Cho bong bóng mục tiêu (luôn sinh ra đầu tiên) bay lên vào giữa khung chơi.
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final target = words.firstWhere((w) => find.text(w.en).evaluate().isNotEmpty);
    expect(tts.spoken, contains(target.en), reason: 'Mimi phải đọc to từ cần tìm');
    expect(find.text('🎈 0/10'), findsOneWidget);

    await tester.tap(find.text(target.emoji!).first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('🎈 1/10'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
