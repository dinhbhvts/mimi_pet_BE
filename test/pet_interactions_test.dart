import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mimi_pet/domain/entities/pet_character.dart';
import 'package:mimi_pet/presentation/screens/home/pet_interactions.dart';
import 'package:mimi_pet/presentation/widgets/mimi_painter.dart';
import 'package:mimi_pet/presentation/widgets/pet_character_painters.dart';

void main() {
  group('TeaseMeter', () {
    final t0 = DateTime(2026, 1, 1, 8);
    DateTime at(int ms) => t0.add(Duration(milliseconds: ms));

    test('trêu dồn dập: dỗi -> phì cười -> mệt, rồi về lại bình thường', () {
      final meter = TeaseMeter();
      final reactions = <TeaseReaction>[];
      // 20 lần chạm cách nhau 100ms (giảm 0.1 điểm/lần), mỗi lần +1.
      for (var i = 0; i < 20; i++) {
        reactions.add(meter.add(1, at(i * 100)));
      }
      final firstGrumpy = reactions.indexOf(TeaseReaction.grumpy);
      final burst = reactions.indexOf(TeaseReaction.burstLaugh);
      final tired = reactions.indexOf(TeaseReaction.tired);
      expect(firstGrumpy, greaterThan(0));
      expect(burst, greaterThan(firstGrumpy));
      expect(tired, greaterThan(burst));
      // Đang dỗi thì các lần trêu tiếp theo vẫn dỗi cho tới khi phì cười.
      expect(reactions.sublist(firstGrumpy, burst), everyElement(TeaseReaction.grumpy));
      // Sau khi mệt, điểm về 0 nên lần kế tiếp là bình thường.
      expect(reactions[tired + 1], TeaseReaction.normal);
    });

    test('bé chạm liên tục 4 lần/giây (qua throttle 900ms ở Home) vẫn leo thang trong vài giây', () {
      final meter = TeaseMeter();
      DateTime? lastAccepted;
      final firstAt = <TeaseReaction, int>{};
      for (var ms = 0; ms <= 15000; ms += 250) {
        final now = at(ms);
        final accepted = lastAccepted == null || now.difference(lastAccepted).inMilliseconds >= 900;
        if (accepted) lastAccepted = now;
        final r = meter.add(accepted ? 1.0 : 0.5, now);
        firstAt.putIfAbsent(r, () => ms);
      }
      expect(firstAt[TeaseReaction.grumpy], lessThan(6000));
      expect(firstAt[TeaseReaction.burstLaugh], lessThan(9000));
      expect(firstAt[TeaseReaction.tired], lessThan(13000));
    });

    test('trêu thong thả thì không bao giờ dỗi (điểm tự giảm)', () {
      final meter = TeaseMeter();
      for (var i = 0; i < 30; i++) {
        expect(meter.add(1, at(i * 1500)), TeaseReaction.normal);
      }
    });

    test('nghỉ một lúc thì hết dỗi', () {
      final meter = TeaseMeter();
      for (var i = 0; i < 7; i++) {
        meter.add(1, at(i * 50));
      }
      expect(meter.add(0, at(400)), TeaseReaction.grumpy);
      expect(meter.add(1, at(10000)), TeaseReaction.normal);
    });

    test('reset xoá sạch điểm', () {
      final meter = TeaseMeter();
      meter.add(8, at(0));
      meter.reset();
      expect(meter.levelAt(at(0)), 0);
      expect(meter.add(1, at(10)), TeaseReaction.normal);
    });
  });

  group('Cho ăn', () {
    PetFood food(String id) => PetFood.all.firstWhere((f) => f.id == id);

    test('ớt luôn cay với mọi nhân vật', () {
      for (final c in PetCharacter.values) {
        expect(foodReactionFor(c, food('chili')), FoodReaction.spicy);
      }
    });

    test('mỗi nhân vật có món khoái và món chê riêng', () {
      expect(foodReactionFor(PetCharacter.bunny, food('carrot')), FoodReaction.love);
      expect(foodReactionFor(PetCharacter.bunny, food('fish')), FoodReaction.dislike);
      expect(foodReactionFor(PetCharacter.mimi, food('fish')), FoodReaction.love);
      expect(foodReactionFor(PetCharacter.mimi, food('broccoli')), FoodReaction.dislike);
      expect(foodReactionFor(PetCharacter.penguin, food('ice_cream')), FoodReaction.love);
      expect(foodReactionFor(PetCharacter.moni, food('cookie')), FoodReaction.like);
      for (final c in PetCharacter.values) {
        final reactions = PetFood.all.map((f) => foodReactionFor(c, f)).toSet();
        expect(reactions, containsAll(FoodReaction.values), reason: '$c');
      }
    });

    test('câu thoại có đọc tên món tiếng Anh', () {
      for (final r in FoodReaction.values.where((r) => r != FoodReaction.spicy)) {
        expect(foodPhrase(r, food('apple')), contains('apple'));
      }
    });
  });

  group('Vùng chạm mới', () {
    const size = Size(220, 220);

    Offset center(Rect r) => r.center;

    test('chạm đúng mũi của từng nhân vật', () {
      for (final c in PetCharacter.values) {
        final anchor = petNoseAnchor(c);
        final point = Offset(anchor.dx * size.width, anchor.dy * size.height);
        expect(hitTestPetCharacter(c, point, size), MimiTapRegion.nose, reason: '$c');
      }
    });

    test('bụng và chân nhận đúng vùng', () {
      expect(hitTestPetCharacter(PetCharacter.bunny, center(const Rect.fromLTWH(86, 160, 48, 30)), size),
          MimiTapRegion.belly);
      expect(hitTestPetCharacter(PetCharacter.bunny, const Offset(70, 196), size), MimiTapRegion.feet);
      expect(hitTestPetCharacter(PetCharacter.moni, const Offset(110, 125), size), MimiTapRegion.belly);
      expect(hitTestPetCharacter(PetCharacter.moni, const Offset(65, 145), size), MimiTapRegion.feet);
      expect(hitTestPetCharacter(PetCharacter.penguin, const Offset(88, 212), size), MimiTapRegion.feet);
    });

    test('vùng chạm co giãn theo kích thước khung vẽ', () {
      const big = Size(440, 440);
      final anchor = petNoseAnchor(PetCharacter.mimi);
      expect(hitTestPetCharacter(PetCharacter.mimi, Offset(anchor.dx * 440, anchor.dy * 440), big),
          MimiTapRegion.nose);
    });

    test('mỗi vùng có câu thoại riêng (chim cánh cụt: mỏ, rùa: mai)', () {
      expect(PetPhrases.forRegion(MimiTapRegion.nose, PetCharacter.penguin), PetPhrases.beak);
      expect(PetPhrases.forRegion(MimiTapRegion.belly, PetCharacter.moni), PetPhrases.shell);
      expect(PetPhrases.forRegion(MimiTapRegion.feet, PetCharacter.bunny), PetPhrases.feet);
    });
  });
}
