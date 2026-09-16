import 'package:flutter/material.dart';

import 'package:mimi_pet/core/theme/app_colors.dart';

/// Phương án thay thế cho các màn hình vốn CHỈ có "Tap to talk" (mic) - hiện
/// 1 dòng chữ nhỏ, bấm vào mở ra ô gõ chữ.
///
/// LÝ DO CẦN CÁI NÀY: Safari trên iPhone/iPad HẦU NHƯ KHÔNG hỗ trợ
/// `speech_to_text` (dựa trên Web Speech API của trình duyệt - bị Apple giới
/// hạn, xem `deployment.md`) - nút mic trên web Safari sẽ luôn báo "không
/// nghe được" dù bé nói rõ ràng. Ô gõ chữ ở đây vẫn dùng được nút ĐỌC CHÍNH
/// TẢ (dictation) có sẵn NGAY TRÊN BÀN PHÍM của iOS (khác cơ chế
/// JS SpeechRecognition mà speech_to_text dùng) - bé chạm vào ô, bấm mic
/// ngay trên bàn phím, đọc to, chữ tự động điền vào ô - vậy nên bé VẪN "nói"
/// được gián tiếp qua đường này, hoạt động trên MỌI nền tảng kể cả Safari,
/// không cần thêm quyền hay cấu hình gì.
class TypeInsteadOfTalk extends StatefulWidget {
  const TypeInsteadOfTalk({
    super.key,
    required this.onSubmitted,
    this.enabled = true,
    this.hintText = 'Gõ từ bé vừa nói...',
    this.collapsedLabel = 'Không nói được? Gõ thay vào đây',
  });

  final ValueChanged<String> onSubmitted;
  final bool enabled;
  final String hintText;
  final String collapsedLabel;

  @override
  State<TypeInsteadOfTalk> createState() => _TypeInsteadOfTalkState();
}

class _TypeInsteadOfTalkState extends State<TypeInsteadOfTalk> {
  bool _expanded = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmitted(text);
    _controller.clear();
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return TextButton.icon(
        onPressed: widget.enabled ? () => setState(() => _expanded = true) : null,
        icon: const Icon(Icons.keyboard_rounded, size: 18),
        label: Text(widget.collapsedLabel),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 220,
          child: TextField(
            controller: _controller,
            autofocus: true,
            enabled: widget.enabled,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: widget.hintText,
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.enabled ? _submit : null,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.check_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}
