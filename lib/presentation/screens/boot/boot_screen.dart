import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/boot_content.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/toeic_vocab.dart';
import '../../../domain/entities/pet_character.dart';
import '../../../domain/entities/pet_mood.dart';
import '../../../services/tts_service.dart';
import '../../widgets/pet_avatar.dart';

/// Màn chờ hiện NGAY LẬP TỨC (trước khi biết kết quả API) trong lúc chờ
/// [future] hoàn tất - dùng cho những chỗ CHẮC CHẮN gọi mạng ngay lúc mở app
/// (tải tiến độ của bé lần đầu, đăng nhập) nên dễ đụng lúc backend Render
/// (gói Free) đang "ngủ", cần 30 giây tới vài phút để thức dậy trước khi trả
/// lời được - xem `core/boot_content.dart`.
///
/// Nguyên tắc (tham khảo từ app khác, ManHinhCho.md 2026-09-17, áp dụng
/// chung cho cả web lẫn Flutter vì 2 bản DÙNG CHUNG 1 bộ code Dart - không
/// tách UI riêng theo nền tảng):
/// - Toàn bộ nội dung hiển thị (mascot, lời chào, từ vựng, mốc trạng thái) là
///   DỮ LIỆU TĨNH dựng sẵn phía client, không phụ thuộc phản hồi từ server.
/// - Thanh tiến trình/câu trạng thái đổi theo THỜI GIAN TRÔI QUA (không phải
///   tiến độ thực của server - client không có cách nào biết chính xác server
///   đang làm gì), KHÔNG BAO GIỜ tự chạy tới 100% - chỉ thực sự đóng màn chờ
///   khi [future] hoàn tất thật (thành công hay lỗi đều đóng, người gọi tự lo
///   phần xử lý kết quả sau khi [onDone] được gọi).
/// - CHỈ 1 request duy nhất, không có timeout nhân tạo ở tầng UI (timeout
///   thật đã đặt ở [ApiClient] khi tạo [future] - xem
///   `BootContent.wakeTimeoutSeconds`), không tự động retry.
class BootScreen extends StatefulWidget {
  /// Future ĐÃ ĐƯỢC BẮT ĐẦU chạy (không phải 1 factory) - màn chờ chỉ lắng
  /// nghe kết quả, không tự gọi lại nếu build lại nhiều lần.
  final Future<void> future;

  /// Gọi đúng 1 lần khi [future] hoàn tất (thành công HAY lỗi đều gọi, xem
  /// doc comment ở trên) - để trống nếu nơi gọi đã tự lắng nghe [future]
  /// bằng cách khác (ví dụ `FutureBuilder` bọc ngoài `BootScreen` tự rebuild
  /// khi future xong, không cần callback riêng - xem `app.dart`).
  final VoidCallback? onDone;

  const BootScreen({super.key, required this.future, this.onDone});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  /// Mỗi thẻ từ hiện 10 giây - đủ đọc cả câu ví dụ; chạm nghe phát âm thì
  /// thẻ được giữ lại thêm (đếm lại từ lúc chạm).
  static const _cardSeconds = 10;

  late final DateTime _startedAt;
  late final List<ToeicWord> _words;
  // Màn chờ nằm NGOÀI cây Provider (xem `app.dart`) nên tự tạo TtsService riêng.
  final TtsService _tts = TtsService();
  Timer? _ticker;
  int _elapsedSeconds = 0;
  int _wordIndex = 0;
  DateTime _cardShownAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _words = List.of(ToeicVocab.all)..shuffle();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        _elapsedSeconds = now.difference(_startedAt).inSeconds;
        if (now.difference(_cardShownAt).inSeconds >= _cardSeconds) _nextWord(now);
      });
    });
    // whenComplete (không phải then) đảm bảo LUÔN gọi onDone dù future lỗi
    // (timeout, 401, mất mạng thật...) - không để bé kẹt mãi ở màn chờ. Nơi
    // gọi thường bọc [future] trong 1 `FutureBuilder` (xem `app.dart`) nên tự
    // rebuild và gỡ bỏ `BootScreen` khi future xong - [onDone] chỉ cần cho
    // trường hợp KHÔNG có `FutureBuilder` bọc ngoài.
    widget.future.whenComplete(() {
      if (!mounted) return;
      widget.onDone?.call();
    });
  }

  void _nextWord(DateTime now) {
    _wordIndex = (_wordIndex + 1) % _words.length;
    _cardShownAt = now;
  }

  void _speak(String text) {
    setState(() => _cardShownAt = DateTime.now());
    _tts.speak(text, kind: VoiceKind.toeic);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = BootContent.stageFor(_elapsedSeconds);
    final word = _words[_wordIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PetAvatar(
                  mood: PetMood.idle,
                  character: PetCharacter.mimi,
                  size: 120,
                ),
                const SizedBox(height: 12),
                Text(
                  BootContent.greetingFor(DateTime.now()),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mimi đang chuẩn bị, chờ bé một chút nhé...',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: stage.progress,
                      minHeight: 10,
                      backgroundColor: Colors.white,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    stage.text,
                    key: ValueKey(stage.text),
                    style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: VocabTipCard(
                    key: ValueKey(_wordIndex),
                    word: word,
                    onSpeak: _speak,
                    onNext: () => setState(() => _nextWord(DateTime.now())),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thẻ từ vựng TOEIC xoay vòng trong lúc chờ - tận dụng thời gian chết thay
/// vì nhìn thanh tiến trình vô nghĩa (dữ liệu: [ToeicVocab.all]). Có phiên âm
/// + nút nghe (cả từ lẫn câu ví dụ), câu ví dụ tô đậm đúng từ đang học, và
/// mẹo phát âm với những từ hay bị đọc sai.
class VocabTipCard extends StatelessWidget {
  final ToeicWord word;
  final void Function(String text) onSpeak;

  /// null = ẩn nút "Từ tiếp" (màn "Từ vựng TOEIC" có thanh điều khiển riêng).
  final VoidCallback? onNext;

  /// Dòng tiêu đề nhỏ trên cùng của thẻ.
  final String label;

  const VocabTipCard({
    super.key,
    required this.word,
    required this.onSpeak,
    this.onNext,
    this.label = '📖 Từ vựng TOEIC hay gặp',
  });

  @override
  Widget build(BuildContext context) {
    final tip = word.tip;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(word.word,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.idleBubble,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(word.typeLabel, style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
          Row(
            children: [
              Flexible(
                child: Text(word.ipa, style: const TextStyle(fontSize: 16, color: Colors.black87)),
              ),
              IconButton(
                tooltip: 'Nghe phát âm',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                onPressed: () => onSpeak(word.word),
              ),
            ],
          ),
          Text(word.meaning, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HighlightedExample(example: word.example, word: word.word),
                      const SizedBox(height: 4),
                      Text(word.exampleVi,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Nghe câu ví dụ',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.record_voice_over_rounded, size: 20, color: AppColors.primary),
                  onPressed: () => onSpeak(word.example),
                ),
              ],
            ),
          ),
          if (tip != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.thinkingBubble,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('💡 $tip', style: const TextStyle(fontSize: 13)),
            ),
          ],
          if (onNext != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onNext,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Từ tiếp'),
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Câu ví dụ có TÔ ĐẬM từ đang học - khớp cả dạng đã chia (submit ->
/// submitted, look into -> looked into) bằng cách tìm theo gốc của từ đầu.
class HighlightedExample extends StatelessWidget {
  final String example;
  final String word;

  const HighlightedExample({super.key, required this.example, required this.word});

  /// Vị trí [start, end) cần tô đậm trong [example], hoặc null nếu không tìm thấy.
  static (int, int)? highlightRange(String example, String word) {
    final lower = example.toLowerCase().replaceAll('é', 'e');
    // "be on display" -> câu ví dụ dùng "are/is on display": bỏ "be" để tìm.
    var target = word.toLowerCase().replaceAll('é', 'e');
    if (target.startsWith('be ')) target = target.substring(3);
    // Luôn tô TRỌN từ trong câu (stack -> "stacked", không chỉ "stack").
    (int, int) wholeWord(int start, int minEnd) {
      var end = minEnd;
      while (end < example.length && RegExp(r"[A-Za-zé'-]").hasMatch(example[end])) {
        end++;
      }
      return (start, end);
    }

    final exact = lower.indexOf(target);
    if (exact >= 0) return wholeWord(exact, exact + target.length);
    var stem = target.split(' ').first;
    // wipe -> wiping, face -> facing: bỏ "e" cuối trước khi tìm theo gốc.
    if (stem.length > 3 && stem.endsWith('e')) stem = stem.substring(0, stem.length - 1);
    if (stem.length > 4) stem = stem.substring(0, 4);
    final start = lower.indexOf(stem);
    if (start < 0) return null;
    return wholeWord(start, start);
  }

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(fontSize: 14, color: Colors.black87, height: 1.3);
    final range = highlightRange(example, word);
    if (range == null) return Text(example, style: base);
    final (start, end) = range;
    return Text.rich(
      TextSpan(style: base, children: [
        TextSpan(text: example.substring(0, start)),
        TextSpan(
          text: example.substring(start, end),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        TextSpan(text: example.substring(end)),
      ]),
    );
  }
}
