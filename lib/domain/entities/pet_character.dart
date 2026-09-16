/// Các nhân vật thú cưng bé có thể chọn để chơi cùng. Đổi nhân vật KHÔNG đổi
/// tính cách/luồng học (vẫn cùng 1 [PetMood], cùng bộ câu hỏi...) - chỉ đổi
/// hình vẽ + tên gọi hiển thị, xem `pet_character_painters.dart`.
///
/// THÊM (2026-08-23): `squirrel` (sóc Ran) và `penguin` (chim cánh cụt
/// Pingo) - xem `SquirrelPainter`/`PenguinPainter` trong
/// `pet_character_painters.dart`. Giống Moni, Pingo KHÔNG có "tai" để kéo
/// (chạm vào luôn tính là chạm THÂN) - xem `_earLeftHitBox`/`_earRightHitBox`.
enum PetCharacter { bunny, mimi, moni, squirrel, penguin }

/// Thông tin hiển thị (tên, emoji) cho từng [PetCharacter] - dùng chung cho
/// cả UI chọn nhân vật lẫn câu thoại (vd "Hi! I'm ${info.displayName}!").
class PetCharacterInfo {
  final PetCharacter id;
  final String displayName;
  final String emoji;

  const PetCharacterInfo({required this.id, required this.displayName, required this.emoji});

  static const Map<PetCharacter, PetCharacterInfo> all = {
    PetCharacter.bunny: PetCharacterInfo(id: PetCharacter.bunny, displayName: 'Bunny', emoji: '🐰'),
    PetCharacter.mimi: PetCharacterInfo(id: PetCharacter.mimi, displayName: 'Mimi', emoji: '🐱'),
    PetCharacter.moni: PetCharacterInfo(id: PetCharacter.moni, displayName: 'Moni', emoji: '🐢'),
    PetCharacter.squirrel: PetCharacterInfo(id: PetCharacter.squirrel, displayName: 'Ran', emoji: '🐿️'),
    PetCharacter.penguin: PetCharacterInfo(id: PetCharacter.penguin, displayName: 'Pingo', emoji: '🐧'),
  };
}
