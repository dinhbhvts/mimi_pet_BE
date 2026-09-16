import '../../domain/repositories/hearts_repository.dart';
import '../../services/cloud_state_store.dart';

/// Implementation của [HeartsRepository] qua [CloudStateStore] - cùng
/// nguyên tắc với [CloudProgressRepository].
class CloudHeartsRepository implements HeartsRepository {
  CloudHeartsRepository(this._store);

  final CloudStateStore _store;

  @override
  Future<int> getHearts() async =>
      // Chưa từng lưu -> coi như mới đăng nhập, đầy tim. Đồng bộ với
      // `HeartsController.maxHearts`.
      _store.getRaw<int>('hearts') ?? 10;

  @override
  Future<void> setHearts(int hearts) async => _store.setRaw('hearts', hearts);

  @override
  Future<DateTime?> getLastLostAt() async {
    final raw = _store.getRaw<String>('heartsLastLostAt');
    return raw == null ? null : DateTime.tryParse(raw);
  }

  @override
  Future<void> setLastLostAt(DateTime? time) async =>
      _store.setRaw('heartsLastLostAt', time?.toIso8601String());
}
