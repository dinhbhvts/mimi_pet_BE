import 'dart:math';

import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/word.dart';

/// Nguồn từ cho minigame.
enum GameWordSource {
  /// Ưu tiên từ bé đã thuộc (ôn lại), thiếu thì bù từ ngẫu nhiên.
  mastered,

  /// Ngẫu nhiên trong toàn bộ bài học.
  random,

  /// Chỉ 1 bài học (thiếu từ thì bù ngẫu nhiên).
  lesson,
}

/// Từ dùng được trong minigame: có emoji rõ nghĩa (không phải ô màu, không
/// phải từ kiểu "repeat" như hello/Monday vốn không vẽ được bằng 1 hình).
bool isGameFriendlyWord(Word w) =>
    w.promptType == PromptType.identify && w.emoji != null && w.swatchColor == null;

/// Bài học có đủ từ để chơi riêng theo chủ đề.
List<Lesson> gameFriendlyLessons(List<Lesson> lessons, {int minWords = 4}) =>
    lessons.where((l) => l.words.where(isGameFriendlyWord).length >= minWords).toList();

/// Nhóm hình NHÌN GẦN GIỐNG NHAU (vd 😴 tired / 😪 sleepy) - không cho 2 từ
/// cùng nhóm xuất hiện chung 1 ván để bé không bị "bẫy" bởi hình vẽ.
const List<Set<String>> confusableEmojiGroups = [
  {'😴', '😪', '🥱'},
  {'🌞', '☀️'},
  {'😨', '😲', '😱'},
  {'🎨', '🖌️'},
  {'😀', '😃', '😄', '😁', '😊'},
];

int? _confusableGroup(String emoji) {
  for (var i = 0; i < confusableEmojiGroups.length; i++) {
    if (confusableEmojiGroups[i].contains(emoji)) return i;
  }
  return null;
}

/// Chọn [count] từ KHÔNG trùng emoji/chữ (và không 2 hình dễ nhầm, xem
/// [confusableEmojiGroups]) để các thẻ/bong bóng/lá sen luôn phân biệt được.
List<Word> pickGameWords({
  required List<Lesson> lessons,
  required Set<String> masteredWordIds,
  required GameWordSource source,
  String? lessonId,
  required int count,
  Random? random,
}) {
  final rnd = random ?? Random();
  final all = lessons.expand((l) => l.words).where(isGameFriendlyWord).toList()..shuffle(rnd);

  final List<Word> preferred;
  switch (source) {
    case GameWordSource.mastered:
      preferred = all.where((w) => masteredWordIds.contains(w.id)).toList();
    case GameWordSource.random:
      preferred = const [];
    case GameWordSource.lesson:
      final lesson = lessons.where((l) => l.id == lessonId);
      preferred = lesson.isEmpty
          ? const []
          : (lesson.first.words.where(isGameFriendlyWord).toList()..shuffle(rnd));
  }

  final picked = <Word>[];
  final seenEmoji = <String>{};
  final seenText = <String>{};
  final seenGroups = <int>{};
  for (final w in [...preferred, ...all]) {
    if (picked.length >= count) break;
    if (seenEmoji.contains(w.emoji!) || seenText.contains(w.en.toLowerCase())) continue;
    final group = _confusableGroup(w.emoji!);
    if (group != null && seenGroups.contains(group)) continue;
    seenEmoji.add(w.emoji!);
    seenText.add(w.en.toLowerCase());
    if (group != null) seenGroups.add(group);
    picked.add(w);
  }
  return picked;
}
