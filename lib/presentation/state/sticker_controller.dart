import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../domain/entities/sticker.dart';
import '../../domain/repositories/sticker_repository.dart';
import 'progress_controller.dart';

/// Phần thưởng sau 1 ván minigame thắng.
@immutable
class GameReward {
  final int stars;
  final SpecialSticker? sticker;

  const GameReward({required this.stars, required this.sticker});
}

/// Bộ sưu tập sticker của bé:
/// - Sticker TỪ VỰNG: không lưu riêng, chính là các từ bé đã thuộc
///   ([ProgressController.masteredWordIds]) - id dạng `word:<wordId>`.
/// - Sticker ĐẶC BIỆT: nhận khi thắng minigame - id dạng `special:<id>`.
/// Sticker nào có mà chưa có trong tập "đã xem" thì album gắn nhãn MỚI.
class StickerController extends ChangeNotifier {
  StickerController(this._repository, {Random? random, DateTime Function()? clock})
      : _random = random ?? Random(),
        _clock = clock ?? DateTime.now;

  /// Minigame chơi lại vô hạn mà sao quy đổi ra ngọc thưởng tiền thật
  /// (xem `GemRewardController`), nên chỉ tặng sao cho vài ván đầu mỗi ngày.
  static const int starsPerGameWin = 2;
  static const int maxStarRewardsPerDay = 5;

  final StickerRepository _repository;
  final Random _random;
  final DateTime Function() _clock;

  Set<String> _ownedSpecialIds = {};
  Set<String> _seenIds = {};
  String? _rewardDay;
  int _rewardCount = 0;
  bool _loaded = false;

  bool get loaded => _loaded;
  Set<String> get ownedSpecialIds => _ownedSpecialIds;
  Set<String> get seenIds => _seenIds;

  static String wordKey(String wordId) => 'word:$wordId';
  static String specialKey(String id) => 'special:$id';

  Future<void> load() async {
    _ownedSpecialIds = await _repository.getOwnedSpecialIds();
    _seenIds = await _repository.getSeenIds();
    final (day, count) = await _repository.getGameStarRewards();
    _rewardDay = day;
    _rewardCount = count;
    _loaded = true;
    notifyListeners();
  }

  String get _today {
    final now = _clock();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  int get starRewardsLeftToday =>
      _rewardDay == _today ? max(0, maxStarRewardsPerDay - _rewardCount) : maxStarRewardsPerDay;

  bool get allSpecialCollected => _ownedSpecialIds.length >= SpecialSticker.all.length;

  /// Gọi 1 lần khi bé thắng 1 ván: cộng sao (nếu còn lượt trong ngày) và tặng
  /// 1 sticker đặc biệt CHƯA CÓ (bốc theo trọng số độ hiếm).
  Future<GameReward> claimGameWin(ProgressController progress) async {
    var stars = 0;
    if (starRewardsLeftToday > 0) {
      final today = _today;
      _rewardCount = _rewardDay == today ? _rewardCount + 1 : 1;
      _rewardDay = today;
      await _repository.setGameStarRewards(today, _rewardCount);
      stars = starsPerGameWin;
      await progress.addStars(stars);
    }

    final sticker = _pickNewSticker();
    if (sticker != null) {
      _ownedSpecialIds = {..._ownedSpecialIds, sticker.id};
      await _repository.setOwnedSpecialIds(_ownedSpecialIds);
    }
    notifyListeners();
    return GameReward(stars: stars, sticker: sticker);
  }

  SpecialSticker? _pickNewSticker() {
    final candidates = SpecialSticker.all.where((s) => !_ownedSpecialIds.contains(s.id)).toList();
    if (candidates.isEmpty) return null;
    final total = candidates.fold<int>(0, (sum, s) => sum + s.rarity.weight);
    var roll = _random.nextInt(total);
    for (final s in candidates) {
      roll -= s.rarity.weight;
      if (roll < 0) return s;
    }
    return candidates.last;
  }

  /// Đánh dấu đã xem - gọi khi bé mở album để lần sau không còn nhãn MỚI.
  Future<void> markSeen(Iterable<String> keys) async {
    final updated = {..._seenIds, ...keys};
    if (updated.length == _seenIds.length) return;
    _seenIds = updated;
    await _repository.setSeenIds(_seenIds);
    notifyListeners();
  }

  /// Số sticker (từ vựng + đặc biệt) bé có mà chưa xem trong album.
  int newCount(Set<String> masteredWordIds) {
    var n = 0;
    for (final id in masteredWordIds) {
      if (!_seenIds.contains(wordKey(id))) n++;
    }
    for (final id in _ownedSpecialIds) {
      if (!_seenIds.contains(specialKey(id))) n++;
    }
    return n;
  }
}
