import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/domain/entities/pet_character.dart';
import 'package:mimi_pet/domain/entities/pet_mood.dart';
import 'package:mimi_pet/domain/entities/pet_palette.dart';
import 'package:mimi_pet/presentation/screens/exam/exam_home_screen.dart';
import 'package:mimi_pet/presentation/screens/games/games_hub_screen.dart';
import 'package:mimi_pet/presentation/screens/home/pet_interactions.dart';
import 'package:mimi_pet/presentation/screens/scenes/picture_scenes_screen.dart';
import 'package:mimi_pet/presentation/state/child_name_controller.dart';
import 'package:mimi_pet/presentation/state/pet_character_controller.dart';
import 'package:mimi_pet/presentation/state/pet_controller.dart';
import 'package:mimi_pet/presentation/state/pet_inventory_controller.dart';
import 'package:mimi_pet/presentation/state/pet_palette_controller.dart';
import 'package:mimi_pet/presentation/widgets/mimi_painter.dart';
import 'package:mimi_pet/presentation/widgets/pet_avatar.dart';
import 'package:mimi_pet/presentation/widgets/speech_bubble.dart';
import 'package:mimi_pet/presentation/widgets/talk_button.dart';
import 'package:mimi_pet/presentation/widgets/type_instead_of_talk.dart';
import 'package:mimi_pet/services/speech_service.dart';
import 'package:mimi_pet/services/tts_service.dart';
import 'package:mimi_pet/presentation/widgets/emoji_art.dart';
import 'package:mimi_pet/presentation/widgets/ios_web_tips.dart';

/// Tab "Home": nơi bé gặp thú cưng (Bunny/Mimi/Moni - bé tự chọn) và có thể
/// chào hỏi tự do (không tính vào bài học/điểm sao) - đúng bước 6-8 trong kế
/// hoạch: thú cưng nói, thú cưng nghe, thú cưng trả lời. Muốn học từ vựng có
/// thưởng sao, bé qua tab "Play".
///
/// Ngoài chạm/vuốt ve, có thêm 1 hàng nút "chơi cùng" (xoay vòng / nhảy cao /
/// cho ăn) - đều chỉ để vui, KHÔNG cộng sao, giống nguyên tắc của việc vuốt
/// ve (xem [PetAvatarController] trong `pet_avatar.dart`). Nhân vật đang chọn
/// được lưu qua [PetCharacterController] (xem `pet_character_controller.dart`),
/// màu đang chọn lưu qua `PetPaletteController` (độc lập với nhân vật) - cả
/// 2 đều giữ đúng lựa chọn của bé giữa các lần mở app.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _bubbleText;
  bool _isBusy = false;
  DateTime? _lastPetAt;
  DateTime? _lastDoubleTapAt;
  final _random = Random();
  late final PetAvatarController _mimiController;

  /// true khi hàng chọn thú cưng/màu đang MỞ RỘNG - mặc định THU GỌN để dành
  /// chỗ cho vùng tương tác chính (avatar + nút chơi) luôn vừa trong 1 khung
  /// màn hình, không cần cuộn (xem yêu cầu rà soát UI Home). Bé vẫn đổi được
  /// bình thường, chỉ cần bấm mở ra trước.
  bool _customizeExpanded = false;

  /// Chạy lặp lại trong lúc bé GIỮ TAY cù thú cưng (xem [_handleTickleStart]).
  Timer? _tickleTimer;
  DateTime? _tickleStartedAt;

  /// Đang đọc dở 1 câu cười - nhịp cù kế tiếp KHÔNG ngắt ngang câu đó (trước
  /// đây cứ 0,9 giây đọc câu mới làm câu nào cũng bị cắt giữa chừng).
  bool _tickleSpeaking = false;

  /// Trêu dồn dập -> giả vờ dỗi -> phì cười -> mệt (xem [TeaseMeter]).
  final _teaseMeter = TeaseMeter();

  /// Ngủ kéo dài sau khi bấm "Đi ngủ" - chạm 1 lần chỉ trở mình, chạm tiếp
  /// thì giật mình thức dậy; tự dậy sau [_sleepDuration].
  bool _asleep = false;
  int _sleepStirs = 0;
  Timer? _autoWakeTimer;
  static const _sleepDuration = Duration(seconds: 30);

  /// Mốc các lần cho ăn gần đây - ăn quá nhiều liền nhau thì "no căng bụng".
  final List<DateTime> _recentFeeds = [];

  /// Thú cưng tự rủ bé chơi khi để yên lâu - chỉ khi bé đang ở tab Home và
  /// không có màn hình khác đè lên, tối đa vài lần liên tiếp để không làm phiền.
  Timer? _idleTimer;
  DateTime _lastInteractionAt = DateTime.now();
  int _idlePromptsInRow = 0;
  Duration _nextIdleAfter = const Duration(seconds: 30);
  static const _maxIdlePromptsInRow = 3;
  ValueListenable<TickerModeData>? _tickerEnabled;
  ModalRoute<Object?>? _route;
  bool _wasHidden = false;

  @override
  void initState() {
    super.initState();
    _mimiController = PetAvatarController();
    _nextIdleAfter = _randomIdleDelay();
    _idleTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkIdle());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerEnabled = TickerMode.getValuesNotifier(context);
    _route = ModalRoute.of(context);
  }

  @override
  void dispose() {
    _mimiController.dispose();
    _tickleTimer?.cancel();
    _autoWakeTimer?.cancel();
    _idleTimer?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------------ helpers

  PetCharacter get _character => context.read<PetCharacterController>().character;

  String _withName(String phrase) {
    final name = context.read<ChildNameController>().name;
    return phrase.replaceAll('{child}', (name == null || name.trim().isEmpty) ? 'friend' : name.trim());
  }

  /// Hiện câu trong bong bóng + đọc to + đổi mood. Các phản ứng "khó chịu"
  /// (dỗi, chóng mặt, nhăn mặt) dùng mood idle để thú cưng không nhún nhảy vui.
  void _say(String phrase, {PetMood mood = PetMood.happy, Duration idleAfter = const Duration(seconds: 2)}) {
    final text = _withName(phrase);
    setState(() => _bubbleText = text);
    final pet = context.read<PetController>();
    if (mood == PetMood.happy) {
      pet.setMood(PetMood.happy, autoIdleAfter: idleAfter);
    } else {
      pet.setMood(mood);
    }
    context.read<TtsService>().speak(text);
  }

  void _markInteraction() {
    _lastInteractionAt = DateTime.now();
    _idlePromptsInRow = 0;
  }

  /// Phản ứng theo mức bị trêu - trả về true nếu đã xử lý (dỗi/cười/mệt).
  bool _reactToTease(TeaseReaction reaction) {
    switch (reaction) {
      case TeaseReaction.grumpy:
        _mimiController.play(MimiTrick.grumpy);
        _say(PetPhrases.pick(PetPhrases.grumpy, _random), mood: PetMood.idle);
        return true;
      case TeaseReaction.burstLaugh:
        _mimiController.play(MimiTrick.bellyLaugh);
        _say(PetPhrases.pick(PetPhrases.burstLaugh, _random), idleAfter: const Duration(seconds: 3));
        return true;
      case TeaseReaction.tired:
        _mimiController.play(MimiTrick.yawn);
        _say(PetPhrases.pick(PetPhrases.tired, _random), mood: PetMood.idle);
        return true;
      case TeaseReaction.normal:
        return false;
    }
  }

  // ------------------------------------------------------------------ touch

  /// Bé chạm/vuốt ve thú cưng ở Home - chỉ để vui, KHÔNG cộng sao. Mỗi vùng
  /// (tai/mũi/bụng/chân/thân) có phản ứng riêng.
  void _handlePetTap(MimiTapRegion region) {
    if (_isBusy) return;
    _markInteraction();
    if (_asleep) {
      _handleSleepingTap();
      return;
    }

    final now = DateTime.now();
    if (_lastPetAt != null && now.difference(_lastPetAt!) < const Duration(milliseconds: 900)) {
      // Chạm dồn dập: không nói thêm câu mới (tránh câu nọ chèn câu kia) nhưng
      // VẪN tính là đang trêu - nếu không, điểm trêu tự giảm nhanh hơn tốc độ
      // cộng và thú cưng không bao giờ dỗi/phì cười dù bé chạm liên tục.
      final reaction = _teaseMeter.add(0.5, now);
      if (reaction == TeaseReaction.burstLaugh || reaction == TeaseReaction.tired) {
        _lastPetAt = now;
        _reactToTease(reaction);
      }
      return;
    }
    _lastPetAt = now;

    HapticFeedback.mediumImpact();
    final reaction = _teaseMeter.add(region == MimiTapRegion.body ? 1.0 : 1.5, now);
    if (_reactToTease(reaction)) return;

    switch (region) {
      case MimiTapRegion.nose:
        _mimiController.play(MimiTrick.sneeze);
      case MimiTapRegion.belly:
        _mimiController.play(_character == PetCharacter.moni ? MimiTrick.hide : MimiTrick.bellyLaugh);
      case MimiTapRegion.feet:
        _mimiController.play(MimiTrick.footWiggle);
      case MimiTapRegion.earLeft:
      case MimiTapRegion.earRight:
      case MimiTapRegion.body:
        break; // PetAvatar đã tự kéo tai/lắc cười ngay lúc chạm
    }
    _say(PetPhrases.pick(PetPhrases.forRegion(region, _character), _random));
  }

  /// Chạm 2 lần liên tiếp (nhanh) - phản ứng MẠNH: cười lăn.
  void _handlePetDoubleTap() {
    if (_isBusy) return;
    _markInteraction();
    if (_asleep) {
      _wake();
      _mimiController.bonusJump();
      _say(PetPhrases.pick(PetPhrases.sleepWake, _random));
      return;
    }
    HapticFeedback.heavyImpact();
    final now = DateTime.now();
    final reaction = _teaseMeter.add(2, now);
    // Chạm liên hồi tạo ra double tap liên tục - chỉ phản ứng lại sau mỗi
    // 1.5 giây (trừ lúc phì cười/mệt) để câu đang đọc không bị cắt ngang.
    final lastDouble = _lastDoubleTapAt;
    final tooSoon = lastDouble != null && now.difference(lastDouble) < const Duration(milliseconds: 1500);
    if (tooSoon && reaction != TeaseReaction.burstLaugh && reaction != TeaseReaction.tired) return;
    _lastDoubleTapAt = now;
    _lastPetAt = now;
    if (_reactToTease(reaction)) return;
    _mimiController.play(MimiTrick.bellyLaugh);
    _say(PetPhrases.pick(PetPhrases.doubleTap, _random));
  }

  /// Bé bắt đầu GIỮ TAY cù - câu cười leo thang theo thời gian giữ (khúc
  /// khích -> "Stop, stop!" -> "I can't breathe!"), không ngắt câu đang đọc.
  void _handleTickleStart() {
    if (_isBusy) return;
    _markInteraction();
    var firstPhrase = _asleep ? PetPhrases.pick(PetPhrases.sleepWakeLaugh, _random) : null;
    if (_asleep) _wake();
    _tickleTimer?.cancel();
    _tickleStartedAt = DateTime.now();

    void tick() {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      final held = DateTime.now().difference(_tickleStartedAt!);
      final tier = held < const Duration(seconds: 3)
          ? PetPhrases.tickleMild
          : held < const Duration(seconds: 7)
              ? PetPhrases.tickleStrong
              : PetPhrases.tickleMax;
      final phrase = firstPhrase ?? PetPhrases.pick(tier, _random);
      firstPhrase = null;
      setState(() => _bubbleText = phrase);
      if (!_tickleSpeaking) {
        _tickleSpeaking = true;
        context.read<TtsService>().speak(phrase).whenComplete(() => _tickleSpeaking = false);
      }
    }

    tick();
    _tickleTimer = Timer.periodic(const Duration(milliseconds: 900), (_) => tick());
    context.read<PetController>().setMood(PetMood.happy);
  }

  /// Bé thả tay: cù quá lâu thì thú cưng mệt ngáp dài, còn không thì thở phào.
  void _handleTickleEnd() {
    _tickleTimer?.cancel();
    _tickleTimer = null;
    final started = _tickleStartedAt;
    _tickleStartedAt = null;
    if (!mounted || started == null) return;
    _markInteraction();
    final heldSeconds = DateTime.now().difference(started).inMilliseconds / 1000.0;
    if (heldSeconds >= 7) {
      _teaseMeter.reset();
      _mimiController.play(MimiTrick.yawn);
      _say(PetPhrases.pick(PetPhrases.tired, _random), mood: PetMood.idle);
      return;
    }
    if (_reactToTease(_teaseMeter.add(heldSeconds * 0.5, DateTime.now()))) return;
    setState(() => _bubbleText = 'Phew! Hehe, that was fun! 😊');
    context.read<PetController>().setMood(PetMood.happy, autoIdleAfter: const Duration(seconds: 2));
  }

  /// Bé thả tay sau khi KÉO thú cưng - kéo qua lại nhiều thì chóng mặt.
  void _handleDragEnd(double intensity) {
    if (_isBusy || intensity < 1.0) return;
    _markInteraction();
    if (_asleep) {
      _wake();
      _mimiController.bonusJump();
      _say('Whoa! Am I sleepwalking?! 😳');
      return;
    }
    if (intensity >= 5) {
      _teaseMeter.add(2, DateTime.now());
      _mimiController.play(MimiTrick.dizzy);
      _say(PetPhrases.pick(PetPhrases.dragWild, _random), mood: PetMood.idle);
    } else {
      _teaseMeter.add(1, DateTime.now());
      _say(PetPhrases.pick(PetPhrases.dragSmall, _random));
    }
  }

  // ------------------------------------------------------------------ sleep

  void _wake() {
    _autoWakeTimer?.cancel();
    _autoWakeTimer = null;
    setState(() {
      _asleep = false;
      _sleepStirs = 0;
    });
  }

  /// Nút chơi/nói bất kỳ trong lúc ngủ: đánh thức êm (không nói gì thêm).
  void _wakeIfAsleep() {
    if (_asleep) _wake();
  }

  void _handleSleepingTap() {
    _sleepStirs++;
    if (_sleepStirs < 2) {
      HapticFeedback.lightImpact();
      final phrase = PetPhrases.pick(PetPhrases.sleepStir, _random);
      setState(() => _bubbleText = phrase);
      context.read<TtsService>().speak(phrase);
      return;
    }
    HapticFeedback.heavyImpact();
    _wake();
    _mimiController.bonusJump();
    _say(PetPhrases.pick(PetPhrases.sleepWake, _random));
  }

  // ------------------------------------------------------------------ buttons

  void _handleSpin() {
    if (_isBusy) return;
    _markInteraction();
    _wakeIfAsleep();
    _mimiController.spin();
    HapticFeedback.lightImpact();
    setState(() => _bubbleText = 'Wheee! 🌀');
    context.read<PetController>().setMood(PetMood.happy, autoIdleAfter: const Duration(seconds: 2));
    context.read<TtsService>().speak('Wheee!');
  }

  void _handleBonusJump() {
    if (_isBusy) return;
    _markInteraction();
    _wakeIfAsleep();
    _mimiController.bonusJump();
    HapticFeedback.lightImpact();
    setState(() => _bubbleText = 'Boing boing! 🦘');
    context.read<PetController>().setMood(PetMood.happy, autoIdleAfter: const Duration(seconds: 2));
    context.read<TtsService>().speak('Boing boing! Jump with me!');
  }

  /// "Cho ăn": bé chọn món - thú cưng có món THÍCH (tim bay), món GHÉT (nhăn
  /// mặt), ăn ớt thì phun lửa, ăn liền nhiều món thì no căng bụng.
  Future<void> _handleFeed() async {
    if (_isBusy) return;
    _markInteraction();
    _wakeIfAsleep();
    final food = await showModalBottomSheet<PetFood>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => _FoodMenu(petName: PetCharacterInfo.all[_character]!.displayName),
    );
    if (food == null || !mounted) return;
    _markInteraction();
    HapticFeedback.lightImpact();

    final now = DateTime.now();
    _recentFeeds.removeWhere((t) => now.difference(t) > const Duration(minutes: 1));
    if (_recentFeeds.length >= 5) {
      _mimiController.play(MimiTrick.yawn);
      _say("I'm so full! No more food, please! 😵", mood: PetMood.idle);
      return;
    }
    _recentFeeds.add(now);

    final reaction = foodReactionFor(_character, food);
    switch (reaction) {
      case FoodReaction.love:
        _mimiController.play(MimiTrick.love);
        _say(foodPhrase(reaction, food), idleAfter: const Duration(seconds: 3));
      case FoodReaction.like:
        _mimiController.eat();
        _say(foodPhrase(reaction, food));
      case FoodReaction.dislike:
        _mimiController.play(MimiTrick.disgust);
        _say(foodPhrase(reaction, food), mood: PetMood.idle);
      case FoodReaction.spicy:
        _mimiController.play(MimiTrick.fire);
        _say(foodPhrase(reaction, food), mood: PetMood.idle);
    }
  }

  void _handleBath() {
    if (_isBusy) return;
    _markInteraction();
    _wakeIfAsleep();
    _mimiController.bath();
    HapticFeedback.lightImpact();
    setState(() => _bubbleText = 'Splish splash! Bath time! 🛁');
    context.read<PetController>().setMood(PetMood.happy, autoIdleAfter: const Duration(seconds: 2));
    context.read<TtsService>().speak('Splish splash! I love bath time!');
  }

  /// Ngủ KÉO DÀI (xem [_asleep]) - mood idle để không nhún nhảy trong lúc ngủ.
  void _handleSleep() {
    if (_isBusy) return;
    _markInteraction();
    _mimiController.sleep();
    HapticFeedback.lightImpact();
    _autoWakeTimer?.cancel();
    setState(() {
      _asleep = true;
      _sleepStirs = 0;
      _bubbleText = 'Good night! Sweet dreams! 🌙';
    });
    context.read<PetController>().setMood(PetMood.idle);
    context.read<TtsService>().speak('Good night! Sweet dreams!');
    _autoWakeTimer = Timer(_sleepDuration, () {
      if (!mounted || !_asleep) return;
      _wake();
      _mimiController.bonusJump();
      _say(PetPhrases.sleepAutoWake);
    });
  }

  void _handleExercise() {
    if (_isBusy) return;
    _markInteraction();
    _wakeIfAsleep();
    _mimiController.exercise();
    HapticFeedback.lightImpact();
    setState(() => _bubbleText = "Let's exercise! One, two, three! 🤸");
    context.read<PetController>().setMood(PetMood.happy, autoIdleAfter: const Duration(seconds: 2));
    context.read<TtsService>().speak("Let's exercise together!");
  }

  // ------------------------------------------------------------------ idle

  Duration _randomIdleDelay() => Duration(seconds: 25 + _random.nextInt(16));

  /// Thú cưng tự rủ chơi - CHỈ khi bé đang nhìn thấy Home (đúng tab, không
  /// có màn hình khác đè lên, app đang mở) và không đang ngủ/cù/bận.
  void _checkIdle() {
    if (!mounted || _isBusy || _asleep || _tickleTimer != null) return;
    if (_idlePromptsInRow >= _maxIdlePromptsInRow) return;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final visible = (_tickerEnabled?.value.enabled ?? true) &&
        (_route?.isCurrent ?? true) &&
        (lifecycle == null || lifecycle == AppLifecycleState.resumed);
    final now = DateTime.now();
    if (!visible) {
      _wasHidden = true;
      return;
    }
    if (_wasHidden) {
      // Bé vừa quay lại Home: đếm lại từ đầu, không "nhảy vào nói" ngay.
      _wasHidden = false;
      _lastInteractionAt = now;
      return;
    }
    if (now.difference(_lastInteractionAt) < _nextIdleAfter) return;

    final prompts = IdlePrompt.forCharacter(_character);
    final prompt = prompts[_random.nextInt(prompts.length)];
    switch (prompt.action) {
      case IdleAction.wiggle:
        _mimiController.play(MimiTrick.footWiggle);
      case IdleAction.yawn:
        _mimiController.play(MimiTrick.yawn);
      case IdleAction.jump:
        _mimiController.bonusJump();
    }
    _say(prompt.text, mood: prompt.action == IdleAction.yawn ? PetMood.idle : PetMood.happy);
    _idlePromptsInRow++;
    _lastInteractionAt = now;
    _nextIdleAfter = _randomIdleDelay();
  }

  /// Bé chọn đổi nhân vật - chỉ đổi hình vẽ + câu chào, KHÔNG reset mood hay
  /// điểm sao (xem [PetCharacterController]).
  void _handleSelectCharacter(PetCharacter character) {
    if (_isBusy) return;
    final controller = context.read<PetCharacterController>();
    if (controller.character == character) return;
    _markInteraction();
    _wakeIfAsleep();
    _teaseMeter.reset();
    HapticFeedback.selectionClick();
    controller.select(character);
    final info = PetCharacterInfo.all[character]!;
    setState(() => _bubbleText = "Hi! I'm ${info.displayName}! ${info.emoji}");
    context.read<TtsService>().speak("Hi! I'm ${info.displayName}!");
  }

  /// Bé chọn đổi màu CHO NHÂN VẬT ĐANG CHỌN - mỗi nhân vật nhớ màu riêng của
  /// nó, độc lập với 2 nhân vật còn lại (xem [PetPaletteController]).
  void _handleSelectPalette(PetCharacter character, PetPalette palette) {
    if (_isBusy) return;
    final controller = context.read<PetPaletteController>();
    if (controller.paletteFor(character) == palette) return;
    _markInteraction();
    HapticFeedback.selectionClick();
    controller.select(character, palette);
    setState(() => _bubbleText = 'Ooh, I love this color! ✨');
  }

  Future<void> _handleTalkPressed() async {
    if (_isBusy) return;
    _markInteraction();
    _wakeIfAsleep();

    final pet = context.read<PetController>();
    final speech = context.read<SpeechService>();

    setState(() => _isBusy = true);
    pet.setMood(PetMood.listening);

    // BỌC try/catch/finally: nếu speech_to_text lỗi (mic bị từ chối quyền,
    // plugin lỗi...) mà không bắt, _isBusy sẽ kẹt ở true MÃI MÃI -> nút "Tap
    // to talk" bị vô hiệu hoá vĩnh viễn sau lần bấm đầu tiên (đúng lỗi "nút
    // không tương tác được" đã gặp). Có finally đảm bảo LUÔN reset lại được.
    try {
      final outcome = await speech
          .listenOnce(listenFor: const Duration(seconds: 5))
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      await _respondToHeard(outcome.recognizedText);
    } catch (_) {
      if (!mounted) return;
      setState(() => _bubbleText = "Sorry, I can't hear you right now. Try again? 🎤");
      pet.setMood(PetMood.idle);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Fallback KHÔNG dùng giọng nói - xem `TypeInsteadOfTalk` (widget) để biết
  /// lý do cần cái này (mic của Safari trên iPhone/iPad hay chập chờn -
  /// xem `deployment.md`). Dùng LẠI ĐÚNG logic phản hồi với [_handleTalkPressed]
  /// (xem [_respondToHeard]) - chỉ khác nguồn lấy chữ (bàn phím thay vì mic),
  /// nên KHÔNG cần bọc try/catch/timeout của speech_to_text.
  Future<void> _handleTypedTalk(String text) async {
    if (_isBusy) return;
    _markInteraction();
    _wakeIfAsleep();
    setState(() => _isBusy = true);
    try {
      await _respondToHeard(text);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _respondToHeard(String recognizedText) async {
    final pet = context.read<PetController>();
    final tts = context.read<TtsService>();
    final info = PetCharacterInfo.all[context.read<PetCharacterController>().character]!;

    pet.setMood(PetMood.thinking);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final heard = recognizedText.toLowerCase();
    final String reply;
    if (heard.contains('hello') || heard.contains('hi')) {
      reply = 'Hello! Nice to meet you! ${info.emoji}';
    } else if (heard.isEmpty) {
      reply = 'I didn\'t hear you. Try: "Hello ${info.displayName}!"';
    } else {
      reply = 'Hi there! Try saying: "Hello ${info.displayName}!"';
    }

    setState(() => _bubbleText = reply);
    pet.setMood(PetMood.happy, autoIdleAfter: const Duration(seconds: 3));
    await tts.speak(reply);
  }

  /// Mở màn "Bài tranh" (xem `PictureScenesScreen`) - đặt thành 1 thẻ RIÊNG ở
  /// Home thay vì thêm tab thứ 6 ở thanh dưới (đã hơi chật với 5 mục hiện
  /// tại), theo đúng lựa chọn của người dùng khi tư vấn tính năng này.
  void _openPictureScenes(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PictureScenesScreen()),
    );
  }

  /// Mở màn "Thi thử" (đề YLE Movers/Flyers + khung TOEIC, xem
  /// `docs/THIET_KE_SCHEMA_CHUNG.md`) - cùng cách đặt thẻ riêng ở Home thay vì
  /// thêm tab thứ 6 như [_openPictureScenes].
  void _openExam(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExamHomeScreen()),
    );
  }

  void _openGames(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GamesHubScreen()),
    );
  }

  Widget _playButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return OutlinedButton.icon(
      onPressed: _isBusy ? null : onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF8B6FD9),
        side: const BorderSide(color: Color(0xFFD8C6F7), width: 1.5),
        backgroundColor: const Color(0xFFF6F0FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  /// Hàng chọn nhân vật - 3 nút tròn nhỏ (emoji + tên), nhân vật đang chọn
  /// được viền/tô đậm rõ ràng để bé 8 tuổi dễ nhận biết.
  Widget _characterChip(PetCharacter character, bool selected) {
    final info = PetCharacterInfo.all[character]!;
    return GestureDetector(
      onTap: () => _handleSelectCharacter(character),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF6F0FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF8B6FD9) : const Color(0xFFE0D6F5),
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(info.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 2),
            Text(
              info.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? const Color(0xFF8B6FD9) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1 chấm màu trong hàng chọn màu - màu đang chọn có viền đậm + dấu ✓.
  Widget _paletteChip(PetCharacter character, PetPalette palette, bool selected) {
    final info = PetPaletteInfo.all[palette]!;
    return GestureDetector(
      onTap: () => _handleSelectPalette(character, palette),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: info.swatch,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? const Color(0xFF8B6FD9) : Colors.black.withValues(alpha: 0.08),
            width: selected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        alignment: Alignment.center,
        child: selected
            ? Icon(Icons.check_rounded, size: 16, color: Colors.black.withValues(alpha: 0.55))
            : null,
      ),
    );
  }

  /// Hàng nhỏ bấm để MỞ/ĐÓNG phần chọn thú cưng + màu (xem [_customizeExpanded]).
  /// Luôn hiện tên+emoji nhân vật đang chọn ngay cả khi đang thu gọn, để bé
  /// vẫn biết đang chơi với ai mà không cần mở ra.
  Widget _customizeToggle(PetCharacterInfo info) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _customizeExpanded = !_customizeExpanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(info.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                '${info.displayName} · Đổi thú cưng/màu',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF8B6FD9)),
              ),
              Icon(
                _customizeExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                size: 20,
                color: const Color(0xFF8B6FD9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pet = context.watch<PetController>();
    final characterController = context.watch<PetCharacterController>();
    final character = characterController.character;
    final palette = context.watch<PetPaletteController>().paletteFor(character);
    final inventory = context.watch<PetInventoryController>();
    final info = PetCharacterInfo.all[character]!;
    final isListening = pet.mood == PetMood.listening;
    final bubbleText = _bubbleText ?? "Hi! I'm ${info.displayName}! ${info.emoji}";

    // CẤU TRÚC (rà soát UI Home, SỬA LẠI sau khi phát hiện lỗi trên di động
    // thật): bản đầu dùng `Expanded` CỐ ĐỊNH chiều cao vùng tương tác thú
    // cưng - chạy tốt trên màn hình rộng lúc test nhưng VỠ trên điện thoại
    // thật màn hình nhỏ + khi bàn phím ảo mở (Expanded co về 0 làm "Bài
    // tranh"/"Thi thử" biến mất hẳn, đồng thời không còn ai lo cuộn nên bàn
    // phím che mất ô nhập liệu). Quay lại đúng pattern CUỘN TOÀN BỘ đã dùng
    // trước đây (LayoutBuilder + SingleChildScrollView + ConstrainedBox
    // (minHeight) + IntrinsicHeight) - tự co giãn đúng theo bàn phím ảo
    // (Flutter tự trừ `viewInsets.bottom` vào `constraints.maxHeight`), vẫn
    // "vừa 1 màn hình không cần cuộn" trên máy đủ cao nhờ nội dung đã thu
    // gọn (hàng chọn nhân vật/màu mặc định ẩn, xem [_customizeExpanded]) -
    // chỉ cuộn thật sự khi máy quá nhỏ hoặc bàn phím chiếm nhiều chỗ, đúng
    // hành vi "graceful" thay vì cắt cứng nội dung.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const IosWebTipsBanner(),
                  _customizeToggle(info),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: !_customizeExpanded
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: PetCharacter.values
                                      .map((c) => _characterChip(c, c == character))
                                      .toList(growable: false),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 10,
                                  runSpacing: 8,
                                  children: PetPalette.values
                                      .map((p) => _paletteChip(character, p, p == palette))
                                      .toList(growable: false),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 6),
                  PetAvatar(
                    mood: pet.mood,
                    character: character,
                    palette: palette,
                    headAccessory: inventory.equippedHead,
                    neckAccessory: inventory.equippedNeck,
                    size: 200,
                    onTap: _handlePetTap,
                    onDoubleTap: _handlePetDoubleTap,
                    onTickleStart: _handleTickleStart,
                    onTickleEnd: _handleTickleEnd,
                    onDragEnd: _handleDragEnd,
                    sleeping: _asleep,
                    controller: _mimiController,
                  ),
                  const SizedBox(height: 8),
                  // Nút "chơi cùng" đặt NGAY SÁT dưới avatar (thay vì tách xa
                  // như trước) - đúng yêu cầu "để sát lên phần hình ảnh pet".
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _playButton(label: 'Xoay vòng', icon: Icons.refresh_rounded, onTap: _handleSpin),
                      _playButton(
                        label: 'Nhảy chơi',
                        icon: Icons.arrow_upward_rounded,
                        onTap: _handleBonusJump,
                      ),
                      _playButton(label: 'Cho ăn 🥕', icon: Icons.favorite_rounded, onTap: _handleFeed),
                      _playButton(label: 'Tắm 🛁', icon: Icons.bathtub_rounded, onTap: _handleBath),
                      _playButton(label: 'Đi ngủ 🌙', icon: Icons.bedtime_rounded, onTap: _handleSleep),
                      _playButton(
                        label: 'Tập thể dục 🤸',
                        icon: Icons.fitness_center_rounded,
                        onTap: _handleExercise,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SpeechBubble(text: bubbleText),
                  const SizedBox(height: 10),
                  TalkButton(
                    isListening: isListening,
                    enabled: !_isBusy,
                    onTap: _handleTalkPressed,
                    label: isListening ? 'Listening...' : 'Tap to talk',
                  ),
                  const SizedBox(height: 6),
                  // Fallback cho Safari trên iPhone/iPad (mic hay chập
                  // chờn) - xem `TypeInsteadOfTalk`.
                  TypeInsteadOfTalk(
                    enabled: !_isBusy,
                    onSubmitted: _handleTypedTalk,
                    hintText: 'Gõ "Hello"...',
                  ),
                  const SizedBox(height: 18),
                  // "Bài tranh"/"Thi thử" - ĐẨY XUỐNG DƯỚI, ngay trong CÙNG
                  // cột cuộn (không tách `Expanded` riêng như bản trước - đó
                  // chính là nguyên nhân card "biến mất" trên máy nhỏ/khi mở
                  // bàn phím, xem ghi chú ở đầu `build()`).
                  _PictureScenesCard(onTap: () => _openPictureScenes(context)),
                  const SizedBox(height: 10),
                  _GamesCard(onTap: () => _openGames(context)),
                  const SizedBox(height: 10),
                  _ExamCard(onTap: () => _openExam(context)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Thẻ lối vào "Bài tranh" (xem [HomeScreen._openPictureScenes]) - đặt nổi
/// bật, riêng biệt với hàng nút "chơi cùng" nhỏ bên dưới, để bé dễ nhận ra
/// đây là 1 khu vực học khác (xem tranh + trả lời câu hỏi) chứ không phải 1
/// trò chơi cùng thú cưng như các nút Xoay vòng/Cho ăn...
class _PictureScenesCard extends StatelessWidget {
  final VoidCallback onTap;

  const _PictureScenesCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF1DC),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0C98A), width: 1.5),
          ),
          child: Row(
            children: [
              const Text('🖼️', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bài tranh',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Xem tranh, trả lời câu hỏi bằng tiếng Anh',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFC98A3F)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thẻ lối vào "Góc trò chơi" (minigame + album sticker) - màu xanh lá để
/// phân biệt với "Bài tranh" (cam) và "Thi thử" (tím).
class _GamesCard extends StatelessWidget {
  final VoidCallback onTap;

  const _GamesCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE9F7EC),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFA8DDB5), width: 1.5),
          ),
          child: const Row(
            children: [
              Text('🎲', style: TextStyle(fontSize: 30)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Góc trò chơi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      'Lật thẻ, chạm bong bóng, ếch qua sông, sưu tập sticker',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFF3FAE5A)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thẻ lối vào "Thi thử" (xem [HomeScreen._openExam]) - đặt ngay dưới thẻ
/// "Bài tranh", cùng kiểu thẻ nổi bật nhưng dùng màu tím (đồng bộ AppColors.primary)
/// để phân biệt trực quan với thẻ "Bài tranh" (màu cam).
class _ExamCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ExamCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6F0FF),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD8C6F7), width: 1.5),
          ),
          child: Row(
            children: [
              const Text('📝', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thi thử',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Luyện đề YLE Movers/Flyers, có cả khung TOEIC',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8B6FD9)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menu "Cho ăn": bé chọn 1 món (hình + tên tiếng Anh để học từ).
class _FoodMenu extends StatelessWidget {
  final String petName;

  const _FoodMenu({required this.petName});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cho $petName ăn gì nào? 🍽️',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Có món bạn ấy rất thích, có món bạn ấy chê đấy!',
                style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final food in PetFood.all)
                  Material(
                    color: const Color(0xFFFFF6EA),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).pop(food),
                      child: SizedBox(
                        width: 76,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            children: [
                              EmojiArt(food.emoji, size: 36),
                              const SizedBox(height: 4),
                              Text(food.en,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
