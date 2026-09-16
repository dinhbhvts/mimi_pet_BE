import 'package:flutter/foundation.dart';

import '../../domain/entities/pet_character.dart';
import '../../domain/entities/pet_palette.dart';
import '../../domain/repositories/pet_palette_repository.dart';

/// Quản lý màu bé đang chọn cho thú cưng, đọc/ghi qua [PetPaletteRepository]
/// (data layer) - cùng nguyên tắc với [PetCharacterController]: UI không
/// bao giờ đọc/ghi SharedPreferences trực tiếp, luôn đi qua controller này.
///
/// TỪ 2026-08-22: mỗi nhân vật (Bunny/Mimi/Moni) nhớ màu CỦA RIÊNG NÓ (trước
/// đây chỉ có 1 màu dùng chung cho cả 3 con) - đổi nhân vật không mất màu đã
/// chọn cho nhân vật kia, và nhân vật nào cũng có 1 màu "gu riêng" mặc định
/// (xem [defaultPaletteFor]) ngay cả khi bé chưa từng tự chọn màu cho nó.
class PetPaletteController extends ChangeNotifier {
  PetPaletteController(this._repository);

  final PetPaletteRepository _repository;

  final Map<PetCharacter, PetPalette> _palettes = {};
  bool _loaded = false;

  bool get loaded => _loaded;

  /// Màu hiện tại của [character] - trả về màu mặc định riêng của nhân vật
  /// đó (xem `pet_palette.dart`) nếu bé chưa từng tự chọn màu khác.
  PetPalette paletteFor(PetCharacter character) => _palettes[character] ?? defaultPaletteFor(character);

  Future<void> load() async {
    for (final character in PetCharacter.values) {
      _palettes[character] = await _repository.getSelected(character);
    }
    _loaded = true;
    notifyListeners();
  }

  /// Đổi màu cho RIÊNG [character] - không ảnh hưởng màu của 2 nhân vật còn
  /// lại.
  Future<void> select(PetCharacter character, PetPalette palette) async {
    if (_palettes[character] == palette) return;
    _palettes[character] = palette;
    notifyListeners();
    await _repository.setSelected(character, palette);
  }
}
