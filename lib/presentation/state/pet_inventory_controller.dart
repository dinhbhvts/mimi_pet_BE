import 'package:flutter/foundation.dart';

import '../../domain/entities/pet_accessory.dart';
import '../../domain/repositories/pet_inventory_repository.dart';

/// Quản lý phụ kiện bé ĐANG MẶC cho thú cưng (tối đa 1 món/vị trí), đọc/ghi
/// qua [PetInventoryRepository]. KHÔNG tự biết món nào đã "mở khoá" - việc đó
/// do UI (Rewards) tự so `PetAccessoryInfo.unlockStars` với
/// `ProgressController.stars` rồi mới cho phép gọi [equip] - controller này
/// chỉ lo phần "đang mặc gì", giữ đúng nguyên tắc 1 controller/1 trách nhiệm
/// như các controller khác trong app.
class PetInventoryController extends ChangeNotifier {
  PetInventoryController(this._repository);

  final PetInventoryRepository _repository;

  PetAccessoryId? _head;
  PetAccessoryId? _neck;
  bool _loaded = false;

  bool get loaded => _loaded;
  PetAccessoryId? get equippedHead => _head;
  PetAccessoryId? get equippedNeck => _neck;

  PetAccessoryId? equippedFor(AccessorySlot slot) =>
      slot == AccessorySlot.head ? _head : _neck;

  Future<void> load() async {
    _head = await _repository.getEquipped(AccessorySlot.head);
    _neck = await _repository.getEquipped(AccessorySlot.neck);
    _loaded = true;
    notifyListeners();
  }

  /// Mặc [id] vào đúng vị trí của nó (tự cởi món cũ ở vị trí đó nếu có).
  /// Bấm lại đúng món ĐANG mặc sẽ CỞI RA (toggle) - xem `RewardsScreen`.
  Future<void> equip(PetAccessoryId id) async {
    final info = PetAccessoryInfo.all[id]!;
    final current = equippedFor(info.slot);
    final next = current == id ? null : id;
    if (info.slot == AccessorySlot.head) {
      _head = next;
    } else {
      _neck = next;
    }
    notifyListeners();
    await _repository.setEquipped(info.slot, next);
  }

  /// Cởi hết phụ kiện đang mặc - dùng khi bé "làm lại từ đầu" ở Settings, để
  /// không còn hiển thị món đã mở khoá bằng số sao vừa bị xoá (xem
  /// `SettingsScreen._confirmReset`).
  Future<void> resetEquipped() async {
    _head = null;
    _neck = null;
    notifyListeners();
    await _repository.setEquipped(AccessorySlot.head, null);
    await _repository.setEquipped(AccessorySlot.neck, null);
  }
}
