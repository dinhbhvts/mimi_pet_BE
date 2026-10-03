import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Vẽ minh hoạ cho 1 "Bài tranh" (xem `domain/entities/picture_scene.dart`)
/// bằng [CustomPainter] - PHONG CÁCH FLASHCARD ĐƠN GIẢN (hình khối cơ bản:
/// hình tròn/chữ nhật/tam giác/path đơn giản), KHÔNG chi tiết cầu kỳ như 1
/// bức tranh vẽ tay thật - vẽ cả 1 khung cảnh nhiều nhân vật/đồ vật tốn công
/// hơn NHIỀU so với vẽ 1 nhân vật thú cưng đơn lẻ (xem `pet_character_painters.dart`),
/// nên các minh hoạ này ưu tiên RÕ RÀNG/DỄ NHẬN BIẾT hơn là chi tiết mỹ thuật.
///
/// Mỗi painter vẽ theo TOẠ ĐỘ TỈ LỆ (`size.width`/`size.height` * phân số)
/// thay vì khung tham chiếu cố định như `buildPetCharacterPainter` - đơn
/// giản hơn vì các cảnh này không cần tái sử dụng animation pose chung.
class SceneIllustration extends StatelessWidget {
  final String illustrationId;

  const SceneIllustration({super.key, required this.illustrationId});

  /// Các [illustrationId] đã có hình vẽ - test kiểm tra mọi bài tranh trong
  /// `scenes.json` đều thuộc danh sách này (không rơi vào hình trống).
  static const supportedIds = {
    'park_v1', 'breakfast_v1', 'classroom_v1', 'zoo_v1', 'bedtime_v1', 'beach_v1', 'farm_v1', 'kitchen_v1',
    'garden_v1', 'birthday_v1', 'rainy_v1', 'playground_v1', 'snowy_v1',
    'market_v1', 'space_v1', 'sea_v1', 'street_v1', 'camping_v1',
  };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: CustomPaint(
          painter: _painterFor(illustrationId),
          child: Container(),
        ),
      ),
    );
  }

  CustomPainter _painterFor(String id) {
    switch (id) {
      case 'park_v1':
        return _ParkScenePainter();
      case 'breakfast_v1':
        return _BreakfastScenePainter();
      case 'classroom_v1':
        return _ClassroomScenePainter();
      case 'zoo_v1':
        return _ZooScenePainter();
      case 'bedtime_v1':
        return _BedtimeScenePainter();
      case 'beach_v1':
        return _BeachScenePainter();
      case 'farm_v1':
        return _FarmScenePainter();
      case 'kitchen_v1':
        return _KitchenScenePainter();
      case 'garden_v1':
        return _GardenScenePainter();
      case 'birthday_v1':
        return _BirthdayScenePainter();
      case 'rainy_v1':
        return _RainyScenePainter();
      case 'playground_v1':
        return _PlaygroundScenePainter();
      case 'snowy_v1':
        return _SnowyScenePainter();
      case 'market_v1':
        return _MarketScenePainter();
      case 'space_v1':
        return _SpaceScenePainter();
      case 'sea_v1':
        return _SeaScenePainter();
      case 'street_v1':
        return _StreetScenePainter();
      case 'camping_v1':
        return _CampingScenePainter();
      default:
        return _UnknownScenePainter();
    }
  }
}

// ---------------------------------------------------------------------------
// Helper vẽ dùng chung giữa nhiều scene - hình khối cơ bản, tham số hoá bằng
// tâm + kích thước để dễ đặt vị trí theo tỉ lệ khung hình.
// ---------------------------------------------------------------------------

void _drawSun(Canvas canvas, Offset center, double radius, Color color) {
  final paint = Paint()..color = color;
  canvas.drawCircle(center, radius, paint);
  final rayPaint = Paint()
    ..color = color
    ..strokeWidth = radius * 0.18
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 8; i++) {
    final angle = (i / 8) * 2 * math.pi;
    final start = Offset(center.dx + radius * 1.25 * _cos(angle), center.dy + radius * 1.25 * _sin(angle));
    final end = Offset(center.dx + radius * 1.7 * _cos(angle), center.dy + radius * 1.7 * _sin(angle));
    canvas.drawLine(start, end, rayPaint);
  }
}

double _cos(double radians) => math.cos(radians);
double _sin(double radians) => math.sin(radians);

void _drawTree(Canvas canvas, Offset trunkBase, double trunkHeight, double trunkWidth, double canopyRadius, {Color canopyColor = const Color(0xFF6FBE7A)}) {
  final trunkPaint = Paint()..color = const Color(0xFF8D6748);
  final trunkRect = Rect.fromCenter(
    center: Offset(trunkBase.dx, trunkBase.dy - trunkHeight / 2),
    width: trunkWidth,
    height: trunkHeight,
  );
  canvas.drawRRect(RRect.fromRectAndRadius(trunkRect, Radius.circular(trunkWidth * 0.3)), trunkPaint);

  final canopyCenter = Offset(trunkBase.dx, trunkBase.dy - trunkHeight - canopyRadius * 0.55);
  final canopyPaint = Paint()..color = canopyColor;
  canvas.drawCircle(canopyCenter, canopyRadius, canopyPaint);
}

/// Vẽ 1 người đơn giản: đầu tròn + thân hình chữ nhật bo góc (áo) - dùng
/// chung cho bé trai/giáo viên/phụ huynh/khách tham quan, chỉ khác màu áo.
void _drawSimplePerson(
  Canvas canvas,
  Offset feetPosition,
  double height, {
  required Color shirtColor,
  Color skinColor = const Color(0xFFFFD8B0),
  Color hairColor = const Color(0xFF4A3728),
}) {
  final headRadius = height * 0.16;
  final bodyHeight = height * 0.5;
  final legHeight = height * 0.34;

  final legTop = feetPosition.dy - legHeight;
  final bodyTop = legTop - bodyHeight;
  final headCenter = Offset(feetPosition.dx, bodyTop - headRadius);

  // Chân (2 chữ nhật nhỏ).
  final legPaint = Paint()..color = const Color(0xFF5B4636);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(feetPosition.dx - headRadius * 0.9, legTop, headRadius * 0.7, legHeight),
      Radius.circular(headRadius * 0.2),
    ),
    legPaint,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(feetPosition.dx + headRadius * 0.2, legTop, headRadius * 0.7, legHeight),
      Radius.circular(headRadius * 0.2),
    ),
    legPaint,
  );

  // Thân (áo).
  final shirtPaint = Paint()..color = shirtColor;
  final bodyRect = Rect.fromLTWH(
    feetPosition.dx - headRadius * 1.15,
    bodyTop,
    headRadius * 2.3,
    bodyHeight,
  );
  canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, Radius.circular(headRadius * 0.5)), shirtPaint);

  // Đầu + tóc.
  final skinPaint = Paint()..color = skinColor;
  canvas.drawCircle(headCenter, headRadius, skinPaint);
  final hairPaint = Paint()..color = hairColor;
  canvas.drawArc(
    Rect.fromCircle(center: headCenter, radius: headRadius * 1.05),
    3.4,
    3.05,
    true,
    hairPaint,
  );
}

void _drawCloud(Canvas canvas, Offset center, double scale, {Color color = Colors.white}) {
  final paint = Paint()..color = color;
  canvas.drawCircle(center, 14 * scale, paint);
  canvas.drawCircle(center.translate(16 * scale, 4 * scale), 11 * scale, paint);
  canvas.drawCircle(center.translate(-16 * scale, 5 * scale), 10 * scale, paint);
  canvas.drawRect(
    Rect.fromCenter(center: center.translate(0, 8 * scale), width: 40 * scale, height: 12 * scale),
    paint,
  );
}

void _drawBird(Canvas canvas, Offset center, double scale, {Color color = const Color(0xFF4A4A4A)}) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2 * scale
    ..strokeCap = StrokeCap.round;
  final path = Path()
    ..moveTo(center.dx - 8 * scale, center.dy)
    ..quadraticBezierTo(center.dx - 3 * scale, center.dy - 6 * scale, center.dx, center.dy)
    ..quadraticBezierTo(center.dx + 3 * scale, center.dy - 6 * scale, center.dx + 8 * scale, center.dy);
  canvas.drawPath(path, paint);
}

void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
  final paint = Paint()..color = color;
  final path = Path();
  for (var i = 0; i < 8; i++) {
    final angle = (i / 8) * 2 * math.pi;
    final r = i.isEven ? radius : radius * 0.4;
    final point = Offset(center.dx + r * _cos(angle), center.dy + r * _sin(angle));
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();
  canvas.drawPath(path, paint);
}

/// Vẽ 1 gợn sóng nhỏ (path lượn sóng đơn giản) - dùng cho scene bãi biển.
void _drawWave(Canvas canvas, Offset start, double width, double amplitude, Color color) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = amplitude * 0.5
    ..strokeCap = StrokeCap.round;
  final path = Path()..moveTo(start.dx, start.dy);
  final segments = 4;
  for (var i = 0; i < segments; i++) {
    final x1 = start.dx + width * (i + 0.5) / segments;
    final y1 = start.dy + (i.isEven ? -amplitude : amplitude);
    final x2 = start.dx + width * (i + 1) / segments;
    path.quadraticBezierTo(x1, y1, x2, start.dy);
  }
  canvas.drawPath(path, paint);
}

/// Vẽ 1 bông hoa đơn giản: vài cánh tròn quanh nhuỵ + cuống - dùng cho scene
/// khu vườn.
void _drawFlower(Canvas canvas, Offset center, double petalRadius, Color petalColor, {Color centerColor = const Color(0xFFFFC94A)}) {
  final stemPaint = Paint()
    ..color = const Color(0xFF6FBE7A)
    ..strokeWidth = petalRadius * 0.4
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(center, center.translate(0, petalRadius * 3.2), stemPaint);

  final petalPaint = Paint()..color = petalColor;
  for (var i = 0; i < 5; i++) {
    final angle = (i / 5) * 2 * math.pi;
    final petalCenter = Offset(
      center.dx + petalRadius * 1.15 * _cos(angle),
      center.dy + petalRadius * 1.15 * _sin(angle),
    );
    canvas.drawCircle(petalCenter, petalRadius * 0.75, petalPaint);
  }
  canvas.drawCircle(center, petalRadius * 0.7, Paint()..color = centerColor);
}

/// Vẽ 1 quả bóng bay: hình oval + nơ nhỏ dưới đáy + dây dài - dùng cho scene
/// tiệc sinh nhật.
void _drawBalloon(Canvas canvas, Offset center, double scale, Color color) {
  final paint = Paint()..color = color;
  canvas.drawOval(
    Rect.fromCenter(center: center, width: 22 * scale, height: 28 * scale),
    paint,
  );
  final knotPath = Path()
    ..moveTo(center.dx - 3 * scale, center.dy + 14 * scale)
    ..lineTo(center.dx + 3 * scale, center.dy + 14 * scale)
    ..lineTo(center.dx, center.dy + 18 * scale)
    ..close();
  canvas.drawPath(knotPath, paint);
  final stringPaint = Paint()
    ..color = Colors.black26
    ..strokeWidth = 1.2;
  canvas.drawLine(
    Offset(center.dx, center.dy + 18 * scale),
    Offset(center.dx, center.dy + 60 * scale),
    stringPaint,
  );
}

// ---------------------------------------------------------------------------
// Scene 1: "At the Park" - bé trai thả diều, chó dưới ghế đá, 3 con chim,
// trời nắng (khớp đúng 5 câu hỏi trong scenes.json).
// ---------------------------------------------------------------------------
class _ParkScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Trời + đất.
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.72), Paint()..color = const Color(0xFFBEE7FF));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.72, w, h * 0.28), Paint()..color = const Color(0xFF9BD98A));

    _drawSun(canvas, Offset(w * 0.14, h * 0.16), w * 0.06, const Color(0xFFFFC94A));
    _drawCloud(canvas, Offset(w * 0.75, h * 0.14), w * 0.012);
    _drawBird(canvas, Offset(w * 0.45, h * 0.16), w * 0.01);
    _drawBird(canvas, Offset(w * 0.55, h * 0.1), w * 0.01);
    _drawBird(canvas, Offset(w * 0.62, h * 0.18), w * 0.01);

    // 2 cây ở 2 bên.
    _drawTree(canvas, Offset(w * 0.08, h * 0.72), h * 0.18, w * 0.03, w * 0.09);
    _drawTree(canvas, Offset(w * 0.93, h * 0.72), h * 0.16, w * 0.028, w * 0.08);

    // Ghế đá (giữa-phải) + chó NẰM DƯỚI ghế (đúng câu hỏi "dog is under the bench" = True).
    final benchCenter = Offset(w * 0.68, h * 0.78);
    final dogPaint = Paint()..color = const Color(0xFFB07A4E);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(benchCenter.dx, benchCenter.dy + h * 0.02), width: w * 0.14, height: h * 0.05),
      dogPaint,
    );
    canvas.drawCircle(Offset(benchCenter.dx - w * 0.07, benchCenter.dy + h * 0.005), w * 0.03, dogPaint);
    final benchPaint = Paint()..color = const Color(0xFF8D6748);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: benchCenter, width: w * 0.24, height: h * 0.03),
        Radius.circular(4),
      ),
      benchPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(benchCenter.dx - w * 0.11, benchCenter.dy - h * 0.11, w * 0.02, h * 0.13),
      benchPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(benchCenter.dx + w * 0.09, benchCenter.dy - h * 0.11, w * 0.02, h * 0.13),
      benchPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(benchCenter.dx, benchCenter.dy - h * 0.1), width: w * 0.24, height: h * 0.025),
        Radius.circular(4),
      ),
      benchPaint,
    );

    // Bé trai thả diều (bên trái).
    final boyFeet = Offset(w * 0.32, h * 0.92);
    _drawSimplePerson(canvas, boyFeet, h * 0.32, shirtColor: const Color(0xFF4FA8E0));

    // Dây diều + diều màu đỏ (khớp câu hỏi "color of the kite" = red).
    final handPos = Offset(boyFeet.dx + h * 0.06, boyFeet.dy - h * 0.24);
    final kiteCenter = Offset(w * 0.42, h * 0.22);
    final stringPaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1.2;
    canvas.drawLine(handPos, kiteCenter, stringPaint);

    final kitePaint = Paint()..color = const Color(0xFFE84C3D);
    final kitePath = Path()
      ..moveTo(kiteCenter.dx, kiteCenter.dy - w * 0.05)
      ..lineTo(kiteCenter.dx + w * 0.04, kiteCenter.dy)
      ..lineTo(kiteCenter.dx, kiteCenter.dy + w * 0.05)
      ..lineTo(kiteCenter.dx - w * 0.04, kiteCenter.dy)
      ..close();
    canvas.drawPath(kitePath, kitePaint);
    // Đuôi diều (vài nơ nhỏ).
    final tailPaint = Paint()
      ..color = const Color(0xFFE84C3D)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(kiteCenter.dx, kiteCenter.dy + w * 0.05),
      Offset(kiteCenter.dx - w * 0.02, kiteCenter.dy + w * 0.13),
      tailPaint,
    );
    canvas.drawCircle(Offset(kiteCenter.dx - w * 0.02, kiteCenter.dy + w * 0.13), 2.5, kitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Scene 2: "Breakfast Time" - đĩa 2 quả trứng, ly sữa, quả chuối, mẹ rót nước
// cam (khớp đúng 5 câu hỏi trong scenes.json).
// ---------------------------------------------------------------------------
class _BreakfastScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.55), Paint()..color = const Color(0xFFFFEFD6));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.55, w, h * 0.45), Paint()..color = const Color(0xFF8D6748));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.55, w, h * 0.06), Paint()..color = const Color(0xFF6F5236));

    // Đĩa + 2 quả trứng ốp la.
    final plateCenter = Offset(w * 0.32, h * 0.68);
    canvas.drawCircle(plateCenter, w * 0.16, Paint()..color = Colors.white);
    canvas.drawCircle(plateCenter, w * 0.16, Paint()
      ..color = const Color(0xFFDDDDDD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    for (final dx in [-w * 0.055, w * 0.055]) {
      final eggCenter = plateCenter.translate(dx, 0);
      canvas.drawOval(
        Rect.fromCenter(center: eggCenter, width: w * 0.09, height: w * 0.065),
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(eggCenter, w * 0.022, Paint()..color = const Color(0xFFFFC94A));
    }

    // Quả chuối (đúng câu hỏi true/false có chuối trên bàn).
    final bananaPaint = Paint()..color = const Color(0xFFFFD84A);
    final bananaPath = Path()
      ..moveTo(w * 0.55, h * 0.6)
      ..quadraticBezierTo(w * 0.66, h * 0.55, w * 0.72, h * 0.62)
      ..quadraticBezierTo(w * 0.68, h * 0.66, w * 0.6, h * 0.66)
      ..close();
    canvas.drawPath(bananaPath, bananaPaint);

    // Ly sữa (trắng, đúng câu hỏi "what is inside the glass" = milk).
    final glassRect = Rect.fromLTWH(w * 0.8, h * 0.5, w * 0.1, h * 0.16);
    canvas.drawRect(
      glassRect,
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRect(
      Rect.fromLTWH(glassRect.left + 1.5, glassRect.top + h * 0.03, glassRect.width - 3, glassRect.height - h * 0.03 - 1.5),
      Paint()..color = Colors.white,
    );

    // Mẹ đang rót nước cam vào cốc nhỏ (đúng câu hỏi "What is Mom doing?").
    final momFeet = Offset(w * 0.5, h * 0.98);
    _drawSimplePerson(canvas, momFeet, h * 0.4, shirtColor: const Color(0xFFE87FA0));
    final jugCenter = Offset(momFeet.dx + w * 0.1, momFeet.dy - h * 0.28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: jugCenter, width: w * 0.05, height: h * 0.09),
        Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFFF9F45),
    );
    final cupCenter = Offset(jugCenter.dx + w * 0.06, momFeet.dy - h * 0.05);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: cupCenter, width: w * 0.035, height: h * 0.04),
        Radius.circular(3),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawLine(
      Offset(jugCenter.dx, jugCenter.dy + h * 0.045),
      Offset(cupCenter.dx, cupCenter.dy - h * 0.02),
      Paint()
        ..color = const Color(0xFFFF9F45)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Scene 3: "In the Classroom" - cô giáo đứng cạnh bảng, đồng hồ trên tường, 2
// học sinh ngồi bàn, giá sách (khớp đúng 5 câu hỏi trong scenes.json).
// ---------------------------------------------------------------------------
class _ClassroomScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFFFF6E5));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.82, w, h * 0.18), Paint()..color = const Color(0xFFD8B98A));

    // Bảng trắng (đúng câu hỏi "who is standing next to the board").
    final boardRect = Rect.fromLTWH(w * 0.06, h * 0.12, w * 0.34, h * 0.32);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(6)),
      Paint()..color = const Color(0xFF3C6E71),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.deflate(6), const Radius.circular(4)),
      Paint()..color = const Color(0xFF4A8285),
    );

    // Đồng hồ trên tường (đúng câu hỏi "what is on the wall").
    final clockCenter = Offset(w * 0.82, h * 0.2);
    canvas.drawCircle(clockCenter, w * 0.07, Paint()..color = Colors.white);
    canvas.drawCircle(
      clockCenter,
      w * 0.07,
      Paint()
        ..color = const Color(0xFF4A4A4A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawLine(clockCenter, clockCenter.translate(0, -w * 0.045), Paint()..color = Colors.black87..strokeWidth = 2);
    canvas.drawLine(clockCenter, clockCenter.translate(w * 0.03, 0), Paint()..color = Colors.black87..strokeWidth = 2);

    // Giá sách + vài quyển sách đứng (đúng câu hỏi "where are the books").
    final shelfRect = Rect.fromLTWH(w * 0.06, h * 0.5, w * 0.16, h * 0.03);
    canvas.drawRect(shelfRect, Paint()..color = const Color(0xFF8D6748));
    final bookColors = [const Color(0xFFE84C3D), const Color(0xFF4FA8E0), const Color(0xFFFFC94A), const Color(0xFF6FBE7A)];
    for (var i = 0; i < bookColors.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(shelfRect.left + i * (w * 0.035), shelfRect.top - h * 0.11, w * 0.028, h * 0.11),
        Paint()..color = bookColors[i],
      );
    }

    // Cô giáo đứng cạnh bảng.
    _drawSimplePerson(
      canvas,
      Offset(w * 0.44, h * 0.78),
      h * 0.44,
      shirtColor: const Color(0xFFB07AD1),
      hairColor: const Color(0xFF2E2018),
    );

    // 2 học sinh ngồi bàn (đúng câu hỏi true/false có 2 học sinh).
    final deskPaint = Paint()..color = const Color(0xFFC9A46A);
    for (final dx in [w * 0.62, w * 0.82]) {
      final feet = Offset(dx, h * 0.9);
      _drawSimplePerson(canvas, feet, h * 0.28, shirtColor: const Color(0xFFFFC94A));
      canvas.drawRect(
        Rect.fromLTWH(dx - w * 0.07, h * 0.82, w * 0.14, h * 0.05),
        deskPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Scene 4: "At the Zoo" - voi (vòi dài), sư tử (đang gầm), khỉ trên cây, 2 bé
// đang xem (khớp đúng 5 câu hỏi trong scenes.json).
// ---------------------------------------------------------------------------
class _ZooScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.7), Paint()..color = const Color(0xFFCDEBFF));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.7, w, h * 0.3), Paint()..color = const Color(0xFFA9D98A));

    // Cây + khỉ ngồi trên cây (đúng câu hỏi true/false monkey in the tree).
    _drawTree(canvas, Offset(w * 0.18, h * 0.7), h * 0.16, w * 0.03, w * 0.1);
    final monkeyCenter = Offset(w * 0.18, h * 0.48);
    canvas.drawCircle(monkeyCenter, w * 0.035, Paint()..color = const Color(0xFF8D6748));
    canvas.drawCircle(monkeyCenter.translate(0, w * 0.045), w * 0.045, Paint()..color = const Color(0xFF8D6748));
    canvas.drawCircle(monkeyCenter, w * 0.02, Paint()..color = const Color(0xFFE8C39E));

    // Voi (vòi dài - đúng câu hỏi "which animal has a long trunk").
    final elephantCenter = Offset(w * 0.48, h * 0.66);
    final elephantPaint = Paint()..color = const Color(0xFFA9A9B0);
    canvas.drawOval(
      Rect.fromCenter(center: elephantCenter, width: w * 0.28, height: h * 0.22),
      elephantPaint,
    );
    final headCenter = Offset(elephantCenter.dx - w * 0.16, elephantCenter.dy - h * 0.03);
    canvas.drawCircle(headCenter, w * 0.09, elephantPaint);
    // Tai to.
    canvas.drawCircle(headCenter.translate(w * 0.03, -h * 0.03), w * 0.08, Paint()..color = const Color(0xFF8F8F98));
    // Vòi (path cong dài).
    final trunkPaint = Paint()
      ..color = elephantPaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;
    final trunkPath = Path()
      ..moveTo(headCenter.dx - w * 0.06, headCenter.dy + h * 0.02)
      ..quadraticBezierTo(
        headCenter.dx - w * 0.12,
        headCenter.dy + h * 0.09,
        headCenter.dx - w * 0.06,
        headCenter.dy + h * 0.14,
      );
    canvas.drawPath(trunkPath, trunkPaint);
    // Chân voi.
    for (final dx in [-w * 0.08, -w * 0.02, w * 0.04, w * 0.09]) {
      canvas.drawRect(
        Rect.fromLTWH(elephantCenter.dx + dx, elephantCenter.dy + h * 0.06, w * 0.03, h * 0.08),
        elephantPaint,
      );
    }

    // Sư tử đang gầm (miệng mở - đúng câu hỏi "roaring or sleeping" = Roaring).
    final lionCenter = Offset(w * 0.78, h * 0.68);
    final manePaint = Paint()..color = const Color(0xFFC9862E);
    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi;
      final p1 = Offset(lionCenter.dx + w * 0.075 * _cos(angle), lionCenter.dy + w * 0.075 * _sin(angle));
      final p2 = Offset(lionCenter.dx + w * 0.12 * _cos(angle), lionCenter.dy + w * 0.12 * _sin(angle));
      canvas.drawLine(p1, p2, Paint()..color = manePaint.color..strokeWidth = 5);
    }
    canvas.drawCircle(lionCenter, w * 0.075, Paint()..color = const Color(0xFFE8B04A));
    // Miệng mở (cung màu đỏ).
    canvas.drawArc(
      Rect.fromCenter(center: lionCenter.translate(0, w * 0.02), width: w * 0.06, height: w * 0.045),
      0.2,
      2.7,
      true,
      Paint()..color = const Color(0xFFB43C33),
    );

    // 2 bé đang xem (đúng câu hỏi true/false có 2 trẻ em xem).
    _drawSimplePerson(canvas, Offset(w * 0.35, h * 0.97), h * 0.26, shirtColor: const Color(0xFF4FA8E0));
    _drawSimplePerson(canvas, Offset(w * 0.44, h * 0.97), h * 0.24, shirtColor: const Color(0xFFE87FA0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Scene 5: "Bedtime" - bé đang ngủ, gấu bông cạnh gối, đèn ngủ đang sáng, cửa
// sổ thấy mặt trăng, sách trên tủ đầu giường (khớp đúng 5 câu hỏi).
// ---------------------------------------------------------------------------
class _BedtimeScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF2E3A6B));

    // Cửa sổ + trăng + sao (đúng câu hỏi "what can you see outside window").
    final windowRect = Rect.fromLTWH(w * 0.62, h * 0.08, w * 0.3, h * 0.32);
    canvas.drawRRect(RRect.fromRectAndRadius(windowRect, const Radius.circular(8)), Paint()..color = const Color(0xFF16204A));
    canvas.drawRRect(
      RRect.fromRectAndRadius(windowRect, const Radius.circular(8)),
      Paint()
        ..color = const Color(0xFF8D6748)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    final moonCenter = Offset(windowRect.left + windowRect.width * 0.6, windowRect.top + windowRect.height * 0.4);
    canvas.drawCircle(moonCenter, w * 0.045, Paint()..color = const Color(0xFFFFF3C4));
    canvas.drawCircle(moonCenter.translate(w * 0.02, -h * 0.01), w * 0.04, Paint()..color = const Color(0xFF16204A));
    _drawStar(canvas, Offset(windowRect.left + w * 0.03, windowRect.top + h * 0.05), w * 0.012, Colors.white);
    _drawStar(canvas, Offset(windowRect.left + w * 0.06, windowRect.top + h * 0.12), w * 0.009, Colors.white);

    // Tủ đầu giường + đèn ngủ ĐANG SÁNG (đúng câu hỏi true/false "lamp is off" = False)
    // + 1 quyển sách trên mặt tủ (đúng câu hỏi "what is on the nightstand").
    final standRect = Rect.fromLTWH(w * 0.06, h * 0.62, w * 0.16, h * 0.24);
    canvas.drawRect(standRect, Paint()..color = const Color(0xFF6F5236));
    final glowCenter = Offset(standRect.left + standRect.width / 2, standRect.top - h * 0.06);
    canvas.drawCircle(glowCenter, w * 0.09, Paint()..color = const Color(0x55FFE9A8));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: glowCenter.translate(0, h * 0.02), width: w * 0.05, height: h * 0.05),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFFFE9A8),
    );
    canvas.drawRect(
      Rect.fromCenter(center: glowCenter.translate(0, h * 0.06), width: w * 0.015, height: h * 0.04),
      Paint()..color = const Color(0xFF4A3728),
    );
    // Vẽ dày hơn (2 lớp bìa sách chồng nhẹ lên nhau + 1 gáy sách) để rõ ràng
    // là 1 QUYỂN SÁCH nằm trên tủ, không phải 1 vệt màu mờ khó nhận ra.
    final bookRect = Rect.fromLTWH(standRect.left + w * 0.015, standRect.top - h * 0.028, w * 0.09, h * 0.028);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bookRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFFE84C3D),
    );
    canvas.drawLine(
      Offset(bookRect.left + bookRect.width * 0.32, bookRect.top),
      Offset(bookRect.left + bookRect.width * 0.32, bookRect.bottom),
      Paint()
        ..color = const Color(0xFFB33327)
        ..strokeWidth = 2,
    );

    // Giường + chăn + bé đang ngủ (mắt nhắm - đúng câu hỏi "awake or asleep" = Asleep).
    final bedRect = Rect.fromLTWH(w * 0.28, h * 0.55, w * 0.5, h * 0.34);
    canvas.drawRRect(RRect.fromRectAndRadius(bedRect, const Radius.circular(10)), Paint()..color = const Color(0xFF8D6748));
    final blanketRect = Rect.fromLTWH(bedRect.left + 4, bedRect.top + h * 0.08, bedRect.width - 8, bedRect.height - h * 0.08 - 4);
    canvas.drawRRect(RRect.fromRectAndRadius(blanketRect, const Radius.circular(10)), Paint()..color = const Color(0xFF6FA8DC));

    // Gối.
    final pillowCenter = Offset(bedRect.left + w * 0.1, bedRect.top + h * 0.06);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pillowCenter, width: w * 0.14, height: h * 0.07),
        const Radius.circular(8),
      ),
      Paint()..color = Colors.white,
    );

    // Đầu bé nhô lên khỏi chăn, mắt nhắm.
    final headCenter = pillowCenter.translate(w * 0.06, -h * 0.01);
    canvas.drawCircle(headCenter, w * 0.045, Paint()..color = const Color(0xFFFFD8B0));
    final eyePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(headCenter.translate(-w * 0.015, -h * 0.005), headCenter.translate(-w * 0.005, -h * 0.005), eyePaint);
    canvas.drawLine(headCenter.translate(0.005 * w, -h * 0.005), headCenter.translate(0.015 * w, -h * 0.005), eyePaint);

    // Gấu bông NGAY CẠNH gối (đúng câu hỏi "what is next to the pillow").
    final bearCenter = pillowCenter.translate(w * 0.14, h * 0.03);
    final bearPaint = Paint()..color = const Color(0xFFB07A4E);
    canvas.drawCircle(bearCenter.translate(-w * 0.018, -w * 0.02), w * 0.012, bearPaint);
    canvas.drawCircle(bearCenter.translate(w * 0.018, -w * 0.02), w * 0.012, bearPaint);
    canvas.drawCircle(bearCenter, w * 0.028, bearPaint);
    canvas.drawCircle(bearCenter.translate(0, w * 0.035), w * 0.035, bearPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Scene 6: "At the Beach" - bé gái xây lâu đài cát, con cua trên cát, 2 vỏ sò,
// bóng biển màu đỏ, dù đang mở (khớp đúng 5 câu hỏi trong scenes.json).
// ---------------------------------------------------------------------------
class _BeachScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Trời + biển + cát.
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.5), Paint()..color = const Color(0xFFBEE7FF));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.5, w, h * 0.18), Paint()..color = const Color(0xFF4FA8E0));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.68, w, h * 0.32), Paint()..color = const Color(0xFFF2D9A0));

    _drawSun(canvas, Offset(w * 0.86, h * 0.14), w * 0.07, const Color(0xFFFFC94A));
    _drawWave(canvas, Offset(0, h * 0.56), w * 0.5, h * 0.012, Colors.white70);
    _drawWave(canvas, Offset(w * 0.5, h * 0.6), w * 0.5, h * 0.012, Colors.white70);

    // Dù bãi biển ĐANG MỞ (đúng câu hỏi "open or closed" = Open).
    final poleBase = Offset(w * 0.74, h * 0.88);
    final poleTop = Offset(w * 0.74, h * 0.44);
    canvas.drawLine(poleBase, poleTop, Paint()..color = const Color(0xFF8D6748)..strokeWidth = 3);
    final canopyRect = Rect.fromCenter(center: poleTop.translate(0, h * 0.01), width: w * 0.26, height: h * 0.16);
    final canopyPath = Path()
      ..moveTo(canopyRect.left, canopyRect.bottom)
      ..quadraticBezierTo(canopyRect.center.dx, canopyRect.top, canopyRect.right, canopyRect.bottom)
      ..close();
    canvas.drawPath(canopyPath, Paint()..color = const Color(0xFFE84C3D));
    // Viền lượn sóng ở mép dưới dù (bo tròn nhỏ) để rõ là dù đang xoè mở.
    for (var i = 0; i < 4; i++) {
      final scallopCenter = Offset(canopyRect.left + canopyRect.width * (i + 0.5) / 4, canopyRect.bottom);
      canvas.drawCircle(scallopCenter, w * 0.018, Paint()..color = Colors.white);
    }

    // Lâu đài cát (2 tháp nhỏ + 1 tháp giữa cao hơn có cờ).
    final castleBase = Offset(w * 0.28, h * 0.86);
    final castlePaint = Paint()..color = const Color(0xFFD9B873);
    canvas.drawRect(Rect.fromLTWH(castleBase.dx - w * 0.1, castleBase.dy - h * 0.1, w * 0.2, h * 0.1), castlePaint);
    canvas.drawRect(Rect.fromLTWH(castleBase.dx - w * 0.06, castleBase.dy - h * 0.18, w * 0.05, h * 0.08), castlePaint);
    canvas.drawRect(Rect.fromLTWH(castleBase.dx + w * 0.01, castleBase.dy - h * 0.18, w * 0.05, h * 0.08), castlePaint);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(castleBase.dx, castleBase.dy - h * 0.03), width: w * 0.05, height: h * 0.06),
      Paint()..color = const Color(0xFFB58A4A),
    );
    canvas.drawLine(
      Offset(castleBase.dx - w * 0.035, castleBase.dy - h * 0.18),
      Offset(castleBase.dx - w * 0.035, castleBase.dy - h * 0.24),
      Paint()..color = Colors.black45..strokeWidth = 1.5,
    );
    final flagPath = Path()
      ..moveTo(castleBase.dx - w * 0.035, castleBase.dy - h * 0.24)
      ..lineTo(castleBase.dx - w * 0.005, castleBase.dy - h * 0.22)
      ..lineTo(castleBase.dx - w * 0.035, castleBase.dy - h * 0.2)
      ..close();
    canvas.drawPath(flagPath, Paint()..color = const Color(0xFFE84C3D));

    // Xô nhỏ bên cạnh bé gái (gợi ý đang xây lâu đài).
    final girlFeet = Offset(w * 0.44, h * 0.94);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(girlFeet.dx - w * 0.02, girlFeet.dy - h * 0.06, w * 0.05, h * 0.05),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF4FA8E0),
    );
    // Bé gái đang xây lâu đài cát (đúng câu hỏi "What is the girl doing?").
    _drawSimplePerson(canvas, girlFeet, h * 0.3, shirtColor: const Color(0xFFE87FA0));

    // Bóng biển màu đỏ với 1 vệt trắng (đúng câu hỏi "color of the beach ball" = red).
    final ballCenter = Offset(w * 0.6, h * 0.82);
    canvas.drawCircle(ballCenter, w * 0.055, Paint()..color = const Color(0xFFE84C3D));
    canvas.drawArc(
      Rect.fromCenter(center: ballCenter, width: w * 0.11, height: w * 0.11),
      0.3,
      1.2,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.02,
    );

    // Con cua trên cát (đúng câu hỏi true/false "crab on the sand" = True).
    final crabCenter = Offset(w * 0.86, h * 0.9);
    final crabPaint = Paint()..color = const Color(0xFFE8703C);
    canvas.drawOval(Rect.fromCenter(center: crabCenter, width: w * 0.09, height: h * 0.045), crabPaint);
    canvas.drawCircle(crabCenter.translate(-w * 0.05, -h * 0.012), w * 0.018, crabPaint);
    canvas.drawCircle(crabCenter.translate(w * 0.05, -h * 0.012), w * 0.018, crabPaint);
    final crabLegPaint = Paint()
      ..color = crabPaint.color
      ..strokeWidth = 2;
    for (final dx in [-w * 0.03, -w * 0.01, w * 0.01, w * 0.03]) {
      canvas.drawLine(
        Offset(crabCenter.dx + dx, crabCenter.dy + h * 0.018),
        Offset(crabCenter.dx + dx * 1.4, crabCenter.dy + h * 0.035),
        crabLegPaint,
      );
    }

    // 2 vỏ sò (đúng câu hỏi "how many seashells" = Two).
    for (final dx in [-w * 0.04, w * 0.05]) {
      final shellCenter = Offset(w * 0.16 + dx, h * 0.94);
      final shellPaint = Paint()..color = const Color(0xFFFFE3D0);
      canvas.drawArc(
        Rect.fromCenter(center: shellCenter, width: w * 0.06, height: w * 0.05),
        math.pi,
        math.pi,
        true,
        shellPaint,
      );
      for (var i = 0; i <= 3; i++) {
        canvas.drawLine(
          shellCenter,
          Offset(shellCenter.dx - w * 0.03 + i * (w * 0.02), shellCenter.dy - w * 0.02),
          Paint()
            ..color = const Color(0xFFDBAF95)
            ..strokeWidth = 1,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Scene 7: "On the Farm" - bác nông dân rắc thức ăn cho 3 con gà, bò sữa, nhà
// kho màu đỏ, máy kéo đỗ cạnh nhà kho (khớp đúng 5 câu hỏi trong scenes.json).
// ---------------------------------------------------------------------------
class _FarmScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.6), Paint()..color = const Color(0xFFCDEBFF));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.6, w, h * 0.4), Paint()..color = const Color(0xFF9BD98A));
    _drawSun(canvas, Offset(w * 0.1, h * 0.14), w * 0.06, const Color(0xFFFFC94A));

    // Nhà kho màu đỏ (đúng câu hỏi true/false "barn is red" = True).
    final barnRect = Rect.fromLTWH(w * 0.06, h * 0.36, w * 0.28, h * 0.28);
    canvas.drawRect(barnRect, Paint()..color = const Color(0xFFD94F3D));
    final roofPath = Path()
      ..moveTo(barnRect.left - w * 0.02, barnRect.top)
      ..lineTo(barnRect.left + barnRect.width / 2, barnRect.top - h * 0.12)
      ..lineTo(barnRect.right + w * 0.02, barnRect.top)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = const Color(0xFF7A2E22));
    canvas.drawRect(
      Rect.fromCenter(center: Offset(barnRect.center.dx, barnRect.bottom - h * 0.08), width: w * 0.06, height: h * 0.16),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(barnRect.left + w * 0.06, barnRect.top + h * 0.08), width: w * 0.05, height: h * 0.05),
      Paint()..color = const Color(0xFFFFF3C4),
    );

    // Máy kéo đỗ ngay CẠNH nhà kho (đúng câu hỏi "where is the tractor" = Next to the barn).
    final tractorBase = Offset(barnRect.right + w * 0.12, h * 0.72);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tractorBase.dx - w * 0.09, tractorBase.dy - h * 0.09, w * 0.16, h * 0.08),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF3E8E41),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tractorBase.dx - w * 0.03, tractorBase.dy - h * 0.17, w * 0.08, h * 0.09),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF6FBE7A),
    );
    canvas.drawCircle(Offset(tractorBase.dx - w * 0.06, tractorBase.dy + h * 0.01), w * 0.045, Paint()..color = const Color(0xFF3C3C3C));
    canvas.drawCircle(Offset(tractorBase.dx + w * 0.08, tractorBase.dy + h * 0.01), w * 0.065, Paint()..color = const Color(0xFF3C3C3C));

    // Bò sữa (trắng đốm đen) đứng giữa đồng cỏ.
    final cowCenter = Offset(w * 0.45, h * 0.82);
    final cowPaint = Paint()..color = Colors.white;
    canvas.drawOval(Rect.fromCenter(center: cowCenter, width: w * 0.22, height: h * 0.14), cowPaint);
    canvas.drawCircle(cowCenter.translate(-w * 0.13, -h * 0.02), w * 0.06, cowPaint);
    canvas.drawCircle(cowCenter.translate(-w * 0.02, -h * 0.03), w * 0.03, Paint()..color = Colors.black87);
    canvas.drawCircle(cowCenter.translate(w * 0.05, h * 0.02), w * 0.025, Paint()..color = Colors.black87);
    for (final dx in [-w * 0.08, -w * 0.02, w * 0.04, w * 0.09]) {
      canvas.drawRect(Rect.fromLTWH(cowCenter.dx + dx, cowCenter.dy + h * 0.05, w * 0.025, h * 0.07), Paint()..color = Colors.white);
    }

    // Bác nông dân đang rắc thức ăn cho gà (đúng câu hỏi "What is the farmer doing?").
    final farmerFeet = Offset(w * 0.72, h * 0.96);
    _drawSimplePerson(canvas, farmerFeet, h * 0.32, shirtColor: const Color(0xFFE8B04A));
    final seedPaint = Paint()..color = const Color(0xFF6F5236);
    for (final p in [
      Offset(farmerFeet.dx + w * 0.06, farmerFeet.dy - h * 0.1),
      Offset(farmerFeet.dx + w * 0.1, farmerFeet.dy - h * 0.07),
      Offset(farmerFeet.dx + w * 0.13, farmerFeet.dy - h * 0.11),
    ]) {
      canvas.drawCircle(p, w * 0.006, seedPaint);
    }

    // 3 con gà (đúng câu hỏi "how many chickens" = Three).
    for (final dx in [w * 0.82, w * 0.9, w * 0.97]) {
      final chickenCenter = Offset(dx, h * 0.92);
      canvas.drawOval(Rect.fromCenter(center: chickenCenter, width: w * 0.05, height: h * 0.045), Paint()..color = Colors.white);
      canvas.drawCircle(chickenCenter.translate(-w * 0.025, -h * 0.02), w * 0.018, Paint()..color = Colors.white);
      canvas.drawCircle(chickenCenter.translate(-w * 0.035, -h * 0.03), w * 0.008, Paint()..color = const Color(0xFFD94F3D));
      final beakPath = Path()
        ..moveTo(chickenCenter.dx - w * 0.04, chickenCenter.dy - h * 0.02)
        ..lineTo(chickenCenter.dx - w * 0.05, chickenCenter.dy - h * 0.015)
        ..lineTo(chickenCenter.dx - w * 0.04, chickenCenter.dy - h * 0.01)
        ..close();
      canvas.drawPath(beakPath, Paint()..color = const Color(0xFFFFC94A));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Scene 8: "In the Kitchen" - bố nấu ăn ở bếp với nồi màu đỏ, 3 quả táo trong
// bát trên quầy bếp, mèo ngồi cạnh quầy (khớp đúng 5 câu hỏi).
// ---------------------------------------------------------------------------
class _KitchenScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.62), Paint()..color = const Color(0xFFFFF6E5));
    // Quầy bếp (mặt bàn dài) + tủ bếp bên dưới.
    canvas.drawRect(Rect.fromLTWH(0, h * 0.62, w, h * 0.08), Paint()..color = const Color(0xFFD8B98A));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.7, w, h * 0.3), Paint()..color = const Color(0xFFF2E2C4));

    // Bếp nấu (2 lò tròn) bên trái quầy.
    final stoveRect = Rect.fromLTWH(w * 0.06, h * 0.46, w * 0.26, h * 0.16);
    canvas.drawRRect(RRect.fromRectAndRadius(stoveRect, const Radius.circular(6)), Paint()..color = const Color(0xFF4A4A4A));
    canvas.drawCircle(Offset(stoveRect.left + stoveRect.width * 0.3, stoveRect.top + h * 0.02), w * 0.03, Paint()..color = const Color(0xFF2E2E2E));
    canvas.drawCircle(Offset(stoveRect.left + stoveRect.width * 0.75, stoveRect.top + h * 0.02), w * 0.03, Paint()..color = const Color(0xFF2E2E2E));

    // Nồi màu ĐỎ trên bếp (đúng câu hỏi "what color is the pot" = red) + khói bốc lên.
    final potCenter = Offset(stoveRect.left + stoveRect.width * 0.3, stoveRect.top - h * 0.01);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: potCenter, width: w * 0.12, height: h * 0.07),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFE84C3D),
    );
    canvas.drawLine(Offset(potCenter.dx - w * 0.08, potCenter.dy - h * 0.01), Offset(potCenter.dx - w * 0.1, potCenter.dy - h * 0.01), Paint()..color = const Color(0xFFB33327)..strokeWidth = 3);
    canvas.drawLine(Offset(potCenter.dx + w * 0.08, potCenter.dy - h * 0.01), Offset(potCenter.dx + w * 0.1, potCenter.dy - h * 0.01), Paint()..color = const Color(0xFFB33327)..strokeWidth = 3);
    final steamPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final dx in [-w * 0.02, w * 0.02]) {
      final steamPath = Path()
        ..moveTo(potCenter.dx + dx, potCenter.dy - h * 0.05)
        ..quadraticBezierTo(potCenter.dx + dx - w * 0.015, potCenter.dy - h * 0.09, potCenter.dx + dx, potCenter.dy - h * 0.13);
      canvas.drawPath(steamPath, steamPaint);
    }

    // Bố đang nấu ăn cạnh bếp (đúng câu hỏi "What is Dad doing?").
    _drawSimplePerson(canvas, Offset(w * 0.06, h * 0.94), h * 0.4, shirtColor: const Color(0xFF4FA8E0));

    // Bát táo trên quầy bếp, xa khỏi bếp nấu (đúng câu hỏi "where is the bowl" =
    // On the counter). SỬA (2026-08-31, qua review độc lập): tâm bát trước đặt
    // ở 0.6h khiến mép dưới bát (0.6h + nửa chiều cao 0.05h = 0.65h) LÚN XUỐNG
    // dưới mép trên quầy bếp (0.62h) - dời tâm lên 0.55h để mép dưới bát
    // (0.55h + 0.05h = 0.6h) nằm rõ ràng TRÊN mặt quầy.
    final bowlCenter = Offset(w * 0.68, h * 0.55);
    canvas.drawArc(
      Rect.fromCenter(center: bowlCenter, width: w * 0.26, height: h * 0.1),
      0,
      math.pi,
      true,
      Paint()..color = const Color(0xFFE8D8C0),
    );
    // 3 quả táo đỏ trong bát (đúng câu hỏi "how many apples" = Three). SỬA:
    // giãn khoảng cách tâm 2 quả táo cạnh nhau từ 0.07w lên 0.095w (bán kính
    // giữ 0.032w) để mép 2 quả táo cách nhau rõ ràng (~0.03w), tránh nhìn như
    // dính liền khó đếm chính xác 3 quả.
    for (final dx in [-w * 0.095, 0.0, w * 0.095]) {
      final appleCenter = Offset(bowlCenter.dx + dx, bowlCenter.dy - h * 0.03);
      canvas.drawCircle(appleCenter, w * 0.032, Paint()..color = const Color(0xFFE84C3D));
      canvas.drawLine(appleCenter.translate(0, -w * 0.032), appleCenter.translate(0, -w * 0.045), Paint()..color = const Color(0xFF6F5236)..strokeWidth = 1.5);
    }

    // Mèo ngồi cạnh quầy bếp (đúng câu hỏi true/false "cat in the kitchen" = True).
    final catCenter = Offset(w * 0.9, h * 0.9);
    final catPaint = Paint()..color = const Color(0xFFA9A9B0);
    canvas.drawOval(Rect.fromCenter(center: catCenter, width: w * 0.1, height: h * 0.09), catPaint);
    canvas.drawCircle(catCenter.translate(0, -h * 0.06), w * 0.035, catPaint);
    final earPath1 = Path()
      ..moveTo(catCenter.dx - w * 0.03, catCenter.dy - h * 0.08)
      ..lineTo(catCenter.dx - w * 0.02, catCenter.dy - h * 0.12)
      ..lineTo(catCenter.dx - w * 0.01, catCenter.dy - h * 0.08)
      ..close();
    final earPath2 = Path()
      ..moveTo(catCenter.dx + w * 0.01, catCenter.dy - h * 0.08)
      ..lineTo(catCenter.dx + w * 0.02, catCenter.dy - h * 0.12)
      ..lineTo(catCenter.dx + w * 0.03, catCenter.dy - h * 0.08)
      ..close();
    canvas.drawPath(earPath1, catPaint);
    canvas.drawPath(earPath2, catPaint);
    final tailPath = Path()
      ..moveTo(catCenter.dx + w * 0.05, catCenter.dy + h * 0.02)
      ..quadraticBezierTo(catCenter.dx + w * 0.09, catCenter.dy - h * 0.02, catCenter.dx + w * 0.07, catCenter.dy - h * 0.08);
    canvas.drawPath(
      tailPath,
      Paint()
        ..color = catPaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.02
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Scene 9: "In the Garden" - bé gái cầm bình tưới, 4 bông hoa, bọ rùa đỏ trên
// cỏ, bươm bướm bay phía trên hàng hoa, có 1 cây (khớp đúng 5 câu hỏi).
// ---------------------------------------------------------------------------
class _GardenScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.55), Paint()..color = const Color(0xFFBEE7FF));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.55, w, h * 0.45), Paint()..color = const Color(0xFF9BD98A));
    _drawSun(canvas, Offset(w * 0.1, h * 0.14), w * 0.06, const Color(0xFFFFC94A));

    // Cây bên phải (đúng câu hỏi true/false "there is a tree" = True).
    _drawTree(canvas, Offset(w * 0.9, h * 0.55), h * 0.16, w * 0.03, w * 0.09);

    // Bươm bướm bay PHÍA TRÊN hàng hoa (đúng câu hỏi "where is the butterfly" = Above the flowers).
    final butterflyCenter = Offset(w * 0.5, h * 0.42);
    final wingPaint = Paint()..color = const Color(0xFFE87FA0);
    canvas.drawOval(Rect.fromCenter(center: butterflyCenter.translate(-w * 0.025, 0), width: w * 0.05, height: h * 0.06), wingPaint);
    canvas.drawOval(Rect.fromCenter(center: butterflyCenter.translate(w * 0.025, 0), width: w * 0.05, height: h * 0.06), wingPaint);
    canvas.drawLine(butterflyCenter.translate(0, -h * 0.03), butterflyCenter.translate(0, h * 0.03), Paint()..color = Colors.black87..strokeWidth = 2);

    // 4 bông hoa thành 1 hàng (đúng câu hỏi "how many flowers" = Four).
    final flowerColors = [const Color(0xFFE84C3D), const Color(0xFFE87FA0), const Color(0xFF4FA8E0), const Color(0xFFFFC94A)];
    for (var i = 0; i < 4; i++) {
      final flowerCenter = Offset(w * (0.18 + i * 0.16), h * 0.72);
      _drawFlower(canvas, flowerCenter, w * 0.022, flowerColors[i]);
    }

    // Bọ rùa màu đỏ trên cỏ (đúng câu hỏi "color of the ladybug" = red).
    final ladybugCenter = Offset(w * 0.62, h * 0.88);
    canvas.drawCircle(ladybugCenter, w * 0.025, Paint()..color = const Color(0xFFE84C3D));
    canvas.drawLine(ladybugCenter.translate(0, -w * 0.025), ladybugCenter.translate(0, w * 0.025), Paint()..color = Colors.black87..strokeWidth = 1.5);
    canvas.drawCircle(ladybugCenter.translate(-w * 0.007, w * 0.008), w * 0.006, Paint()..color = Colors.black87);
    canvas.drawCircle(ladybugCenter.translate(w * 0.008, -w * 0.005), w * 0.006, Paint()..color = Colors.black87);
    canvas.drawCircle(ladybugCenter.translate(0, -w * 0.02), w * 0.008, Paint()..color = Colors.black87);

    // Bé gái đang cầm bình tưới (đúng câu hỏi "What is the girl holding?").
    final girlFeet = Offset(w * 0.34, h * 0.98);
    _drawSimplePerson(canvas, girlFeet, h * 0.32, shirtColor: const Color(0xFFFFC94A));
    final canCenter = Offset(girlFeet.dx + w * 0.1, girlFeet.dy - h * 0.16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: canCenter, width: w * 0.08, height: h * 0.07),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF6FA8DC),
    );
    canvas.drawLine(
      Offset(canCenter.dx + w * 0.04, canCenter.dy - h * 0.02),
      Offset(canCenter.dx + w * 0.09, canCenter.dy - h * 0.05),
      Paint()
        ..color = const Color(0xFF6FA8DC)
        ..strokeWidth = w * 0.018,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Scene 10: "Birthday Party" - bánh sinh nhật với 3 cây nến, bóng bay, 1 hộp
// quà màu xanh dương, 2 bạn nhỏ ngồi quanh bàn (khớp đúng 5 câu hỏi).
// ---------------------------------------------------------------------------
class _BirthdayScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.7), Paint()..color = const Color(0xFFFFF6E5));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.7, w, h * 0.3), Paint()..color = const Color(0xFFE8D8C0));

    // 3 quả bóng bay (đúng câu hỏi true/false "there are balloons" = True).
    _drawBalloon(canvas, Offset(w * 0.14, h * 0.2), w * 0.006, const Color(0xFFE87FA0));
    _drawBalloon(canvas, Offset(w * 0.26, h * 0.14), w * 0.006, const Color(0xFF4FA8E0));
    _drawBalloon(canvas, Offset(w * 0.86, h * 0.18), w * 0.006, const Color(0xFFFFC94A));

    // Bàn tiệc.
    final tableRect = Rect.fromLTWH(w * 0.18, h * 0.66, w * 0.64, h * 0.06);
    canvas.drawRect(tableRect, Paint()..color = const Color(0xFFD8B98A));
    canvas.drawRect(Rect.fromLTWH(tableRect.left, tableRect.bottom, tableRect.width, h * 0.06), Paint()..color = const Color(0xFFC9A46A));

    // Hộp quà màu XANH DƯƠNG cạnh bàn (đúng câu hỏi "color of the present box" = blue).
    final giftCenter = Offset(w * 0.15, h * 0.78);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: giftCenter, width: w * 0.14, height: h * 0.12),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF4FA8E0),
    );
    canvas.drawRect(Rect.fromCenter(center: giftCenter, width: w * 0.03, height: h * 0.12), Paint()..color = const Color(0xFFFFC94A));
    canvas.drawRect(Rect.fromCenter(center: giftCenter, width: w * 0.14, height: h * 0.025), Paint()..color = const Color(0xFFFFC94A));
    canvas.drawCircle(giftCenter.translate(-w * 0.02, -h * 0.06), w * 0.018, Paint()..color = const Color(0xFFFFC94A));
    canvas.drawCircle(giftCenter.translate(w * 0.02, -h * 0.06), w * 0.018, Paint()..color = const Color(0xFFFFC94A));

    // Bánh sinh nhật ở giữa bàn với 3 cây nến (đúng câu hỏi "what is on the cake" = Candles
    // và "how many candles" = Three).
    final cakeCenter = Offset(w * 0.5, h * 0.62);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: cakeCenter, width: w * 0.24, height: h * 0.1),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFFE87FA0),
    );
    final frostingPath = Path()..moveTo(cakeCenter.dx - w * 0.12, cakeCenter.dy - h * 0.05);
    for (var i = 0; i < 6; i++) {
      final x = cakeCenter.dx - w * 0.12 + (w * 0.24) * (i + 1) / 6;
      frostingPath.quadraticBezierTo(
        cakeCenter.dx - w * 0.12 + (w * 0.24) * (i + 0.5) / 6,
        cakeCenter.dy - h * 0.08,
        x,
        cakeCenter.dy - h * 0.05,
      );
    }
    canvas.drawPath(frostingPath, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = h * 0.025);
    for (final dx in [-w * 0.06, 0.0, w * 0.06]) {
      final candleBase = Offset(cakeCenter.dx + dx, cakeCenter.dy - h * 0.06);
      canvas.drawRect(Rect.fromLTWH(candleBase.dx - w * 0.006, candleBase.dy - h * 0.05, w * 0.012, h * 0.05), Paint()..color = const Color(0xFFFFC94A));
      canvas.drawOval(
        Rect.fromCenter(center: candleBase.translate(0, -h * 0.06), width: w * 0.014, height: h * 0.02),
        Paint()..color = const Color(0xFFE8703C),
      );
    }

    // 2 bạn nhỏ ngồi 2 bên bàn (đúng câu hỏi "how many children at the table" = Two).
    _drawSimplePerson(canvas, Offset(w * 0.3, h * 0.98), h * 0.28, shirtColor: const Color(0xFF6FBE7A));
    _drawSimplePerson(canvas, Offset(w * 0.72, h * 0.98), h * 0.28, shirtColor: const Color(0xFFB07AD1));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Scene 11: "A Rainy Day" - trời xám, ĐÚNG 2 đám mây, mưa rơi, cây bên TRÁI,
// bé gái áo ĐỎ cầm ô VÀNG, vũng nước có vịt VÀNG, ốc sên trên cỏ (khớp 10 câu).
// ---------------------------------------------------------------------------
class _RainyScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.66), Paint()..color = const Color(0xFFB8C4CE));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.66, w, h * 0.34), Paint()..color = const Color(0xFF8FBF7F));

    _drawCloud(canvas, Offset(w * 0.3, h * 0.13), w * 0.006, color: const Color(0xFF7D8A96));
    _drawCloud(canvas, Offset(w * 0.72, h * 0.17), w * 0.0055, color: const Color(0xFF7D8A96));

    final rainPaint = Paint()
      ..color = const Color(0xFF5B8DB8)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var row = 0; row < 6; row++) {
      for (var col = 0; col < 10; col++) {
        final x = w * (0.04 + col * 0.1 + (row.isOdd ? 0.05 : 0));
        final y = h * (0.28 + row * 0.065);
        canvas.drawLine(Offset(x, y), Offset(x - w * 0.012, y + h * 0.035), rainPaint);
      }
    }

    _drawTree(canvas, Offset(w * 0.1, h * 0.72), h * 0.16, w * 0.03, w * 0.08);

    // Vũng nước + vịt vàng đang bơi.
    final puddleCenter = Offset(w * 0.73, h * 0.86);
    canvas.drawOval(
      Rect.fromCenter(center: puddleCenter, width: w * 0.32, height: h * 0.09),
      Paint()..color = const Color(0xFF6FA8DC),
    );
    final duckPaint = Paint()..color = const Color(0xFFFFC94A);
    canvas.drawOval(
      Rect.fromCenter(center: puddleCenter.translate(0, -h * 0.02), width: w * 0.08, height: h * 0.05),
      duckPaint,
    );
    final duckHead = puddleCenter.translate(w * 0.035, -h * 0.06);
    canvas.drawCircle(duckHead, w * 0.022, duckPaint);
    canvas.drawCircle(duckHead.translate(w * 0.006, -h * 0.006), w * 0.004, Paint()..color = Colors.black87);
    final beakPath = Path()
      ..moveTo(duckHead.dx + w * 0.018, duckHead.dy - h * 0.004)
      ..lineTo(duckHead.dx + w * 0.036, duckHead.dy + h * 0.004)
      ..lineTo(duckHead.dx + w * 0.018, duckHead.dy + h * 0.012)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = const Color(0xFFE8703C));

    // Ốc sên: thân dài + vỏ tròn có đường xoắn.
    final snailBase = Offset(w * 0.24, h * 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(snailBase.dx - w * 0.05, snailBase.dy - h * 0.018, w * 0.1, h * 0.022),
        Radius.circular(h * 0.011),
      ),
      Paint()..color = const Color(0xFFD9B98A),
    );
    final shellCenter = snailBase.translate(w * 0.005, -h * 0.04);
    canvas.drawCircle(shellCenter, w * 0.03, Paint()..color = const Color(0xFFB0703C));
    final spiralPaint = Paint()
      ..color = const Color(0xFF7A4A22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawArc(Rect.fromCircle(center: shellCenter, radius: w * 0.02), 0, 4.5, false, spiralPaint);
    canvas.drawArc(Rect.fromCircle(center: shellCenter, radius: w * 0.009), 1.5, 4.5, false, spiralPaint);

    // Bé gái áo đỏ + ô vàng che trên đầu.
    final girlFeet = Offset(w * 0.44, h * 0.95);
    _drawSimplePerson(canvas, girlFeet, h * 0.34, shirtColor: const Color(0xFFE84C3D));
    // Ô lệch sang phải để cán ô nằm cạnh người, không cắt ngang mặt bé.
    final canopyRect = Rect.fromCenter(center: Offset(girlFeet.dx + w * 0.07, h * 0.47), width: w * 0.3, height: h * 0.14);
    final canopyPath = Path()
      ..moveTo(canopyRect.left, canopyRect.bottom)
      ..quadraticBezierTo(canopyRect.center.dx, canopyRect.top - h * 0.06, canopyRect.right, canopyRect.bottom)
      ..close();
    canvas.drawPath(canopyPath, Paint()..color = const Color(0xFFFFC94A));
    final handlePaint = Paint()
      ..color = const Color(0xFF6F5236)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final handleBottom = Offset(canopyRect.center.dx, h * 0.72);
    canvas.drawLine(Offset(canopyRect.center.dx, canopyRect.bottom), handleBottom, handlePaint);
    canvas.drawArc(
      Rect.fromCircle(center: handleBottom.translate(-w * 0.012, 0), radius: w * 0.012),
      0,
      math.pi,
      false,
      handlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Scene 12: "At the Playground" - cầu trượt ĐỎ bên trái, xích đu có ĐÚNG 2
// ghế (bé gái áo TÍM ngồi 1 ghế), bé trai đứng gần cầu trượt, bóng XANH LÁ,
// trời nắng có ĐÚNG 2 con chim (khớp 10 câu).
// ---------------------------------------------------------------------------
class _PlaygroundScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.65), Paint()..color = const Color(0xFFBEE7FF));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.65, w, h * 0.35), Paint()..color = const Color(0xFF9BD98A));

    _drawSun(canvas, Offset(w * 0.88, h * 0.13), w * 0.05, const Color(0xFFFFC94A));
    _drawCloud(canvas, Offset(w * 0.18, h * 0.12), w * 0.005);
    _drawBird(canvas, Offset(w * 0.42, h * 0.14), w * 0.004);
    _drawBird(canvas, Offset(w * 0.58, h * 0.08), w * 0.004);

    // Cầu trượt: thang xám + sàn và máng trượt màu đỏ.
    final ladderPaint = Paint()
      ..color = const Color(0xFF8A8F98)
      ..strokeWidth = w * 0.012
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.08, h * 0.88), Offset(w * 0.1, h * 0.4), ladderPaint);
    canvas.drawLine(Offset(w * 0.16, h * 0.88), Offset(w * 0.18, h * 0.4), ladderPaint);
    for (var i = 1; i <= 5; i++) {
      final y = h * (0.4 + i * 0.08);
      final t = (y - h * 0.4) / (h * 0.48);
      canvas.drawLine(
        Offset(w * (0.1 - 0.02 * t), y),
        Offset(w * (0.18 - 0.02 * t), y),
        Paint()
          ..color = ladderPaint.color
          ..strokeWidth = w * 0.007,
      );
    }
    const slideRed = Color(0xFFE84C3D);
    canvas.drawRect(Rect.fromLTWH(w * 0.09, h * 0.37, w * 0.12, h * 0.035), Paint()..color = slideRed);
    canvas.drawLine(
      Offset(w * 0.2, h * 0.39),
      Offset(w * 0.36, h * 0.86),
      Paint()
        ..color = slideRed
        ..strokeWidth = w * 0.04
        ..strokeCap = StrokeCap.round,
    );

    // Bé trai áo xanh dương đứng cạnh chân cầu trượt.
    _drawSimplePerson(canvas, Offset(w * 0.45, h * 0.96), h * 0.3, shirtColor: const Color(0xFF4FA8E0));

    // Bóng xanh lá trên cỏ.
    final ballCenter = Offset(w * 0.56, h * 0.87);
    canvas.drawCircle(ballCenter, w * 0.035, Paint()..color = const Color(0xFF3E8E41));
    canvas.drawArc(
      Rect.fromCircle(center: ballCenter, radius: w * 0.022),
      3.6,
      1.3,
      false,
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Khung xích đu chữ A + 2 ghế.
    final framePaint = Paint()
      ..color = const Color(0xFF8D6748)
      ..strokeWidth = w * 0.014
      ..strokeCap = StrokeCap.round;
    final barY = h * 0.34;
    canvas.drawLine(Offset(w * 0.62, h * 0.9), Offset(w * 0.66, barY), framePaint);
    canvas.drawLine(Offset(w * 0.98, h * 0.9), Offset(w * 0.94, barY), framePaint);
    canvas.drawLine(Offset(w * 0.64, barY), Offset(w * 0.96, barY), framePaint);

    final ropePaint = Paint()
      ..color = const Color(0xFF5B4636)
      ..strokeWidth = 1.5;
    final seatPaint = Paint()..color = const Color(0xFF6F5236);

    // Ghế 1 - bé gái áo tím đang ngồi (vẽ người trước, ghế đè lên ngang hông).
    const seat1X = 0.73;
    final seat1Y = h * 0.7;
    _drawSimplePerson(canvas, Offset(w * seat1X, seat1Y + h * 0.28 * 0.34), h * 0.28, shirtColor: const Color(0xFFB07AD1));
    canvas.drawLine(Offset(w * (seat1X - 0.045), barY), Offset(w * (seat1X - 0.045), seat1Y), ropePaint);
    canvas.drawLine(Offset(w * (seat1X + 0.045), barY), Offset(w * (seat1X + 0.045), seat1Y), ropePaint);
    canvas.drawRect(Rect.fromLTWH(w * (seat1X - 0.055), seat1Y, w * 0.11, h * 0.02), seatPaint);

    // Ghế 2 - trống.
    const seat2X = 0.87;
    final seat2Y = h * 0.72;
    canvas.drawLine(Offset(w * (seat2X - 0.035), barY), Offset(w * (seat2X - 0.035), seat2Y), ropePaint);
    canvas.drawLine(Offset(w * (seat2X + 0.035), barY), Offset(w * (seat2X + 0.035), seat2Y), ropePaint);
    canvas.drawRect(Rect.fromLTWH(w * (seat2X - 0.045), seat2Y, w * 0.09, h * 0.02), seatPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Scene 13: "A Snowy Day" - tuyết rơi, ĐÚNG 2 cây thông, người tuyết đội mũ
// đen, mũi cà rốt, khăn ĐỎ; bé trai áo XANH LÁ đứng cạnh; nhà mái ĐỎ, ống
// khói đang bốc khói (khớp 10 câu).
// ---------------------------------------------------------------------------
class _SnowyScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.62), Paint()..color = const Color(0xFFBFD4E8));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.62, w, h * 0.38), Paint()..color = const Color(0xFFF4F8FC));

    // 2 cây thông.
    for (final base in [Offset(w * 0.1, h * 0.7), Offset(w * 0.23, h * 0.67)]) {
      canvas.drawRect(
        Rect.fromCenter(center: base.translate(0, -h * 0.03), width: w * 0.02, height: h * 0.06),
        Paint()..color = const Color(0xFF8D6748),
      );
      for (var i = 0; i < 3; i++) {
        final bottomY = base.dy - h * 0.05 - i * h * 0.08;
        final halfWidth = w * (0.07 - i * 0.015);
        final tier = Path()
          ..moveTo(base.dx - halfWidth, bottomY)
          ..lineTo(base.dx, bottomY - h * 0.13)
          ..lineTo(base.dx + halfWidth, bottomY)
          ..close();
        canvas.drawPath(tier, Paint()..color = const Color(0xFF2E7D4F));
      }
    }

    // Nhà mái đỏ + ống khói bốc khói.
    final houseRect = Rect.fromLTWH(w * 0.7, h * 0.4, w * 0.25, h * 0.26);
    canvas.drawRect(houseRect, Paint()..color = const Color(0xFFC98B5E));
    canvas.drawRect(Rect.fromLTWH(w * 0.88, h * 0.25, w * 0.04, h * 0.1), Paint()..color = const Color(0xFF7A2E22));
    final roofPath = Path()
      ..moveTo(w * 0.67, h * 0.41)
      ..lineTo(w * 0.825, h * 0.25)
      ..lineTo(w * 0.98, h * 0.41)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = const Color(0xFFD94F3D));
    canvas.drawRect(Rect.fromLTWH(w * 0.8, h * 0.52, w * 0.05, h * 0.14), Paint()..color = const Color(0xFF6F5236));
    canvas.drawRect(Rect.fromLTWH(w * 0.73, h * 0.46, w * 0.05, h * 0.05), Paint()..color = const Color(0xFFFFE9A8));
    final smokePaint = Paint()..color = const Color(0xCC9EA7B0);
    canvas.drawCircle(Offset(w * 0.9, h * 0.2), w * 0.018, smokePaint);
    canvas.drawCircle(Offset(w * 0.925, h * 0.14), w * 0.024, smokePaint);
    canvas.drawCircle(Offset(w * 0.955, h * 0.07), w * 0.03, smokePaint);

    // Người tuyết.
    final bodyCenter = Offset(w * 0.44, h * 0.82);
    final headCenter = Offset(w * 0.44, h * 0.62);
    final snowPaint = Paint()..color = Colors.white;
    final outline = Paint()
      ..color = const Color(0xFFB8C8D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(bodyCenter, w * 0.1, snowPaint);
    canvas.drawCircle(bodyCenter, w * 0.1, outline);
    canvas.drawCircle(headCenter, w * 0.065, snowPaint);
    canvas.drawCircle(headCenter, w * 0.065, outline);
    final stickPaint = Paint()
      ..color = const Color(0xFF6F5236)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(bodyCenter.translate(-w * 0.09, -h * 0.06), bodyCenter.translate(-w * 0.18, -h * 0.14), stickPaint);
    canvas.drawLine(bodyCenter.translate(w * 0.09, -h * 0.06), bodyCenter.translate(w * 0.17, -h * 0.15), stickPaint);
    for (final dy in [-h * 0.05, 0.0, h * 0.05]) {
      canvas.drawCircle(bodyCenter.translate(0, dy), w * 0.008, Paint()..color = Colors.black87);
    }
    canvas.drawCircle(headCenter.translate(-w * 0.022, -h * 0.02), w * 0.007, Paint()..color = Colors.black87);
    canvas.drawCircle(headCenter.translate(w * 0.022, -h * 0.02), w * 0.007, Paint()..color = Colors.black87);
    final nosePath = Path()
      ..moveTo(headCenter.dx, headCenter.dy - h * 0.005)
      ..lineTo(headCenter.dx + w * 0.06, headCenter.dy + h * 0.01)
      ..lineTo(headCenter.dx, headCenter.dy + h * 0.02)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = const Color(0xFFFF8A2A));
    // Khăn đỏ quanh cổ + 1 vạt buông xuống.
    final scarfPaint = Paint()..color = const Color(0xFFE84C3D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: headCenter.translate(0, h * 0.075), width: w * 0.13, height: h * 0.035),
        const Radius.circular(4),
      ),
      scarfPaint,
    );
    canvas.drawRect(Rect.fromLTWH(headCenter.dx + w * 0.03, headCenter.dy + h * 0.075, w * 0.025, h * 0.08), scarfPaint);
    // Mũ đen.
    final hatPaint = Paint()..color = const Color(0xFF2E2E2E);
    canvas.drawRect(Rect.fromCenter(center: headCenter.translate(0, -h * 0.075), width: w * 0.13, height: h * 0.02), hatPaint);
    canvas.drawRect(Rect.fromCenter(center: headCenter.translate(0, -h * 0.115), width: w * 0.08, height: h * 0.07), hatPaint);

    // Bé trai áo khoác xanh lá đứng cạnh người tuyết.
    _drawSimplePerson(canvas, Offset(w * 0.62, h * 0.96), h * 0.32, shirtColor: const Color(0xFF3E8E41));

    // Bông tuyết rơi khắp nơi (vẽ sau cùng để rơi cả trước người/nhà).
    final flakePaint = Paint()..color = Colors.white;
    for (var row = 0; row < 7; row++) {
      for (var col = 0; col < 9; col++) {
        // Lệch nhẹ theo sin để bông tuyết không xếp thẳng hàng như chấm bi.
        final x = w * (0.05 + col * 0.11 + (row.isOdd ? 0.055 : 0) + 0.025 * _sin(row * 2.3 + col * 1.7));
        final y = h * (0.05 + row * 0.085 + 0.025 * _cos(row * 1.3 + col * 2.9));
        canvas.drawCircle(Offset(x, y), w * (0.005 + 0.003 * ((row + col) % 3) / 2), flakePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Helper cho các scene mới (2026-10-02).
// ---------------------------------------------------------------------------

/// Cá đơn giản: thân oval + đuôi tam giác + mắt. [facingRight] = đầu bên phải.
void _drawFish(Canvas canvas, Offset center, double length, Color color, {bool facingRight = true}) {
  final dir = facingRight ? 1.0 : -1.0;
  final paint = Paint()..color = color;
  canvas.drawOval(Rect.fromCenter(center: center, width: length, height: length * 0.55), paint);
  final tailBase = center.translate(-dir * length * 0.45, 0);
  final tail = Path()
    ..moveTo(tailBase.dx, tailBase.dy)
    ..lineTo(tailBase.dx - dir * length * 0.3, tailBase.dy - length * 0.25)
    ..lineTo(tailBase.dx - dir * length * 0.3, tailBase.dy + length * 0.25)
    ..close();
  canvas.drawPath(tail, paint);
  final eye = center.translate(dir * length * 0.25, -length * 0.06);
  canvas.drawCircle(eye, length * 0.07, Paint()..color = Colors.white);
  canvas.drawCircle(eye, length * 0.035, Paint()..color = Colors.black87);
}

/// Sao biển 5 cánh (khác [_drawStar] chỉ có 4 cánh nhọn).
void _drawFivePointStar(Canvas canvas, Offset center, double radius, Color color) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final angle = -math.pi / 2 + i * math.pi / 5;
    final r = i.isEven ? radius : radius * 0.45;
    final p = Offset(center.dx + r * _cos(angle), center.dy + r * _sin(angle));
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  canvas.drawPath(path, Paint()..color = color);
}

/// Cây thông: thân nâu + 2 tầng tam giác xanh đậm.
void _drawPineTree(Canvas canvas, Offset base, double height, double width) {
  canvas.drawRect(
    Rect.fromCenter(center: base.translate(0, -height * 0.08), width: width * 0.18, height: height * 0.16),
    Paint()..color = const Color(0xFF7A5536),
  );
  final green = Paint()..color = const Color(0xFF2F7D4A);
  for (var i = 0; i < 2; i++) {
    final bottom = base.dy - height * (0.14 + i * 0.3);
    final top = bottom - height * 0.55;
    final half = width * (0.5 - i * 0.12);
    canvas.drawPath(
      Path()
        ..moveTo(base.dx - half, bottom)
        ..lineTo(base.dx + half, bottom)
        ..lineTo(base.dx, top)
        ..close(),
      green,
    );
  }
}

/// Bánh xe đen có vành xám.
void _drawWheel(Canvas canvas, Offset center, double radius) {
  canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF2E2E2E));
  canvas.drawCircle(center, radius * 0.45, Paint()..color = const Color(0xFFBDBDBD));
}

// ---------------------------------------------------------------------------
// Scene 14: "At the Fruit Market" - sạp có mái sọc ĐỎ-trắng, ĐÚNG 3 giỏ: giỏ
// TRÁI 5 quả táo đỏ, giỏ GIỮA 3 quả chuối vàng, giỏ PHẢI 4 quả cam; cô bán
// hàng áo XANH LÁ đứng SAU sạp; bé trai áo VÀNG cầm túi XANH DƯƠNG; trời nắng,
// 1 đám mây (khớp câu hỏi trong scenes.json).
// ---------------------------------------------------------------------------
class _MarketScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.6), Paint()..color = const Color(0xFFBEE7FF));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.6, w, h * 0.4), Paint()..color = const Color(0xFFE8D9C5));
    _drawSun(canvas, Offset(w * 0.9, h * 0.12), w * 0.045, const Color(0xFFFFC94A));
    _drawCloud(canvas, Offset(w * 0.6, h * 0.09), w * 0.004);

    // Cột + mái sọc đỏ - trắng.
    final post = Paint()..color = const Color(0xFF8D6748);
    canvas.drawRect(Rect.fromLTWH(w * 0.15, h * 0.3, w * 0.02, h * 0.45), post);
    canvas.drawRect(Rect.fromLTWH(w * 0.83, h * 0.3, w * 0.02, h * 0.45), post);
    const stripes = 8;
    for (var i = 0; i < stripes; i++) {
      final x = w * (0.13 + i * 0.74 / stripes);
      canvas.drawRect(
        Rect.fromLTWH(x, h * 0.2, w * 0.74 / stripes, h * 0.11),
        Paint()..color = i.isEven ? const Color(0xFFE84C3D) : Colors.white,
      );
    }

    // Cô bán hàng (vẽ TRƯỚC quầy để quầy che phần chân - đứng SAU sạp).
    _drawSimplePerson(canvas, Offset(w * 0.5, h * 0.68), h * 0.36, shirtColor: const Color(0xFF6FBE7A));

    // Quầy hàng.
    canvas.drawRect(Rect.fromLTWH(w * 0.17, h * 0.56, w * 0.66, h * 0.2), Paint()..color = const Color(0xFFB07A4E));
    canvas.drawRect(Rect.fromLTWH(w * 0.17, h * 0.56, w * 0.66, h * 0.025), Paint()..color = const Color(0xFF8D6748));

    // 3 giỏ trên mặt quầy.
    final basket = Paint()..color = const Color(0xFFC98B4E);
    for (final cx in [0.3, 0.5, 0.7]) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w * cx, h * 0.53), width: w * 0.16, height: h * 0.12),
        0,
        math.pi,
        true,
        basket,
      );
    }

    // Giỏ trái: 5 quả táo đỏ (3 dưới + 2 trên).
    final apple = Paint()..color = const Color(0xFFD93B30);
    final r = w * 0.022;
    for (final p in [
      Offset(w * 0.255, h * 0.52),
      Offset(w * 0.3, h * 0.52),
      Offset(w * 0.345, h * 0.52),
      Offset(w * 0.2775, h * 0.465),
      Offset(w * 0.3225, h * 0.465),
    ]) {
      canvas.drawCircle(p, r, apple);
      canvas.drawLine(p.translate(0, -r), p.translate(r * 0.3, -r * 1.5), Paint()
        ..color = const Color(0xFF5B4636)
        ..strokeWidth = 1.5);
    }

    // Giỏ giữa: 3 quả chuối vàng (3 nét cong dày).
    final banana = Paint()
      ..color = const Color(0xFFFFD43B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final dx = w * (0.45 + i * 0.05);
      canvas.drawPath(
        Path()
          ..moveTo(dx - w * 0.02, h * 0.44)
          ..quadraticBezierTo(dx - w * 0.03, h * 0.52, dx + w * 0.025, h * 0.53),
        banana,
      );
    }

    // Giỏ phải: 4 quả cam (3 dưới + 1 trên).
    final orange = Paint()..color = const Color(0xFFF5922A);
    for (final p in [
      Offset(w * 0.655, h * 0.52),
      Offset(w * 0.7, h * 0.52),
      Offset(w * 0.745, h * 0.52),
      Offset(w * 0.7, h * 0.465),
    ]) {
      canvas.drawCircle(p, r, orange);
    }

    // Bé trai áo vàng cầm túi xanh dương (bên phải, trước sạp).
    _drawSimplePerson(canvas, Offset(w * 0.9, h * 0.97), h * 0.3, shirtColor: const Color(0xFFFFC94A));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.93, h * 0.78, w * 0.06, h * 0.1), const Radius.circular(4)),
      Paint()..color = const Color(0xFF3D7DD8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Scene 15: "In Space" - trời đen xanh, mặt trăng XÁM bên TRÁI có hố tròn,
// ĐÚNG 6 ngôi sao, tên lửa trắng mũi ĐỎ đang phun lửa, phi hành gia mũ bảo
// hiểm bay cạnh tên lửa, ĐÚNG 2 hành tinh: 1 hành tinh CAM có vành đai + 1
// hành tinh XANH DƯƠNG nhỏ (khớp câu hỏi trong scenes.json).
// ---------------------------------------------------------------------------
class _SpaceScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF1B2A4A));

    // 6 ngôi sao.
    for (final p in [
      Offset(w * 0.32, h * 0.1),
      Offset(w * 0.6, h * 0.08),
      Offset(w * 0.08, h * 0.55),
      Offset(w * 0.28, h * 0.85),
      Offset(w * 0.62, h * 0.88),
      Offset(w * 0.93, h * 0.48),
    ]) {
      _drawFivePointStar(canvas, p, w * 0.022, const Color(0xFFFFF3B0));
    }

    // Mặt trăng xám + 3 hố.
    final moonC = Offset(w * 0.15, h * 0.24);
    canvas.drawCircle(moonC, w * 0.09, Paint()..color = const Color(0xFFBDBDBD));
    final crater = Paint()..color = const Color(0xFF9E9E9E);
    canvas.drawCircle(moonC.translate(-w * 0.03, -w * 0.02), w * 0.018, crater);
    canvas.drawCircle(moonC.translate(w * 0.035, w * 0.01), w * 0.014, crater);
    canvas.drawCircle(moonC.translate(-w * 0.005, w * 0.045), w * 0.012, crater);

    // Hành tinh cam có vành đai.
    final ringed = Offset(w * 0.8, h * 0.22);
    canvas.drawCircle(ringed, w * 0.07, Paint()..color = const Color(0xFFF5922A));
    canvas.drawOval(
      Rect.fromCenter(center: ringed, width: w * 0.22, height: h * 0.07),
      Paint()
        ..color = const Color(0xFFFFE08A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.008,
    );

    // Hành tinh xanh dương nhỏ (góc dưới phải).
    final blue = Offset(w * 0.86, h * 0.8);
    canvas.drawCircle(blue, w * 0.055, Paint()..color = const Color(0xFF3D7DD8));
    canvas.drawCircle(blue.translate(-w * 0.015, -w * 0.01), w * 0.02, Paint()..color = const Color(0xFF6FBE7A));

    // Lửa dưới đáy tên lửa.
    final cx = w * 0.45;
    canvas.drawPath(
      Path()
        ..moveTo(cx - w * 0.04, h * 0.74)
        ..lineTo(cx + w * 0.04, h * 0.74)
        ..lineTo(cx, h * 0.92)
        ..close(),
      Paint()..color = const Color(0xFFF5922A),
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx - w * 0.02, h * 0.74)
        ..lineTo(cx + w * 0.02, h * 0.74)
        ..lineTo(cx, h * 0.85)
        ..close(),
      Paint()..color = const Color(0xFFFFD43B),
    );

    // Thân tên lửa trắng + mũi đỏ + 2 cánh đỏ + cửa sổ tròn.
    final red = Paint()..color = const Color(0xFFE84C3D);
    canvas.drawPath(
      Path()
        ..moveTo(cx - w * 0.05, h * 0.62)
        ..lineTo(cx - w * 0.1, h * 0.76)
        ..lineTo(cx - w * 0.05, h * 0.72)
        ..close(),
      red,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + w * 0.05, h * 0.62)
        ..lineTo(cx + w * 0.1, h * 0.76)
        ..lineTo(cx + w * 0.05, h * 0.72)
        ..close(),
      red,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(cx - w * 0.05, h * 0.32, cx + w * 0.05, h * 0.75), Radius.circular(w * 0.03)),
      Paint()..color = const Color(0xFFF5F5F5),
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx - w * 0.05, h * 0.34)
        ..lineTo(cx + w * 0.05, h * 0.34)
        ..lineTo(cx, h * 0.18)
        ..close(),
      red,
    );
    canvas.drawCircle(Offset(cx, h * 0.46), w * 0.028, Paint()..color = const Color(0xFF4FA8E0));

    // Dây nối + phi hành gia (áo trắng, mũ bảo hiểm tròn trong suốt).
    final feet = Offset(w * 0.68, h * 0.74);
    final ph = h * 0.28;
    canvas.drawLine(
      Offset(cx + w * 0.05, h * 0.5),
      feet.translate(-w * 0.03, -ph * 0.6),
      Paint()
        ..color = const Color(0xFFBDBDBD)
        ..strokeWidth = 1.5,
    );
    _drawSimplePerson(canvas, feet, ph, shirtColor: const Color(0xFFF5F5F5));
    final headCenter = Offset(feet.dx, feet.dy - ph * 0.84 - ph * 0.16);
    canvas.drawCircle(headCenter, ph * 0.26, Paint()..color = const Color(0x554FA8E0));
    canvas.drawCircle(
      headCenter,
      ph * 0.26,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Scene 16: "Under the Sea" - nước xanh, cát vàng ở đáy, ĐÚNG 4 con cá (3 cá
// CAM nhỏ + 1 cá TÍM to), rùa biển mai XANH LÁ, cua ĐỎ trên cát, sao biển
// VÀNG trên cát, rương kho báu nâu bên PHẢI, rong biển xanh, bong bóng trắng
// (khớp câu hỏi trong scenes.json).
// ---------------------------------------------------------------------------
class _SeaScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF4FB3E8));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.8, w, h * 0.2), Paint()..color = const Color(0xFFF2D59A));

    // Rong biển (3 dải lượn sóng).
    final weed = Paint()
      ..color = const Color(0xFF2F9E5B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round;
    for (final x in [0.07, 0.14, 0.93]) {
      canvas.drawPath(
        Path()
          ..moveTo(w * x, h * 0.84)
          ..quadraticBezierTo(w * (x - 0.03), h * 0.72, w * x, h * 0.62)
          ..quadraticBezierTo(w * (x + 0.03), h * 0.52, w * x, h * 0.44),
        weed,
      );
    }

    // 4 con cá: 3 cam nhỏ + 1 tím to.
    _drawFish(canvas, Offset(w * 0.3, h * 0.2), w * 0.11, const Color(0xFFF5922A));
    _drawFish(canvas, Offset(w * 0.55, h * 0.14), w * 0.1, const Color(0xFFF5922A), facingRight: false);
    _drawFish(canvas, Offset(w * 0.38, h * 0.42), w * 0.1, const Color(0xFFF5922A));
    _drawFish(canvas, Offset(w * 0.75, h * 0.3), w * 0.2, const Color(0xFF8E5BD0), facingRight: false);

    // Bong bóng (vòng tròn trắng).
    final bubble = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final p in [Offset(w * 0.5, h * 0.36), Offset(w * 0.52, h * 0.29), Offset(w * 0.5, h * 0.22)]) {
      canvas.drawCircle(p, w * 0.012, bubble);
    }

    // Rùa biển: mai xanh lá + đầu + 4 chân chèo.
    final turtleC = Offset(w * 0.6, h * 0.58);
    final skin = Paint()..color = const Color(0xFF9CCB6E);
    canvas.drawCircle(turtleC.translate(w * 0.1, -h * 0.01), w * 0.03, skin);
    for (final d in [Offset(-0.06, -0.06), Offset(0.05, -0.07), Offset(-0.06, 0.06), Offset(0.05, 0.07)]) {
      canvas.drawOval(
        Rect.fromCenter(center: turtleC.translate(w * d.dx, h * d.dy), width: w * 0.06, height: h * 0.05),
        skin,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: turtleC, width: w * 0.16, height: h * 0.14),
      Paint()..color = const Color(0xFF2F7D4A),
    );

    // Cua đỏ trên cát (bên trái).
    final crabC = Offset(w * 0.3, h * 0.88);
    final crab = Paint()..color = const Color(0xFFE84C3D);
    canvas.drawOval(Rect.fromCenter(center: crabC, width: w * 0.09, height: h * 0.06), crab);
    canvas.drawCircle(crabC.translate(-w * 0.065, -h * 0.04), w * 0.017, crab);
    canvas.drawCircle(crabC.translate(w * 0.065, -h * 0.04), w * 0.017, crab);
    canvas.drawCircle(crabC.translate(-w * 0.015, -h * 0.035), w * 0.008, Paint()..color = Colors.black87);
    canvas.drawCircle(crabC.translate(w * 0.015, -h * 0.035), w * 0.008, Paint()..color = Colors.black87);

    // Sao biển vàng trên cát.
    _drawFivePointStar(canvas, Offset(w * 0.55, h * 0.9), w * 0.04, const Color(0xFFFFC94A));

    // Rương kho báu (bên phải, trên cát).
    final chest = Rect.fromLTWH(w * 0.76, h * 0.8, w * 0.14, h * 0.12);
    canvas.drawRect(chest, Paint()..color = const Color(0xFF8D6748));
    canvas.drawRect(Rect.fromLTWH(chest.left, chest.top, chest.width, h * 0.035), Paint()..color = const Color(0xFF6E4E32));
    canvas.drawRect(
      Rect.fromCenter(center: Offset(chest.center.dx, chest.top + h * 0.045), width: w * 0.025, height: h * 0.035),
      Paint()..color = const Color(0xFFFFC94A),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Scene 17: "On the Street" - ban ngày, ĐÚNG 2 toà nhà, xe buýt ĐỎ (thấy 2
// bánh) bên trái, ô tô VÀNG bên phải, vạch qua đường trắng, đèn giao thông
// đang sáng XANH, bé gái áo HỒNG đứng trên vỉa hè chờ qua đường; KHÔNG có
// xe đạp (khớp câu hỏi trong scenes.json).
// ---------------------------------------------------------------------------
class _StreetScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.55), Paint()..color = const Color(0xFFBEE7FF));
    _drawSun(canvas, Offset(w * 0.5, h * 0.12), w * 0.04, const Color(0xFFFFC94A));

    // 2 toà nhà.
    final window = Paint()..color = const Color(0xFFFFE08A);
    canvas.drawRect(Rect.fromLTWH(w * 0.04, h * 0.1, w * 0.22, h * 0.45), Paint()..color = const Color(0xFF9EA7B3));
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 3; col++) {
        canvas.drawRect(Rect.fromLTWH(w * (0.065 + col * 0.065), h * (0.15 + row * 0.095), w * 0.04, h * 0.055), window);
      }
    }
    canvas.drawRect(Rect.fromLTWH(w * 0.74, h * 0.2, w * 0.22, h * 0.35), Paint()..color = const Color(0xFFC98B4E));
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        canvas.drawRect(Rect.fromLTWH(w * (0.765 + col * 0.065), h * (0.25 + row * 0.095), w * 0.04, h * 0.055), window);
      }
    }

    // Vỉa hè trên, mặt đường, vỉa hè dưới.
    canvas.drawRect(Rect.fromLTWH(0, h * 0.55, w, h * 0.08), Paint()..color = const Color(0xFFD6D6D6));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.63, w, h * 0.29), Paint()..color = const Color(0xFF5A5A5A));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.92, w, h * 0.08), Paint()..color = const Color(0xFFD6D6D6));

    // Vạch qua đường (các thanh trắng nằm ngang giữa đường).
    final zebra = Paint()..color = Colors.white;
    for (var i = 0; i < 5; i++) {
      canvas.drawRect(Rect.fromLTWH(w * 0.44, h * (0.645 + i * 0.056), w * 0.12, h * 0.03), zebra);
    }

    // Đèn giao thông: cột + hộp đen + đèn XANH đang sáng.
    canvas.drawRect(Rect.fromLTWH(w * 0.665, h * 0.3, w * 0.012, h * 0.3), Paint()..color = const Color(0xFF424242));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.645, h * 0.12, w * 0.052, h * 0.2), const Radius.circular(4)),
      Paint()..color = const Color(0xFF212121),
    );
    canvas.drawCircle(Offset(w * 0.671, h * 0.155), w * 0.014, Paint()..color = const Color(0xFF5C2A27));
    canvas.drawCircle(Offset(w * 0.671, h * 0.22), w * 0.014, Paint()..color = const Color(0xFF5C5427));
    canvas.drawCircle(Offset(w * 0.671, h * 0.285), w * 0.014, Paint()..color = const Color(0xFF3CE06B));

    // Bé gái áo hồng đứng trên vỉa hè cạnh vạch qua đường.
    _drawSimplePerson(canvas, Offset(w * 0.6, h * 0.6), h * 0.24, shirtColor: const Color(0xFFE87FA0));

    // Xe buýt đỏ (bên trái).
    final bus = Rect.fromLTWH(w * 0.04, h * 0.64, w * 0.34, h * 0.18);
    canvas.drawRRect(RRect.fromRectAndRadius(bus, Radius.circular(w * 0.015)), Paint()..color = const Color(0xFFE84C3D));
    for (var i = 0; i < 4; i++) {
      canvas.drawRect(Rect.fromLTWH(bus.left + w * (0.02 + i * 0.08), bus.top + h * 0.025, w * 0.06, h * 0.06), Paint()..color = const Color(0xFFBEE7FF));
    }
    _drawWheel(canvas, Offset(bus.left + w * 0.07, bus.bottom), w * 0.03);
    _drawWheel(canvas, Offset(bus.right - w * 0.07, bus.bottom), w * 0.03);

    // Ô tô vàng (bên phải, nhỏ hơn xe buýt).
    final carBody = Rect.fromLTWH(w * 0.7, h * 0.77, w * 0.2, h * 0.08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.74, h * 0.71, w * 0.11, h * 0.07), Radius.circular(w * 0.015)),
      Paint()..color = const Color(0xFFFFC94A),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(carBody, Radius.circular(w * 0.015)), Paint()..color = const Color(0xFFFFC94A));
    canvas.drawRect(Rect.fromLTWH(w * 0.755, h * 0.725, w * 0.08, h * 0.04), Paint()..color = const Color(0xFFBEE7FF));
    _drawWheel(canvas, Offset(carBody.left + w * 0.04, carBody.bottom), w * 0.022);
    _drawWheel(canvas, Offset(carBody.right - w * 0.04, carBody.bottom), w * 0.022);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Scene 18: "Camping" - ban đêm: trăng vàng nhạt bên PHẢI + 5 ngôi sao, ĐÚNG
// 3 cây thông bên TRÁI, lều màu CAM, lửa trại đang cháy, ĐÚNG 2 người: bố áo
// XANH DƯƠNG + bé gái áo TÍM; không có tuyết (khớp câu hỏi trong scenes.json).
// ---------------------------------------------------------------------------
class _CampingScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.66), Paint()..color = const Color(0xFF24305E));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.66, w, h * 0.34), Paint()..color = const Color(0xFF3E7B4E));

    canvas.drawCircle(Offset(w * 0.86, h * 0.16), w * 0.06, Paint()..color = const Color(0xFFFFF3B0));
    for (final p in [
      Offset(w * 0.45, h * 0.08),
      Offset(w * 0.6, h * 0.2),
      Offset(w * 0.7, h * 0.06),
      Offset(w * 0.38, h * 0.3),
      Offset(w * 0.55, h * 0.38),
    ]) {
      _drawFivePointStar(canvas, p, w * 0.018, const Color(0xFFFFF3B0));
    }

    // 3 cây thông bên trái.
    _drawPineTree(canvas, Offset(w * 0.07, h * 0.72), h * 0.5, w * 0.14);
    _drawPineTree(canvas, Offset(w * 0.18, h * 0.7), h * 0.42, w * 0.12);
    _drawPineTree(canvas, Offset(w * 0.28, h * 0.72), h * 0.48, w * 0.13);

    // Lều màu cam + cửa lều.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.62, h * 0.84)
        ..lineTo(w * 0.94, h * 0.84)
        ..lineTo(w * 0.78, h * 0.48)
        ..close(),
      Paint()..color = const Color(0xFFF08A3C),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.74, h * 0.84)
        ..lineTo(w * 0.82, h * 0.84)
        ..lineTo(w * 0.78, h * 0.66)
        ..close(),
      Paint()..color = const Color(0xFFB85A1E),
    );

    // Lửa trại: 2 khúc gỗ bắt chéo + ngọn lửa.
    final fire = Offset(w * 0.44, h * 0.9);
    final log = Paint()
      ..color = const Color(0xFF7A5536)
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(fire.translate(-w * 0.06, h * 0.03), fire.translate(w * 0.06, -h * 0.01), log);
    canvas.drawLine(fire.translate(w * 0.06, h * 0.03), fire.translate(-w * 0.06, -h * 0.01), log);
    canvas.drawPath(
      Path()
        ..moveTo(fire.dx - w * 0.04, fire.dy)
        ..quadraticBezierTo(fire.dx - w * 0.03, fire.dy - h * 0.1, fire.dx, fire.dy - h * 0.14)
        ..quadraticBezierTo(fire.dx + w * 0.03, fire.dy - h * 0.1, fire.dx + w * 0.04, fire.dy)
        ..close(),
      Paint()..color = const Color(0xFFF5922A),
    );
    canvas.drawPath(
      Path()
        ..moveTo(fire.dx - w * 0.02, fire.dy)
        ..quadraticBezierTo(fire.dx - w * 0.01, fire.dy - h * 0.05, fire.dx, fire.dy - h * 0.08)
        ..quadraticBezierTo(fire.dx + w * 0.01, fire.dy - h * 0.05, fire.dx + w * 0.02, fire.dy)
        ..close(),
      Paint()..color = const Color(0xFFFFD43B),
    );

    // Bố áo xanh dương (trái lửa) + bé gái áo tím (phải lửa).
    _drawSimplePerson(canvas, Offset(w * 0.3, h * 0.97), h * 0.34, shirtColor: const Color(0xFF4FA8E0));
    _drawSimplePerson(canvas, Offset(w * 0.57, h * 0.97), h * 0.25, shirtColor: const Color(0xFFB07AD1));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter dự phòng nếu [illustrationId] không khớp bất kỳ scene nào đã biết
/// (không nên xảy ra với nội dung hợp lệ - phòng lỗi dữ liệu thay vì crash).
class _UnknownScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFEFEFEF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
