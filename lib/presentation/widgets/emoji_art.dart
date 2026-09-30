import 'package:flutter/material.dart';

/// Emoji dùng làm HÌNH MINH HOẠ (sticker, thẻ bài, hình câu hỏi...) - luôn
/// nằm gọn trong ô vuông [size] x [size], không bao giờ bị cắt.
///
/// Vì sao không dùng `Text(emoji, style: TextStyle(fontSize: ...))` trực tiếp:
/// - Flutter phóng chữ theo cỡ chữ hệ thống (phụ huynh hay để chữ to trên
///   điện thoại) - emoji là hình nên phóng theo sẽ tràn ô và bị cắt mất nửa
///   dưới (lỗi từng gặp ở Album sticker).
/// - Chiều cao dòng của font emoji mỗi nền tảng một khác (Android/iOS/web).
/// Widget này tắt phóng chữ cho emoji và dùng [FittedBox] để hình luôn vừa ô.
class EmojiArt extends StatelessWidget {
  final String emoji;
  final double size;

  const EmojiArt(this.emoji, {super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          emoji,
          textScaler: TextScaler.noScaling,
          style: TextStyle(fontSize: size, height: 1.15),
        ),
      ),
    );
  }
}
