import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/boot_content.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/pet_character.dart';
import '../../../domain/entities/pet_mood.dart';
import '../../widgets/pet_avatar.dart';

/// Màn chờ hiện NGAY LẬP TỨC (trước khi biết kết quả API) trong lúc chờ
/// [future] hoàn tất - dùng cho những chỗ CHẮC CHẮN gọi mạng ngay lúc mở app
/// (tải tiến độ của bé lần đầu, đăng nhập) nên dễ đụng lúc backend Render
/// (gói Free) đang "ngủ", cần 30 giây tới vài phút để thức dậy trước khi trả
/// lời được - xem `core/boot_content.dart`.
///
/// Nguyên tắc (tham khảo từ app khác, ManHinhCho.md 2026-09-17, áp dụng
/// chung cho cả web lẫn Flutter vì 2 bản DÙNG CHUNG 1 bộ code Dart - không
/// tách UI riêng theo nền tảng):
/// - Toàn bộ nội dung hiển thị (mascot, lời chào, từ vựng, mốc trạng thái) là
///   DỮ LIỆU TĨNH dựng sẵn phía client, không phụ thuộc phản hồi từ server.
/// - Thanh tiến trình/câu trạng thái đổi theo THỜI GIAN TRÔI QUA (không phải
///   tiến độ thực của server - client không có cách nào biết chính xác server
///   đang làm gì), KHÔNG BAO GIỜ tự chạy tới 100% - chỉ thực sự đóng màn chờ
///   khi [future] hoàn tất thật (thành công hay lỗi đều đóng, người gọi tự lo
///   phần xử lý kết quả sau khi [onDone] được gọi).
/// - CHỈ 1 request duy nhất, không có timeout nhân tạo ở tầng UI (timeout
///   thật đã đặt ở [ApiClient] khi tạo [future] - xem
///   `BootContent.wakeTimeoutSeconds`), không tự động retry.
class BootScreen extends StatefulWidget {
  /// Future ĐÃ ĐƯỢC BẮT ĐẦU chạy (không phải 1 factory) - màn chờ chỉ lắng
  /// nghe kết quả, không tự gọi lại nếu build lại nhiều lần.
  final Future<void> future;

  /// Gọi đúng 1 lần khi [future] hoàn tất (thành công HAY lỗi đều gọi, xem
  /// doc comment ở trên) - để trống nếu nơi gọi đã tự lắng nghe [future]
  /// bằng cách khác (ví dụ `FutureBuilder` bọc ngoài `BootScreen` tự rebuild
  /// khi future xong, không cần callback riêng - xem `app.dart`).
  final VoidCallback? onDone;

  const BootScreen({super.key, required this.future, this.onDone});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  late final DateTime _startedAt;
  late final List<(String, String)> _shuffledTips;
  Timer? _ticker;
  int _elapsedSeconds = 0;
  int _tipIndex = 0;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _shuffledTips = List.of(BootContent.toeicVocabTips)..shuffle();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds = DateTime.now().difference(_startedAt).inSeconds;
        // Xoay từ vựng mỗi 4 giây - đủ thời gian bé đọc, không quá lâu tới
        // mức nhàm trong lúc chờ có thể kéo dài cả phút.
        _tipIndex = (_elapsedSeconds ~/ 4) % _shuffledTips.length;
      });
    });
    // whenComplete (không phải then) đảm bảo LUÔN gọi onDone dù future lỗi
    // (timeout, 401, mất mạng thật...) - không để bé kẹt mãi ở màn chờ. Nơi
    // gọi thường bọc [future] trong 1 `FutureBuilder` (xem `app.dart`) nên tự
    // rebuild và gỡ bỏ `BootScreen` khi future xong - [onDone] chỉ cần cho
    // trường hợp KHÔNG có `FutureBuilder` bọc ngoài.
    widget.future.whenComplete(() {
      if (!mounted) return;
      widget.onDone?.call();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = BootContent.stageFor(_elapsedSeconds);
    final tip = _shuffledTips[_tipIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PetAvatar(
                  mood: PetMood.idle,
                  character: PetCharacter.mimi,
                  size: 140,
                ),
                const SizedBox(height: 12),
                Text(
                  BootContent.greetingFor(DateTime.now()),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mimi đang chuẩn bị, chờ bé một chút nhé...',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: stage.progress,
                    minHeight: 10,
                    backgroundColor: Colors.white,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    stage.text,
                    key: ValueKey(stage.text),
                    style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _VocabTipCard(key: ValueKey(_tipIndex), word: tip.$1, meaning: tip.$2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thẻ từ vựng TOEIC nhỏ xoay vòng trong lúc chờ - tận dụng thời gian chết
/// thay vì để bé nhìn thanh tiến trình vô nghĩa (xem [BootContent.toeicVocabTips]).
class _VocabTipCard extends StatelessWidget {
  final String word;
  final String meaning;

  const _VocabTipCard({super.key, required this.word, required this.meaning});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '📖 Từ vựng TOEIC hay gặp',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(word, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(meaning, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
