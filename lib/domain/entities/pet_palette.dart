import 'package:flutter/material.dart';

import 'pet_character.dart';

/// Bảng màu (lông/mai) mà bé có thể chọn cho thú cưng - áp dụng CHUNG cho cả
/// 3 nhân vật (đổi nhân vật không mất lựa chọn màu, đổi màu không mất lựa
/// chọn nhân vật - 2 lựa chọn độc lập nhau). Mỗi [PetPalette] map sang 1 bộ
/// màu cụ thể RIÊNG cho từng nhân vật (mèo trắng khác thỏ trắng khác rùa
/// trắng...), xem bảng màu trong `pet_character_painters.dart`.
enum PetPalette { classic, snow, sky, mint, blossom }

/// Thông tin hiển thị cho từng [PetPalette] - dùng cho hàng chọn màu ở Home
/// (chấm tròn màu [swatch] + tên [displayName]).
class PetPaletteInfo {
  final PetPalette id;
  final String displayName;
  final Color swatch;

  const PetPaletteInfo({required this.id, required this.displayName, required this.swatch});

  static const Map<PetPalette, PetPaletteInfo> all = {
    PetPalette.classic: PetPaletteInfo(id: PetPalette.classic, displayName: 'Gốc', swatch: Color(0xFFFFB6C1)),
    PetPalette.snow: PetPaletteInfo(id: PetPalette.snow, displayName: 'Trắng', swatch: Color(0xFFF2F2F2)),
    PetPalette.sky: PetPaletteInfo(id: PetPalette.sky, displayName: 'Da trời', swatch: Color(0xFFAEE3F5)),
    PetPalette.mint: PetPaletteInfo(id: PetPalette.mint, displayName: 'Bạc hà', swatch: Color(0xFFB7ECD0)),
    PetPalette.blossom: PetPaletteInfo(id: PetPalette.blossom, displayName: 'Hồng phấn', swatch: Color(0xFFFFC1E0)),
  };
}

/// MÀU MẶC ĐỊNH RIÊNG CHO TỪNG NHÂN VẬT (2026-08-22, theo yêu cầu người
/// dùng): trước đây cả 3 nhân vật dùng chung 1 màu mặc định "classic". Giờ
/// mỗi nhân vật có màu "gu riêng" khi bé CHƯA từng tự đổi màu cho nó - Thỏ
/// hồng phấn, Mèo trắng, Rùa da trời (nhân vật mặc định khi mở app vẫn là
/// Mèo - KHÔNG đổi, xem [PetCharacterController]). Bé vẫn có thể tự chọn
/// màu khác cho từng nhân vật bất cứ lúc nào qua hàng chấm màu ở Home - lựa
/// chọn được nhớ RIÊNG cho từng nhân vật (xem [PetPaletteController]).
///
/// THÊM (2026-08-23): Sóc Ran mặc định **nâu** và Chim cánh cụt Pingo mặc
/// định **đen** - với 2 nhân vật này, `PetPalette.classic` ("Gốc") CHÍNH LÀ
/// màu nâu/đen đó (xem `squirrelPaletteColors`/`penguinPaletteColors` trong
/// `pet_character_painters.dart`), nên chỉ cần trỏ về `classic` như màu mặc
/// định, không cần thêm giá trị `PetPalette` mới.
const Map<PetCharacter, PetPalette> defaultPaletteByCharacter = {
  PetCharacter.bunny: PetPalette.blossom,
  PetCharacter.mimi: PetPalette.snow,
  PetCharacter.moni: PetPalette.sky,
  PetCharacter.squirrel: PetPalette.classic,
  PetCharacter.penguin: PetPalette.classic,
};

/// Màu mặc định của [character] khi bé chưa từng tự chọn màu khác cho nó.
PetPalette defaultPaletteFor(PetCharacter character) =>
    defaultPaletteByCharacter[character] ?? PetPalette.classic;
