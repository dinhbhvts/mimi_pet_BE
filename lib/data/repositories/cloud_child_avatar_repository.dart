import '../../domain/entities/child_avatar.dart';
import '../../domain/repositories/child_avatar_repository.dart';
import '../../services/cloud_state_store.dart';

/// Implementation của [ChildAvatarRepository] qua [CloudStateStore] - lưu
/// riêng "loại" ([ChildAvatarKind]) và "giá trị" (emoji, hoặc chuỗi base64
/// của ảnh bé chọn - xem [ChildAvatarController.pickPhoto]) thành 2 key.
class CloudChildAvatarRepository implements ChildAvatarRepository {
  CloudChildAvatarRepository(this._store);

  final CloudStateStore _store;

  @override
  Future<ChildAvatar> getAvatar() async {
    final rawKind = _store.getRaw<String>('childAvatarKind');
    final value = _store.getRaw<String>('childAvatarValue');
    if (rawKind == null || value == null || value.isEmpty) {
      return ChildAvatar.fallback;
    }
    final kind = ChildAvatarKind.values.firstWhere(
      (k) => k.name == rawKind,
      orElse: () => ChildAvatarKind.emoji,
    );
    return ChildAvatar(kind: kind, value: value);
  }

  @override
  Future<void> setAvatar(ChildAvatar avatar) async {
    _store.setRaw('childAvatarKind', avatar.kind.name);
    _store.setRaw('childAvatarValue', avatar.value);
  }
}
