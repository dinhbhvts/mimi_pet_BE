import 'package:flutter/foundation.dart';

/// Vị trí trên người thú cưng mà 1 phụ kiện chiếm - mỗi vị trí chỉ mặc được
/// TỐI ĐA 1 món cùng lúc (mặc món mới ở cùng vị trí sẽ tự cởi món cũ), giống
/// đúng cách các app "trang điểm cho pet" thường làm.
enum AccessorySlot { head, neck }

/// Danh sách phụ kiện thời trang bé có thể "mở khoá dần" bằng sao tích luỹ
/// (xem [ProgressController.stars]) rồi mặc cho thú cưng ở tab Rewards - món
/// đang mặc sẽ hiển thị luôn trên Home (và Chat/Lesson) bất kể đang chọn
/// nhân vật/màu nào (xem `pet_accessory_painter.dart` - phụ kiện vẽ ĐÈ LÊN
/// nhân vật, dùng chung hình vẽ cho cả 3 con thú).
enum PetAccessoryId { bowTie, partyHat, scarf, flowerCrown, crown, medal }

/// Thông tin hiển thị + điều kiện mở khoá của 1 phụ kiện.
@immutable
class PetAccessoryInfo {
  final PetAccessoryId id;
  final AccessorySlot slot;
  final String displayName;

  /// Emoji minh hoạ dùng cho thẻ trong "Cửa hàng phụ kiện" (KHÔNG phải hình
  /// vẽ thật lên thú cưng - hình vẽ thật xem `pet_accessory_painter.dart`).
  final String emoji;

  /// Số sao tích luỹ (xem [ProgressController.stars] - CỘNG DỒN, không trừ
  /// khi tiêu) cần có để mở khoá món này.
  final int unlockStars;

  const PetAccessoryInfo({
    required this.id,
    required this.slot,
    required this.displayName,
    required this.emoji,
    required this.unlockStars,
  });

  static const Map<PetAccessoryId, PetAccessoryInfo> all = {
    PetAccessoryId.bowTie: PetAccessoryInfo(
      id: PetAccessoryId.bowTie,
      slot: AccessorySlot.neck,
      displayName: 'Nơ cổ',
      emoji: '🎀',
      unlockStars: 5,
    ),
    PetAccessoryId.partyHat: PetAccessoryInfo(
      id: PetAccessoryId.partyHat,
      slot: AccessorySlot.head,
      displayName: 'Mũ tiệc',
      emoji: '🥳',
      unlockStars: 10,
    ),
    PetAccessoryId.scarf: PetAccessoryInfo(
      id: PetAccessoryId.scarf,
      slot: AccessorySlot.neck,
      displayName: 'Khăn quàng',
      emoji: '🧣',
      unlockStars: 20,
    ),
    PetAccessoryId.flowerCrown: PetAccessoryInfo(
      id: PetAccessoryId.flowerCrown,
      slot: AccessorySlot.head,
      displayName: 'Vòng hoa',
      emoji: '🌸',
      unlockStars: 35,
    ),
    PetAccessoryId.crown: PetAccessoryInfo(
      id: PetAccessoryId.crown,
      slot: AccessorySlot.head,
      displayName: 'Vương miện',
      emoji: '👑',
      unlockStars: 50,
    ),
    PetAccessoryId.medal: PetAccessoryInfo(
      id: PetAccessoryId.medal,
      slot: AccessorySlot.neck,
      displayName: 'Huy chương',
      emoji: '🏅',
      unlockStars: 80,
    ),
  };

  /// Toàn bộ phụ kiện, sắp theo số sao cần thiết TĂNG DẦN - dùng để hiển thị
  /// "Cửa hàng phụ kiện" ở Rewards theo đúng thứ tự mở khoá.
  static List<PetAccessoryInfo> get orderedByUnlock =>
      all.values.toList()..sort((a, b) => a.unlockStars.compareTo(b.unlockStars));
}
