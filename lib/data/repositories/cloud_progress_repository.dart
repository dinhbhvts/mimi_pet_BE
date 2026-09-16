import '../../domain/repositories/progress_repository.dart';
import '../../services/cloud_state_store.dart';

/// Implementation của [ProgressRepository] đọc/ghi qua [CloudStateStore]
/// (đồng bộ backend, xem file đó) - THAY cho bản cũ đọc thẳng
/// `SharedPreferences` (`LocalProgressRepository`), để tiến độ của bé đồng
/// bộ được giữa web và app di động.
class CloudProgressRepository implements ProgressRepository {
  CloudProgressRepository(this._store);

  final CloudStateStore _store;

  @override
  Future<int> getStars() async => _store.getRaw<int>('stars') ?? 0;

  @override
  Future<int> addStars(int amount) async {
    final updated = (_store.getRaw<int>('stars') ?? 0) + amount;
    _store.setRaw('stars', updated);
    return updated;
  }

  @override
  Future<Set<String>> getMasteredWordIds() async {
    final raw = _store.getRaw<List<dynamic>>('masteredWordIds') ?? const [];
    return raw.map((e) => e.toString()).toSet();
  }

  @override
  Future<void> markWordMastered(String wordId) async {
    final current = await getMasteredWordIds();
    current.add(wordId);
    _store.setRaw('masteredWordIds', current.toList());
  }

  @override
  Future<void> resetProgress() async {
    _store.setRaw('stars', 0);
    _store.setRaw('masteredWordIds', <String>[]);
  }
}
