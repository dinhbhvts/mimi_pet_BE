import 'package:flutter/material.dart';

/// Mô tả "dáng" hiện tại của thú cưng đang chọn tại 1 thời điểm - mọi con số
/// ở đây được [PetAvatar] (qua `pet_character_painters.dart`) dùng để vẽ
/// trực tiếp bằng vector (Canvas), thay vì dùng ảnh PNG tĩnh. Nhờ vậy hình
/// luôn NÉT ở mọi kích thước màn hình, không cần ảnh ngoài (rất nhẹ), và
/// từng bộ phận (tai, mắt, miệng...) có thể tự "diễn" (chớp mắt, vẫy tai,
/// nhún nhảy...) mượt hơn nhiều so với chỉ xoay/co giãn cả tấm ảnh - đúng
/// hướng vector + animation theo từng phần (kiểu SVG + CSS animation).
///
/// [MimiPose] KHÔNG gắn với 1 nhân vật cụ thể nào - đổi nhân vật (Bunny/
/// Mimi/Moni) chỉ đổi PAINTER nào đọc pose này để vẽ, animation (breathing,
/// chớp mắt, vẫy tai, nói chuyện...) vẫn dùng chung 1 bộ điều khiển.
class MimiPose {
  final double bodyScaleY;
  final double headOffsetY;
  final double headTilt;
  final double earLeftAngle;
  final double earRightAngle;
  final double earLeftScaleY;
  final double earRightScaleY;
  final double eyeScaleY;
  final bool showHappyEyes;
  final MimiMouth mouth;
  final double mouthOpen;

  const MimiPose({
    this.bodyScaleY = 1.0,
    this.headOffsetY = 0,
    this.headTilt = 0,
    this.earLeftAngle = 0,
    this.earRightAngle = 0,
    this.earLeftScaleY = 1.0,
    this.earRightScaleY = 1.0,
    this.eyeScaleY = 1.0,
    this.showHappyEyes = false,
    this.mouth = MimiMouth.idle,
    this.mouthOpen = 0.3,
  });
}

enum MimiMouth { idle, talk, happy }

/// Bảng màu dùng chung cho phần UI xoay quanh thú cưng (không phải màu vẽ
/// từng nhân vật - mỗi nhân vật có màu riêng, xem `pet_character_painters.dart`).
class MimiPalette {
  static const fur = Color(0xFFD8C6F7);
  static const furDark = Color(0xFFB79CF0);
  static const accent = Color(0xFFF6A8D0);
  static const skin = Color(0xFFFFF8FC);
  static const ink = Color(0xFF4A3B6B);
  static const mouthColor = Color(0xFFB4457A);
}

/// Vùng trên người thú cưng mà bé vừa chạm vào - để phân biệt "vuốt ve"
/// (thân/đầu) với "kéo tai" (tai trái/phải), cho 2 phản ứng khác nhau. Xem
/// `hitTestPetCharacter` trong `pet_character_painters.dart` để biết cách
/// xác định vùng này theo từng nhân vật (rùa Moni không có tai).
enum MimiTapRegion { earLeft, earRight, body }
