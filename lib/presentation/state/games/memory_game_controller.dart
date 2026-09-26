import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/word.dart';

/// Mỗi từ có 2 thẻ: 1 thẻ HÌNH (emoji) và 1 thẻ CHỮ (tiếng Anh) - bé phải
/// ghép hình với đúng từ, không chỉ tìm 2 hình giống nhau.
enum MemoryCardFace { picture, word }

class MemoryCard {
  final Word word;
  final MemoryCardFace face;
  bool revealed = false;
  bool matched = false;

  MemoryCard(this.word, this.face);
}

enum MemoryFlipResult { ignored, firstOfPair, match, mismatch }

class MemoryGameController extends ChangeNotifier {
  MemoryGameController({
    required List<Word> words,
    Random? random,
    this.mismatchDelay = const Duration(milliseconds: 900),
  }) : cards = [
          for (final w in words) ...[MemoryCard(w, MemoryCardFace.picture), MemoryCard(w, MemoryCardFace.word)],
        ]..shuffle(random ?? Random());

  final List<MemoryCard> cards;
  final Duration mismatchDelay;

  int? _firstIndex;
  bool _busy = false;
  bool _disposed = false;
  int _moves = 0;

  int get moves => _moves;
  int get pairCount => cards.length ~/ 2;
  int get matchedPairs => cards.where((c) => c.matched).length ~/ 2;
  bool get isComplete => cards.isNotEmpty && cards.every((c) => c.matched);

  /// Lật dò là một phần của trò chơi, nên chấm rộng tay: ≤ 2 lượt/cặp được
  /// 3 sao, ≤ 3 lượt/cặp được 2 sao.
  int get rating {
    if (_moves <= pairCount * 2) return 3;
    if (_moves <= pairCount * 3) return 2;
    return 1;
  }

  /// Kết quả trả về NGAY (để UI phát âm thanh đúng lúc); cặp lật sai tự úp
  /// lại sau [mismatchDelay], trong lúc đó mọi lần chạm khác bị bỏ qua.
  MemoryFlipResult flip(int index) {
    if (_busy || index < 0 || index >= cards.length) return MemoryFlipResult.ignored;
    final card = cards[index];
    if (card.revealed || card.matched) return MemoryFlipResult.ignored;

    card.revealed = true;
    final first = _firstIndex;
    if (first == null) {
      _firstIndex = index;
      _notify();
      return MemoryFlipResult.firstOfPair;
    }

    _firstIndex = null;
    _moves++;
    final other = cards[first];
    if (other.word.id == card.word.id) {
      other.matched = true;
      card.matched = true;
      _notify();
      return MemoryFlipResult.match;
    }

    _busy = true;
    _notify();
    Future<void>.delayed(mismatchDelay, () {
      other.revealed = false;
      card.revealed = false;
      _busy = false;
      _notify();
    });
    return MemoryFlipResult.mismatch;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
