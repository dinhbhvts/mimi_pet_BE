import '../entities/pet_character.dart';
import '../entities/pet_palette.dart';

/// Lưu/đọc màu bé đang chọn cho thú cưng - RIÊNG CHO TỪNG NHÂN VẬT
/// (2026-08-22: trước đây chỉ 1 màu dùng chung cho cả 3 con, giờ mỗi nhân
/// vật nhớ màu của chính nó, xem doc comment `defaultPaletteFor` trong
/// `pet_palette.dart`). Cùng nguyên tắc với [PetCharacterRepository]: domain
/// chỉ biết interface, không biết lưu bằng SharedPreferences hay gì khác
/// (xem `data/repositories/local_pet_palette_repository.dart`).
abstract class PetPaletteRepository {
  Future<PetPalette> getSelected(PetCharacter character);
  Future<void> setSelected(PetCharacter character, PetPalette palette);
}
