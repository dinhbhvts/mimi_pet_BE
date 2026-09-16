import '../../domain/entities/pet_character.dart';
import '../../domain/entities/pet_palette.dart';
import '../../domain/repositories/pet_palette_repository.dart';
import '../../services/cloud_state_store.dart';

/// Implementation của [PetPaletteRepository] qua [CloudStateStore] - MỖI
/// NHÂN VẬT có 1 entry riêng trong map con `selectedPaletteByCharacter` (giữ
/// đúng hành vi bản cũ `LocalPetPaletteRepository`: đổi màu cho nhân vật này
/// không ảnh hưởng màu đã chọn cho nhân vật khác).
class CloudPetPaletteRepository implements PetPaletteRepository {
  CloudPetPaletteRepository(this._store);

  final CloudStateStore _store;
  static const _key = 'selectedPaletteByCharacter';

  @override
  Future<PetPalette> getSelected(PetCharacter character) async {
    final raw = _store.getMap(_key)[character.name] as String?;
    if (raw == null) return defaultPaletteFor(character);
    return PetPalette.values.firstWhere(
      (p) => p.name == raw,
      orElse: () => defaultPaletteFor(character),
    );
  }

  @override
  Future<void> setSelected(PetCharacter character, PetPalette palette) async =>
      _store.setMapEntry(_key, character.name, palette.name);
}
