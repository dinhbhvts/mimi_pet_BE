import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/word.dart';

/// 1 bong bóng - toạ độ CHUẨN HOÁ theo khung chơi: x 0..1 (trái→phải),
/// y 0..1 (trên→dưới), bong bóng bay từ dưới (y > 1) lên trên (y < 0).
class Bubble {
  final int id;
  final Word word;
  final double baseX;
  final double speed;
  final double phase;
  double y;
  double age = 0;

  /// > 0 khi đang nổ (0..1), bong bóng bị xoá khi đạt 1.
  double popProgress = 0;

  /// > 0 khi vừa bị chạm sai - UI lắc nhẹ trong lúc giảm dần về 0.
  double shake = 0;

  Bubble({
    required this.id,
    required this.word,
    required this.baseX,
    required this.speed,
    required this.phase,
    required this.y,
  });

  bool get isPopping => popProgress > 0;

  /// Lắc lư nhẹ sang 2 bên cho sinh động.
  double get x => baseX + 0.025 * sin(age * 2.2 + phase);
}

enum BubbleTapResult { ignored, correct, wrong }

class BubbleGameController extends ChangeNotifier {
  BubbleGameController({required List<Word> words, this.targetsToWin = 10, Random? random})
      : assert(words.length >= 2),
        _words = words,
        _random = random ?? Random() {
    _target = _words[_random.nextInt(_words.length)];
  }

  static const int maxBubbles = 6;
  static const double spawnInterval = 0.85;
  static const List<double> _lanes = [0.13, 0.32, 0.5, 0.68, 0.87];

  final List<Word> _words;
  final Random _random;
  final int targetsToWin;
  final List<Bubble> bubbles = [];

  late Word _target;
  int _targetRound = 0;
  int _score = 0;
  int _mistakes = 0;
  int _nextId = 0;
  double _spawnTimer = 0;
  double _elapsed = 0;
  bool _disposed = false;

  Word get target => _target;

  /// Tăng mỗi lần đổi từ cần tìm - UI dùng để biết lúc nào đọc to từ mới.
  int get targetRound => _targetRound;
  int get score => _score;
  int get mistakes => _mistakes;
  double get elapsedSeconds => _elapsed;
  bool get isComplete => _score >= targetsToWin;

  int get rating {
    if (_mistakes <= 1) return 3;
    if (_mistakes <= 4) return 2;
    return 1;
  }

  /// Gọi mỗi khung hình với [dt] giây đã trôi qua.
  void tick(double dt) {
    if (isComplete) return;
    _elapsed += dt;
    for (final b in bubbles) {
      b.age += dt;
      if (b.isPopping) {
        b.popProgress += dt / 0.3;
      } else {
        b.y -= b.speed * dt;
      }
      if (b.shake > 0) b.shake = max(0, b.shake - dt / 0.4);
    }
    bubbles.removeWhere((b) => b.popProgress >= 1 || b.y < -0.2);

    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && bubbles.length < maxBubbles) {
      _spawn();
      _spawnTimer = spawnInterval;
    }
    _notify();
  }

  void _spawn() {
    final targetVisible = bubbles.any((b) => !b.isPopping && b.word.id == _target.id);
    final Word word;
    if (!targetVisible) {
      word = _target;
    } else {
      final others = _words.where((w) => w.id != _target.id).toList();
      word = others[_random.nextInt(others.length)];
    }
    // Tránh làn đang có bong bóng ở gần đáy để không chồng lên nhau.
    final busyLanes = bubbles.where((b) => b.y > 0.75).map((b) => b.baseX).toSet();
    final free = _lanes.where((l) => !busyLanes.contains(l)).toList();
    final lane = (free.isEmpty ? _lanes : free)[_random.nextInt((free.isEmpty ? _lanes : free).length)];
    bubbles.add(Bubble(
      id: _nextId++,
      word: word,
      baseX: lane,
      speed: 0.11 + _random.nextDouble() * 0.06,
      phase: _random.nextDouble() * pi * 2,
      y: 1.15,
    ));
  }

  BubbleTapResult tap(int bubbleId) {
    if (isComplete) return BubbleTapResult.ignored;
    final matches = bubbles.where((b) => b.id == bubbleId && !b.isPopping);
    if (matches.isEmpty) return BubbleTapResult.ignored;
    final bubble = matches.first;

    if (bubble.word.id == _target.id) {
      bubble.popProgress = 0.01;
      _score++;
      if (!isComplete) _nextTarget();
      _notify();
      return BubbleTapResult.correct;
    }
    _mistakes++;
    bubble.shake = 1;
    _notify();
    return BubbleTapResult.wrong;
  }

  void _nextTarget() {
    final others = _words.where((w) => w.id != _target.id).toList();
    _target = others[_random.nextInt(others.length)];
    _targetRound++;
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
