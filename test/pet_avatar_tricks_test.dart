import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mimi_pet/domain/entities/pet_character.dart';
import 'package:mimi_pet/domain/entities/pet_mood.dart';
import 'package:mimi_pet/presentation/widgets/pet_avatar.dart';

/// Chạy qua MỌI trò của thú cưng (cả lúc thức lẫn lúc ngủ) với từng nhân vật
/// để chắc chắn phần tính tư thế/hiệu ứng không ném lỗi ở bất kỳ khung hình nào.
void main() {
  testWidgets('kéo lắc thú cưng báo đúng cường độ (quãng đường / kích thước)', (tester) async {
    final intensities = <double>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: PetAvatar(
            mood: PetMood.happy,
            character: PetCharacter.mimi,
            size: 200,
            onTap: (_) {},
            onDragEnd: intensities.add,
          ),
        ),
      ),
    ));
    final gesture = await tester.startGesture(tester.getCenter(find.byType(PetAvatar)));
    // Lắc qua lại 10 lần, mỗi lần 120px -> tổng ~1200px = 6 lần kích thước.
    for (var i = 0; i < 10; i++) {
      for (var s = 0; s < 6; s++) {
        await gesture.moveBy(Offset(i.isEven ? 20 : -20, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
    expect(intensities, hasLength(1));
    expect(intensities.single, greaterThan(5));
    await tester.pumpWidget(const SizedBox());
  });

  for (final character in PetCharacter.values) {
    for (final sleeping in [false, true]) {
      testWidgets('${character.name} - mọi trò chạy êm (sleeping: $sleeping)', (tester) async {
        final controller = PetAvatarController();
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Center(
              child: PetAvatar(
                mood: PetMood.happy,
                character: character,
                controller: controller,
                sleeping: sleeping,
              ),
            ),
          ),
        ));
        for (final trick in MimiTrick.values) {
          controller.play(trick);
          for (var i = 0; i < 12; i++) {
            await tester.pump(const Duration(milliseconds: 250));
          }
        }
        expect(tester.takeException(), isNull);
        // Tháo widget để dừng các animation lặp (thở, 💤...).
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
