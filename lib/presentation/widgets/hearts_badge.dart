import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/hearts_controller.dart';

/// Huy hiệu hiển thị số tim còn lại của bé - tự làm mới định kỳ (mỗi 60s)
/// để phản ánh tim hồi phục theo thời gian ngay cả khi bé không rời khỏi
/// màn hình này (ví dụ đang xem tab Home).
class HeartsBadge extends StatefulWidget {
  const HeartsBadge({super.key});

  @override
  State<HeartsBadge> createState() => _HeartsBadgeState();
}

class _HeartsBadgeState extends State<HeartsBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      context.read<HeartsController>().refreshRegen();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hearts = context.watch<HeartsController>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('❤️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            '${hearts.hearts}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
