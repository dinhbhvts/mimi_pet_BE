import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mimi_pet/app.dart';
import 'package:mimi_pet/presentation/widgets/emoji_art.dart';

void main() {
  testWidgets('EmojiArt luôn nằm gọn trong ô kể cả khi cỡ chữ hệ thống rất lớn', (tester) async {
    await tester.pumpWidget(const MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: EmojiArt('🐱', size: 34)),
      ),
    ));
    final box = tester.getSize(find.byType(EmojiArt));
    expect(box, const Size(34, 34));
    // Nội dung chữ bên trong được FittedBox thu vào vừa ô, không tràn.
    final text = tester.getRect(find.text('🐱'));
    final outer = tester.getRect(find.byType(EmojiArt));
    expect(outer.contains(text.topLeft) && outer.contains(text.bottomRight - const Offset(0.01, 0.01)), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('app giới hạn mức phóng chữ hệ thống ở 1.3 lần', (tester) async {
    late TextScaler seen;
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
      child: Builder(
        builder: (context) => clampTextScale(
          context,
          Builder(builder: (inner) {
            seen = MediaQuery.textScalerOf(inner);
            return const SizedBox();
          }),
        ),
      ),
    ));
    expect(seen.scale(10), closeTo(13, 0.001));
  });
}
