// Smoke test: app khởi động phải hiện được màn đăng nhập (chưa đăng nhập
// lúc test, không có SharedPreferences/token nào được nạp sẵn) mà không
// crash. Đây là bài test rộng nhất có thể viết mà không cần mock ApiClient/
// backend thật - xác nhận ít nhất cây widget gốc build được, phát hiện sớm
// lỗi Provider/import kiểu như đã gặp thực tế khi thêm đăng nhập (xem
// `deployment.md`).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mimi_pet/app.dart';

void main() {
  testWidgets('MimiApp hien duoc man dang nhap khi chua co token', (WidgetTester tester) async {
    // AuthService.load() doc SharedPreferences ngay luc khoi dong - can mock
    // gia tri rong (chua tung dang nhap) truoc, neu khong plugin se khong co
    // "host" thuc de tra loi trong moi truong test.
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MimiApp());
    // AuthService.load() la async (doc SharedPreferences) - bom vai frame de
    // no kip hoan tat truoc khi AuthGate quyet dinh hien man nao.
    await tester.pumpAndSettle();

    expect(find.text('Mimi English Pet'), findsOneWidget);
    expect(find.text('Gửi mã'), findsOneWidget);
  });
}
