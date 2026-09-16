import '../../domain/entities/pet_accessory.dart';
import '../../domain/repositories/pet_inventory_repository.dart';
import '../../services/cloud_state_store.dart';

/// Implementation của [PetInventoryRepository] qua [CloudStateStore] - 1
/// entry riêng cho mỗi vị trí ([AccessorySlot.head]/[AccessorySlot.neck])
/// trong map con `equippedBySlot`.
class CloudPetInventoryRepository implements PetInventoryRepository {
  CloudPetInventoryRepository(this._store);

  final CloudStateStore _store;
  static const _key = 'equippedBySlot';

  @override
  Future<PetAccessoryId?> getEquipped(AccessorySlot slot) async {
    final raw = _store.getMap(_key)[slot.name] as String?;
    if (raw == null) return null;
    for (final id in PetAccessoryId.values) {
      if (id.name == raw) return id;
    }
    return null;
  }

  @override
  Future<void> setEquipped(AccessorySlot slot, PetAccessoryId? id) async =>
      _store.setMapEntry(_key, slot.name, id?.name);
}
