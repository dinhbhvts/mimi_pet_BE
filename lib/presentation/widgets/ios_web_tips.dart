import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/platform/platform_info.dart';
import '../../core/theme/app_colors.dart';

/// 1 mẹo trong hướng dẫn dùng bản web trên iPhone/iPad.
class IosWebTip {
  final String emoji;
  final String title;
  final String detail;

  const IosWebTip(this.emoji, this.title, this.detail);
}

/// Danh sách mẹo - [standalone] = đang mở từ icon ở Màn hình chính rồi thì
/// không cần nhắc bước "Thêm vào Màn hình chính" nữa.
List<IosWebTip> iosWebTips({required bool standalone}) => [
  if (!standalone)
    const IosWebTip(
      '📲',
      'Thêm Mimi vào Màn hình chính',
      'Trong Safari, bấm nút Chia sẻ (ô vuông có mũi tên lên) → "Thêm vào MH chính". '
          'Lần sau mở Mimi từ icon chú thỏ: toàn màn hình như app thật, không còn thanh địa chỉ.',
    ),
  const IosWebTip(
    '🎤',
    'Cho phép micro',
    'Khi được hỏi, chọn "Cho phép". Để không bị hỏi lại mỗi lần: Cài đặt → Safari → Micrô → Cho phép '
        '(hoặc bấm "aA" trên thanh địa chỉ → Cài đặt trang web → Micrô → Cho phép).',
  ),
  const IosWebTip(
    '🗣️',
    'Bật Đọc chính tả',
    'Safari nhận giọng nói nhờ dịch vụ Đọc chính tả của Apple: Cài đặt → Cài đặt chung → Bàn phím → '
        'bật "Đọc chính tả". Nói rõ từng câu, Mimi nghe xong câu sẽ tự dừng.',
  ),
  const IosWebTip(
    '🔊',
    'Không nghe thấy Mimi nói?',
    'Tăng âm lượng, tắt chế độ Im lặng, rồi chạm vào màn hình 1 lần - iPhone chỉ cho trang web phát '
        'tiếng sau khi bé đã chạm vào trang.',
  ),
  const IosWebTip(
    '⌨️',
    'Micro vẫn không nghe được?',
    'Dùng ô gõ chữ (nút bàn phím ở Chat, hoặc "Gõ thay vào đây"), rồi bấm biểu tượng micro TRÊN BÀN PHÍM '
        'iPhone để đọc - chữ sẽ tự điền vào ô.',
  ),
];

Future<void> showIosWebTipsDialog(BuildContext context) {
  final tips = iosWebTips(standalone: PlatformInfo.isStandaloneWebApp);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Dùng Mimi trên iPhone/iPad'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final tip in tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tip.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tip.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(tip.detail, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Đã hiểu')),
      ],
    ),
  );
}

/// Thẻ nhắc nhỏ ở Home - CHỈ hiện trên bản web chạy trên iPhone/iPad, ẩn
/// vĩnh viễn (trên máy đó) khi bấm ✕. Vẫn mở lại được từ Cài đặt.
class IosWebTipsBanner extends StatefulWidget {
  const IosWebTipsBanner({super.key});

  static const prefsKey = 'mimi.iosWebTips.dismissed';

  @override
  State<IosWebTipsBanner> createState() => _IosWebTipsBannerState();
}

class _IosWebTipsBannerState extends State<IosWebTipsBanner> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (PlatformInfo.isIosWeb) _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || (prefs.getBool(IosWebTipsBanner.prefsKey) ?? false)) return;
      setState(() => _visible = true);
    } catch (_) {
      // Không đọc được bộ nhớ trình duyệt - thôi không hiện.
    }
  }

  Future<void> _dismiss() async {
    setState(() => _visible = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(IosWebTipsBanner.prefsKey, true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showIosWebTipsDialog(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
            child: Row(
              children: [
                const Text('📱', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Dùng iPhone/iPad? Xem mẹo để Mimi nghe và nói tốt hơn',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: _dismiss,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Ẩn',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
