import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/domain/entities/lesson.dart';
import 'package:mimi_pet/domain/entities/word.dart';
import 'package:mimi_pet/domain/repositories/progress_repository.dart';
import 'package:mimi_pet/domain/repositories/sticker_repository.dart';
import 'package:mimi_pet/presentation/screens/games/frog_game_screen.dart';
import 'package:mimi_pet/presentation/state/games/frog_game_controller.dart';
import 'package:mimi_pet/presentation/state/games/game_words.dart';
import 'package:mimi_pet/presentation/state/progress_controller.dart';
import 'package:mimi_pet/presentation/state/sticker_controller.dart';
import 'package:mimi_pet/services/sound_service.dart';
import 'package:mimi_pet/services/tts_service.dart';

const _words = [
  Word(id: 'cat', en: 'cat', vi: 'mèo', emoji: '🐱'),
  Word(id: 'dog', en: 'dog', vi: 'chó', emoji: '🐶'),
  Word(id: 'cow', en: 'cow', vi: 'bò', emoji: '🐄'),
  Word(id: 'pig', en: 'pig', vi: 'lợn', emoji: '🐷'),
  Word(id: 'fox', en: 'fox', vi: 'cáo', emoji: '🦊'),
  Word(id: 'owl', en: 'owl', vi: 'cú', emoji: '🦉'),
];

int _correctIndex(FrogGameController c) => c.row.indexWhere((w) => w.id == c.target.id);
int _wrongIndex(FrogGameController c) =>
    List.generate(c.row.length, (i) => i).firstWhere((i) => c.row[i].id != c.target.id && !c.isSunk(i));

void _finishHop(FrogGameController c) {
  for (var i = 0; i < 20 && c.phase == FrogPhase.hopping; i++) {
    c.tick(0.05);
  }
}

void main() {
  group('FrogGameController', () {
    test('mỗi hàng có đúng số lá sen, lá đúng nằm trong hàng, không trùng hình', () {
      for (final d in FrogDifficulty.values) {
        final c = FrogGameController(words: _words, difficulty: d, random: Random(1));
        for (var s = 0; s < 5; s++) {
          expect(c.row.length, d.pads);
          expect(c.row.map((w) => w.emoji).toSet().length, d.pads);
          expect(c.row.any((w) => w.id == c.target.id), isTrue);
          c.tap(_correctIndex(c));
          _finishHop(c);
        }
      }
    });

    test('chạm đúng: ếch nhảy, xong cú nhảy thì sang bước mới với từ khác', () {
      final c = FrogGameController(words: _words, random: Random(2));
      final first = c.target;
      final round = c.targetRound;
      expect(c.tap(_correctIndex(c)), FrogTapResult.correct);
      expect(c.phase, FrogPhase.hopping);
      // Trong lúc nhảy không nhận chạm.
      expect(c.tap(0), FrogTapResult.ignored);
      _finishHop(c);
      expect(c.step, 1);
      expect(c.phase, FrogPhase.choosing);
      expect(c.target.id, isNot(first.id), reason: 'không hỏi lại đúng từ vừa hỏi');
      expect(c.targetRound, greaterThan(round));
    });

    test('chạm sai: lá chìm, mất 1 mạng, Mimi đọc lại; hết 3 mạng thì thua', () {
      final c = FrogGameController(words: _words, difficulty: FrogDifficulty.hard, random: Random(3));
      final round = c.targetRound;
      final wrong = _wrongIndex(c);
      expect(c.tap(wrong), FrogTapResult.wrong);
      expect(c.isSunk(wrong), isTrue);
      expect(c.lives, 2);
      expect(c.targetRound, round + 1);
      expect(c.tap(wrong), FrogTapResult.ignored, reason: 'lá đã chìm không chạm lại được');
      c.tap(_wrongIndex(c));
      c.tap(_wrongIndex(c));
      expect(c.lives, 0);
      expect(c.phase, FrogPhase.lost);
      expect(c.isOver, isTrue);
    });

    test('đi đủ số bước là qua sông (thắng); còn nguyên mạng được 3 sao', () {
      final c = FrogGameController(words: _words, difficulty: FrogDifficulty.easy, random: Random(4));
      for (var s = 0; s < FrogDifficulty.easy.steps; s++) {
        c.tap(_correctIndex(c));
        _finishHop(c);
      }
      expect(c.phase, FrogPhase.won);
      expect(c.rating, 3);
    });

    test('mức Khó: hết giờ thì mất 1 mạng; giờ mỗi bước ngắn dần nhưng không dưới mức tối thiểu', () {
      final c = FrogGameController(words: _words, difficulty: FrogDifficulty.hard, random: Random(5));
      expect(c.timeLimit, 7);
      // 1.2 giây đầu là thời gian chuẩn bị (Mimi đang đọc) - chưa trừ giờ.
      for (var i = 0; i < 24; i++) {
        c.tick(0.05);
      }
      expect(c.timeLeft, 7);
      for (var i = 0; i < 150; i++) {
        c.tick(0.05); // thêm 7.5 giây
      }
      expect(c.lives, 2);
      expect(c.timeLeft, greaterThan(6), reason: 'tính giờ lại sau khi hết giờ');
      for (var s = 0; s < 11; s++) {
        c.tap(_correctIndex(c));
        _finishHop(c);
      }
      expect(c.timeLimit, 4, reason: '7 - 0.3 x 11 = 3.7 -> kẹp ở 4 giây');
    });

    test('mức Dễ/Vừa không hẹn giờ', () {
      final c = FrogGameController(words: _words, difficulty: FrogDifficulty.normal);
      expect(c.timeLeft, isNull);
      for (var i = 0; i < 400; i++) {
        c.tick(0.05);
      }
      expect(c.lives, 3);
    });
  });

  test('chọn từ cho minigame không bao giờ lấy 2 hình dễ nhầm (😴 tired / 😪 sleepy...)', () {
    const lesson = Lesson(id: 'feel', title: 'Feelings', emoji: '😀', words: [
      Word(id: 'tired', en: 'tired', vi: 'mệt', emoji: '😴'),
      Word(id: 'sleepy', en: 'sleepy', vi: 'buồn ngủ', emoji: '😪'),
      Word(id: 'sunny', en: 'sunny', vi: 'nắng', emoji: '🌞'),
      Word(id: 'summer', en: 'summer', vi: 'mùa hè', emoji: '☀️'),
      Word(id: 'cat', en: 'cat', vi: 'mèo', emoji: '🐱'),
      Word(id: 'dog', en: 'dog', vi: 'chó', emoji: '🐶'),
    ]);
    for (var seed = 0; seed < 30; seed++) {
      final picked = pickGameWords(
        lessons: const [lesson],
        masteredWordIds: const {},
        source: GameWordSource.random,
        count: 6,
        random: Random(seed),
      ).map((w) => w.id).toSet();
      expect(picked.containsAll({'tired', 'sleepy'}), isFalse);
      expect(picked.containsAll({'sunny', 'summer'}), isFalse);
      expect(picked.length, 4);
    }
  });

  testWidgets('màn chơi: Mimi đọc từ, chạm đúng lá sen thì ếch tiến 1 bước', (tester) async {
    final tts = _SilentTts();
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<TtsService>.value(value: tts),
        Provider<SoundService>.value(value: SoundService(enabled: false)),
        ChangeNotifierProvider(create: (_) => ProgressController(_MemProgressRepo())),
        ChangeNotifierProvider.value(value: StickerController(_MemStickerRepo())),
      ],
      child: const MaterialApp(home: FrogGameScreen(pickWords: _pick, difficulty: FrogDifficulty.easy)),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('0/8'), findsOneWidget);
    final target = _words.firstWhere((w) => find.text(w.en).evaluate().isNotEmpty);
    expect(tts.spoken, contains(target.en));

    await tester.tap(find.text(target.emoji!).first, warnIfMissed: false);
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('1/8'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

List<Word> _pick() => _words;

class _SilentTts extends TtsService {
  final spoken = <String>[];

  @override
  Future<void> speak(String text, {VoiceKind kind = VoiceKind.kid, double speed = 1.0}) async => spoken.add(text);

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
