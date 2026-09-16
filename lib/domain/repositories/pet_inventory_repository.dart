import '../entities/pet_accessory.dart';

/// Lưu/đọc phụ kiện bé ĐANG MẶC cho thú cưng, theo từng vị trí ([AccessorySlot]
/// - mỗi vị trí tối đa 1 món). KHÔNG lưu "đã mở khoá món nào" - trạng thái mở
/// khoá luôn được TÍNH LẠI từ số sao hiện tại (xem
/// `PetAccessoryInfo.unlockStars`) so với [ProgressController.stars], tránh
/// 2 nguồn dữ liệu có thể lệch nhau. Cùng nguyên tắc tách interface/implementation
/// với các repository khác trong app (xem `pet_character_repository.dart`).
abstract class PetInventoryRepository {
  Future<PetAccessoryId?> getEquipped(AccessorySlot slot);
  Future<void> setEquipped(AccessorySlot slot, PetAccessoryId? id);
}
