import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/entities/pet_accessory.dart';
import '../../domain/entities/pet_character.dart';
import '../../domain/entities/pet_palette.dart';
import 'mimi_painter.dart';
import 'pet_accessory_painter.dart';

/// Vẽ 3 nhân vật (Thỏ Bunny / Mèo Mimi / Rùa Moni) bằng Canvas thuần, dựa
/// trên bộ vector bạn gửi. Mỗi con có "bề mặt" tham số khác nhau (thỏ+mèo có
/// 2 tai, rùa không có tai mà có [MoniTurtlePainter.headYOffset] để rụt đầu
/// vào mai) - [buildPetCharacterPainter] là nơi DUY NHẤT dịch 1 [MimiPose]
/// dùng chung (xem `mimi_painter.dart`) sang đúng tham số của từng con, để
/// phần còn lại của app (animation, mood...) không cần biết đang vẽ con nào.
///
/// Khác với painter cũ (tự scale theo `designWidth/designHeight` cố định),
/// 3 painter dưới đây vẽ theo toạ độ TUYỆT ĐỐI quanh tâm khung - nên được
/// bọc trong [PetCharacterPainter], luôn vẽ vào 1 khung tham chiếu
/// `petCharacterReferenceSize` cố định rồi scale ra đúng kích thước thật
/// (giống hệt cách `hitTestPetCharacter` tính lại toạ độ chạm).

/// ---------------------------------------------------------------------------
/// 1. THỎ BUNNY
/// ---------------------------------------------------------------------------
class BunnyPainter extends CustomPainter {
  final double eyeOpenRatio; // 0.0 (nhắm) -> 1.0 (mở)
  final double mouthRatio; // 0.0 (đóng) -> 1.0 (mở nói/cười)
  final double leftEarStretch; // 1.0 (bình thường) -> lớn hơn = kéo dài
  final double rightEarStretch;
  final double leftEarAngle; // radian, vẫy/kéo tai
  final double rightEarAngle;
  final bool isHappy;
  final PetPalette palette;

  BunnyPainter({
    this.eyeOpenRatio = 1.0,
    this.mouthRatio = 0.2,
    this.leftEarStretch = 1.0,
    this.rightEarStretch = 1.0,
    this.leftEarAngle = 0.0,
    this.rightEarAngle = 0.0,
    this.isHappy = false,
    this.palette = PetPalette.classic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final colors = bunnyPaletteColors[palette]!;
    final center = Offset(size.width / 2, size.height / 2 + 10);
    final primaryPaint = Paint()
      ..color = colors.primary
      ..style = PaintingStyle.fill;
    final secondaryPaint = Paint()
      ..color = colors.secondary
      ..style = PaintingStyle.fill;
    final skinPaint = Paint()
      ..color = colors.skin
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    // Tai trái
    canvas.save();
    canvas.translate(center.dx - 35, center.dy - 40);
    canvas.rotate(leftEarAngle);
    canvas.scale(1.0, leftEarStretch);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 32, height: 80), primaryPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 16, height: 50), secondaryPaint);
    canvas.restore();
    // Tai phải
    canvas.save();
    canvas.translate(center.dx + 35, center.dy - 40);
    canvas.rotate(rightEarAngle);
    canvas.scale(1.0, rightEarStretch);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 32, height: 80), primaryPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 16, height: 50), secondaryPaint);
    canvas.restore();
    // Thân
    final bodyPath = Path()
      ..moveTo(center.dx - 40, center.dy + 80)
      ..cubicTo(center.dx - 40, center.dy + 20, center.dx + 40, center.dy + 20, center.dx + 40, center.dy + 80)
      ..close();
    canvas.drawPath(bodyPath, primaryPaint);
    // Bụng
    final bellyPath = Path()
      ..moveTo(center.dx - 25, center.dy + 80)
      ..cubicTo(center.dx - 25, center.dy + 40, center.dx + 25, center.dy + 40, center.dx + 25, center.dy + 80)
      ..close();
    canvas.drawPath(bellyPath, skinPaint);
    // Đầu
    canvas.drawCircle(Offset(center.dx, center.dy - 10), 50, primaryPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy - 2), width: 80, height: 60), skinPaint);
    // Má hồng
    final blushPaint = Paint()..color = colors.secondary.withValues(alpha: 0.35);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 30, center.dy + 2), width: 14, height: 8), blushPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 30, center.dy + 2), width: 14, height: 8), blushPaint);
    // Mắt
    if (isHappy) {
      final leftEyePath = Path()
        ..moveTo(center.dx - 28, center.dy - 10)
        ..quadraticBezierTo(center.dx - 20, center.dy - 18, center.dx - 12, center.dy - 10);
      final rightEyePath = Path()
        ..moveTo(center.dx + 12, center.dy - 10)
        ..quadraticBezierTo(center.dx + 20, center.dy - 18, center.dx + 28, center.dy - 10);
      canvas.drawPath(leftEyePath, strokePaint);
      canvas.drawPath(rightEyePath, strokePaint);
    } else {
      final eyeHeight = 12.0 * eyeOpenRatio.clamp(0.1, 1.0);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx - 20, center.dy - 10), width: 10, height: eyeHeight),
        Paint()..color = const Color(0xFF2C3E50),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx + 20, center.dy - 10), width: 10, height: eyeHeight),
        Paint()..color = const Color(0xFF2C3E50),
      );
    }
    // Mũi
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy), width: 8, height: 6), secondaryPaint);
    // Miệng
    if (mouthRatio > 0.4) {
      final mouthPath = Path()
        ..moveTo(center.dx - 10, center.dy + 8)
        ..quadraticBezierTo(center.dx, center.dy + 8 + (15 * mouthRatio), center.dx + 10, center.dy + 8)
        ..close();
      canvas.drawPath(mouthPath, Paint()..color = const Color(0xFFB00020));
    } else {
      final mouthPath = Path()
        ..moveTo(center.dx - 8, center.dy + 8)
        ..quadraticBezierTo(center.dx - 4, center.dy + 14, center.dx, center.dy + 8)
        ..quadraticBezierTo(center.dx + 4, center.dy + 14, center.dx + 8, center.dy + 8);
      canvas.drawPath(mouthPath, strokePaint);
    }
    // Chân
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 40, center.dy + 75), width: 26, height: 16), primaryPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 40, center.dy + 75), width: 26, height: 16), primaryPaint);
  }

  @override
  bool shouldRepaint(covariant BunnyPainter oldDelegate) => true;
}

/// ---------------------------------------------------------------------------
/// 2. MÈO MIMI
/// ---------------------------------------------------------------------------
class MimiCatPainter extends CustomPainter {
  final double eyeOpenRatio;
  final double mouthRatio;
  final double leftEarStretch;
  final double rightEarStretch;
  final double leftEarAngle;
  final double rightEarAngle;
  final bool isHappy;
  final PetPalette palette;

  MimiCatPainter({
    this.eyeOpenRatio = 1.0,
    this.mouthRatio = 0.2,
    this.leftEarStretch = 1.0,
    this.rightEarStretch = 1.0,
    this.leftEarAngle = 0.0,
    this.rightEarAngle = 0.0,
    this.isHappy = false,
    this.palette = PetPalette.classic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final colors = catPaletteColors[palette]!;
    final center = Offset(size.width / 2, size.height / 2 + 10);
    final primaryPaint = Paint()
      ..color = colors.primary
      ..style = PaintingStyle.fill;
    final earInnerPaint = Paint()
      ..color = colors.earInner
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    // Tai mèo (tam giác) - xoay/kéo dài quanh gốc tai (sát đầu) để vẫy/kéo
    // tai được, giống cách tai thỏ hoạt động.
    canvas.save();
    final leftPivot = Offset(center.dx - 30, center.dy - 20);
    canvas.translate(leftPivot.dx, leftPivot.dy);
    canvas.rotate(leftEarAngle);
    canvas.scale(1.0, leftEarStretch);
    canvas.translate(-leftPivot.dx, -leftPivot.dy);
    final leftEar = Path()
      ..moveTo(center.dx - 50, center.dy - 20)
      ..lineTo(center.dx - 25, center.dy - 75)
      ..lineTo(center.dx - 10, center.dy - 40)
      ..close();
    canvas.drawPath(leftEar, primaryPaint);
    final leftEarInner = Path()
      ..moveTo(center.dx - 45, center.dy - 25)
      ..lineTo(center.dx - 27, center.dy - 65)
      ..lineTo(center.dx - 15, center.dy - 40)
      ..close();
    canvas.drawPath(leftEarInner, earInnerPaint);
    canvas.restore();
    canvas.save();
    final rightPivot = Offset(center.dx + 30, center.dy - 20);
    canvas.translate(rightPivot.dx, rightPivot.dy);
    canvas.rotate(rightEarAngle);
    canvas.scale(1.0, rightEarStretch);
    canvas.translate(-rightPivot.dx, -rightPivot.dy);
    final rightEar = Path()
      ..moveTo(center.dx + 10, center.dy - 40)
      ..lineTo(center.dx + 25, center.dy - 75)
      ..lineTo(center.dx + 50, center.dy - 20)
      ..close();
    canvas.drawPath(rightEar, primaryPaint);
    final rightEarInner = Path()
      ..moveTo(center.dx + 15, center.dy - 40)
      ..lineTo(center.dx + 27, center.dy - 65)
      ..lineTo(center.dx + 45, center.dy - 25)
      ..close();
    canvas.drawPath(rightEarInner, earInnerPaint);
    canvas.restore();
    // Thân mèo
    final bodyPath = Path()
      ..moveTo(center.dx - 38, center.dy + 80)
      ..cubicTo(center.dx - 38, center.dy + 25, center.dx + 38, center.dy + 25, center.dx + 38, center.dy + 80)
      ..close();
    canvas.drawPath(bodyPath, primaryPaint);
    // Bụng (màu tương phản nhẹ với lông, để luôn rõ kể cả khi lông trắng)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 55), width: 42, height: 45),
      Paint()..color = colors.belly,
    );
    // Đầu mèo
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy - 10), width: 95, height: 75), primaryPaint);
    // Mắt mèo
    if (isHappy) {
      final leftEyePath = Path()
        ..moveTo(center.dx - 28, center.dy - 12)
        ..quadraticBezierTo(center.dx - 20, center.dy - 20, center.dx - 12, center.dy - 12);
      final rightEyePath = Path()
        ..moveTo(center.dx + 12, center.dy - 12)
        ..quadraticBezierTo(center.dx + 20, center.dy - 20, center.dx + 28, center.dy - 12);
      canvas.drawPath(leftEyePath, strokePaint);
      canvas.drawPath(rightEyePath, strokePaint);
    } else {
      final eyeHeight = 14.0 * eyeOpenRatio.clamp(0.1, 1.0);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx - 22, center.dy - 12), width: 12, height: eyeHeight),
        Paint()..color = const Color(0xFF2C3E50),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx + 22, center.dy - 12), width: 12, height: eyeHeight),
        Paint()..color = const Color(0xFF2C3E50),
      );
      // Điểm sáng trong mắt
      if (eyeOpenRatio > 0.5) {
        canvas.drawCircle(Offset(center.dx - 24, center.dy - 15), 2.5, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(center.dx + 20, center.dy - 15), 2.5, Paint()..color = Colors.white);
      }
    }
    // Râu mèo
    canvas.drawLine(Offset(center.dx - 35, center.dy - 2), Offset(center.dx - 55, center.dy - 8), strokePaint..strokeWidth = 2);
    canvas.drawLine(Offset(center.dx - 35, center.dy + 4), Offset(center.dx - 58, center.dy + 6), strokePaint);
    canvas.drawLine(Offset(center.dx + 35, center.dy - 2), Offset(center.dx + 55, center.dy - 8), strokePaint);
    canvas.drawLine(Offset(center.dx + 35, center.dy + 4), Offset(center.dx + 58, center.dy + 6), strokePaint);
    // Mũi nhỏ
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - 4, center.dy - 2)
        ..lineTo(center.dx + 4, center.dy - 2)
        ..lineTo(center.dx, center.dy + 3)
        ..close(),
      earInnerPaint,
    );
    // Miệng mèo - có mở/nói khi mouthRatio lớn (giống thỏ), giữ nụ cười nhỏ
    // lúc bình thường (giống bản gốc bạn gửi).
    if (mouthRatio > 0.4) {
      final openT = min(mouthRatio, 1.0);
      final mouthPath = Path()
        ..moveTo(center.dx - 7, center.dy + 5)
        ..quadraticBezierTo(center.dx, center.dy + 5 + (12 * openT), center.dx + 7, center.dy + 5)
        ..close();
      canvas.drawPath(mouthPath, Paint()..color = const Color(0xFFB4457A));
    } else {
      final mouthPath = Path()
        ..moveTo(center.dx - 8, center.dy + 5)
        ..quadraticBezierTo(center.dx - 4, center.dy + 10, center.dx, center.dy + 5)
        ..quadraticBezierTo(center.dx + 4, center.dy + 10, center.dx + 8, center.dy + 5);
      canvas.drawPath(mouthPath, strokePaint..strokeWidth = 2.5);
    }
    // Chân trước
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 18, center.dy + 65), width: 16, height: 22), primaryPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 18, center.dy + 65), width: 16, height: 22), primaryPaint);
  }

  @override
  bool shouldRepaint(covariant MimiCatPainter oldDelegate) => true;
}

/// ---------------------------------------------------------------------------
/// 3. RÙA MONI
/// ---------------------------------------------------------------------------
class MoniTurtlePainter extends CustomPainter {
  final double eyeOpenRatio;
  final double headYOffset; // Nhô đầu ra/rụt vào mai
  final bool isHappy;
  final PetPalette palette;

  MoniTurtlePainter({
    this.eyeOpenRatio = 1.0,
    this.headYOffset = 0.0,
    this.isHappy = false,
    this.palette = PetPalette.classic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final colors = turtlePaletteColors[palette]!;
    final center = Offset(size.width / 2, size.height / 2 + 15);
    final shellPaint = Paint()
      ..color = colors.shell
      ..style = PaintingStyle.fill;
    final shellPatternPaint = Paint()
      ..color = colors.shellPattern
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final skinPaint = Paint()
      ..color = colors.skin
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    // 4 Chân rùa
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 45, center.dy + 20), width: 24, height: 18), skinPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 45, center.dy + 20), width: 24, height: 18), skinPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 35, center.dy + 45), width: 26, height: 18), skinPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 35, center.dy + 45), width: 26, height: 18), skinPaint);
    // Đầu rùa (tuỳ chỉnh vị trí nhô lên/rụt vào)
    final headCenter = Offset(center.dx, center.dy - 35 + headYOffset);
    canvas.drawCircle(headCenter, 32, skinPaint);
    // Mắt rùa
    if (isHappy) {
      final leftEyePath = Path()
        ..moveTo(headCenter.dx - 18, headCenter.dy - 4)
        ..quadraticBezierTo(headCenter.dx - 12, headCenter.dy - 10, headCenter.dx - 6, headCenter.dy - 4);
      final rightEyePath = Path()
        ..moveTo(headCenter.dx + 6, headCenter.dy - 4)
        ..quadraticBezierTo(headCenter.dx + 12, headCenter.dy - 10, headCenter.dx + 18, headCenter.dy - 4);
      canvas.drawPath(leftEyePath, strokePaint);
      canvas.drawPath(rightEyePath, strokePaint);
    } else {
      final eyeHeight = 10.0 * eyeOpenRatio.clamp(0.1, 1.0);
      canvas.drawCircle(Offset(headCenter.dx - 12, headCenter.dy - 4), eyeHeight / 2, Paint()..color = const Color(0xFF2C3E50));
      canvas.drawCircle(Offset(headCenter.dx + 12, headCenter.dy - 4), eyeHeight / 2, Paint()..color = const Color(0xFF2C3E50));
    }
    // Má hồng nhẹ
    final blushPaint = Paint()..color = const Color(0xFFFF8B94).withValues(alpha: 0.4);
    canvas.drawCircle(Offset(headCenter.dx - 18, headCenter.dy + 6), 5, blushPaint);
    canvas.drawCircle(Offset(headCenter.dx + 18, headCenter.dy + 6), 5, blushPaint);
    // Miệng cười
    final mouthPath = Path()
      ..moveTo(headCenter.dx - 8, headCenter.dy + 8)
      ..quadraticBezierTo(headCenter.dx, headCenter.dy + 15, headCenter.dx + 8, headCenter.dy + 8);
    canvas.drawPath(mouthPath, strokePaint);
    // Mai rùa (vòm chính)
    final shellPath = Path()
      ..moveTo(center.dx - 55, center.dy + 35)
      ..cubicTo(center.dx - 60, center.dy - 30, center.dx + 60, center.dy - 30, center.dx + 55, center.dy + 35)
      ..close();
    canvas.drawPath(shellPath, shellPaint);
    canvas.drawPath(shellPath, strokePaint);
    // Hoa văn mai rùa
    canvas.drawCircle(Offset(center.dx, center.dy), 14, shellPatternPaint);
    canvas.drawCircle(Offset(center.dx - 22, center.dy + 10), 10, shellPatternPaint);
    canvas.drawCircle(Offset(center.dx + 22, center.dy + 10), 10, shellPatternPaint);
  }

  @override
  bool shouldRepaint(covariant MoniTurtlePainter oldDelegate) => true;
}

/// ---------------------------------------------------------------------------
/// 4. SÓC RAN
/// ---------------------------------------------------------------------------
class SquirrelPainter extends CustomPainter {
  final double eyeOpenRatio;
  final double mouthRatio;
  final double leftEarStretch;
  final double rightEarStretch;
  final double leftEarAngle;
  final double rightEarAngle;
  final bool isHappy;
  final PetPalette palette;

  SquirrelPainter({
    this.eyeOpenRatio = 1.0,
    this.mouthRatio = 0.2,
    this.leftEarStretch = 1.0,
    this.rightEarStretch = 1.0,
    this.leftEarAngle = 0.0,
    this.rightEarAngle = 0.0,
    this.isHappy = false,
    this.palette = PetPalette.classic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final colors = squirrelPaletteColors[palette]!;
    final center = Offset(size.width / 2, size.height / 2 + 10);
    final primaryPaint = Paint()
      ..color = colors.primary
      ..style = PaintingStyle.fill;
    final secondaryPaint = Paint()
      ..color = colors.secondary
      ..style = PaintingStyle.fill;
    final skinPaint = Paint()
      ..color = colors.skin
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    // Đuôi xù (nét đặc trưng của sóc) - vẽ TRƯỚC thân/đầu để nằm ĐÈ SAU
    // lưng, cong vòng từ hông lên qua sau đầu, có 1 dải màu đậm hơn ở giữa
    // cho cảm giác "xù lông" mà không cần vẽ từng sợi lông riêng lẻ.
    final tailPath = Path()
      ..moveTo(center.dx + 30, center.dy + 70)
      ..cubicTo(
        center.dx + 85,
        center.dy + 55,
        center.dx + 78,
        center.dy - 55,
        center.dx + 18,
        center.dy - 78,
      )
      ..cubicTo(
        center.dx + 45,
        center.dy - 40,
        center.dx + 50,
        center.dy + 40,
        center.dx + 15,
        center.dy + 60,
      )
      ..close();
    canvas.drawPath(tailPath, primaryPaint);
    final tailStripe = Path()
      ..moveTo(center.dx + 38, center.dy + 55)
      ..cubicTo(
        center.dx + 68,
        center.dy + 40,
        center.dx + 62,
        center.dy - 45,
        center.dx + 22,
        center.dy - 62,
      );
    canvas.drawPath(tailStripe, strokePaint..strokeWidth = 6);
    // Tai (nhỏ, tròn hơn tai thỏ) - cùng cơ chế xoay/kéo dài để vẫy/kéo tai
    // được giống thỏ/mèo.
    canvas.save();
    canvas.translate(center.dx - 32, center.dy - 42);
    canvas.rotate(leftEarAngle);
    canvas.scale(1.0, leftEarStretch);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 24, height: 30), primaryPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 12, height: 16), secondaryPaint);
    canvas.restore();
    canvas.save();
    canvas.translate(center.dx + 32, center.dy - 42);
    canvas.rotate(rightEarAngle);
    canvas.scale(1.0, rightEarStretch);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 24, height: 30), primaryPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 12, height: 16), secondaryPaint);
    canvas.restore();
    // Thân
    final bodyPath = Path()
      ..moveTo(center.dx - 38, center.dy + 78)
      ..cubicTo(center.dx - 38, center.dy + 22, center.dx + 38, center.dy + 22, center.dx + 38, center.dy + 78)
      ..close();
    canvas.drawPath(bodyPath, primaryPaint);
    // Bụng sáng màu
    final bellyPath = Path()
      ..moveTo(center.dx - 22, center.dy + 78)
      ..cubicTo(center.dx - 22, center.dy + 42, center.dx + 22, center.dy + 42, center.dx + 22, center.dy + 78)
      ..close();
    canvas.drawPath(bellyPath, skinPaint);
    // Đầu
    canvas.drawCircle(Offset(center.dx, center.dy - 10), 48, primaryPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy - 2), width: 74, height: 56), skinPaint);
    // Má hồng
    final blushPaint = Paint()..color = colors.secondary.withValues(alpha: 0.35);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 28, center.dy + 4), width: 14, height: 8), blushPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 28, center.dy + 4), width: 14, height: 8), blushPaint);
    // Mắt
    if (isHappy) {
      final leftEyePath = Path()
        ..moveTo(center.dx - 26, center.dy - 8)
        ..quadraticBezierTo(center.dx - 18, center.dy - 16, center.dx - 10, center.dy - 8);
      final rightEyePath = Path()
        ..moveTo(center.dx + 10, center.dy - 8)
        ..quadraticBezierTo(center.dx + 18, center.dy - 16, center.dx + 26, center.dy - 8);
      canvas.drawPath(leftEyePath, strokePaint..strokeWidth = 3);
      canvas.drawPath(rightEyePath, strokePaint);
    } else {
      final eyeHeight = 11.0 * eyeOpenRatio.clamp(0.1, 1.0);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx - 18, center.dy - 8), width: 10, height: eyeHeight),
        Paint()..color = const Color(0xFF2C3E50),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx + 18, center.dy - 8), width: 10, height: eyeHeight),
        Paint()..color = const Color(0xFF2C3E50),
      );
    }
    // Mũi
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy + 2), width: 7, height: 5), secondaryPaint);
    // Miệng
    if (mouthRatio > 0.4) {
      final mouthPath = Path()
        ..moveTo(center.dx - 9, center.dy + 9)
        ..quadraticBezierTo(center.dx, center.dy + 9 + (13 * mouthRatio), center.dx + 9, center.dy + 9)
        ..close();
      canvas.drawPath(mouthPath, Paint()..color = const Color(0xFFB00020));
    } else {
      final mouthPath = Path()
        ..moveTo(center.dx - 7, center.dy + 9)
        ..quadraticBezierTo(center.dx - 3, center.dy + 14, center.dx, center.dy + 9)
        ..quadraticBezierTo(center.dx + 3, center.dy + 14, center.dx + 7, center.dy + 9);
      canvas.drawPath(mouthPath, strokePaint..strokeWidth = 2.5);
    }
    // 2 tay nhỏ ôm phía trước bụng (dáng đặc trưng của sóc)
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 20, center.dy + 46), width: 14, height: 18), primaryPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 20, center.dy + 46), width: 14, height: 18), primaryPaint);
    // Chân
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 24, center.dy + 76), width: 22, height: 14), primaryPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 24, center.dy + 76), width: 22, height: 14), primaryPaint);
  }

  @override
  bool shouldRepaint(covariant SquirrelPainter oldDelegate) => true;
}

/// ---------------------------------------------------------------------------
/// 5. CHIM CÁNH CỤT PINGO
/// ---------------------------------------------------------------------------
class PenguinPainter extends CustomPainter {
  final double eyeOpenRatio;
  final double mouthRatio;

  /// Không có tai để kéo (giống Moni) - 2 giá trị này tái dùng LUÔN chuyển
  /// động "vẫy tai" có sẵn (ear twitch timer trong `PetAvatar`) để làm 2
  /// CÁNH (flipper) tự đung đưa nhẹ lúc rảnh, thay vì thêm hẳn 1 bộ tham số
  /// animation mới chỉ cho riêng Pingo.
  final double leftFlipperAngle;
  final double rightFlipperAngle;
  final bool isHappy;
  final PetPalette palette;

  PenguinPainter({
    this.eyeOpenRatio = 1.0,
    this.mouthRatio = 0.2,
    this.leftFlipperAngle = 0.0,
    this.rightFlipperAngle = 0.0,
    this.isHappy = false,
    this.palette = PetPalette.classic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final colors = penguinPaletteColors[palette]!;
    final center = Offset(size.width / 2, size.height / 2 + 10);
    final bodyPaint = Paint()
      ..color = colors.body
      ..style = PaintingStyle.fill;
    final bellyPaint = Paint()
      ..color = colors.belly
      ..style = PaintingStyle.fill;
    final beakPaint = Paint()
      ..color = colors.beak
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    // 2 chân (vẽ trước để nằm dưới thân)
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 22, center.dy + 84), width: 26, height: 14), beakPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 22, center.dy + 84), width: 26, height: 14), beakPaint);
    // 2 cánh (flipper) - đung đưa nhẹ quanh điểm neo ở vai.
    canvas.save();
    canvas.translate(center.dx - 42, center.dy + 20);
    canvas.rotate(leftFlipperAngle - 0.25);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 20, height: 55), bodyPaint);
    canvas.restore();
    canvas.save();
    canvas.translate(center.dx + 42, center.dy + 20);
    canvas.rotate(rightFlipperAngle + 0.25);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 20, height: 55), bodyPaint);
    canvas.restore();
    // Thân (hình quả trứng đứng) + bụng trắng phía trước
    final bodyPath = Path()
      ..moveTo(center.dx, center.dy - 58)
      ..cubicTo(center.dx + 46, center.dy - 58, center.dx + 46, center.dy + 90, center.dx, center.dy + 90)
      ..cubicTo(center.dx - 46, center.dy + 90, center.dx - 46, center.dy - 58, center.dx, center.dy - 58)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);
    final bellyPath = Path()
      ..moveTo(center.dx, center.dy - 30)
      ..cubicTo(center.dx + 26, center.dy - 30, center.dx + 28, center.dy + 84, center.dx, center.dy + 88)
      ..cubicTo(center.dx - 28, center.dy + 84, center.dx - 26, center.dy - 30, center.dx, center.dy - 30)
      ..close();
    canvas.drawPath(bellyPath, bellyPaint);
    // Đầu (tiếp nối màu thân, không tách rời)
    canvas.drawCircle(Offset(center.dx, center.dy - 55), 34, bodyPaint);
    // Mặt trắng quanh mắt (đặc trưng chim cánh cụt)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy - 55), width: 46, height: 32),
      bellyPaint,
    );
    // Mắt
    if (isHappy) {
      final leftEyePath = Path()
        ..moveTo(center.dx - 15, center.dy - 58)
        ..quadraticBezierTo(center.dx - 9, center.dy - 64, center.dx - 3, center.dy - 58);
      final rightEyePath = Path()
        ..moveTo(center.dx + 3, center.dy - 58)
        ..quadraticBezierTo(center.dx + 9, center.dy - 64, center.dx + 15, center.dy - 58);
      canvas.drawPath(leftEyePath, strokePaint..strokeWidth = 3);
      canvas.drawPath(rightEyePath, strokePaint);
    } else {
      final eyeHeight = 9.0 * eyeOpenRatio.clamp(0.1, 1.0);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx - 9, center.dy - 58), width: 8, height: eyeHeight),
        Paint()..color = const Color(0xFF2C3E50),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx + 9, center.dy - 58), width: 8, height: eyeHeight),
        Paint()..color = const Color(0xFF2C3E50),
      );
    }
    // Mỏ (tam giác cam) + miệng mở khi nói
    final beakOpen = mouthRatio > 0.4 ? min(mouthRatio, 1.0) : 0.0;
    canvas.save();
    canvas.translate(center.dx, center.dy - 44);
    final topBeak = Path()
      ..moveTo(-9, 0)
      ..lineTo(9, 0)
      ..lineTo(0, 14 + beakOpen * 6)
      ..close();
    canvas.drawPath(topBeak, beakPaint);
    if (beakOpen > 0) {
      final bottomBeak = Path()
        ..moveTo(-8, 14 + beakOpen * 6)
        ..lineTo(8, 14 + beakOpen * 6)
        ..lineTo(0, 14 + beakOpen * 14)
        ..close();
      canvas.drawPath(bottomBeak, beakPaint);
    }
    canvas.restore();
    // Má hồng
    final blushPaint = Paint()..color = const Color(0xFFFF8B94).withValues(alpha: 0.35);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 22, center.dy - 44), width: 12, height: 7), blushPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 22, center.dy - 44), width: 12, height: 7), blushPaint);
  }

  @override
  bool shouldRepaint(covariant PenguinPainter oldDelegate) => true;
}

/// ---------------------------------------------------------------------------
/// Bảng màu theo [PetPalette] - mỗi nhân vật có bộ màu RIÊNG cho từng
/// palette (mèo trắng khác thỏ trắng khác rùa trắng), để bé chọn 1
/// [PetPalette] chung mà con nào cũng ra hình đẹp/hợp lý. Đây là nơi DUY
/// NHẤT định nghĩa màu sắc của 3 nhân vật - muốn thêm màu mới, thêm giá trị
/// vào enum `PetPalette` (`lib/domain/entities/pet_palette.dart`) rồi thêm
/// 1 dòng vào MỖI bảng dưới đây (bunny/cat/turtle).
/// ---------------------------------------------------------------------------

class _BunnyColors {
  final Color primary;
  final Color secondary;
  final Color skin;
  const _BunnyColors({required this.primary, required this.secondary, required this.skin});
}

const Map<PetPalette, _BunnyColors> bunnyPaletteColors = {
  PetPalette.classic: _BunnyColors(
    primary: Color(0xFFFFB6C1),
    secondary: Color(0xFFFF69B4),
    skin: Color(0xFFFFF0F5),
  ),
  PetPalette.snow: _BunnyColors(
    primary: Color(0xFFFAFAFA),
    secondary: Color(0xFFE3B8C8),
    skin: Color(0xFFFFFFFF),
  ),
  PetPalette.sky: _BunnyColors(
    primary: Color(0xFFAEE3F5),
    secondary: Color(0xFF6FC7E8),
    skin: Color(0xFFEFFCFF),
  ),
  PetPalette.mint: _BunnyColors(
    primary: Color(0xFFB7ECD0),
    secondary: Color(0xFF74D6A2),
    skin: Color(0xFFF0FFF6),
  ),
  PetPalette.blossom: _BunnyColors(
    primary: Color(0xFFFFD6EC),
    secondary: Color(0xFFFF8FC7),
    skin: Color(0xFFFFF3FA),
  ),
};

class _CatColors {
  final Color primary;
  final Color earInner;
  final Color belly;
  const _CatColors({required this.primary, required this.earInner, required this.belly});
}

const Map<PetPalette, _CatColors> catPaletteColors = {
  PetPalette.classic: _CatColors(
    primary: Color(0xFFFFD1DC), // Creamy Pink
    earInner: Color(0xFFFF9EAA),
    belly: Color(0xFFFFFFFF),
  ),
  PetPalette.snow: _CatColors(
    primary: Color(0xFFF7F7F7),
    earInner: Color(0xFFE8B9C6),
    belly: Color(0xFFE4E4E4),
  ),
  PetPalette.sky: _CatColors(
    primary: Color(0xFFAEE3F5),
    earInner: Color(0xFF6FC7E8),
    belly: Color(0xFFFFFFFF),
  ),
  PetPalette.mint: _CatColors(
    primary: Color(0xFFB7ECD0),
    earInner: Color(0xFF74D6A2),
    belly: Color(0xFFFFFFFF),
  ),
  PetPalette.blossom: _CatColors(
    primary: Color(0xFFFFD6EC),
    earInner: Color(0xFFFF8FC7),
    belly: Color(0xFFFFFFFF),
  ),
};

class _TurtleColors {
  final Color shell;
  final Color shellPattern;
  final Color skin;
  const _TurtleColors({required this.shell, required this.shellPattern, required this.skin});
}

const Map<PetPalette, _TurtleColors> turtlePaletteColors = {
  PetPalette.classic: _TurtleColors(
    shell: Color(0xFF7BC043),
    shellPattern: Color(0xFF439A2A),
    skin: Color(0xFFA8E6CF),
  ),
  PetPalette.snow: _TurtleColors(
    shell: Color(0xFFF0F0F0),
    shellPattern: Color(0xFFCBCBCB),
    skin: Color(0xFFFFFFFF),
  ),
  PetPalette.sky: _TurtleColors(
    shell: Color(0xFF7EC8E3),
    shellPattern: Color(0xFF4A9BC4),
    skin: Color(0xFFD5F3FF),
  ),
  PetPalette.mint: _TurtleColors(
    shell: Color(0xFF9EE6C9),
    shellPattern: Color(0xFF5CBE95),
    skin: Color(0xFFE0FFF3),
  ),
  PetPalette.blossom: _TurtleColors(
    shell: Color(0xFFFFC4DE),
    shellPattern: Color(0xFFE894BC),
    skin: Color(0xFFFFF0F6),
  ),
};

class _SquirrelColors {
  final Color primary;
  final Color secondary;
  final Color skin;
  const _SquirrelColors({required this.primary, required this.secondary, required this.skin});
}

/// `classic` ("Gốc") CHÍNH LÀ màu nâu tự nhiên của sóc - đây là màu MẶC ĐỊNH
/// của Ran (xem `defaultPaletteByCharacter` trong `pet_palette.dart`).
const Map<PetPalette, _SquirrelColors> squirrelPaletteColors = {
  PetPalette.classic: _SquirrelColors(
    primary: Color(0xFFB5793F),
    secondary: Color(0xFF8B5A2B),
    skin: Color(0xFFFFE9C7),
  ),
  PetPalette.snow: _SquirrelColors(
    primary: Color(0xFFF2F2F2),
    secondary: Color(0xFFD8C6B0),
    skin: Color(0xFFFFFFFF),
  ),
  PetPalette.sky: _SquirrelColors(
    primary: Color(0xFFAEE3F5),
    secondary: Color(0xFF6FC7E8),
    skin: Color(0xFFEFFCFF),
  ),
  PetPalette.mint: _SquirrelColors(
    primary: Color(0xFFB7ECD0),
    secondary: Color(0xFF74D6A2),
    skin: Color(0xFFF0FFF6),
  ),
  PetPalette.blossom: _SquirrelColors(
    primary: Color(0xFFFFD6EC),
    secondary: Color(0xFFFF8FC7),
    skin: Color(0xFFFFF3FA),
  ),
};

class _PenguinColors {
  final Color body;
  final Color belly;
  final Color beak;
  const _PenguinColors({required this.body, required this.belly, required this.beak});
}

/// `classic` ("Gốc") CHÍNH LÀ màu đen tự nhiên của chim cánh cụt - đây là
/// màu MẶC ĐỊNH của Pingo (xem `defaultPaletteByCharacter`). Cố tình dùng
/// đen "mềm" (`0xFF2B2B2B`) thay vì đen tuyệt đối để giữ cảm giác thân
/// thiện, dễ thương, không quá gắt với trẻ nhỏ.
const Map<PetPalette, _PenguinColors> penguinPaletteColors = {
  PetPalette.classic: _PenguinColors(
    body: Color(0xFF2B2B2B),
    belly: Color(0xFFFFFFFF),
    beak: Color(0xFFFFA726),
  ),
  PetPalette.snow: _PenguinColors(
    body: Color(0xFFB0BEC5),
    belly: Color(0xFFFFFFFF),
    beak: Color(0xFFFFCC80),
  ),
  PetPalette.sky: _PenguinColors(
    body: Color(0xFF6FC7E8),
    belly: Color(0xFFFFFFFF),
    beak: Color(0xFFFFA726),
  ),
  PetPalette.mint: _PenguinColors(
    body: Color(0xFF74D6A2),
    belly: Color(0xFFFFFFFF),
    beak: Color(0xFFFFA726),
  ),
  PetPalette.blossom: _PenguinColors(
    body: Color(0xFFFF8FC7),
    belly: Color(0xFFFFFFFF),
    beak: Color(0xFFFFA726),
  ),
};

/// ---------------------------------------------------------------------------
/// Adapter: MimiPose (dùng chung, do AnimationController điều khiển) ->
/// đúng painter + tham số của nhân vật đang chọn.
/// ---------------------------------------------------------------------------

/// Khung toạ độ tham chiếu mà cả 3 painter trên được vẽ vào (khớp với các
/// con số tuyệt đối ~±90 quanh tâm trong code gốc bạn gửi) - [PetCharacterPainter]
/// sẽ scale khung này ra đúng kích thước thật của `PetAvatar` (230 ở Home,
/// 170 ở Lesson...), và [hitTestPetCharacter] dùng lại ĐÚNG công thức scale
/// này để vùng chạm luôn khớp với hình đang hiển thị.
const double petCharacterReferenceSize = 220.0;

double _mouthRatioFromPose(MimiPose pose) {
  switch (pose.mouth) {
    case MimiMouth.idle:
      return 0.2;
    case MimiMouth.talk:
      return min(max(pose.mouthOpen, 0.0), 1.0);
    case MimiMouth.happy:
      return 0.7;
  }
}

/// Vẽ [character] theo đúng "dáng" [pose] hiện tại, với màu [palette] bé đã
/// chọn (mặc định `PetPalette.classic` - màu gốc) - đây là hàm DUY NHẤT nơi
/// khác trong app cần biết để lấy painter đúng nhân vật.
CustomPainter buildPetCharacterPainter(
  PetCharacter character,
  MimiPose pose, [
  PetPalette palette = PetPalette.classic,
]) {
  final mouthRatio = _mouthRatioFromPose(pose);
  switch (character) {
    case PetCharacter.bunny:
      return BunnyPainter(
        eyeOpenRatio: pose.eyeScaleY,
        mouthRatio: mouthRatio,
        leftEarStretch: pose.earLeftScaleY,
        rightEarStretch: pose.earRightScaleY,
        leftEarAngle: pose.earLeftAngle,
        rightEarAngle: pose.earRightAngle,
        isHappy: pose.showHappyEyes,
        palette: palette,
      );
    case PetCharacter.mimi:
      return MimiCatPainter(
        eyeOpenRatio: pose.eyeScaleY,
        mouthRatio: mouthRatio,
        leftEarStretch: pose.earLeftScaleY,
        rightEarStretch: pose.earRightScaleY,
        leftEarAngle: pose.earLeftAngle,
        rightEarAngle: pose.earRightAngle,
        isHappy: pose.showHappyEyes,
        palette: palette,
      );
    case PetCharacter.moni:
      return MoniTurtlePainter(
        eyeOpenRatio: pose.eyeScaleY,
        headYOffset: pose.headOffsetY * 1.6,
        isHappy: pose.showHappyEyes,
        palette: palette,
      );
    case PetCharacter.squirrel:
      return SquirrelPainter(
        eyeOpenRatio: pose.eyeScaleY,
        mouthRatio: mouthRatio,
        leftEarStretch: pose.earLeftScaleY,
        rightEarStretch: pose.earRightScaleY,
        leftEarAngle: pose.earLeftAngle,
        rightEarAngle: pose.earRightAngle,
        isHappy: pose.showHappyEyes,
        palette: palette,
      );
    case PetCharacter.penguin:
      return PenguinPainter(
        eyeOpenRatio: pose.eyeScaleY,
        mouthRatio: mouthRatio,
        // Pingo không có tai để kéo - tái dùng góc "vẫy tai" có sẵn để làm
        // 2 cánh đung đưa (xem doc comment của [PenguinPainter]).
        leftFlipperAngle: pose.earLeftAngle,
        rightFlipperAngle: pose.earRightAngle,
        isHappy: pose.showHappyEyes,
        palette: palette,
      );
  }
}

/// Bọc painter của từng nhân vật, luôn vẽ vào khung tham chiếu
/// [petCharacterReferenceSize] rồi scale vừa khít khung thật (giữ tỉ lệ,
/// canh giữa) - tương tự cách painter cũ scale theo
/// designWidth/designHeight, nhưng dùng 1 khung vuông chung cho cả 3 con.
class PetCharacterPainter extends CustomPainter {
  final PetCharacter character;
  final MimiPose pose;
  final PetPalette palette;

  /// Phụ kiện bé ĐANG MẶC cho thú cưng (xem `pet_accessory.dart` +
  /// `pet_inventory_controller.dart`) - null nghĩa là không mặc gì ở vị trí
  /// đó. Vẽ ĐÈ LÊN nhân vật sau khi vẽ xong (xem `pet_accessory_painter.dart`).
  final PetAccessoryId? headAccessory;
  final PetAccessoryId? neckAccessory;

  PetCharacterPainter({
    required this.character,
    required this.pose,
    this.palette = PetPalette.classic,
    this.headAccessory,
    this.neckAccessory,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / petCharacterReferenceSize;
    if (scale <= 0) return;
    canvas.save();
    canvas.translate(
      (size.width - petCharacterReferenceSize * scale) / 2,
      (size.height - petCharacterReferenceSize * scale) / 2,
    );
    canvas.scale(scale);
    buildPetCharacterPainter(character, pose, palette).paint(
      canvas,
      const Size(petCharacterReferenceSize, petCharacterReferenceSize),
    );
    if (headAccessory != null || neckAccessory != null) {
      paintPetAccessories(
        canvas,
        character,
        pose,
        headAccessory: headAccessory,
        neckAccessory: neckAccessory,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PetCharacterPainter oldDelegate) => true;
}

/// Vùng tai trái/phải theo từng nhân vật trong khung tham chiếu
/// [petCharacterReferenceSize] - rùa Moni không có tai nên luôn trả về
/// `null` (mọi lần chạm vào rùa đều tính là chạm THÂN).
Rect? _earLeftHitBox(PetCharacter character) {
  switch (character) {
    case PetCharacter.bunny:
      return const Rect.fromLTWH(48, 15, 56, 115);
    case PetCharacter.mimi:
      return const Rect.fromLTWH(52, 30, 60, 80);
    case PetCharacter.moni:
      return null;
    case PetCharacter.squirrel:
      return const Rect.fromLTWH(66, 63, 24, 30);
    case PetCharacter.penguin:
      // Pingo không có tai (chỉ có cánh, không phải vùng chạm riêng) - giống
      // Moni, mọi lần chạm đều tính là chạm THÂN.
      return null;
  }
}

Rect? _earRightHitBox(PetCharacter character) {
  switch (character) {
    case PetCharacter.bunny:
      return const Rect.fromLTWH(116, 15, 56, 115);
    case PetCharacter.mimi:
      return const Rect.fromLTWH(108, 30, 60, 80);
    case PetCharacter.moni:
      return null;
    case PetCharacter.squirrel:
      return const Rect.fromLTWH(130, 63, 24, 30);
    case PetCharacter.penguin:
      return null;
  }
}

/// Xác định bé vừa chạm vào vùng nào của [character] - [localPoint] là toạ
/// độ chạm TRONG khung vẽ thật (đã trừ Padding bao quanh), [canvasSize] là
/// kích thước khung vẽ đó. Dùng đúng công thức scale/canh giữa mà
/// [PetCharacterPainter] dùng để vùng chạm không bị lệch so với hình đang
/// hiển thị.
MimiTapRegion hitTestPetCharacter(PetCharacter character, Offset localPoint, Size canvasSize) {
  if (canvasSize.width <= 0 || canvasSize.height <= 0) return MimiTapRegion.body;
  final scale = canvasSize.shortestSide / petCharacterReferenceSize;
  if (scale <= 0) return MimiTapRegion.body;
  final offsetX = (canvasSize.width - petCharacterReferenceSize * scale) / 2;
  final offsetY = (canvasSize.height - petCharacterReferenceSize * scale) / 2;
  final referencePoint = Offset(
    (localPoint.dx - offsetX) / scale,
    (localPoint.dy - offsetY) / scale,
  );
  final earLeft = _earLeftHitBox(character);
  final earRight = _earRightHitBox(character);
  if (earLeft != null && earLeft.contains(referencePoint)) return MimiTapRegion.earLeft;
  if (earRight != null && earRight.contains(referencePoint)) return MimiTapRegion.earRight;
  return MimiTapRegion.body;
}
