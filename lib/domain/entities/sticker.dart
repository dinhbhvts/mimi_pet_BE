import 'package:flutter/foundation.dart';

/// Độ hiếm của sticker đặc biệt - quyết định xác suất rơi ra khi thắng minigame.
enum StickerRarity { common, rare, legendary }

extension StickerRarityInfo on StickerRarity {
  /// Trọng số khi bốc ngẫu nhiên (common ra nhiều nhất).
  int get weight => switch (this) {
        StickerRarity.common => 6,
        StickerRarity.rare => 3,
        StickerRarity.legendary => 1,
      };

  String get label => switch (this) {
        StickerRarity.common => 'Thường',
        StickerRarity.rare => 'Hiếm',
        StickerRarity.legendary => 'Huyền thoại',
      };
}

/// Sticker đặc biệt - KHÔNG gắn với từ vựng (sticker từ vựng lấy từ các từ bé
/// đã thuộc, xem `StickerAlbumScreen`), chỉ nhận được khi thắng minigame.
@immutable
class SpecialSticker {
  final String id;
  final String emoji;
  final String nameEn;
  final String nameVi;
  final StickerRarity rarity;

  const SpecialSticker(this.id, this.emoji, this.nameEn, this.nameVi, this.rarity);

  static const List<SpecialSticker> all = [
    SpecialSticker('panda', '🐼', 'panda', 'gấu trúc', StickerRarity.common),
    SpecialSticker('koala', '🐨', 'koala', 'gấu túi', StickerRarity.common),
    SpecialSticker('hamster', '🐹', 'hamster', 'chuột hamster', StickerRarity.common),
    SpecialSticker('flamingo', '🦩', 'flamingo', 'hồng hạc', StickerRarity.common),
    SpecialSticker('chick', '🐥', 'baby chick', 'gà con', StickerRarity.common),
    SpecialSticker('llama', '🦙', 'llama', 'lạc đà không bướu', StickerRarity.common),
    SpecialSticker('hippo', '🦛', 'hippo', 'hà mã', StickerRarity.common),
    SpecialSticker('rhino', '🦏', 'rhino', 'tê giác', StickerRarity.common),
    SpecialSticker('donut', '🍩', 'donut', 'bánh vòng', StickerRarity.common),
    SpecialSticker('cupcake', '🧁', 'cupcake', 'bánh cupcake', StickerRarity.common),
    SpecialSticker('lollipop', '🍭', 'lollipop', 'kẹo mút', StickerRarity.common),
    SpecialSticker('popcorn', '🍿', 'popcorn', 'bỏng ngô', StickerRarity.common),
    SpecialSticker('sparkle_heart', '💖', 'sparkling heart', 'trái tim lấp lánh', StickerRarity.common),
    SpecialSticker('four_leaf', '🍀', 'lucky clover', 'cỏ bốn lá', StickerRarity.common),
    SpecialSticker('carousel', '🎠', 'carousel', 'vòng quay ngựa gỗ', StickerRarity.common),
    SpecialSticker('sunflower', '🌻', 'sunflower', 'hoa hướng dương', StickerRarity.common),
    SpecialSticker('peacock', '🦚', 'peacock', 'chim công', StickerRarity.rare),
    SpecialSticker('otter', '🦦', 'otter', 'rái cá', StickerRarity.rare),
    SpecialSticker('sloth', '🦥', 'sloth', 'con lười', StickerRarity.rare),
    SpecialSticker('ghost', '👻', 'friendly ghost', 'con ma thân thiện', StickerRarity.rare),
    SpecialSticker('alien', '👽', 'alien', 'người ngoài hành tinh', StickerRarity.rare),
    SpecialSticker('ufo', '🛸', 'UFO', 'đĩa bay', StickerRarity.rare),
    SpecialSticker('volcano', '🌋', 'volcano', 'núi lửa', StickerRarity.rare),
    SpecialSticker('crystal_ball', '🔮', 'crystal ball', 'quả cầu pha lê', StickerRarity.rare),
    SpecialSticker('shooting_star', '🌠', 'shooting star', 'sao băng', StickerRarity.rare),
    SpecialSticker('ferris_wheel', '🎡', 'Ferris wheel', 'vòng đu quay', StickerRarity.rare),
    SpecialSticker('crocodile', '🐊', 'crocodile', 'cá sấu', StickerRarity.rare),
    SpecialSticker('unicorn', '🦄', 'unicorn', 'kỳ lân', StickerRarity.legendary),
    SpecialSticker('dragon', '🐉', 'dragon', 'rồng', StickerRarity.legendary),
    SpecialSticker('trex', '🦖', 'T-rex', 'khủng long bạo chúa', StickerRarity.legendary),
    SpecialSticker('dino', '🦕', 'long-neck dinosaur', 'khủng long cổ dài', StickerRarity.legendary),
    SpecialSticker('fairy', '🧚', 'fairy', 'nàng tiên', StickerRarity.legendary),
    SpecialSticker('mermaid', '🧜‍♀️', 'mermaid', 'nàng tiên cá', StickerRarity.legendary),
    SpecialSticker('glowing_star', '🌟', 'glowing star', 'ngôi sao phát sáng', StickerRarity.legendary),
  ];

  static SpecialSticker? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}
