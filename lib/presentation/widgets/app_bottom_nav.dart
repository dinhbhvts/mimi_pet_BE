import 'package:flutter/material.dart';

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem(this.icon, this.label);
}

/// Thanh điều hướng dưới cùng: Home / Play / Rewards / Chat / Từ điển.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  static const List<_NavItem> _items = [
    _NavItem(Icons.home_rounded, 'Home'),
    _NavItem(Icons.sports_esports_rounded, 'Play'),
    _NavItem(Icons.card_giftcard_rounded, 'Rewards'),
    _NavItem(Icons.chat_bubble_rounded, 'Chat'),
    _NavItem(Icons.menu_book_rounded, 'Từ điển'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      // GIẢM padding ngang (30 -> 14) + BỌC mỗi mục trong `Expanded` (thay vì
      // Row spaceAround với item rộng cố định): từ khi thêm tab thứ 5 ("Từ
      // điển", nhãn dài hơn các tab cũ), 5 item rộng cố định + padding 30 dễ
      // tràn ngang (RenderFlex overflow) trên màn hình hẹp - Expanded đảm bảo
      // luôn vừa đúng chiều rộng còn lại dù có bao nhiêu tab.
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 25),
      child: Row(
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final selected = i == currentIndex;
          final color = selected ? const Color(0xFF7C5CFC) : Colors.black54;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 28, color: color),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
