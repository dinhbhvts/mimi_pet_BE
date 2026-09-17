import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/domain/entities/pet_character.dart';
import 'package:mimi_pet/domain/entities/pet_mood.dart';
import 'package:mimi_pet/domain/entities/pet_palette.dart';
import 'package:mimi_pet/presentation/screens/exam/exam_home_screen.dart';
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
  // "{child}" (nếu có) được thay bằng tên riêng của bé đã đặt trong Cài đặt
  // (xem [ChildNameController]/[_handlePetTap]) - KHÔNG phải mọi câu đều cần
  // có {child}, chỉ vài câu để thỉnh thoảng thú cưng gọi tên bé, tránh lặp
  // lại tên trong MỌI câu nghe cứng nhắc.
  static const List<String> _petPhrases = [
    'Hehe, that tickles! 😄',
    'Yay! Hi again, {child}! 👋',
    'I like you, {child}! 💜',
    "You're my best friend!",
    'Woohoo!',
  ];

  static const List<String> _earPullPhrases = [
    'Hehe, my ear! 😆',
    'Tickle tickle!',
    "That's my ear!",
    'Giggle giggle!',
  ];

  /// Câu Mimi nói khi bé chạm 2 lần liên tiếp - PHẢN ỨNG MẠNH hơn hẳn 1 lần
  /// chạm thường (xem [_handlePetDoubleTap]/[PetAvatar.onDoubleTap]).
  static const List<String> _doubleTapPhrases = [
    'Whoa! Hehehe, again?! 😆',
    'Hihi, you got me twice!',
    'Ahaha, double tickle!',
  ];

  /// Câu Mimi nói LẶP LẠI trong lúc bé GIỮ TAY trêu (xem [_handleTickleStart]/
  /// [PetAvatar.onTickleStart]) - xoay vòng ngẫu nhiên mỗi nhịp cho tới khi bé
  /// thả tay, cảm giác thú cưng "cười không dừng được" càng trêu càng lâu.
  static const List<String> _tickleLoopPhrases = [
    'Hahaha! Stop, hihi! 😂',
    "That tickles so much!",
    'Hihihi, no more, hehe!',
    'Ahaha, I can\'t stop laughing!',
  ];

  /// `null` nghĩa là chưa có tương tác gì - lúc đó bong bóng thoại hiển thị
  /// câu chào MẶC ĐỊNH theo đúng tên nhân vật đang chọn (xem [build]), thay
  /// vì cố định "Hi! I'm Mimi!" như trước (giờ bé có thể chọn Bunny/Moni).
  String? _bubbleText;
  bool _isBusy = false;
  DateTime? _lastPetAt;
  final _random = Random();
  late final PetAvatarController _mimiController;

  /// true khi hàng chọn thú cưng/màu đang MỞ RỘNG - mặc định THU GỌN để dành
  /// chỗ cho vùng tương tác chính (avatar + nút chơi) luôn vừa trong 1 khung
  /// màn hình, không cần cuộn (xem yêu cầu rà soát UI Home). Bé vẫn đổi được
  /// bình thường, chỉ cần bấm mở ra trước.
  bool _customizeExpanded = false;

  /// Chạy lặp lại trong lúc bé GIỮ TAY trêu thú cưng (xem [_handleTickleStart]/
  /// [_handleTickleEnd]) - đọc to 1 câu "cười" ngẫu nhiên + rung nhẹ mỗi
  /// nhịp, dừng hẳn khi bé thả tay ra.
  Timer? _tickleTimer;

  @override
  void initState() {
    super.initState();
    _mimiController = PetAvatarController();
  }

  @override
  void dispose() {
    _mimiController.dispose();
    _tickleTimer?.cancel();
    super.dispose();
  }

  /// Bé chạm/vuốt ve thú cưng ở Home - chỉ để vui, KHÔNG cộng sao (phân biệt
  /// rõ với việc học ở tab Play, tránh bé bấm loạn để "cày" sao ảo). Chạm
  /// vào tai (trái/phải) có câu thoại riêng, khác với chạm vào thân/đầu.
  void _handlePetTap(MimiTapRegion region) {
    if (_isBusy) return;

    final now = DateTime.now();
    if (_lastPetAt != null && now.difference(_lastPetAt!) < const Duration(milliseconds: 900)) {
      return; // chống bấm liên tục dồn dập
    }
    _lastPetAt = now;

    final pet = context.read<PetController>();
    final tts = context.read<TtsService>();
    final isEar = region == MimiTapRegion.earLeft || region == MimiTapRegion.earRight;
    final rawPhrase = isEar
        ? _earPullPhrases[_random.nextInt(_earPullPhrases.length)]
        : _petPhrases[_random.nextInt(_petPhrases.length)];
    // "friend" khi bé chưa đặt tên riêng - đọc tự nhiên trong câu tiếng Anh
    // (xem [_petPhrases]), khác cách xưng hô chung chung tiếng Việt "bạn"
    // dùng ở những chỗ khác trong app (Cài đặt...).
    final childName = context.read<ChildNameController>().name;
    final phrase = rawPhrase.replaceAll(
      '{child}',
      (childName == null || childName.trim().isEmpty) ? 'friend' : childName.trim(),
    );

    HapticFeedback.mediumImpact();
    setState(() => _bubbleText = phrase);
    pet.setMood(PetMood.happy, autoIdleAfter: const Duration(seconds: 2));
    tts.speak(phrase);
  }

  /// Chạm 2 lần liên tiếp (nhanh) - phản ứng MẠNH hơn hẳn 1 lần chạm thường,
  /// đúng kiểu bé "trêu bất ngờ" thú cưng (xem [PetAvatar.onDoubleTap]).
  void _handlePetDoubleTap() {
    if (_isBusy) return;
    final phrase = _doubleTapPhrases[_random.nextInt(_doubleTapPhrases.length)];
    HapticFeedback.heavyImpact();
    setState(() => _bubbleText = phrase);
    context.read<PetController>().setMood(PetMood.happy, autoIdleAfter: const Duration(seconds: 2));
    context.read<TtsService>().speak(phrase);
  }

  /// Bé bắt đầu GIỮ TAY trêu thú cưng - đọc ngay 1 câu, rồi lặp lại đều đặn
  /// (kèm rung nhẹ mỗi nhịp) cho tới khi bé thả tay ([_handleTickleEnd]) -
  /// đúng kiểu "trêu càng lâu thú cưng càng cười to" bé nhà bạn thích.
  void _handleTickleStart() {
    if (_isBusy) return;
    _tickleTimer?.cancel();
    void tick() {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() => _bubbleText = _tickleLoopPhrases[_random.nextInt(_tickleLoopPhrases.length)]);
      context.read<TtsService>().speak(_bubbleText!);
    }

    tick();
    _tickleTimer = Timer.periodic(const Duration(milliseconds: 900), (_) => tick());
    context.read<PetController>().setMood(PetMood.happy);
  }

  /// Bé thả tay ra - dừng hẳn vòng lặp câu "cười", thú cưng thở phào trở lại
  /// bình thường sau vài giây.
  void _handleTickleEnd() {
    _tickleTimer?.cancel();
    _tickleTimer = null;
    if (!mounted) return;
    setState(() => _bubbleText = 'Phew! Hehe, that was fun! 😊');
    context.read<PetController>().setMood(PetMood.happy, autoIdleAfter: const Duration(seconds: 2));
  }

  void _handleSpin() {
    if (_isBusy) return;
    _mimiController.spin();
    HapticFeedback.lightImpact();
    setState(() => _bubbleText = 'Wheee! 🌀');
    context.read<PetController>().setMood(PetMood.happy, autoIdleAfter: const Duration(seconds: 2));
    context.read<TtsService>().speak('Wheee!');
  }

  void _handleBonusJump() {
    if (_isBusy) return;
    _mimiController.bonusJump();
    HapticFeedback.lightImpact();
    setState(() => _bubbleText = 'Boing boing! 🦘');
    context.read<PetController>().setMood(PetMood.happy, autoIdleAfter: const Duration(seconds: 2));
    context.read<TtsService>().speak('Boing boing! Jump with me!');
  }

  void _handleFeed() {
    if (_isBusy) return;
    _mimiController.eat();
    HapticFeedback.lightImpact();
    setState(() => _bubbleText = 'Yummy carrot! 🥕');
    context.read<PetController>().setMood(PetMood.happy, autoIdleAfter: const Duration(seconds: 2));
    context.read<TtsService>().speak('Yummy! I love carrots!');
  }

  void _handleBath() {
    if (_isBusy) return;
    _mimiController.bath();
    HapticFeedback.lightImpact();
    setState(() => _bubbleText = 'Splish splash! Bath time! 🛁');
    context.read<PetController>().setMood(PetMood.happy, autoIdleAfter: const Duration(seconds: 2));
    context.read<TtsService>().speak('Splish splash! I love bath time!');
  }

  /// KHÔNG đặt mood `happy` (khác các trò khác) - "đi ngủ" cần đứng yên,
  /// mắt nhắm, không nhún nhảy (mood happy sẽ làm Mimi nhảy trong lúc đang
  /// "ngủ", nhìn kỳ - xem `PetAvatarController.sleep`/`_PetAvatarState._buildPose`).
  void _handleSleep() {
    if (_isBusy) return;
    _mimiController.sleep();
    HapticFeedback.lightImpact();
    setState(() => _bubbleText = 'Good night! Sweet dreams! 🌙');
    context.read<PetController>().setMood(PetMood.idle);
    context.read<TtsService>().speak('Good night! Sweet dreams!');
  }

  void _handleExercise() {
    if (_isBusy) return;
    _mimiController.exercise();
    HapticFeedback.lightImpact();
    setState(() => _bubbleText = "Let's exercise! One, two, three! 🤸");
    context.read<PetController>().setMood(PetMood.happy, autoIdleAfter: const Duration(seconds: 2));
    context.read<TtsService>().speak("Let's exercise together!");
  }

  /// Bé chọn đổi nhân vật - chỉ đổi hình vẽ + câu chào, KHÔNG reset mood hay
  /// điểm sao (xem [PetCharacterController]).
  void _handleSelectCharacter(PetCharacter character) {
    if (_isBusy) return;
    final controller = context.read<PetCharacterController>();
    if (controller.character == character) return;
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
    HapticFeedback.selectionClick();
    controller.select(character, palette);
    setState(() => _bubbleText = 'Ooh, I love this color! ✨');
  }

  Future<void> _handleTalkPressed() async {
    if (_isBusy) return;

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
  /// lý do cần cái này (Safari trên iPhone/iPad hầu như không hỗ trợ
  /// speech_to_text). Dùng LẠI ĐÚNG logic phản hồi với [_handleTalkPressed]
  /// (xem [_respondToHeard]) - chỉ khác nguồn lấy chữ (bàn phím thay vì mic),
  /// nên KHÔNG cần bọc try/catch/timeout của speech_to_text.
  Future<void> _handleTypedTalk(String text) async {
    if (_isBusy) return;
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
                  // Fallback cho Safari trên iPhone/iPad (hầu như không hỗ
                  // trợ speech_to_text) - xem `TypeInsteadOfTalk`.
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
