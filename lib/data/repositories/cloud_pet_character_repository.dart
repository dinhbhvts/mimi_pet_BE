import '../../domain/entities/pet_character.dart';
import '../../domain/repositories/pet_character_repository.dart';
import '../../services/cloud_state_store.dart';

/// Implementation của [PetCharacterRepository] qua [CloudStateStore].
class CloudPetCharacterRepository implements PetCharacterRepository {
  CloudPetCharacterRepository(this._store);

  final CloudStateStore _store;

  @override
  Future<PetCharacter> getSelected() async {
    final raw = _store.getRaw<String>('selectedCharacter');
    return PetCharacter.values.firstWhere(
      (c) => c.name == raw,
      orElse: () => PetCharacter.mimi,
    );
  }

  @override
  Future<void> setSelected(PetCharacter character) async => _store.setRaw('selectedCharacter', character.name);
}
