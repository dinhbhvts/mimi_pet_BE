import '../../domain/repositories/sticker_repository.dart';
import '../../services/cloud_state_store.dart';

/// Implementation của [StickerRepository] qua [CloudStateStore] - đồng bộ bộ
/// sưu tập sticker giữa web và app di động.
class CloudStickerRepository implements StickerRepository {
  CloudStickerRepository(this._store);

  final CloudStateStore _store;

  Set<String> _readSet(String key) =>
      (_store.getRaw<List<dynamic>>(key) ?? const []).map((e) => e.toString()).toSet();

  @override
  Future<Set<String>> getOwnedSpecialIds() async => _readSet('specialStickers');

  @override
  Future<void> setOwnedSpecialIds(Set<String> ids) async => _store.setRaw('specialStickers', ids.toList());

  @override
  Future<Set<String>> getSeenIds() async => _readSet('seenStickers');

  @override
  Future<void> setSeenIds(Set<String> ids) async => _store.setRaw('seenStickers', ids.toList());

  @override
  Future<(String?, int)> getGameStarRewards() async =>
      (_store.getRaw<String>('gameStarRewardDay'), _store.getRaw<int>('gameStarRewardCount') ?? 0);

  @override
  Future<void> setGameStarRewards(String day, int count) async {
    _store.setRaw('gameStarRewardDay', day);
    _store.setRaw('gameStarRewardCount', count);
  }
}
