import 'package:flutter/foundation.dart';

import '../../domain/entities/pet_character.dart';
import '../../domain/repositories/pet_character_repository.dart';

/// Quản lý nhân vật (Bunny/Mimi/Moni) bé đang chọn để chơi cùng, đọc/ghi qua
/// [PetCharacterRepository] (data layer) - cùng nguyên tắc với
/// [ProgressController]: UI không bao giờ đọc/ghi SharedPreferences trực
/// tiếp, luôn đi qua controller này.
class PetCharacterController extends ChangeNotifier {
  PetCharacterController(this._repository);

  final PetCharacterRepository _repository;

  PetCharacter _character = PetCharacter.mimi;
  bool _loaded = false;

  PetCharacter get character => _character;
  bool get loaded => _loaded;

  Future<void> load() async {
    _character = await _repository.getSelected();
    _loaded = true;
    notifyListeners();
  }

  Future<void> select(PetCharacter character) async {
    if (_character == character) return;
    _character = character;
    notifyListeners();
    await _repository.setSelected(character);
  }
}
