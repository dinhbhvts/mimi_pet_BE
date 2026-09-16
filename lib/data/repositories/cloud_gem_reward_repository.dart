import '../../domain/repositories/gem_reward_repository.dart';
import '../../services/cloud_state_store.dart';

/// Implementation của [GemRewardRepository] qua [CloudStateStore] - cùng
/// nguyên tắc với [CloudHeartsRepository].
class CloudGemRewardRepository implements GemRewardRepository {
  CloudGemRewardRepository(this._store);

  final CloudStateStore _store;

  @override
  Future<int> getClaimedGemCount() async => _store.getRaw<int>('claimedGemCount') ?? 0;

  @override
  Future<void> setClaimedGemCount(int count) async => _store.setRaw('claimedGemCount', count);
}
