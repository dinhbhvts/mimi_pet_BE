import '../entities/pet_character.dart';

/// Lưu/đọc nhân vật bé đang chọn. Cùng nguyên tắc với [ProgressRepository]:
/// domain chỉ biết interface, không biết lưu bằng SharedPreferences hay gì
/// khác (xem `data/repositories/local_pet_character_repository.dart`).
abstract class PetCharacterRepository {
  Future<PetCharacter> getSelected();
  Future<void> setSelected(PetCharacter character);
}
