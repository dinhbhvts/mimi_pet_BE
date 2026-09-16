import '../entities/child_avatar.dart';

/// Interface lưu/đọc avatar của BÉ (không phải thú cưng) - implementation
/// thật đồng bộ qua backend, xem `CloudChildAvatarRepository`.
abstract class ChildAvatarRepository {
  Future<ChildAvatar> getAvatar();

  Future<void> setAvatar(ChildAvatar avatar);
}
