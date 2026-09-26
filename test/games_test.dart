import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:mimi_pet/domain/entities/lesson.dart';
import 'package:mimi_pet/domain/entities/sticker.dart';
import 'package:mimi_pet/domain/entities/word.dart';
import 'package:mimi_pet/domain/repositories/progress_repository.dart';
import 'package:mimi_pet/domain/repositories/sticker_repository.dart';
import 'package:mimi_pet/presentation/state/games/bubble_game_controller.dart';
import 'package:mimi_pet/presentation/state/games/game_words.dart';
import 'package:mimi_pet/presentation/state/games/memory_game_controller.dart';
import 'package:mimi_pet/presentation/state/progress_controller.dart';
import 'package:mimi_pet/presentation/state/sticker_controller.dart';

Word _w(String id, String emoji) => Word(id: id, en: id, vi: id, emoji: emoji);

final _words = [_w('cat', '🐱'), _w('dog', '🐶'), _w('cow', '🐄'), _w('pig', '🐷')];

class _FakeProgressRepo implements ProgressRepository {
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

class _FakeStickerRepo implements StickerRepository {
  Set<String> owned = {};
  Set<String> seen = {};
  String? day;
  int count = 0;
  @override
  Future<Set<String>> getOwnedSpecialIds() async => owned;
  @override
  Future<void> setOwnedSpecialIds(Set<String> ids) async => owned = ids;
  @override
  Future<Set<String>> getSeenIds() async => seen;
  @override
  Future<void> setSeenIds(Set<String> ids) async => seen = ids;
  @override
  Future<(String?, int)> getGameStarRewards() async => (day, count);
  @override
  Future<void> setGameStarRewards(String d, int c) async {
    day = d;
    count = c;
  }
}

void main() {
  group('MemoryGameController', () {
    test('mỗi từ có 1 thẻ hình + 1 thẻ chữ', () {
      final ctrl = MemoryGameController(words: _words, random: Random(1));
      expect(ctrl.cards.length, 8);
      for (final w in _words) {
        final faces = ctrl.cards.where((c) => c.word.id == w.id).map((c) => c.face).toSet();
        expect(faces, {MemoryCardFace.picture, MemoryCardFace.word});
      }
    });

    test('lật đúng cặp thì giữ mở, lật sai thì úp lại', () async {
      final ctrl = MemoryGameController(words: _words, random: Random(2), mismatchDelay: Duration.zero);
      final a = ctrl.cards.indexWhere((c) => c.word.id == 'cat');
      final b = ctrl.cards.lastIndexWhere((c) => c.word.id == 'cat');
      final other = ctrl.cards.indexWhere((c) => c.word.id == 'dog');

      expect(ctrl.flip(a), MemoryFlipResult.firstOfPair);
      expect(ctrl.flip(other), MemoryFlipResult.mismatch);
      expect(ctrl.flip(b), MemoryFlipResult.ignored, reason: 'đang chờ úp lại thì không cho lật');
      await Future<void>.delayed(Duration.zero);
      expect(ctrl.cards[a].revealed, isFalse);

      expect(ctrl.flip(a), MemoryFlipResult.firstOfPair);
      expect(ctrl.flip(b), MemoryFlipResult.match);
      expect(ctrl.cards[a].matched && ctrl.cards[b].matched, isTrue);
      expect(ctrl.matchedPairs, 1);
    });

    test('ghép hết không sai lượt nào thì hoàn thành với 3 sao', () {
      final ctrl = MemoryGameController(words: _words, random: Random(3));
      for (final w in _words) {
        ctrl.flip(ctrl.cards.indexWhere((c) => c.word.id == w.id));
        ctrl.flip(ctrl.cards.lastIndexWhere((c) => c.word.id == w.id));
      }
      expect(ctrl.isComplete, isTrue);
      expect(ctrl.moves, 4);
      expect(ctrl.rating, 3);
    });
  });

  group('BubbleGameController', () {
    test('luôn có bong bóng của từ cần tìm, chạm đúng/sai tính điểm', () {
      final ctrl = BubbleGameController(words: _words, targetsToWin: 3, random: Random(4));
      ctrl.tick(0.016);
      expect(ctrl.bubbles.any((b) => b.word.id == ctrl.target.id), isTrue);

      for (var i = 0; i < 20; i++) {
        ctrl.tick(BubbleGameController.spawnInterval);
      }
      final wrong = ctrl.bubbles.firstWhere((b) => b.word.id != ctrl.target.id);
      expect(ctrl.tap(wrong.id), BubbleTapResult.wrong);
      expect(ctrl.mistakes, 1);

      var guard = 0;
      while (!ctrl.isComplete && guard++ < 500) {
        final hit = ctrl.bubbles.where((b) => b.word.id == ctrl.target.id && !b.isPopping);
        if (hit.isNotEmpty) {
          expect(ctrl.tap(hit.first.id), BubbleTapResult.correct);
        }
        ctrl.tick(0.1);
      }
      expect(ctrl.isComplete, isTrue);
      expect(ctrl.score, 3);
    });
  });

  test('pickGameWords không trùng hình và bỏ từ không vẽ được', () {
    final lesson = Lesson(id: 'l', title: 'L', emoji: '📘', words: [
      ..._words,
      _w('kitty', '🐱'),
      const Word(id: 'hello', en: 'hello', vi: 'xin chào', emoji: '👋', promptType: PromptType.repeat),
    ]);
    final picked = pickGameWords(
      lessons: [lesson],
      masteredWordIds: const {},
      source: GameWordSource.random,
      count: 10,
      random: Random(5),
    );
    expect(picked.map((w) => w.emoji).toSet().length, picked.length);
    expect(picked.any((w) => w.id == 'hello'), isFalse);
    expect(picked.length, 4);
  });

  group('StickerController', () {
    test('mỗi ván thắng tặng 1 sticker chưa có; sao giới hạn theo ngày', () async {
      var now = DateTime(2026, 9, 27, 10);
      final repo = _FakeStickerRepo();
      final progressRepo = _FakeProgressRepo();
      final progress = ProgressController(progressRepo);
      final ctrl = StickerController(repo, random: Random(6), clock: () => now)..load();
      await Future<void>.delayed(Duration.zero);

      final got = <String>{};
      for (var i = 0; i < StickerController.maxStarRewardsPerDay + 2; i++) {
        final reward = await ctrl.claimGameWin(progress);
        expect(reward.sticker, isNotNull);
        expect(got.add(reward.sticker!.id), isTrue, reason: 'không được trùng sticker');
      }
      expect(progressRepo.stars, StickerController.starsPerGameWin * StickerController.maxStarRewardsPerDay);
      expect(ctrl.starRewardsLeftToday, 0);

      now = DateTime(2026, 9, 28, 9);
      expect(ctrl.starRewardsLeftToday, StickerController.maxStarRewardsPerDay);
      final nextDay = await ctrl.claimGameWin(progress);
      expect(nextDay.stars, StickerController.starsPerGameWin);
    });

    test('hết sticker thì không tặng thêm', () async {
      final repo = _FakeStickerRepo()..owned = SpecialSticker.all.map((s) => s.id).toSet();
      final ctrl = StickerController(repo)..load();
      await Future<void>.delayed(Duration.zero);
      final reward = await ctrl.claimGameWin(ProgressController(_FakeProgressRepo()));
      expect(reward.sticker, isNull);
      expect(ctrl.allSpecialCollected, isTrue);
    });
  });
}
