import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/entities/pet_accessory.dart';
import '../../domain/entities/pet_character.dart';
import 'mimi_painter.dart';

/// Vẽ phụ kiện (mũ/vòng hoa/khăn/nơ...) ĐÈ LÊN thú cưng, SAU KHI đã vẽ xong
/// nhân vật (xem `PetCharacterPainter.paint` trong `pet_character_painters.dart`).
///
/// Thay vì vẽ riêng từng phụ kiện cho từng nhân vật (3 lần công sức), dùng
/// chung 1 hình vẽ cho mỗi phụ kiện rồi chỉ đổi "điểm neo" (anchor - vị trí
/// đầu/cổ) theo từng nhân vật, xem [_headAnchor]/[_neckAnchor]. Toạ độ nằm
/// trong CÙNG khung tham chiếu `petCharacterReferenceSize = 220` mà 3 painter
/// nhân vật đang dùng (xem `pet_character_painters.dart`).
///
/// LƯU Ý QUAN TRỌNG: toạ độ neo dưới đây là ước lượng dựa theo công thức
/// hình học của từng nhân vật (không có cách xem app Flutter thật chạy trong
/// môi trường này để canh chỉnh bằng mắt) - nếu bé/phụ huynh build thử thấy
/// phụ kiện lệch (đè lên mắt/tai, trôi ra ngoài đầu...), gửi ảnh chụp màn
/// hình lại để chỉnh chính xác toạ độ trong lần sau.
void paintPetAccessories(
  Canvas canvas,
  PetCharacter character,
  MimiPose pose, {
  PetAccessoryId? headAccessory,
  PetAccessoryId? neckAccessory,
}) {
  if (neckAccessory != null) {
    _paintNeckAccessory(canvas, neckAccessory, _neckAnchor(character, pose));
  }
  // Vẽ đầu SAU cổ - phòng trường hợp 2 anchor gần nhau, phụ kiện đầu (mũ...)
  // luôn nằm trên/trước phụ kiện cổ (khăn/nơ) cho đúng thứ tự lớp tự nhiên.
  if (headAccessory != null) {
    _paintHeadAccessory(canvas, headAccessory, _headAnchor(character, pose));
  }
}

/// Điểm neo TRÊN ĐỈNH ĐẦU của từng nhân vật (nơi đặt mũ/vòng hoa/vương miện).
Offset _headAnchor(PetCharacter character, MimiPose pose) {
  switch (character) {
    case PetCharacter.bunny:
      // Đầu thỏ: hình tròn tâm (110, 120) bán kính 50 (xem BunnyPainter).
      return const Offset(110, 66);
    case PetCharacter.mimi:
      // Đầu mèo: hình oval tâm (110, 120) cao 75 (xem MimiCatPainter) - tai
      // tam giác mọc cao hơn 2 bên nên mũ đặt hơi thấp hơn thỏ để tránh chen
      // vào giữa 2 tai.
      return const Offset(110, 78);
    case PetCharacter.moni:
      // Đầu rùa nhô/rụt theo headYOffset (xem MoniTurtlePainter) - tâm đầu
      // (110, 95 + headYOffset), bán kính 32.
      final headYOffset = pose.headOffsetY * 1.6;
      return Offset(110, 68 + headYOffset);
    case PetCharacter.squirrel:
      // Đầu sóc: hình tròn tâm (110, 110) bán kính 48 (xem SquirrelPainter) -
      // tương tự thỏ nhưng tai nhỏ/thấp hơn nên mũ có thể đặt gần giống thỏ.
      return const Offset(110, 68);
    case PetCharacter.penguin:
      // Đầu Pingo: hình tròn tâm (110, 65) bán kính 34 (xem PenguinPainter) -
      // không có tai nên mũ/vòng hoa có thể đặt ngay sát đỉnh đầu.
      return const Offset(110, 38);
  }
}

/// Điểm neo VÙNG CỔ của từng nhân vật (nơi đặt nơ/khăn/huy chương).
Offset _neckAnchor(PetCharacter character, MimiPose pose) {
  switch (character) {
    case PetCharacter.bunny:
      return const Offset(110, 148);
    case PetCharacter.mimi:
      return const Offset(110, 146);
    case PetCharacter.moni:
      final headYOffset = pose.headOffsetY * 1.6;
      return Offset(110, 126 + headYOffset);
    case PetCharacter.squirrel:
      return const Offset(110, 150);
    case PetCharacter.penguin:
      // Vùng ngực trên, ngay dưới đầu, phía trước bụng trắng.
      return const Offset(110, 98);
  }
}

void _paintHeadAccessory(Canvas canvas, PetAccessoryId id, Offset anchor) {
  switch (id) {
    case PetAccessoryId.partyHat:
      _paintPartyHat(canvas, anchor);
      break;
    case PetAccessoryId.flowerCrown:
      _paintFlowerCrown(canvas, anchor);
      break;
    case PetAccessoryId.crown:
      _paintCrown(canvas, anchor);
      break;
    case PetAccessoryId.bowTie:
    case PetAccessoryId.scarf:
    case PetAccessoryId.medal:
      break; // Không phải phụ kiện đầu - không vẽ ở đây.
  }
}

void _paintNeckAccessory(Canvas canvas, PetAccessoryId id, Offset anchor) {
  switch (id) {
    case PetAccessoryId.bowTie:
      _paintBowTie(canvas, anchor);
      break;
    case PetAccessoryId.scarf:
      _paintScarf(canvas, anchor);
      break;
    case PetAccessoryId.medal:
      _paintMedal(canvas, anchor);
      break;
    case PetAccessoryId.partyHat:
    case PetAccessoryId.flowerCrown:
    case PetAccessoryId.crown:
      break; // Không phải phụ kiện cổ - không vẽ ở đây.
  }
}

/// 🥳 Mũ tiệc (chóp nón + sọc + bông tròn trên đỉnh).
void _paintPartyHat(Canvas canvas, Offset anchor) {
  final hatPaint = Paint()..color = const Color(0xFFFF6F91);
  final stripePaint = Paint()
    ..color = const Color(0xFFFFD166)
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round;
  final path = Path()
    ..moveTo(anchor.dx - 24, anchor.dy + 12)
    ..lineTo(anchor.dx + 24, anchor.dy + 12)
    ..lineTo(anchor.dx, anchor.dy - 32)
    ..close();
  canvas.drawPath(path, hatPaint);
  canvas.drawLine(
    Offset(anchor.dx - 9, anchor.dy + 7),
    Offset(anchor.dx - 2, anchor.dy - 14),
    stripePaint,
  );
  canvas.drawLine(
    Offset(anchor.dx + 9, anchor.dy + 7),
    Offset(anchor.dx + 2, anchor.dy - 14),
    stripePaint,
  );
  canvas.drawCircle(Offset(anchor.dx, anchor.dy - 32), 6, Paint()..color = Colors.white);
}

/// 🌸 Vòng hoa nhỏ (5 bông rải theo đường cong ngang đỉnh đầu).
void _paintFlowerCrown(Canvas canvas, Offset anchor) {
  const petalColors = [Color(0xFFFF8FC7), Color(0xFFFFD166), Color(0xFFB7ECD0), Color(0xFFAEE3F5)];
  for (var i = 0; i < 5; i++) {
    final dx = anchor.dx - 34 + i * 17.0;
    final dy = anchor.dy - (i.isOdd ? 6 : 0);
    final color = petalColors[i % petalColors.length];
    for (var p = 0; p < 5; p++) {
      final angle = p * (pi * 2 / 5);
      canvas.drawCircle(
        Offset(dx + cos(angle) * 4.2, dy + sin(angle) * 4.2),
        3.4,
        Paint()..color = color,
      );
    }
    canvas.drawCircle(Offset(dx, dy), 2.4, Paint()..color = const Color(0xFFFFF176));
  }
}

/// 👑 Vương miện (zigzag vàng + 3 viên đá nhỏ).
void _paintCrown(Canvas canvas, Offset anchor) {
  final paint = Paint()..color = const Color(0xFFFFD700);
  final path = Path()
    ..moveTo(anchor.dx - 28, anchor.dy + 10)
    ..lineTo(anchor.dx - 28, anchor.dy - 6)
    ..lineTo(anchor.dx - 14, anchor.dy + 6)
    ..lineTo(anchor.dx, anchor.dy - 18)
    ..lineTo(anchor.dx + 14, anchor.dy + 6)
    ..lineTo(anchor.dx + 28, anchor.dy - 6)
    ..lineTo(anchor.dx + 28, anchor.dy + 10)
    ..close();
  canvas.drawPath(path, paint);
  canvas.drawCircle(Offset(anchor.dx, anchor.dy - 16), 3.6, Paint()..color = const Color(0xFFE63988));
  canvas.drawCircle(Offset(anchor.dx - 20, anchor.dy - 1), 2.6, Paint()..color = const Color(0xFF4FC3F7));
  canvas.drawCircle(Offset(anchor.dx + 20, anchor.dy - 1), 2.6, Paint()..color = const Color(0xFF4FC3F7));
}

/// 🎀 Nơ cổ (2 tam giác + nút thắt tròn ở giữa).
void _paintBowTie(Canvas canvas, Offset anchor) {
  final paint = Paint()..color = const Color(0xFFE63988);
  final left = Path()
    ..moveTo(anchor.dx - 2, anchor.dy)
    ..lineTo(anchor.dx - 18, anchor.dy - 9)
    ..lineTo(anchor.dx - 18, anchor.dy + 9)
    ..close();
  final right = Path()
    ..moveTo(anchor.dx + 2, anchor.dy)
    ..lineTo(anchor.dx + 18, anchor.dy - 9)
    ..lineTo(anchor.dx + 18, anchor.dy + 9)
    ..close();
  canvas.drawPath(left, paint);
  canvas.drawPath(right, paint);
  canvas.drawCircle(anchor, 4.5, Paint()..color = const Color(0xFFB4457A));
}

/// 🧣 Khăn quàng (dải quanh cổ + 1 đuôi khăn buông xuống).
void _paintScarf(Canvas canvas, Offset anchor) {
  final paint = Paint()..color = const Color(0xFF6FC7E8);
  final band = Rect.fromCenter(center: anchor, width: 58, height: 15);
  canvas.drawRRect(RRect.fromRectAndRadius(band, const Radius.circular(7.5)), paint);
  final tail = Path()
    ..moveTo(anchor.dx + 13, anchor.dy + 5)
    ..lineTo(anchor.dx + 21, anchor.dy + 28)
    ..lineTo(anchor.dx + 8, anchor.dy + 28)
    ..lineTo(anchor.dx + 6, anchor.dy + 5)
    ..close();
  canvas.drawPath(tail, paint);
}

/// 🏅 Huy chương (2 dải ruy băng + mặt huy chương tròn).
void _paintMedal(Canvas canvas, Offset anchor) {
  final ribbonPaint = Paint()
    ..color = const Color(0xFFE63988)
    ..strokeWidth = 8;
  canvas.drawLine(Offset(anchor.dx - 10, anchor.dy - 10), Offset(anchor.dx, anchor.dy + 6), ribbonPaint);
  canvas.drawLine(Offset(anchor.dx + 10, anchor.dy - 10), Offset(anchor.dx, anchor.dy + 6), ribbonPaint);
  canvas.drawCircle(Offset(anchor.dx, anchor.dy + 20), 13, Paint()..color = const Color(0xFFFFD700));
  canvas.drawCircle(Offset(anchor.dx, anchor.dy + 20), 8, Paint()..color = const Color(0xFFFFF3C4));
}
