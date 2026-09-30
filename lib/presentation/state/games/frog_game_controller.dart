import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/word.dart';

/// Độ khó "Ếch nhảy qua sông": số lá sen mỗi hàng, số bước để qua sông, và
/// (chỉ ở mức Khó) đồng hồ đếm ngược mỗi bước - rút ngắn dần sau mỗi bước.
enum FrogDifficulty {
  easy(pads: 2, steps: 8, label: 'Dễ · 2 lá sen'),
  normal(pads: 3, steps: 10, label: 'Vừa · 3 lá sen'),
  hard(pads: 4, steps: 12, label: 'Khó · 4 lá + hẹn giờ', startSeconds: 7, minSeconds: 4, shrinkPerStep: 0.3);

  const FrogDifficulty({
    required this.pads,
    required this.steps,
    required this.label,
    this.startSeconds,
    this.minSeconds = 0,
    this.shrinkPerStep = 0,
  });

  final int pads;
  final int steps;
  final String label;

  /// null = không giới hạn giờ.
  final double? startSeconds;
  final double minSeconds;
  final double shrinkPerStep;
}

enum FrogPhase { choosing, hopping, won, lost }

enum FrogTapResult { ignored, correct, wrong }

/// Logic minigame "Ếch nhảy qua sông" (luyện NGHE nhanh): mỗi bước Mimi đọc 1
/// từ, bé chạm đúng lá sen có hình của từ đó để ếch nhảy lên. Chạm sai thì lá
/// sen đó chìm và mất 1 mạng; hết mạng là ếch rơi xuống sông (thua). Đi đủ
/// [FrogDifficulty.steps] bước là qua sông (thắng).
class FrogGameController extends ChangeNotifier {
  FrogGameController({
    required List<Word> words,
    this.difficulty = FrogDifficulty.normal,
    Random? random,
  })  : assert(words.length >= difficulty.pads, 'cần đủ từ cho 1 hàng lá sen'),
        _words = words,
        _random = random ?? Random() {
    _newRow();
  }

  static const int startLives = 3;

  /// Thời gian 1 cú nhảy (giây) - trong lúc nhảy không nhận chạm.
  static const double hopSeconds = 0.45;

  /// Mức Khó: chờ Mimi đọc xong từ rồi mới bắt đầu đếm giờ.
  static const double graceSeconds = 1.2;

  final List<Word> _words;
  final Random _random;
  final FrogDifficulty difficulty;

  List<Word> _row = const [];
  late Word _target;
  final Set<int> _sunk = {};
  int _step = 0;
  int _lives = startLives;
  int _mistakes = 0;
  int _targetRound = 0;
  int? _hopTo;
  double _hopProgress = 0;
  double? _timeLeft;
  double _grace = 0;
  double _elapsed = 0;
  Word? _lastTarget;
  FrogPhase _phase = FrogPhase.choosing;
  bool _disposed = false;

  List<Word> get row => List.unmodifiable(_row);
  Word get target => _target;
  bool isSunk(int index) => _sunk.contains(index);
  int get step => _step;
  int get stepsToWin => difficulty.steps;
  int get lives => _lives;
  int get mistakes => _mistakes;
  FrogPhase get phase => _phase;
  bool get isOver => _phase == FrogPhase.won || _phase == FrogPhase.lost;
  double get elapsedSeconds => _elapsed;

  /// Tăng mỗi khi có từ mới cần đọc (hàng mới, hoặc đọc lại sau khi sai/hết
  /// giờ) - UI dùng để biết lúc nào cần đọc to.
  int get targetRound => _targetRound;

  /// Lá sen ếch đang nhảy tới (chỉ có trong lúc [FrogPhase.hopping]).
  int? get hopTo => _hopTo;
  double get hopProgress => _hopProgress;

  /// Giây còn lại của bước hiện tại - null nếu không hẹn giờ.
  double? get timeLeft => _timeLeft;
  double? get timeLimit => _limitForStep(_step);

  int get rating => _lives.clamp(1, 3);

  double? _limitForStep(int step) {
    final start = difficulty.startSeconds;
    if (start == null) return null;
    return max(difficulty.minSeconds, start - difficulty.shrinkPerStep * step);
  }

  /// Hàng lá sen mới: 1 lá đúng + các lá nhiễu KHÁC hình nhau, vị trí lá đúng
  /// ngẫu nhiên; tránh hỏi lại đúng từ vừa hỏi ở bước trước.
  void _newRow() {
    final candidates = _words.where((w) => w.id != _lastTarget?.id).toList();
    _target = candidates[_random.nextInt(candidates.length)];
    _lastTarget = _target;
    final others = _words.where((w) => w.id != _target.id && w.emoji != _target.emoji).toList()..shuffle(_random);
    final distractors = <Word>[];
    for (final w in others) {
      if (distractors.length >= difficulty.pads - 1) break;
      if (distractors.any((d) => d.emoji == w.emoji)) continue;
      distractors.add(w);
    }
    final pads = [...distractors]..insert(_random.nextInt(distractors.length + 1), _target);
    _row = pads;
    _sunk.clear();
    _timeLeft = _limitForStep(_step);
    _grace = graceSeconds;
    _targetRound++;
  }

  /// Gọi mỗi khung hình với [dt] giây đã trôi qua.
  void tick(double dt) {
    if (isOver) return;
    _elapsed += dt;
    if (_phase == FrogPhase.hopping) {
      _hopProgress += dt / hopSeconds;
      if (_hopProgress >= 1) {
        _hopProgress = 0;
        _hopTo = null;
        _step++;
        if (_step >= difficulty.steps) {
          _phase = FrogPhase.won;
        } else {
          _phase = FrogPhase.choosing;
          _newRow();
        }
      }
      _notify();
      return;
    }
    final left = _timeLeft;
    if (left != null && _grace > 0) {
      _grace -= dt;
    } else if (left != null) {
      _timeLeft = left - dt;
      if (_timeLeft! <= 0) {
        // Hết giờ: mất 1 mạng, đọc lại từ và tính giờ lại (vẫn hàng cũ).
        _loseLife();
        if (!isOver) {
          _timeLeft = _limitForStep(_step);
          _grace = graceSeconds;
          _targetRound++;
        }
      }
      _notify();
    }
  }

  FrogTapResult tap(int index) {
    if (_phase != FrogPhase.choosing || index < 0 || index >= _row.length || _sunk.contains(index)) {
      return FrogTapResult.ignored;
    }
    if (_row[index].id == _target.id) {
      _phase = FrogPhase.hopping;
      _hopTo = index;
      _hopProgress = 0;
      _notify();
      return FrogTapResult.correct;
    }
    _sunk.add(index);
    _loseLife();
    if (!isOver) _targetRound++; // đọc lại từ cho bé nghe lần nữa
    _notify();
    return FrogTapResult.wrong;
  }

  void _loseLife() {
    _mistakes++;
    _lives--;
    if (_lives <= 0) {
      _lives = 0;
      _phase = FrogPhase.lost;
    }
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
