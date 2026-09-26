import 'dart:math';

import '../../../domain/entities/pet_character.dart';
import '../../widgets/mimi_painter.dart';

/// Kho câu thoại + luật phản ứng khi bé trêu thú cưng ở Home. Tách khỏi
/// `home_screen.dart` để dễ thêm câu mới và viết test cho phần logic.
/// Câu thoại cố ý NHẤN tên bộ phận cơ thể (EAR, NOSE, TUMMY...) để bé vừa
/// trêu vừa học từ.
class PetPhrases {
  PetPhrases._();

  static const body = [
    'Hehe, that tickles! 😄',
    'Yay! Hi again, {child}! 👋',
    'I like you, {child}! 💜',
    "You're my best friend!",
    'Woohoo!',
    'Pat pat! That feels nice! 😊',
    'More, more! 😆',
    'Hehe, you found my HEAD!',
  ];

  static const ear = [
    'Hey! That\'s my EAR! 😆',
    'Hehe, my ear!',
    'Tickle tickle, my EARS!',
    "Don't pull my ears, silly! 😜",
    'My EARS are ticklish!',
  ];

  static const nose = [
    'Ah... ah... ACHOO! 🤧',
    'Boop! My NOSE! Achoo!',
    'Hehe, my nose is itchy! ACHOO!',
  ];

  static const beak = [
    'Boop! That\'s my BEAK! Achoo!',
    'Ah... ah... ACHOO! My beak! 🤧',
  ];

  static const belly = [
    'Hahaha! My TUMMY tickles!',
    'Not my belly! Hahaha! 😂',
    'Hehe, stop! My TUMMY!',
  ];

  static const shell = [
    'Knock knock! That\'s my SHELL! 🐢',
    'Hey! I\'m hiding in my shell! Hehe!',
  ];

  static const feet = [
    'Eek! My FEET are ticklish!',
    'Hehe, not my toes! 🤭',
    'My FEET! Hahaha!',
  ];

  static const doubleTap = [
    'Whoa! Hehehe, again?! 😆',
    'Hihi, you got me twice!',
    'Ahaha, double tickle!',
    'Double boop! Hahaha!',
  ];

  /// Câu khi bé GIỮ TAY cù, tăng dần theo thời gian giữ.
  static const tickleMild = ['Hehe! That tickles! 😆', 'Hihi! 🤭', 'Hehehe!'];
  static const tickleStrong = ['Hahaha! Stop, stop! 😂', 'Hahaha! No more! 😂', 'That tickles so much!'];
  static const tickleMax = ["I can't breathe! Hahahaha! 🤣", 'Hahaha! Help! 🤣', 'Mercy! Hahahaha!'];

  static const dragSmall = ['Whee! Where are we going? 😄', 'Hey, put me down! Hehe!'];
  static const dragWild = ["Whoa! I'm so dizzy! 😵", 'Everything is spinning! 💫'];

  static const grumpy = [
    'Hmph! Stop it! 😤',
    "I'm NOT laughing! Hmph!",
    'Stop teasing me! 😠',
    "Hmph! I'm angry now! 💢",
  ];
  static const burstLaugh = [
    'Pfft... hahaha! OK, OK, you win! 😂',
    "Hahaha! I can't stay angry! 😂",
  ];
  static const tired = [
    "Yaaawn... I'm so tired now. 😪",
    'Phew... Too much fun. I need a rest! 😴',
  ];

  static const sleepStir = ['Zzz... mmm... five more minutes... 😴', 'Zzz... hmm? ...zzz'];
  static const sleepWake = ['Huh?! Who woke me up? 😳', 'Wha...?! I was sleeping! 😳'];
  static const sleepWakeLaugh = ["Hehe! OK, OK, I'm awake! 😆"];
  static const sleepAutoWake = 'Good morning! I feel great! 🌞';

  static String pick(List<String> list, Random random) => list[random.nextInt(list.length)];

  /// Câu cho 1 lần chạm theo vùng - vài con có tên bộ phận riêng (mỏ chim
  /// cánh cụt, mai rùa).
  static List<String> forRegion(MimiTapRegion region, PetCharacter character) {
    switch (region) {
      case MimiTapRegion.earLeft:
      case MimiTapRegion.earRight:
        return ear;
      case MimiTapRegion.nose:
        return character == PetCharacter.penguin ? beak : nose;
      case MimiTapRegion.belly:
        return character == PetCharacter.moni ? shell : belly;
      case MimiTapRegion.feet:
        return feet;
      case MimiTapRegion.body:
        return body;
    }
  }
}

/// Phản ứng theo "mức bị trêu" dồn lại.
enum TeaseReaction { normal, grumpy, burstLaugh, tired }

enum _TeaseStage { calm, grumpy, laughed }

/// Đo mức bé đang trêu thú cưng dồn dập tới đâu: mỗi lần trêu cộng điểm,
/// điểm tự giảm dần theo thời gian. Trêu liên tục thì thú cưng giả vờ DỖI,
/// trêu tiếp thì phì CƯỜI, trêu nữa thì MỆT ngáp dài rồi mọi thứ về lại từ đầu.
class TeaseMeter {
  TeaseMeter({this.decayPerSecond = 1.0});

  static const double grumpyAt = 6;
  static const double burstAt = 11;
  static const double tiredAt = 16;
  static const double calmBelow = 3;

  final double decayPerSecond;
  double _level = 0;
  DateTime? _lastAt;
  _TeaseStage _stage = _TeaseStage.calm;

  double levelAt(DateTime now) {
    _decay(now);
    return _level;
  }

  void _decay(DateTime now) {
    final last = _lastAt;
    _lastAt = now;
    if (last == null) return;
    final seconds = now.difference(last).inMilliseconds / 1000.0;
    _level = max(0, _level - seconds * decayPerSecond);
    if (_level < calmBelow) _stage = _TeaseStage.calm;
  }

  TeaseReaction add(double amount, DateTime now) {
    _decay(now);
    _level += amount;
    if (_level >= tiredAt) {
      _level = 0;
      _stage = _TeaseStage.calm;
      return TeaseReaction.tired;
    }
    if (_stage == _TeaseStage.grumpy && _level >= burstAt) {
      _stage = _TeaseStage.laughed;
      return TeaseReaction.burstLaugh;
    }
    if (_stage == _TeaseStage.calm && _level >= grumpyAt) {
      _stage = _TeaseStage.grumpy;
      return TeaseReaction.grumpy;
    }
    return _stage == _TeaseStage.grumpy ? TeaseReaction.grumpy : TeaseReaction.normal;
  }

  void reset() {
    _level = 0;
    _stage = _TeaseStage.calm;
  }
}

/// Món ăn trong menu "Cho ăn" - tên tiếng Anh được đọc to khi cho ăn (học từ).
class PetFood {
  final String id;
  final String emoji;
  final String en;
  final String vi;

  const PetFood(this.id, this.emoji, this.en, this.vi);

  static const all = [
    PetFood('carrot', '🥕', 'carrot', 'cà rốt'),
    PetFood('apple', '🍎', 'apple', 'táo'),
    PetFood('banana', '🍌', 'banana', 'chuối'),
    PetFood('watermelon', '🍉', 'watermelon', 'dưa hấu'),
    PetFood('fish', '🐟', 'fish', 'cá'),
    PetFood('cheese', '🧀', 'cheese', 'phô mai'),
    PetFood('nuts', '🥜', 'nuts', 'hạt'),
    PetFood('broccoli', '🥦', 'broccoli', 'bông cải xanh'),
    PetFood('pizza', '🍕', 'pizza', 'pizza'),
    PetFood('cookie', '🍪', 'cookie', 'bánh quy'),
    PetFood('ice_cream', '🍦', 'ice cream', 'kem'),
    PetFood('chili', '🌶️', 'chili', 'ớt'),
  ];
}

enum FoodReaction { love, like, dislike, spicy }

const Map<PetCharacter, Set<String>> _loves = {
  PetCharacter.bunny: {'carrot', 'apple'},
  PetCharacter.mimi: {'fish', 'cheese'},
  PetCharacter.moni: {'watermelon', 'banana'},
  PetCharacter.squirrel: {'nuts', 'apple'},
  PetCharacter.penguin: {'fish', 'ice_cream'},
};

const Map<PetCharacter, Set<String>> _dislikes = {
  PetCharacter.bunny: {'fish'},
  PetCharacter.mimi: {'broccoli'},
  PetCharacter.moni: {'pizza'},
  PetCharacter.squirrel: {'fish'},
  PetCharacter.penguin: {'broccoli'},
};

FoodReaction foodReactionFor(PetCharacter character, PetFood food) {
  if (food.id == 'chili') return FoodReaction.spicy;
  if (_loves[character]?.contains(food.id) ?? false) return FoodReaction.love;
  if (_dislikes[character]?.contains(food.id) ?? false) return FoodReaction.dislike;
  return FoodReaction.like;
}

String foodPhrase(FoodReaction reaction, PetFood food) => switch (reaction) {
      FoodReaction.love => 'Yummy! I LOVE ${food.en}! ❤️',
      FoodReaction.like => 'Mmm, ${food.en}! Tasty! 😋',
      FoodReaction.dislike => 'Yuck! No ${food.en}, please! 🤢',
      FoodReaction.spicy => 'Hot, hot, HOT! 🔥 Water, please!',
    };

/// Lời thú cưng TỰ rủ bé chơi khi để yên lâu - vài câu gợi ý luôn cách trêu
/// mới (chạm mũi, bụng) để bé tự khám phá.
class IdlePrompt {
  final String text;
  final IdleAction action;

  const IdlePrompt(this.text, this.action);

  static List<IdlePrompt> forCharacter(PetCharacter character) => [
        IdlePrompt(
          character == PetCharacter.penguin ? 'Psst! Try tapping my BEAK! 🤭' : 'Psst! Try tapping my NOSE! 🤭',
          IdleAction.wiggle,
        ),
        const IdlePrompt("I'm bored... Tickle me! 😆", IdleAction.yawn),
        const IdlePrompt('Hello, {child}! Play with me! 👋', IdleAction.jump),
        IdlePrompt(
          character == PetCharacter.moni ? 'Knock on my SHELL! 🐢' : 'Hey! What about my TUMMY? 😆',
          IdleAction.wiggle,
        ),
        const IdlePrompt('Yaaawn... Is anybody there? 😪', IdleAction.yawn),
        const IdlePrompt("I'm hungry! Can you feed me? 🍎", IdleAction.jump),
      ];
}

enum IdleAction { wiggle, yawn, jump }
