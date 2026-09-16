import '../../domain/repositories/streak_repository.dart';
import '../../services/cloud_state_store.dart';

/// Implementation của [StreakRepository] qua [CloudStateStore].
class CloudStreakRepository implements StreakRepository {
  CloudStreakRepository(this._store);

  final CloudStateStore _store;

  @override
  Future<int> getCurrentStreak() async => _store.getRaw<int>('streak') ?? 0;

  @override
  Future<void> setCurrentStreak(int days) async => _store.setRaw('streak', days);

  @override
  Future<String?> getLastActiveDate() async => _store.getRaw<String>('streakLastActiveDate');

  @override
  Future<void> setLastActiveDate(String? date) async => _store.setRaw('streakLastActiveDate', date);
}
