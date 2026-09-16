import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/entities/pet_accessory.dart';
import '../../domain/entities/pet_character.dart';
import '../../domain/entities/pet_mood.dart';
import '../../domain/entities/pet_palette.dart';
import 'mimi_painter.dart';
import 'pet_character_painters.dart';

/// Các "trò" Mimi có thể chơi theo yêu cầu từ bên ngoài (nút bấm ở màn
/// hình), khác với animation tự động theo [PetMood] - đây là hiệu ứng
/// NHẤT THỜI (một lần), không đổi trạng thái lâu dài của Mimi.
///
/// THÊM (2026-08-23): `bath` (tắm), `sleep` (đi ngủ), `exercise` (tập thể
/// dục) - 3 hành động tương tác mới ở Home, xem doc comment tương ứng trong
/// `_PetAvatarState._buildPose`/`_buildTrickDecorations`.
enum MimiTrick { spin, bonusJump, eat, bath, sleep, exercise }

/// Kênh để 1 màn hình (ví dụ HomeScreen) yêu cầu [PetAvatar] chơi 1 "trò"
/// mà không cần đổi [PetMood] - PetAvatar tự lắng nghe qua [stream].
/// Tạo 1 instance, giữ trong State của màn hình, nhớ gọi [dispose] ở
/// `State.dispose()` (giống Controller của TextField).
class PetAvatarController {
  final _tricksController = StreamController<MimiTrick>.broadcast();

  Stream<MimiTrick> get stream => _tricksController.stream;

  /// Mimi xoay 1 vòng vui vẻ.
  void spin() => _tricksController.add(MimiTrick.spin);

  /// Mimi nhảy 1 cú thật cao (khác nhún nhảy nhỏ lúc mood happy).
  void bonusJump() => _tricksController.add(MimiTrick.bonusJump);

  /// Mimi "ăn" (miệng mấp máy vài nhịp) - dùng cho nút "cho ăn".
  void eat() => _tricksController.add(MimiTrick.eat);

  /// Mimi "tắm" (lắc người kỳ cọ + nhắm mắt + vài bọt xà phòng bay lên).
  void bath() => _tricksController.add(MimiTrick.bath);

  /// Mimi "đi ngủ" (nhắm mắt, cúi đầu nghỉ, có chữ "Zzz" bay lên).
  void sleep() => _tricksController.add(MimiTrick.sleep);

  /// Mimi "tập thể dục" (nhảy nhịp vui vẻ vài cái, có tia năng lượng ✨).
  void exercise() => _tricksController.add(MimiTrick.exercise);

  void dispose() => _tricksController.close();
}

/// Hiển thị Mimi trên màn hình.
///
/// Vẽ Mimi hoàn toàn bằng vector (Canvas, xem `mimi_painter.dart`) thay vì
/// ảnh PNG tĩnh - theo đúng hướng bạn tham khảo được (vector + animation
/// theo từng bộ phận, kiểu SVG + CSS animation): luôn nét ở mọi kích thước,
/// không cần ảnh ngoài (rất nhẹ), và từng bộ phận (tai, mắt, miệng...) tự
/// "diễn" mượt hơn nhiều so với chỉ xoay/co giãn cả tấm ảnh tĩnh.
///
/// Có 2 kiểu tương tác:
/// - Chạm trực tiếp vào Mimi (qua [onTap]): PetAvatar tự nhận biết bé chạm
///   vào TAI hay vào THÂN/ĐẦU (xem [MimiTapRegion] trong `mimi_painter.dart`)
///   và phản ứng khác nhau (tai: giật/kéo dài ra; thân: "giggle" lắc lư nhẹ).
/// - Trò chơi theo nút bấm bên ngoài (qua [controller]): xoay vòng, nhảy
///   cao, ăn - không bắt buộc phải chạm trực tiếp vào Mimi.
///
/// Đây là NƠI DUY NHẤT biết Mimi được vẽ như thế nào - phần còn lại của app
/// chỉ cần biết [PetMood] hiện tại.
class PetAvatar extends StatefulWidget {
  final PetMood mood;
  final double size;

  /// Nhân vật đang hiển thị (Bunny/Mimi/Moni) - xem [PetCharacter]. Đổi
  /// nhân vật chỉ đổi hình vẽ, không đổi animation/tương tác bên dưới.
  final PetCharacter character;

  /// Màu (lông/mai) đang chọn - xem [PetPalette]. Độc lập với [character]:
  /// đổi màu không đổi nhân vật và ngược lại. Mặc định `PetPalette.classic`
  /// (màu gốc) nếu màn hình gọi chưa cần bé chọn màu.
  final PetPalette palette;

  /// Phụ kiện ĐANG MẶC ở đầu/cổ (xem `pet_accessory.dart`) - để trống (null,
  /// mặc định) nếu màn hình chưa cần hiển thị phụ kiện (giữ đúng hành vi cũ).
  final PetAccessoryId? headAccessory;
  final PetAccessoryId? neckAccessory;

  /// Gọi khi bé chạm vào thú cưng (vuốt ve/kéo tai), kèm theo vùng vừa
  /// chạm. Để trống nếu màn hình không cần tương tác này (ví dụ trong
  /// LessonScreen) - khi đó PetAvatar không gắn gesture chạm/kéo nào cả
  /// (giữ đúng hành vi cũ, không đổi bất ngờ ở màn hình khác).
  final void Function(MimiTapRegion region)? onTap;

  /// Kênh nhận yêu cầu chơi trò (xoay vòng/nhảy/ăn) từ bên ngoài. Có thể để
  /// trống nếu màn hình không cần các trò này.
  final PetAvatarController? controller;

  const PetAvatar({
    super.key,
    required this.mood,
    required this.character,
    this.palette = PetPalette.classic,
    this.headAccessory,
    this.neckAccessory,
    this.size = 220,
    this.onTap,
    this.controller,
  });

  @override
  State<PetAvatar> createState() => _PetAvatarState();
}

class _PetAvatarState extends State<PetAvatar> with TickerProviderStateMixin {
  late final AnimationController _breatheCtrl;
  late final AnimationController _blinkCtrl;
  late final AnimationController _earTwitchCtrl;
  late final AnimationController _talkCtrl;
  late final AnimationController _jumpCtrl;
  late final AnimationController _giggleCtrl;
  late final AnimationController _dragSnapCtrl;
  late final AnimationController _earPullCtrl;
  late final AnimationController _spinCtrl;
  late final AnimationController _bonusJumpCtrl;
  late final AnimationController _eatCtrl;
  late final AnimationController _bathCtrl;
  late final AnimationController _sleepCtrl;
  late final AnimationController _exerciseCtrl;

  Timer? _blinkTimer;
  Timer? _earTwitchTimer;
  StreamSubscription<MimiTrick>? _trickSub;
  final Random _random = Random();

  Offset _dragOffset = Offset.zero;
  Animation<Offset>? _dragSnapAnimation;
  MimiTapRegion? _activeEarPull;

  static final Animatable<double> _earTwitchTween = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.22), weight: 20),
    TweenSequenceItem(tween: Tween(begin: -0.22, end: 0.12), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 0.12, end: 0.0), weight: 50),
  ]);

  static final Animatable<double> _giggleTween = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.16), weight: 15),
    TweenSequenceItem(tween: Tween(begin: -0.16, end: 0.16), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 0.16, end: -0.09), weight: 25),
    TweenSequenceItem(tween: Tween(begin: -0.09, end: 0.0), weight: 35),
  ]);

  static final Animatable<double> _earPullTween = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 65),
  ]);

  @override
  void initState() {
    super.initState();
    _breatheCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _blinkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _earTwitchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _talkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _jumpCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _giggleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _dragSnapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _earPullCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _bonusJumpCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _eatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _bathCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _sleepCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _exerciseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

    _scheduleBlink();
    _scheduleEarTwitch();
    _syncMoodLoops();
    _trickSub = widget.controller?.stream.listen(_playTrick);
  }

  @override
  void didUpdateWidget(covariant PetAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _syncMoodLoops();
    }
    if (oldWidget.controller != widget.controller) {
      _trickSub?.cancel();
      _trickSub = widget.controller?.stream.listen(_playTrick);
    }
  }

  void _syncMoodLoops() {
    if (widget.mood == PetMood.talking) {
      _talkCtrl.repeat();
    } else {
      _talkCtrl.stop();
    }
    if (widget.mood == PetMood.happy) {
      _jumpCtrl.repeat();
    } else {
      _jumpCtrl.stop();
      _jumpCtrl.value = 0;
    }
  }

  bool get _canBlink => widget.mood != PetMood.happy;
  bool get _canEarTwitch => widget.mood == PetMood.idle || widget.mood == PetMood.encourage;

  void _scheduleBlink() {
    _blinkTimer?.cancel();
    final delay = Duration(milliseconds: 2800 + _random.nextInt(3000));
    _blinkTimer = Timer(delay, () {
      if (!mounted) return;
      if (_canBlink) {
        _blinkCtrl.forward(from: 0).then((_) {
          if (mounted) _blinkCtrl.reverse();
        });
      }
      _scheduleBlink();
    });
  }

  void _scheduleEarTwitch() {
    _earTwitchTimer?.cancel();
    final delay = Duration(milliseconds: 3200 + _random.nextInt(3600));
    _earTwitchTimer = Timer(delay, () {
      if (!mounted) return;
      if (_canEarTwitch) {
        _earTwitchCtrl.forward(from: 0);
      }
      _scheduleEarTwitch();
    });
  }

  void _playTrick(MimiTrick trick) {
    if (!mounted) return;
    switch (trick) {
      case MimiTrick.spin:
        _spinCtrl.forward(from: 0);
        break;
      case MimiTrick.bonusJump:
        _bonusJumpCtrl.forward(from: 0);
        break;
      case MimiTrick.eat:
        _eatCtrl.forward(from: 0);
        break;
      case MimiTrick.bath:
        _bathCtrl.forward(from: 0);
        break;
      case MimiTrick.sleep:
        _sleepCtrl.forward(from: 0);
        break;
      case MimiTrick.exercise:
        _exerciseCtrl.forward(from: 0);
        break;
    }
  }

  void _handleTapUp(TapUpDetails details) {
    final inset = widget.size * 0.1;
    final canvasSize = Size(widget.size - inset * 2, widget.size - inset * 2);
    final localInCanvas = details.localPosition - Offset(inset, inset);
    final region = hitTestPetCharacter(widget.character, localInCanvas, canvasSize);

    if (region == MimiTapRegion.earLeft || region == MimiTapRegion.earRight) {
      _activeEarPull = region;
      _earPullCtrl.forward(from: 0);
    } else {
      _giggleCtrl.forward(from: 0);
    }
    widget.onTap?.call(region);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _dragSnapCtrl.stop();
    final maxOffset = widget.size * 0.18;
    setState(() {
      final next = _dragOffset + details.delta * 0.35;
      _dragOffset = Offset(
        min(max(next.dx, -maxOffset), maxOffset),
        min(max(next.dy, -maxOffset), maxOffset),
      );
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    final tween = Tween<Offset>(begin: _dragOffset, end: Offset.zero);
    _dragSnapAnimation = tween.animate(CurvedAnimation(parent: _dragSnapCtrl, curve: Curves.elasticOut));
    _dragSnapCtrl
      ..removeListener(_onDragSnapTick)
      ..addListener(_onDragSnapTick)
      ..forward(from: 0);
  }

  void _onDragSnapTick() {
    if (!mounted || _dragSnapAnimation == null) return;
    setState(() => _dragOffset = _dragSnapAnimation!.value);
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _earTwitchTimer?.cancel();
    _trickSub?.cancel();
    _breatheCtrl.dispose();
    _blinkCtrl.dispose();
    _earTwitchCtrl.dispose();
    _talkCtrl.dispose();
    _jumpCtrl.dispose();
    _giggleCtrl.dispose();
    _dragSnapCtrl.dispose();
    _earPullCtrl.dispose();
    _spinCtrl.dispose();
    _bonusJumpCtrl.dispose();
    _eatCtrl.dispose();
    _bathCtrl.dispose();
    _sleepCtrl.dispose();
    _exerciseCtrl.dispose();
    super.dispose();
  }

  Color _haloFor(PetMood mood) {
    switch (mood) {
      case PetMood.idle:
        return const Color(0xFFE9D8FF);
      case PetMood.listening:
        return const Color(0xFFB2F2E5);
      case PetMood.thinking:
        return const Color(0xFFFFE8B3);
      case PetMood.talking:
        return const Color(0xFFCDE7FF);
      case PetMood.happy:
        return const Color(0xFFFFD6E8);
      case PetMood.encourage:
        return const Color(0xFFE9D8FF);
    }
  }

  MimiPose _buildPose() {
    final breathe = _breatheCtrl.value;
    double bodyScaleY = 1.0 + breathe * 0.02;
    double headOffsetY = -breathe * 4;
    double headTilt = 0;
    double earL = _earTwitchTween.evaluate(_earTwitchCtrl);
    double earR = -_earTwitchTween.evaluate(_earTwitchCtrl) * 0.6;
    double earScaleL = 1.0;
    double earScaleR = 1.0;
    bool happyEyes = false;
    MimiMouth mouth = MimiMouth.idle;
    double mouthOpen = 0.3;

    switch (widget.mood) {
      case PetMood.idle:
        break;
      case PetMood.encourage:
        headTilt = 0.05;
        break;
      case PetMood.listening:
        headTilt = 0.12;
        earL -= 0.2;
        earR += 0.2;
        earScaleL = 1.08;
        earScaleR = 1.08;
        mouth = MimiMouth.talk;
        mouthOpen = 0.35;
        break;
      case PetMood.thinking:
        headTilt = -0.15;
        earL += 0.1;
        break;
      case PetMood.talking:
        final t = _talkCtrl.value;
        headOffsetY += sin(t * pi * 2) * 3;
        headTilt += sin(t * pi * 2) * 0.05;
        earL += sin(t * pi * 2 * 0.9) * 0.14;
        earR -= sin(t * pi * 2 * 1.15) * 0.14;
        mouth = MimiMouth.talk;
        mouthOpen = 0.25 + sin(t * pi * 6).abs() * 0.85;
        break;
      case PetMood.happy:
        happyEyes = true;
        mouth = MimiMouth.happy;
        earL = -0.32;
        earR = 0.32;
        final bounce = min(max(sin(_jumpCtrl.value * pi), 0.0), 1.0);
        headOffsetY -= bounce * 10;
        bodyScaleY = 1.0 - bounce * 0.06;
        break;
    }

    // Kéo tai (nhất thời, đè lên animation theo mood) - chỉ ảnh hưởng đúng
    // bên tai vừa bị bé chạm vào.
    final pull = _earPullTween.evaluate(_earPullCtrl);
    if (pull > 0 && _activeEarPull == MimiTapRegion.earLeft) {
      earL += pull * 0.55;
      earScaleL += pull * 0.45;
    } else if (pull > 0 && _activeEarPull == MimiTapRegion.earRight) {
      earR -= pull * 0.55;
      earScaleR += pull * 0.45;
    }

    // "Ăn" (nhất thời, đè lên miệng theo mood) - vài nhịp mấp máy rồi tự
    // khép lại, kèm cúi đầu nhẹ xuống như đang ăn.
    final eatT = _eatCtrl.value;
    if (eatT > 0 && eatT < 1) {
      mouth = MimiMouth.talk;
      mouthOpen = 0.2 + sin(eatT * pi * 3).abs() * 0.9;
      headTilt -= 0.1 * sin(eatT * pi);
      headOffsetY += 4 * sin(eatT * pi);
    }

    // Dùng để ép mắt NHẮM TỊT trong lúc tắm/ngủ, bất kể mood hiện tại đang
    // "happy" (nếu không ép `happyEyes = false`, painter sẽ vẽ mắt cười cong
    // thay vì oval nhắm - xem `BunnyPainter`/`MimiCatPainter`: chỉ oval mới
    // đọc `eyeScaleY`, đường cong "happy" luôn vẽ cố định).
    double? forcedEyeScaleY;

    // "Tắm" (nhất thời) - lắc đầu/tai qua lại như đang được kỳ cọ, nhắm mắt
    // khoan khoái. Bọt xà phòng bay lên vẽ RIÊNG ở [_buildTrickDecorations],
    // không phải trong [MimiPose] (bọt không thuộc về hình nhân vật).
    final bathT = _bathCtrl.value;
    if (bathT > 0 && bathT < 1) {
      headTilt += sin(bathT * pi * 7) * 0.16;
      earL += sin(bathT * pi * 7) * 0.2;
      earR -= sin(bathT * pi * 7) * 0.2;
      bodyScaleY = 1.0 - sin(bathT * pi).abs() * 0.05;
      happyEyes = false;
      forcedEyeScaleY = 0.15;
    }

    // "Đi ngủ" (nhất thời) - nhắm mắt hẳn, đầu cúi nghiêng nghỉ ngơi. Chữ
    // "Zzz" bay lên vẽ RIÊNG ở [_buildTrickDecorations].
    final sleepT = _sleepCtrl.value;
    if (sleepT > 0 && sleepT < 1) {
      headTilt = 0.28;
      headOffsetY += 6;
      happyEyes = false;
      forcedEyeScaleY = 0.05;
      mouth = MimiMouth.idle;
    }

    // "Tập thể dục" (nhất thời) - nhảy nhịp nhanh vài cái, vui vẻ. Tia năng
    // lượng ✨ vẽ RIÊNG ở [_buildTrickDecorations].
    final exerciseT = _exerciseCtrl.value;
    if (exerciseT > 0 && exerciseT < 1) {
      final bounce = sin(exerciseT * pi * 3).abs();
      headOffsetY -= bounce * 14;
      bodyScaleY = 1.0 - bounce * 0.05;
      earL += sin(exerciseT * pi * 8) * 0.25;
      earR -= sin(exerciseT * pi * 8) * 0.25;
      happyEyes = true;
      mouth = MimiMouth.happy;
    }

    final eyeScaleY =
        forcedEyeScaleY ?? (happyEyes ? 1.0 : min(max(1.0 - _blinkCtrl.value * 0.92, 0.06), 1.0));

    return MimiPose(
      bodyScaleY: bodyScaleY,
      headOffsetY: headOffsetY,
      headTilt: headTilt,
      earLeftAngle: earL,
      earRightAngle: earR,
      earLeftScaleY: earScaleL,
      earRightScaleY: earScaleR,
      eyeScaleY: eyeScaleY,
      showHappyEyes: happyEyes,
      mouth: mouth,
      mouthOpen: mouthOpen,
    );
  }

  /// Trang trí NHẤT THỜI đè lên avatar trong lúc chơi trò tắm/ngủ/tập thể
  /// dục (bọt xà phòng 🫧, "Zzz" 💤, tia năng lượng ✨) - vẽ bằng Widget
  /// thường (Positioned + Text) thay vì trong `CustomPainter` vì đây là hiệu
  /// ứng phụ, KHÔNG thuộc về hình vẽ nhân vật (không cần scale/toạ độ tuyệt
  /// đối theo `petCharacterReferenceSize` như phụ kiện).
  List<Widget> _buildTrickDecorations() {
    final decorations = <Widget>[];

    final bathT = _bathCtrl.value;
    if (bathT > 0 && bathT < 1) {
      for (var i = 0; i < 3; i++) {
        final delay = i * 0.18;
        final t = ((bathT - delay) / (1 - delay)).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final rise = t * widget.size * 0.5;
        final sway = sin(t * pi * 3 + i) * 8;
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        decorations.add(Positioned(
          left: widget.size * (0.28 + i * 0.2) + sway,
          bottom: widget.size * 0.15 + rise,
          child: Opacity(
            opacity: opacity,
            child: const Text('🫧', style: TextStyle(fontSize: 18)),
          ),
        ));
      }
    }

    final sleepT = _sleepCtrl.value;
    if (sleepT > 0 && sleepT < 1) {
      final rise = sleepT * widget.size * 0.35;
      final fadeOutStart = 0.15;
      final opacity = sleepT < fadeOutStart
          ? sleepT / fadeOutStart
          : (1.0 - (sleepT - fadeOutStart) / (1 - fadeOutStart)).clamp(0.0, 1.0);
      decorations.add(Positioned(
        right: widget.size * 0.06,
        top: widget.size * 0.05 - rise,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: const Text('💤', style: TextStyle(fontSize: 26)),
        ),
      ));
    }

    final exerciseT = _exerciseCtrl.value;
    if (exerciseT > 0 && exerciseT < 1) {
      final bounce = sin(exerciseT * pi * 3).abs();
      if (bounce > 0.6) {
        decorations.add(Positioned(
          top: widget.size * 0.02,
          left: widget.size * 0.06,
          child: Opacity(opacity: bounce, child: const Text('✨', style: TextStyle(fontSize: 20))),
        ));
        decorations.add(Positioned(
          top: widget.size * 0.02,
          right: widget.size * 0.06,
          child: Opacity(opacity: bounce, child: const Text('✨', style: TextStyle(fontSize: 20))),
        ));
      }
    }

    return decorations;
  }

  @override
  Widget build(BuildContext context) {
    final listenable = Listenable.merge([
      _breatheCtrl,
      _blinkCtrl,
      _earTwitchCtrl,
      _talkCtrl,
      _jumpCtrl,
      _giggleCtrl,
      _earPullCtrl,
      _spinCtrl,
      _bonusJumpCtrl,
      _eatCtrl,
      _bathCtrl,
      _sleepCtrl,
      _exerciseCtrl,
    ]);

    final avatar = AnimatedBuilder(
      animation: listenable,
      builder: (context, child) {
        double lift = 0;
        if (widget.mood == PetMood.happy) {
          final bounce = min(max(sin(_jumpCtrl.value * pi), 0.0), 1.0);
          lift -= bounce * 26;
        }
        // Nhảy chơi (bonus) - 1 cú nhảy cao rồi rơi xuống, tự về 0 khi xong.
        final bonusBounce = min(max(sin(_bonusJumpCtrl.value * pi), 0.0), 1.0);
        lift -= bonusBounce * 40;

        final giggleRotate = _giggleTween.evaluate(_giggleCtrl);
        final spinRotate = _spinCtrl.value * 2 * pi;

        return Transform.translate(
          offset: Offset(_dragOffset.dx, _dragOffset.dy + lift),
          child: Transform.rotate(
            angle: giggleRotate + spinRotate,
            child: TweenAnimationBuilder<double>(
              key: ValueKey((
                widget.mood,
                widget.character,
                widget.palette,
                widget.headAccessory,
                widget.neckAccessory,
              )),
              tween: Tween(begin: 0.86, end: 1.0),
              duration: const Duration(milliseconds: 350),
              curve: Curves.elasticOut,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: _haloFor(widget.mood),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(widget.size * 0.1),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox.expand(
                        child: CustomPaint(
                          painter: PetCharacterPainter(
                            character: widget.character,
                            palette: widget.palette,
                            pose: _buildPose(),
                            headAccessory: widget.headAccessory,
                            neckAccessory: widget.neckAccessory,
                          ),
                        ),
                      ),
                      ..._buildTrickDecorations(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (widget.onTap == null) return avatar;

    return GestureDetector(
      onTapUp: _handleTapUp,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      behavior: HitTestBehavior.opaque,
      child: avatar,
    );
  }
}

// Ghi chú: bạn tham khảo Gemini gửi 1 file HTML hoàn chỉnh (SVG + CSS
// animation + Web Audio API) - đây là code chạy trong TRÌNH DUYỆT, không
// thể "dùng trực tiếp cho ứng dụng Web" của Flutter (Flutter Web build ra
// Canvas/JS riêng, không nhúng thẳng HTML/CSS đó vào được) và cũng không tự
// "chuyển đổi dễ dàng" sang Flutter như tư vấn - phải viết lại bằng công cụ
// vẽ của Flutter (CustomPainter) như trên. Những phần Ý TƯỞNG đã áp dụng
// lại đúng tinh thần: vẽ theo từng bộ phận, animate độc lập (chớp mắt, vẫy
// tai, nhún nhảy khi vui, "giggle" khi chạm), kéo-thả có độ nảy đàn hồi,
// VÀ (bổ sung lần này) kéo TAI riêng biệt + trò xoay vòng/nhảy cao/cho ăn
// theo nút bấm - giống tinh thần "pull ears", "somersault/spin" trong demo
// gốc, dịch lại bằng CustomPainter + AnimationController.
//
// Những phần vẫn CHƯA làm theo (có chủ đích, không phải thiếu sót):
// - Nhào lộn 360° kiểu lộn ngược đầu (khác xoay tại chỗ đang có): cần thêm
//   phối cảnh 3D phức tạp hơn (rotateX kiểu SVG `spin360`) - để dành nếu
//   bạn thực sự muốn, tăng thêm rủi ro lỗi không nhỏ so với lợi ích.
// - Âm thanh kiểu "Boing/Giggle" tổng hợp bằng Web Audio API: chưa thêm vì
//   sẽ cần thêm 1 package âm thanh mới (rủi ro lỗi build Android như package
//   speech_to_text từng gặp) - đã dùng haptic rung nhẹ thay thế. Có thể làm
//   riêng 1 lần sau nếu bạn muốn, sau khi kiểm tra kỹ package trước.
// - Khung hội thoại chọn câu trả lời có sẵn (giống demo web): KHÔNG áp dụng
//   vì đây là bước LÙI so với app hiện tại - Play/Lesson đã cho bé trả lời
//   bằng GIỌNG NÓI THẬT (speech_to_text) thay vì bấm chọn nút có sẵn.
