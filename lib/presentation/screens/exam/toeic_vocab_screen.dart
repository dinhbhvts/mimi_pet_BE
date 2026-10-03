import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/core/toeic_vocab.dart';
import 'package:mimi_pet/presentation/screens/boot/boot_screen.dart';
import 'package:mimi_pet/presentation/state/toeic_vocab_controller.dart';
import 'package:mimi_pet/services/tts_service.dart';

/// "Từ vựng TOEIC" trong phần ôn luyện: thẻ từ TỰ CHUYỂN như ở màn chờ, thêm
/// lọc chủ đề, tua lại/tạm dừng, tự đọc, đánh dấu đã thuộc (xem
/// [ToeicVocabController]).
///
/// Đếm giờ: mỗi thẻ hiện ra thì (nếu bật tự đọc) Mimi đọc XONG rồi mới bắt
/// đầu đếm [ToeicVocabController.cardSeconds] giây - thẻ không bị chuyển
/// ngang khi đang đọc dở câu ví dụ dài. Chạm nghe lại thì đếm lại từ đầu.
class ToeicVocabScreen extends StatefulWidget {
  const ToeicVocabScreen({super.key});

  @override
  State<ToeicVocabScreen> createState() => _ToeicVocabScreenState();
}

class _ToeicVocabScreenState extends State<ToeicVocabScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _countdown;
  late final ToeicVocabController _vocab;
  late final TtsService _tts;

  /// Thẻ đã "bắt đầu" gần nhất - đổi thẻ thì đọc + đếm lại.
  ToeicWord? _shownWord;
  int _shownIndex = -1;
  bool _shownAuto = false;

  /// Tăng mỗi lần bắt đầu thẻ/nghe lại - lượt đọc cũ xong muộn thì bỏ qua.
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _vocab = context.read<ToeicVocabController>();
    _tts = context.read<TtsService>();
    _countdown = AnimationController(vsync: this, duration: Duration(seconds: _vocab.cardSeconds))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted && _vocab.autoAdvance) _vocab.next();
      });
    _vocab.addListener(_onVocabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onVocabChanged());
  }

  void _onVocabChanged() {
    if (!mounted) return;
    _countdown.duration = Duration(seconds: _vocab.cardSeconds);
    final word = _vocab.current;
    final cardChanged = word != _shownWord || _vocab.index != _shownIndex;
    final autoChanged = _vocab.autoAdvance != _shownAuto;
    _shownWord = word;
    _shownIndex = _vocab.index;
    _shownAuto = _vocab.autoAdvance;
    if (cardChanged) {
      _startCard();
    } else if (autoChanged) {
      if (_vocab.autoAdvance) {
        _countdown.forward(from: 0);
      } else {
        _countdown
          ..stop()
          ..value = 0;
      }
    }
  }

  Future<void> _startCard() async {
    final token = ++_token;
    _countdown
      ..stop()
      ..value = 0;
    final word = _vocab.current;
    if (word == null) return;
    switch (_vocab.autoRead) {
      case VocabAutoRead.off:
        break;
      case VocabAutoRead.word:
        await _read(word.word);
      case VocabAutoRead.wordAndExample:
        await _read(word.word);
        if (token == _token) await _read(word.example);
    }
    if (!mounted || token != _token) return;
    if (_vocab.autoAdvance) _countdown.forward(from: 0);
  }

  /// Đọc và CHỜ đọc xong - tối đa 8 giây: nếu trình duyệt không báo "đọc
  /// xong" (vd Safari iPhone chặn giọng đọc trước lần chạm đầu tiên) thì vẫn
  /// đếm giờ tiếp, thẻ không bị kẹt mãi.
  Future<void> _read(String text) => _tts
      .speak(text, kind: VoiceKind.toeic)
      .timeout(const Duration(seconds: 8), onTimeout: () {})
      .catchError((Object _) {});

  /// Chạm nghe từ/câu ví dụ: dừng đếm, đọc xong mới đếm lại từ đầu.
  Future<void> _speak(String text) async {
    final token = ++_token;
    _countdown.stop();
    await _read(text);
    if (!mounted || token != _token) return;
    if (_vocab.autoAdvance) _countdown.forward(from: 0);
  }

  @override
  void dispose() {
    _token++;
    _vocab.removeListener(_onVocabChanged);
    _countdown.dispose();
    _tts.stop();
    super.dispose();
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ChangeNotifierProvider.value(value: _vocab, child: const _SettingsSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vocab = context.watch<ToeicVocabController>();
    final word = vocab.current;
    final topicWords = vocab.topicWords;
    final knownInTopic = topicWords.where(vocab.isKnown).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Từ vựng TOEIC'),
        actions: [
          IconButton(onPressed: _openSettings, icon: const Icon(Icons.tune_rounded), tooltip: 'Tuỳ chỉnh'),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _TopicChip(
                    label: '📚 Tất cả (${vocab.totalCount})',
                    selected: vocab.topicId == null,
                    onTap: () => vocab.selectTopic(null),
                  ),
                  for (final t in vocab.topics)
                    _TopicChip(
                      label: '${t.emoji} ${t.title} (${t.words.length})',
                      selected: vocab.topicId == t.id,
                      onTap: () => vocab.selectTopic(t.id),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      word == null ? 'Đã thuộc $knownInTopic/${topicWords.length} từ' :
                          'Thẻ ${vocab.index + 1}/${vocab.deck.length} · đã thuộc $knownInTopic/${topicWords.length}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                  Text(
                    vocab.autoAdvance ? '⏱ ${vocab.cardSeconds}s/thẻ' : '⏸ Đang dừng',
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: AnimatedBuilder(
                animation: _countdown,
                builder: (context, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: vocab.autoAdvance ? _countdown.value : 0,
                    minHeight: 6,
                    backgroundColor: Colors.white,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: word == null
                  ? _AllKnown(onShowKnown: () => vocab.setHideKnown(false))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: VocabTipCard(
                            key: ValueKey('${vocab.index}-${word.word}'),
                            word: word,
                            onSpeak: _speak,
                            label: vocab.isKnown(word) ? '✅ Đã thuộc' : '📖 Từ vựng TOEIC',
                          ),
                        ),
                      ),
                    ),
            ),
            if (word != null) _ControlBar(word: word),
          ],
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TopicChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        backgroundColor: Colors.white,
      ),
    );
  }
}

/// Trước / Tạm dừng-Tự chuyển / Đã thuộc / Sau.
class _ControlBar extends StatelessWidget {
  final ToeicWord word;

  const _ControlBar({required this.word});

  @override
  Widget build(BuildContext context) {
    final vocab = context.watch<ToeicVocabController>();
    final known = vocab.isKnown(word);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: vocab.previous,
            icon: const Icon(Icons.skip_previous_rounded),
            tooltip: 'Từ trước',
          ),
          IconButton.filledTonal(
            onPressed: () => vocab.setAutoAdvance(!vocab.autoAdvance),
            icon: Icon(vocab.autoAdvance ? Icons.pause_rounded : Icons.play_arrow_rounded),
            tooltip: vocab.autoAdvance ? 'Tạm dừng tự chuyển' : 'Bật tự chuyển từ',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => vocab.toggleKnown(word),
              style: FilledButton.styleFrom(
                backgroundColor: known ? AppColors.disabled : const Color(0xFF3E9E5B),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: Icon(known ? Icons.undo_rounded : Icons.check_rounded),
              label: Text(known ? 'Bỏ đánh dấu' : 'Đã thuộc'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: vocab.next,
            icon: const Icon(Icons.skip_next_rounded),
            tooltip: 'Từ tiếp',
          ),
        ],
      ),
    );
  }
}

class _AllKnown extends StatelessWidget {
  final VoidCallback onShowKnown;

  const _AllKnown({required this.onShowKnown});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            const Text(
              'Đã thuộc hết từ trong chủ đề này!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Chọn chủ đề khác, hoặc ôn lại các từ đã thuộc.',
              style: TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onShowKnown, child: const Text('Ôn lại từ đã thuộc')),
          ],
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final vocab = context.watch<ToeicVocabController>();
    Widget chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
        );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tuỳ chỉnh thẻ từ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            const Text('Thời gian mỗi thẻ', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              for (final s in ToeicVocabController.cardSecondsOptions)
                chip('$s giây', vocab.cardSeconds == s, () => vocab.setCardSeconds(s)),
            ]),
            const SizedBox(height: 14),
            const Text('Tự đọc khi sang thẻ mới', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              for (final m in VocabAutoRead.values) chip(m.label, vocab.autoRead == m, () => vocab.setAutoRead(m)),
            ]),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tự chuyển từ'),
              value: vocab.autoAdvance,
              onChanged: vocab.setAutoAdvance,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Trộn ngẫu nhiên'),
              value: vocab.shuffle,
              onChanged: vocab.setShuffle,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ẩn từ đã thuộc'),
              subtitle: Text('Đã thuộc ${vocab.knownCount}/${vocab.totalCount} từ'),
              value: vocab.hideKnown,
              onChanged: vocab.setHideKnown,
            ),
          ],
        ),
      ),
    );
  }
}
