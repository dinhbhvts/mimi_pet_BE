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
///
/// THÊM (2026-09-27): các phản ứng khi bé TRÊU - giggle (lắc cười), sneeze
/// (hắt xì khi chạm mũi), bellyLaugh (cười lăn khi chạm bụng), footWiggle
/// (giãy chân), dizzy (chóng mặt khi bị kéo mạnh), grumpy (giả vờ dỗi khi bị
/// trêu dồn dập), yawn (ngáp), disgust (nhăn mặt với món ghét), fire (ăn ớt
/// phun lửa), love (ăn món thích, tim bay), hide (rùa rụt đầu vào mai).
enum MimiTrick {
  spin,
  bonusJump,
  eat,
  bath,
  sleep,
  exercise,
  giggle,
  sneeze,
  bellyLaugh,
  footWiggle,
  dizzy,
  grumpy,
  yawn,
  disgust,
  fire,
  love,
  hide,
}

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

  void play(MimiTrick trick) => _tricksController.add(trick);

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

  /// Bé chạm 2 lần liên tiếp (nhanh) vào thú cưng - phản ứng "giật mình cười
  /// phá lên", MẠNH hơn hẳn 1 lần chạm thường (xem [_handleDoubleTap]). Để
  /// trống nếu màn hình không cần (giữ nguyên hành vi 1-chạm cũ).
  final VoidCallback? onDoubleTap;

  /// Bé GIỮ TAY (nhấn giữ) trên thú cưng - vào/ra 1 trạng thái "đang bị
  /// trêu/cù" LIÊN TỤC cho tới khi thả tay, khác hẳn các "trò" một lần
  /// ([PetAvatarController]) hay chạm rời rạc ([onTap]) - đúng kiểu bé thích
  /// "trêu" thú cưng thật sự (giữ càng lâu, thú cưng càng cười to hơn). Màn
  /// hình gọi nên bắt đầu 1 chu kỳ đọc câu trêu/rung nhẹ lặp lại trong
  /// [onTickleStart], dừng lại trong [onTickleEnd].
  final VoidCallback? onTickleStart;
  final VoidCallback? onTickleEnd;

  /// Kênh nhận yêu cầu chơi trò (xoay vòng/nhảy/ăn) từ bên ngoài. Có thể để
  /// trống nếu màn hình không cần các trò này.
  final PetAvatarController? controller;

  /// Thú cưng đang NGỦ (kéo dài tới khi màn hình gọi đánh thức) - nhắm mắt,
  /// cụp tai, 💤 bay lên liên tục.
  final bool sleeping;

  /// Bé thả tay sau khi KÉO thú cưng - [intensity] = tổng quãng đường kéo
  /// chia cho kích thước avatar (kéo qua lại càng nhiều càng lớn).
  final void Function(double intensity)? onDragEnd;

  const PetAvatar({
    super.key,
    required this.mood,
    required this.character,
    this.palette = PetPalette.classic,
    this.headAccessory,
    this.neckAccessory,
    this.size = 220,
    this.onTap,
    this.onDoubleTap,
    this.onTickleStart,
    this.onTickleEnd,
    this.controller,
    this.sleeping = false,
    this.onDragEnd,
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
  late final AnimationController _tickleCtrl;
  late final AnimationController _sneezeCtrl;
  late final AnimationController _laughCtrl;
  late final AnimationController _wiggleCtrl;
  late final AnimationController _dizzyCtrl;
  late final AnimationController _grumpyCtrl;
  late final AnimationController _yawnCtrl;
  late final AnimationController _disgustCtrl;
  late final AnimationController _fireCtrl;
  late final AnimationController _loveCtrl;
  late final AnimationController _hideCtrl;

  /// Chạy lặp khi [PetAvatar.sleeping] để 💤 bay lên liên tục.
  late final AnimationController _sleepLoopCtrl;

  /// Tự nhận biết chạm 2 lần bằng mốc thời gian thay vì `onDoubleTap` của
  /// GestureDetector - `onDoubleTap` bắt MỌI lần chạm đơn phải chờ ~300ms xem
  /// có chạm lần 2 không, làm thú cưng phản ứng chậm.
  DateTime? _lastTapAt;
  static const _doubleTapWindow = Duration(milliseconds: 320);

  double _panDistance = 0;

  Timer? _blinkTimer;
  Timer? _earTwitchTimer;
  StreamSubscription<MimiTrick>? _trickSub;
  final Random _random = Random();

  Offset _dragOffset = Offset.zero;
  Animation<Offset>? _dragSnapAnimation;
  MimiTapRegion? _activeEarPull;

  /// true trong khoảng thời gian bé đang GIỮ TAY trêu (xem
  /// [_handleLongPressStart]/[_handleLongPressEnd]) - dáng "cù lét" ở
  /// [_buildPose] chỉ áp dụng khi cờ này bật, độc lập với việc
  /// `_tickleCtrl.isAnimating` (animation có thể còn đang chạy nốt vòng lặp
  /// dở dang ngay lúc thả tay).
  bool _isTickling = false;

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
    _tickleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _sneezeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
    _laughCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _wiggleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _dizzyCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _grumpyCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _yawnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));
    _disgustCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
    _fireCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _loveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _hideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _sleepLoopCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    if (widget.sleeping) _sleepLoopCtrl.repeat();

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
    if (oldWidget.sleeping != widget.sleeping) {
      if (widget.sleeping) {
        _sleepLoopCtrl.repeat();
      } else {
        _sleepLoopCtrl
          ..stop()
          ..value = 0;
      }
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

  bool get _canBlink => widget.mood != PetMood.happy && !widget.sleeping;
  bool get _canEarTwitch =>
      !widget.sleeping && (widget.mood == PetMood.idle || widget.mood == PetMood.encourage);

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
      case MimiTrick.giggle:
        _giggleCtrl.forward(from: 0);
      case MimiTrick.sneeze:
        _sneezeCtrl.forward(from: 0);
      case MimiTrick.bellyLaugh:
        _laughCtrl.forward(from: 0);
      case MimiTrick.footWiggle:
        _wiggleCtrl.forward(from: 0);
      case MimiTrick.dizzy:
        _dizzyCtrl.forward(from: 0);
      case MimiTrick.grumpy:
        _grumpyCtrl.forward(from: 0);
      case MimiTrick.yawn:
        _yawnCtrl.forward(from: 0);
      case MimiTrick.disgust:
        _disgustCtrl.forward(from: 0);
      case MimiTrick.fire:
        _fireCtrl.forward(from: 0);
      case MimiTrick.love:
        _loveCtrl.forward(from: 0);
      case MimiTrick.hide:
        _hideCtrl.forward(from: 0);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    final now = DateTime.now();
    final last = _lastTapAt;
    if (widget.onDoubleTap != null && last != null && now.difference(last) < _doubleTapWindow) {
      _lastTapAt = null;
      widget.onDoubleTap!();
      return;
    }
    _lastTapAt = now;

    final inset = widget.size * 0.1;
    final canvasSize = Size(widget.size - inset * 2, widget.size - inset * 2);
    final localInCanvas = details.localPosition - Offset(inset, inset);
    final region = hitTestPetCharacter(widget.character, localInCanvas, canvasSize);

    // Phản hồi hình ảnh TỨC THÌ cho tai/thân; các vùng khác (mũi/bụng/chân)
    // do màn hình quyết định trò qua [PetAvatarController] vì còn phụ thuộc
    // mức bị trêu (dỗi, cười lăn...). Đang ngủ thì để màn hình xử lý hết.
    if (!widget.sleeping) {
      if (region == MimiTapRegion.earLeft || region == MimiTapRegion.earRight) {
        _activeEarPull = region;
        _earPullCtrl.forward(from: 0);
      } else if (region == MimiTapRegion.body) {
        _giggleCtrl.forward(from: 0);
      }
    }
    widget.onTap?.call(region);
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    setState(() => _isTickling = true);
    _tickleCtrl.repeat(reverse: true);
    widget.onTickleStart?.call();
  }

  void _handleLongPressEnd(LongPressEndDetails details) => _endTickle();

  /// Phòng trường hợp cử chỉ giữ tay bị HUỶ NGANG (ví dụ tay trượt ra ngoài
  /// vùng thú cưng, hệ thống cướp gesture...) - Flutter gọi `onLongPressCancel`
  /// thay vì `onLongPressEnd` trong các trường hợp này, KHÔNG dọn dẹp ở đây
  /// sẽ khiến `_isTickling`/`_tickleCtrl` kẹt mãi ở trạng thái "đang trêu".
  void _handleLongPressCancel() => _endTickle();

  void _endTickle() {
    if (!mounted || !_isTickling) return;
    setState(() => _isTickling = false);
    _tickleCtrl.stop();
    widget.onTickleEnd?.call();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _dragSnapCtrl.stop();
    _panDistance += details.delta.distance;
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
    final intensity = _panDistance / widget.size;
    _panDistance = 0;
    widget.onDragEnd?.call(intensity);
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
    _tickleCtrl.dispose();
    _sneezeCtrl.dispose();
    _laughCtrl.dispose();
    _wiggleCtrl.dispose();
    _dizzyCtrl.dispose();
    _grumpyCtrl.dispose();
    _yawnCtrl.dispose();
    _disgustCtrl.dispose();
    _fireCtrl.dispose();
    _loveCtrl.dispose();
    _hideCtrl.dispose();
    _sleepLoopCtrl.dispose();
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

  /// Giá trị (0..1) của 1 trò đang chạy dở, null nếu trò không chạy.
  double? _running(AnimationController ctrl) {
    final v = ctrl.value;
    return (v > 0 && v < 1) ? v : null;
  }

  /// 0 -> 1 nhanh ở đầu, giữ 1, rồi về 0 ở cuối - cho các trạng thái "giữ"
  /// một lúc (dỗi, rụt đầu).
  double _envelope(double t) {
    if (t < 0.15) return t / 0.15;
    if (t > 0.85) return (1 - t) / 0.15;
    return 1;
  }

  /// Rung lắc/nhảy CẢ NGƯỜI do các trò trêu gây ra: (dịch ngang, dịch dọc, xoay).
  (double, double, double) _trickMotion() {
    var dx = 0.0, dy = 0.0, rot = 0.0;
    final sneezeT = _running(_sneezeCtrl);
    if (sneezeT != null && sneezeT >= 0.62) {
      final u = (sneezeT - 0.62) / 0.38;
      rot += sin(u * pi) * 0.18;
      dy += sin(u * pi) * 6;
    }
    final laughT = _running(_laughCtrl);
    if (laughT != null) {
      rot += sin(laughT * pi * 10) * 0.12 * (1 - laughT);
      dy -= sin(laughT * pi * 5).abs() * 10 * (1 - laughT);
    }
    final wiggleT = _running(_wiggleCtrl);
    if (wiggleT != null) {
      dx += sin(wiggleT * pi * 8) * 12 * (1 - wiggleT);
      dy -= sin(wiggleT * pi * 4).abs() * 12 * (1 - wiggleT);
    }
    final dizzyT = _running(_dizzyCtrl);
    if (dizzyT != null) {
      rot += sin(dizzyT * pi * 6) * 0.18 * (1 - dizzyT * 0.5);
      dx += sin(dizzyT * pi * 3) * 8;
    }
    final grumpyT = _running(_grumpyCtrl);
    if (grumpyT != null && grumpyT < 0.3) {
      dx += sin(grumpyT * pi * 20) * 4;
    }
    final yawnT = _running(_yawnCtrl);
    if (yawnT != null) {
      dy -= sin(yawnT * pi) * 4;
    }
    final disgustT = _running(_disgustCtrl);
    if (disgustT != null) {
      dx += sin(disgustT * pi * 10) * 6 * (1 - disgustT);
    }
    final fireT = _running(_fireCtrl);
    if (fireT != null) {
      dy -= sin(fireT * pi * 6).abs() * 14 * (1 - fireT);
    }
    return (dx, dy, rot);
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

    // Dùng để ép mắt nhắm/híp bất kể mood (xem ghi chú ở phần "Tắm" bên dưới).
    double? forcedEyeScaleY;

    // Đang NGỦ (kéo dài): nhắm mắt, cụp tai, đầu cúi - các trò phía dưới vẫn
    // đè lên được (ví dụ bị đánh thức).
    if (widget.sleeping) {
      happyEyes = false;
      forcedEyeScaleY = 0.05;
      mouth = MimiMouth.idle;
      headOffsetY += 6;
      earL += 0.25;
      earR -= 0.25;
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

    // Ép mắt NHẮM TỊT trong lúc tắm/ngủ, bất kể mood hiện tại đang "happy"
    // (nếu không ép `happyEyes = false`, painter sẽ vẽ mắt cười cong thay vì
    // oval nhắm - chỉ oval mới đọc `eyeScaleY`).

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

    // ---- Phản ứng khi bị trêu (nhất thời) ----
    final sneezeT = _running(_sneezeCtrl);
    if (sneezeT != null) {
      happyEyes = false;
      mouth = MimiMouth.talk;
      if (sneezeT < 0.62) {
        // Lấy đà: híp mắt, há miệng dần, ngửa đầu.
        final build = sneezeT / 0.62;
        forcedEyeScaleY = 1 - build * 0.8;
        mouthOpen = 0.3 + build * 0.6;
        headOffsetY -= build * 6;
        earL -= build * 0.2;
        earR += build * 0.2;
      } else {
        final u = (sneezeT - 0.62) / 0.38;
        forcedEyeScaleY = 0.08;
        mouthOpen = 1 - u * 0.7;
      }
    }

    final laughT = _running(_laughCtrl);
    if (laughT != null) {
      happyEyes = true;
      mouth = MimiMouth.talk;
      mouthOpen = 0.6 + sin(laughT * pi * 8).abs() * 0.4;
      earL = -0.3 + sin(laughT * pi * 8) * 0.25;
      earR = 0.3 - sin(laughT * pi * 8) * 0.25;
    }

    final wiggleT = _running(_wiggleCtrl);
    if (wiggleT != null) {
      happyEyes = true;
      mouth = MimiMouth.happy;
      earL += sin(wiggleT * pi * 8) * 0.2;
      earR -= sin(wiggleT * pi * 8) * 0.2;
    }

    final dizzyT = _running(_dizzyCtrl);
    if (dizzyT != null) {
      happyEyes = false;
      forcedEyeScaleY = 0.4;
      mouth = MimiMouth.talk;
      mouthOpen = 0.35;
      earL += 0.3;
      earR -= 0.3;
    }

    final grumpyT = _running(_grumpyCtrl);
    if (grumpyT != null) {
      final env = _envelope(grumpyT);
      happyEyes = false;
      forcedEyeScaleY = 1 - env * 0.55;
      mouth = MimiMouth.idle;
      earL += 0.45 * env;
      earR -= 0.45 * env;
    }

    final yawnT = _running(_yawnCtrl);
    if (yawnT != null) {
      final open = sin(yawnT * pi);
      happyEyes = false;
      forcedEyeScaleY = 1 - open * 0.9;
      mouth = MimiMouth.talk;
      mouthOpen = 0.2 + open * 0.8;
      earL += open * 0.15;
      earR -= open * 0.15;
    }

    final disgustT = _running(_disgustCtrl);
    if (disgustT != null) {
      happyEyes = false;
      forcedEyeScaleY = 0.35;
      mouth = MimiMouth.idle;
    }

    final fireT = _running(_fireCtrl);
    if (fireT != null) {
      happyEyes = false;
      forcedEyeScaleY = 0.15;
      mouth = MimiMouth.talk;
      mouthOpen = 1.0;
    }

    final loveT = _running(_loveCtrl);
    if (loveT != null) {
      happyEyes = true;
      if (loveT < 0.5) {
        mouth = MimiMouth.talk;
        mouthOpen = 0.2 + sin(loveT * pi * 6).abs() * 0.8;
      } else {
        mouth = MimiMouth.happy;
      }
    }

    // Rùa rụt đầu vào mai (painter rùa đọc headOffsetY; các con khác chỉ nhắm mắt).
    final hideT = _running(_hideCtrl);
    if (hideT != null) {
      headOffsetY += 22 * _envelope(hideT);
      happyEyes = false;
      forcedEyeScaleY = 0.05;
    }

    // "Bị trêu/cù" (LIÊN TỤC trong lúc bé giữ tay, xem [_handleLongPressStart])
    // - đè lên MỌI animation theo mood khác (kể cả "happy") vì đây là phản ứng
    // MẠNH NHẤT, rõ ràng nhất cho bé thấy thú cưng "chịu không nổi" khi bị
    // trêu - tai/đầu rung nhanh theo nhịp `_tickleCtrl` (0->1->0 lặp lại liên
    // tục), khác hẳn kiểu "giggle" 1 lần khi chạm thường.
    if (_isTickling) {
      final t = _tickleCtrl.value;
      happyEyes = true;
      mouth = MimiMouth.happy;
      earL = -0.32 + sin(t * pi * 2) * 0.28;
      earR = 0.32 - sin(t * pi * 2) * 0.28;
      headTilt += sin(t * pi * 4) * 0.14;
      bodyScaleY = 1.0 - t * 0.07;
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

    decorations.addAll(_buildTeaseDecorations());
    return decorations;
  }

  Widget _emoji(String emoji, {required double left, required double top, double size = 22, double opacity = 1}) {
    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Text(emoji, style: TextStyle(fontSize: size)),
        ),
      ),
    );
  }

  /// Hiệu ứng emoji cho các phản ứng khi bị trêu - toạ độ tính trong khung
  /// vẽ bên trong (kích thước `size * 0.8`, xem Padding ở [build]).
  List<Widget> _buildTeaseDecorations() {
    final inner = widget.size * 0.8;
    final nose = petNoseAnchor(widget.character);
    final noseX = nose.dx * inner;
    final noseY = nose.dy * inner;
    final out = <Widget>[];

    if (widget.sleeping) {
      for (var i = 0; i < 2; i++) {
        final t = (_sleepLoopCtrl.value + i * 0.5) % 1.0;
        out.add(_emoji('💤',
            left: inner * 0.72 + sin(t * pi * 2) * 6,
            top: inner * 0.15 - t * inner * 0.3,
            size: 16 + t * 8,
            opacity: t < 0.2 ? t / 0.2 : 1 - (t - 0.2) / 0.8));
      }
    }

    final sneezeT = _running(_sneezeCtrl);
    if (sneezeT != null && sneezeT >= 0.62) {
      final u = (sneezeT - 0.62) / 0.38;
      out.add(_emoji('💦', left: noseX - 34 - u * 26, top: noseY - 6 + u * 10, size: 18, opacity: 1 - u));
      out.add(_emoji('💦', left: noseX + 14 + u * 26, top: noseY - 6 + u * 10, size: 18, opacity: 1 - u));
    }

    final laughT = _running(_laughCtrl);
    if (laughT != null) {
      out.add(_emoji('😂', left: inner * 0.02, top: inner * 0.25 - laughT * inner * 0.2, size: 20, opacity: 1 - laughT));
      out.add(_emoji('😂', left: inner * 0.82, top: inner * 0.3 - laughT * inner * 0.2, size: 20, opacity: 1 - laughT));
    }

    final dizzyT = _running(_dizzyCtrl);
    if (dizzyT != null) {
      for (var i = 0; i < 2; i++) {
        final a = dizzyT * pi * 6 + i * pi;
        out.add(_emoji('💫',
            left: inner * 0.44 + cos(a) * inner * 0.28, top: inner * 0.06 + sin(a) * inner * 0.06, size: 20));
      }
    }

    final grumpyT = _running(_grumpyCtrl);
    if (grumpyT != null) {
      out.add(_emoji('💢',
          left: inner * 0.74, top: inner * 0.08, size: 20 + sin(grumpyT * pi * 4).abs() * 6, opacity: _envelope(grumpyT)));
    }

    final disgustT = _running(_disgustCtrl);
    if (disgustT != null) {
      out.add(_emoji('🤢', left: inner * 0.76, top: inner * 0.08, size: 22, opacity: _envelope(disgustT)));
    }

    final fireT = _running(_fireCtrl);
    if (fireT != null) {
      // 2 luồng lửa phụt ngang ra 2 bên miệng (không đè lên người), to dần
      // rồi tắt - kích thước theo khung vẽ để avatar nhỏ cũng không bị che.
      final fireSize = inner * (0.1 + sin(fireT * pi) * 0.08);
      for (final side in const [-1.0, 1.0]) {
        final dx = side * (inner * 0.1 + fireT * inner * 0.2);
        out.add(_emoji('🔥',
            left: noseX + dx - fireSize / 2,
            top: noseY - fireSize * 0.4,
            size: fireSize,
            opacity: 1 - fireT * 0.6));
      }
      if (fireT > 0.6) {
        out.add(_emoji('💧', left: inner * 0.78, top: inner * 0.1, size: 18, opacity: (fireT - 0.6) / 0.4));
      }
    }

    final loveT = _running(_loveCtrl);
    if (loveT != null) {
      for (var i = 0; i < 3; i++) {
        final t = ((loveT - i * 0.15) / 0.7).clamp(0.0, 1.0);
        if (t <= 0) continue;
        out.add(_emoji('❤️',
            left: inner * (0.2 + i * 0.28) + sin(t * pi * 2 + i) * 6,
            top: inner * 0.2 - t * inner * 0.3,
            size: 18,
            opacity: 1 - t));
      }
    }
    return out;
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
      _tickleCtrl,
      _sneezeCtrl,
      _laughCtrl,
      _wiggleCtrl,
      _dizzyCtrl,
      _grumpyCtrl,
      _yawnCtrl,
      _disgustCtrl,
      _fireCtrl,
      _loveCtrl,
      _hideCtrl,
      _sleepLoopCtrl,
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
        final (motionX, motionY, motionRotate) = _trickMotion();

        return Transform.translate(
          offset: Offset(_dragOffset.dx + motionX, _dragOffset.dy + lift + motionY),
          child: Transform.rotate(
            angle: giggleRotate + spinRotate + motionRotate,
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
      onLongPressStart: _handleLongPressStart,
      onLongPressEnd: _handleLongPressEnd,
      onLongPressCancel: _handleLongPressCancel,
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
