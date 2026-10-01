import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/domain/entities/lesson.dart';
import 'package:mimi_pet/domain/entities/word.dart';
import 'package:mimi_pet/domain/repositories/lesson_repository.dart';
import 'package:mimi_pet/domain/repositories/progress_repository.dart';
import 'package:mimi_pet/domain/repositories/sticker_repository.dart';
import 'package:mimi_pet/presentation/screens/games/games_hub_screen.dart';
import 'package:mimi_pet/presentation/state/lessons_controller.dart';
import 'package:mimi_pet/presentation/state/progress_controller.dart';
import 'package:mimi_pet/presentation/state/sticker_controller.dart';

void main() {
  for (final game in ['Lật thẻ tìm cặp', 'Chạm bong bóng', 'Ếch nhảy qua sông']) {
    testWidgets('$game: nút "Chơi thôi" luôn nằm trong khung hình dù có rất nhiều chủ đề', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final lessons = LessonsController(_ManyLessons());
      await lessons.load();
      final stickers = StickerController(_StickerRepo());
      await stickers.load();
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: lessons),
          ChangeNotifierProvider(create: (_) => ProgressController(_ProgressRepo())),
          ChangeNotifierProvider.value(value: stickers),
        ],
        child: const MaterialApp(home: GamesHubScreen()),
      ));
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text(game));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final play = find.text('Chơi thôi! ▶');
      expect(play, findsOneWidget);
      final rect = tester.getRect(play);
      expect(rect.bottom, lessThanOrEqualTo(667), reason: 'nút phải hiện ngay, không phải cuộn');
      // Chọn 1 chủ đề ở cuối danh sách -> chân bảng hiện đúng lựa chọn.
      await tester.scrollUntilVisible(find.text('🎯 Topic 59'), 200, scrollable: find.byType(Scrollable).last);
      await tester.tap(find.text('🎯 Topic 59'));
      await tester.pump();
      expect(find.text('Đang chọn: 🎯 Topic 59'), findsOneWidget);
      expect(tester.getRect(play).bottom, lessThanOrEqualTo(667));
      expect(tester.takeException(), isNull);
    });
  }
}

class _ManyLessons implements LessonRepository {
  @override
  Future<List<Lesson>> getAllLessons() async => [
    for (var i = 0; i < 60; i++)
      Lesson(id: 'l$i', title: 'Topic $i', emoji: '🎯', words: [
        for (final e in ['🐱', '🐶', '🐄', '🐷', '🦊', '🦉']) Word(id: '$i$e', en: 'w$i$e', vi: 'x', emoji: e),
      ]),
  ];
}

class _ProgressRepo implements ProgressRepository {
  @override
  Future<int> addStars(int amount) async => amount;
  @override
  Future<Set<String>> getMasteredWordIds() async => {};
  @override
  Future<int> getStars() async => 0;
  @override
  Future<void> markWordMastered(String wordId) async {}
  @override
  Future<void> resetProgress() async {}
}

class _StickerRepo implements StickerRepository {
  @override
  Future<Set<String>> getOwnedSpecialIds() async => {};
  @override
  Future<void> setOwnedSpecialIds(Set<String> ids) async {}
  @override
  Future<Set<String>> getSeenIds() async => {};
  @override
  Future<void> setSeenIds(Set<String> ids) async {}
  @override
  Future<(String?, int)> getGameStarRewards() async => (null, 0);
  @override
  Future<void> setGameStarRewards(String day, int count) async {}
}
