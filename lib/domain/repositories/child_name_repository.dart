/// Interface lưu/đọc TÊN RIÊNG của bé (khác avatar - xem
/// `child_avatar_repository.dart`) - dùng để thú cưng gọi tên bé khi tương
/// tác (Chat, Home...) thay vì chỉ xưng hô chung chung. Implementation thật
/// đồng bộ qua backend, xem `CloudChildNameRepository`.
///
/// CẬP NHẬT (2026-09-16): app giờ ĐÃ có đăng nhập (username + mật khẩu, xem
/// `AuthService`) - tên bé được lưu THEO TỪNG TÀI KHOẢN (mỗi tài khoản 1
/// dòng `profile_states` riêng phía backend), đúng như ghi chú cũ ở đây đã
/// dự tính.
abstract class ChildNameRepository {
  /// null nghĩa là bé/phụ huynh CHƯA từng đặt tên riêng - lúc đó thú cưng
  /// dùng cách xưng hô chung chung (xem `ChildNameController.displayName`).
  Future<String?> getName();

  /// Truyền null để XOÁ tên đã đặt (quay lại xưng hô chung chung).
  Future<void> setName(String? name);
}
