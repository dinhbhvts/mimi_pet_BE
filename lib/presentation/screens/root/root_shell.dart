import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/progress_controller.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/hearts_badge.dart';
import '../../widgets/star_badge.dart';
import '../../widgets/streak_badge.dart';
import '../chat/chat_screen.dart';
import '../dictionary/dictionary_screen.dart';
import '../home/home_screen.dart';
import '../play/play_screen.dart';
import '../rewards/rewards_screen.dart';
import '../settings/settings_screen.dart';

/// "Khung" chính của app: thanh trên cùng (sao/tim/streak + cài đặt), 5 tab
/// Home/Play/Rewards/Chat/Từ điển, và thanh điều hướng dưới cùng. Dùng IndexedStack
/// để giữ nguyên trạng thái từng tab khi chuyển qua lại (ví dụ không mất câu
/// chào của Mimi ở Home, hay lịch sử chat, khi bé chuyển qua tab khác rồi
/// quay lại).
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Flexible + scroll ngang: phòng trường hợp màn hình hẹp
                  // không đủ chỗ cho cả 3 huy hiệu (sao/tim/streak) cùng lúc,
                  // tránh lỗi tràn ngang (RenderFlex overflow).
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StarBadge(stars: progress.stars),
                          const SizedBox(width: 8),
                          const HeartsBadge(),
                          const SizedBox(width: 8),
                          const StreakBadge(),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                    icon: const Icon(Icons.settings_rounded, size: 28),
                  ),
                ],
              ),
            ),
            Expanded(
              // sizing: StackFit.expand - bắt buộc IndexedStack (và cả 3 tab
              // bên trong) LUÔN lấp đầy đúng chiều rộng màn hình. Thiếu dòng
              // này, IndexedStack mặc định co theo tab RỘNG NHẤT trong số cả
              // 3 tab (kể cả tab đang ẩn), rồi đặt tab đang hiện ở góc
              // trên-trái (mặc định của Stack) thay vì canh giữa - đây chính
              // là lý do Home từng bị lệch trái lúc mới vào (nội dung Home
              // hẹp hơn khối RewardsScreen có Container rộng hết cỡ), và tự
              // "hết lệch" sau khi tương tác vì lúc đó nội dung Home tình cờ
              // đủ rộng để lấp đầy khung.
              child: IndexedStack(
                index: _tabIndex,
                sizing: StackFit.expand,
                children: const [
                  HomeScreen(),
                  PlayScreen(),
                  RewardsScreen(),
                  ChatScreen(),
                  DictionaryScreen(),
                ],
              ),
            ),
            AppBottomNav(
              currentIndex: _tabIndex,
              onTap: (index) => setState(() => _tabIndex = index),
            ),
          ],
        ),
      ),
    );
  }
}
