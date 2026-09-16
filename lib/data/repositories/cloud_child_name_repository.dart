import '../../domain/repositories/child_name_repository.dart';
import '../../services/cloud_state_store.dart';

/// Implementation của [ChildNameRepository] qua [CloudStateStore].
class CloudChildNameRepository implements ChildNameRepository {
  CloudChildNameRepository(this._store);

  final CloudStateStore _store;

  @override
  Future<String?> getName() async {
    final value = _store.getRaw<String>('childName');
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  @override
  Future<void> setName(String? name) async {
    final trimmed = name?.trim();
    _store.setRaw('childName', (trimmed == null || trimmed.isEmpty) ? null : trimmed);
  }
}
