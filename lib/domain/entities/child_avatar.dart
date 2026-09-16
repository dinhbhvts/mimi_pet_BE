/// Cách bé chọn avatar đại diện cho MÌNH (khác với avatar của thú cưng - xem
/// `pet_avatar.dart`) - dùng để hiển thị cạnh tin nhắn của bé trong màn
/// Chat, tương tự avatar tròn nhỏ đã có sẵn cho thú cưng.
enum ChildAvatarKind { emoji, photo }

/// Avatar hiện tại của bé: hoặc 1 emoji có sẵn ([ChildAvatarKind.emoji],
/// [value] là chính ký tự emoji đó), hoặc 1 ảnh bé chọn từ máy
/// ([ChildAvatarKind.photo], [value] là chuỗi BASE64 của ảnh - xem
/// `CloudChildAvatarRepository`/`ChildAvatarController.pickPhoto`) - dùng
/// `Image.memory(base64Decode(value))` để hiển thị, chạy được trên mọi nền
/// tảng kể cả web.
class ChildAvatar {
  final ChildAvatarKind kind;
  final String value;

  const ChildAvatar({required this.kind, required this.value});

  /// Avatar mặc định khi bé chưa từng chọn gì - 1 emoji trung tính, vui vẻ.
  static const ChildAvatar fallback = ChildAvatar(kind: ChildAvatarKind.emoji, value: '🧒');

  @override
  bool operator ==(Object other) =>
      other is ChildAvatar && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);
}

/// Bộ emoji được chọn lọc sẵn cho bé chọn làm avatar trong Cài đặt - ưu tiên
/// gương mặt/nhân vật vui nhộn, thân thiện, phù hợp trẻ 8 tuổi, KHÔNG liên
/// quan tới bộ emoji nhân vật thú cưng (`PetCharacterInfo`) hay phụ kiện
/// (`PetAccessoryInfo`) đã có.
const List<String> curatedChildAvatarEmojis = [
  '🧒', '👧', '👦',
  '😊', '😎', '🤓', '🥳',
  '🦄', '🐱', '🐶', '🐼', '🦋', '🐻',
  '🌟', '🌈', '🚀',
];
