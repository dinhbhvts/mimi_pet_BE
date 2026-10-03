import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/grammar_lessons.dart';
import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/domain/entities/dictionary_lookup.dart';
import 'package:mimi_pet/domain/usecases/evaluate_answer.dart';
import 'package:mimi_pet/presentation/screens/grammar/grammar_screens.dart';
import 'package:mimi_pet/presentation/state/dictionary_controller.dart';

/// Tab "Tra cứu" (trước 2026-10-03 là "Từ điển"), 2 chế độ:
/// - 📖 Tra từ: tra 1 từ/câu (tự động 2 chiều Anh<->Việt) với phiên âm, từ
///   loại, các nghĩa, câu ví dụ song ngữ (nghe được), từ đồng nghĩa và ghi
///   chú cách dùng; nghe phát âm + kiểm tra bé đọc theo.
/// - 💬 Hỏi đáp ngữ pháp: hỏi bằng tiếng Việt (hoặc tiếng Anh), "Cô Mimi"
///   giải thích bằng tiếng Việt kèm ví dụ song ngữ, mẹo nhớ, câu hỏi gợi ý
///   tiếp và nút mở bài ngữ pháp liên quan trong app.
class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final _lookupController = TextEditingController();
  final _askController = TextEditingController();
  final _qaScroll = ScrollController();
  int _lastTurnCount = 0;

  static const _lookupSamples = ['deadline', 'apple', 'con mèo', 'look forward to', 'How are you?'];

  @override
  void dispose() {
    _lookupController.dispose();
    _askController.dispose();
    _qaScroll.dispose();
    super.dispose();
  }

  void _lookup(DictionaryController c, [String? text]) {
    final query = text ?? _lookupController.text;
    if (query.trim().isEmpty) return;
    if (text != null) _lookupController.text = text;
    FocusScope.of(context).unfocus();
    c.lookup(query);
  }

  void _ask(DictionaryController c, [String? text]) {
    final question = text ?? _askController.text;
    if (question.trim().isEmpty || c.isAsking) return;
    _askController.clear();
    FocusScope.of(context).unfocus();
    c.ask(question);
  }

  void _scrollQaIfNeeded(DictionaryController c) {
    final count = c.qaTurns.length + (c.isAsking ? 1 : 0);
    if (count == _lastTurnCount) return;
    _lastTurnCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_qaScroll.hasClients) return;
      _qaScroll.animateTo(
        _qaScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<DictionaryController>();
    final isLookup = c.mode == DictionaryMode.lookup;
    if (!isLookup) _scrollQaIfNeeded(c);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tra từ & Hỏi đáp 📖',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SegmentedButton<DictionaryMode>(
            segments: const [
              ButtonSegment(value: DictionaryMode.lookup, label: Text('📖 Tra từ')),
              ButtonSegment(value: DictionaryMode.ask, label: Text('💬 Hỏi ngữ pháp')),
            ],
            selected: {c.mode},
            showSelectedIcon: false,
            onSelectionChanged: (s) => c.setMode(s.first),
          ),
          const SizedBox(height: 12),
          Expanded(child: isLookup ? _buildLookup(c) : _buildAsk(c)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- tra từ

  Widget _buildLookup(DictionaryController c) {
    final chips = c.recentLookups.isNotEmpty ? c.recentLookups : _lookupSamples;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lookupController,
                  enabled: !c.isListening,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _lookup(c),
                  decoration: _inputDecoration('Từ hoặc câu tiếng Anh / tiếng Việt...'),
                ),
              ),
              const SizedBox(width: 8),
              _RoundButton(
                icon: Icons.search_rounded,
                tooltip: 'Tra',
                onTap: (c.isLookingUp || c.isListening) ? null : () => _lookup(c),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(c.recentLookups.isNotEmpty ? '🕘 Đã tra:' : '💡 Thử:',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              for (final q in chips)
                ActionChip(
                  label: Text(q, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.white,
                  onPressed: c.isLookingUp ? null : () => _lookup(c, q),
                ),
            ],
          ),
          if (c.isLookingUp) const _Loading(),
          if (c.error != null)
            _ErrorBox(message: DictionaryController.friendlyErrorMessage(c.error!), onTap: c.clearError),
          if (c.result != null) ...[
            const SizedBox(height: 14),
            _ResultCard(controller: c, onLookup: (w) => _lookup(c, w)),
          ] else if (!c.isLookingUp && c.error == null)
            const Padding(
              padding: EdgeInsets.only(top: 36),
              child: Column(
                children: [
                  Text('🔎', style: TextStyle(fontSize: 44)),
                  SizedBox(height: 6),
                  Text(
                    'Gõ 1 từ hoặc 1 câu để xem nghĩa, phiên âm\nvà câu ví dụ có đọc mẫu',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- hỏi đáp

  Widget _buildAsk(DictionaryController c) {
    final turns = c.qaTurns;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final a in GrammarAudience.values) ...[
              ChoiceChip(
                label: Text(a.label, style: const TextStyle(fontSize: 12)),
                selected: c.audience == a,
                onSelected: (_) => c.setAudience(a),
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
            ],
            const Spacer(),
            if (turns.isNotEmpty)
              IconButton(
                onPressed: c.isAsking ? null : c.clearQa,
                icon: const Icon(Icons.delete_sweep_rounded),
                color: AppColors.textMuted,
                tooltip: 'Xoá cuộc hỏi đáp',
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: turns.isEmpty && !c.isAsking
              ? _AskEmptyState(questions: c.starterQuestions, onTap: (q) => _ask(c, q))
              : ListView.builder(
                  controller: _qaScroll,
                  itemCount: turns.length,
                  itemBuilder: (context, i) {
                    final turn = turns[i];
                    final isLast = i == turns.length - 1;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _QuestionBubble(text: turn.question),
                        if (turn.answer != null)
                          _AnswerCard(
                            answer: turn.answer!,
                            onSpeak: c.speakEnglish,
                            followUps: isLast && !c.isAsking ? turn.answer!.followUps : const [],
                            onFollowUp: (q) => _ask(c, q),
                          )
                        else if (isLast && c.isAsking)
                          const _Loading(text: 'Cô Mimi đang soạn câu trả lời...'),
                      ],
                    );
                  },
                ),
        ),
        if (c.askError != null)
          _ErrorBox(message: DictionaryController.friendlyErrorMessage(c.askError!), onTap: c.clearAskError),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _askController,
                enabled: !c.isAsking,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _ask(c),
                decoration: _inputDecoration('Hỏi Cô Mimi, hoặc dán 1 câu để kiểm tra...'),
              ),
            ),
            const SizedBox(width: 8),
            _RoundButton(icon: Icons.send_rounded, tooltip: 'Hỏi', onTap: c.isAsking ? null : () => _ask(c)),
          ],
        ),
      ],
    );
  }

  static InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      );
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _RoundButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: onTap == null ? AppColors.disabled : AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(12), child: Icon(icon, color: Colors.white, size: 22)),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  final String? text;

  const _Loading({this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          if (text != null) ...[
            const SizedBox(width: 10),
            Text(text!, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onTap;

  const _ErrorBox({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.happyBubble, borderRadius: BorderRadius.circular(12)),
          child: Text(message, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
    );

/// Thẻ kết quả tra cứu: từ + phiên âm + từ loại, nghĩa chính/nghĩa khác,
/// câu ví dụ song ngữ (nghe được), từ đồng nghĩa (chạm để tra), ghi chú,
/// nút nghe và "Kiểm tra phát âm".
class _ResultCard extends StatelessWidget {
  final DictionaryController controller;
  final ValueChanged<String> onLookup;

  const _ResultCard({required this.controller, required this.onLookup});

  @override
  Widget build(BuildContext context) {
    final r = controller.result!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  r.english,
                  style: TextStyle(
                    fontSize: r.isSentence ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                onPressed: controller.isSpeaking ? null : controller.playPronunciation,
                icon: Icon(Icons.volume_up_rounded,
                    color: controller.isSpeaking ? AppColors.disabled : AppColors.primary),
                tooltip: 'Nghe phát âm',
              ),
            ],
          ),
          if (r.ipa.isNotEmpty || r.partOfSpeech.isNotEmpty)
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (r.ipa.isNotEmpty) Text(r.ipa, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                if (r.partOfSpeech.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.idleBubble, borderRadius: BorderRadius.circular(10)),
                    child: Text(r.partOfSpeech, style: const TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          const SizedBox(height: 6),
          Text(r.vietnamese, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          if (r.meanings.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Nghĩa khác: ${r.meanings.join('; ')}',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ],
          if (r.examples.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _SectionLabel('Ví dụ'),
            for (final e in r.examples) _ExampleRow(example: e, onSpeak: controller.speakEnglish),
          ],
          if (r.synonyms.isNotEmpty) ...[
            const SizedBox(height: 10),
            const _SectionLabel('Từ đồng nghĩa (chạm để tra)'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in r.synonyms)
                  ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    onPressed: controller.isLookingUp ? null : () => onLookup(s),
                  ),
              ],
            ),
          ],
          if (r.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            _TipBox(text: r.note, label: r.isSentence ? 'Cấu trúc câu' : 'Ghi chú'),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: controller.isListening ? null : controller.checkPronunciation,
            icon: Icon(controller.isListening ? Icons.mic : Icons.mic_none_rounded),
            label: Text(controller.isListening ? 'Đang nghe...' : 'Kiểm tra phát âm'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          if (controller.pronunciationResult != null) ...[
            const SizedBox(height: 10),
            _PronunciationFeedback(result: controller.pronunciationResult!),
            if (controller.pronunciationWordResults != null) ...[
              const SizedBox(height: 8),
              _WordLevelFeedback(wordMatch: controller.pronunciationWordResults!),
            ],
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted));
}

class _ExampleRow extends StatelessWidget {
  final BilingualExample example;
  final ValueChanged<String> onSpeak;

  const _ExampleRow({required this.example, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: example.correct ? AppColors.background : const Color(0xFFFFEDEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${example.correct ? '' : '❌ '}${example.english}',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    decoration: example.correct ? null : TextDecoration.lineThrough,
                    decorationColor: Colors.redAccent,
                  ),
                ),
                if (example.vietnamese.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(example.vietnamese,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          if (example.correct)
            IconButton(
              onPressed: () => onSpeak(example.english),
              icon: const Icon(Icons.volume_up_rounded, size: 20, color: AppColors.primary),
              tooltip: 'Nghe câu ví dụ',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _TipBox extends StatelessWidget {
  final String text;
  final String label;

  const _TipBox({required this.text, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.thinkingBubble, borderRadius: BorderRadius.circular(12)),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: '💡 $label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: text),
        ]),
        style: const TextStyle(fontSize: 13, height: 1.35),
      ),
    );
  }
}

class _AskEmptyState extends StatelessWidget {
  final List<String> questions;
  final ValueChanged<String> onTap;

  const _AskEmptyState({required this.questions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text('👩‍🏫', textAlign: TextAlign.center, style: TextStyle(fontSize: 42)),
          const SizedBox(height: 6),
          const Text(
            'Hỏi Cô Mimi bất cứ điều gì về tiếng Anh: ngữ pháp, cách dùng từ, phát âm... '
            'hoặc dán 1 câu tiếng Anh để Cô kiểm tra giúp. Cô giải thích bằng tiếng Việt!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.35),
          ),
          const SizedBox(height: 14),
          for (final q in questions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () => onTap(q),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('❓ $q', style: const TextStyle(fontSize: 13.5)),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuestionBubble extends StatelessWidget {
  final String text;

  const _QuestionBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 6, left: 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14.5)),
      ),
    );
  }
}

/// Câu trả lời: lời giải thích (tiếng Việt), ví dụ song ngữ (✅/❌, nghe
/// được), mẹo nhớ, nút mở bài ngữ pháp liên quan, câu hỏi gợi ý tiếp.
class _AnswerCard extends StatelessWidget {
  final GrammarAnswer answer;
  final ValueChanged<String> onSpeak;
  final List<String> followUps;
  final ValueChanged<String> onFollowUp;

  const _AnswerCard({
    required this.answer,
    required this.onSpeak,
    required this.followUps,
    required this.onFollowUp,
  });

  @override
  Widget build(BuildContext context) {
    final lesson = GrammarLessons.all.where((l) => l.id == answer.relatedLessonId).firstOrNull;
    return Container(
      margin: const EdgeInsets.only(right: 12, bottom: 6),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('👩‍🏫 Cô Mimi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 6),
          SelectableText(answer.answer, style: const TextStyle(fontSize: 14.5, height: 1.45)),
          if (answer.examples.isNotEmpty) ...[
            const SizedBox(height: 10),
            const _SectionLabel('Ví dụ'),
            for (final e in answer.examples) _ExampleRow(example: e, onSpeak: onSpeak),
          ],
          if (answer.tip.isNotEmpty) ...[
            const SizedBox(height: 10),
            _TipBox(text: answer.tip, label: 'Mẹo nhớ'),
          ],
          if (lesson != null) ...[
            const SizedBox(height: 4),
            GrammarLessonLink(lesson: lesson),
          ],
          if (followUps.isNotEmpty) ...[
            const SizedBox(height: 6),
            const _SectionLabel('Hỏi tiếp'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final q in followUps)
                  ActionChip(
                    label: Text(q, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onFollowUp(q),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PronunciationFeedback extends StatelessWidget {
  final AnswerResult result;

  const _PronunciationFeedback({required this.result});

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color color;
    switch (result) {
      case AnswerResult.correct:
        text = '✅ Phát âm tốt lắm!';
        color = const Color(0xFF3FAE5A);
      case AnswerResult.incorrect:
        text = '🔁 Chưa đúng lắm, thử lại nhé!';
        color = const Color(0xFFE0863C);
      case AnswerResult.empty:
        text = '🎤 Không nghe rõ, thử nói to hơn nhé!';
        color = AppColors.textMuted;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

/// Tô màu TỪNG TỪ trong câu tiếng Anh theo kết quả so khớp chi tiết
/// [DictionaryController.pronunciationWordResults] (xem
/// [EvaluateAnswer.wordLevelMatch]) - xanh nếu bé đọc đúng từ đó, cam nếu
/// chưa đúng. Hiển thị TRỰC TIẾP [WordMatchResult.words] (đã chuẩn hoá, CÙNG
/// số lượng với [WordMatchResult.matches]) thay vì tự tách lại câu gốc (tách
/// lại có thể lệch số từ khi câu có dấu nháy đơn, vd "it's").
class _WordLevelFeedback extends StatelessWidget {
  final WordMatchResult wordMatch;

  const _WordLevelFeedback({required this.wordMatch});

  @override
  Widget build(BuildContext context) {
    final words = wordMatch.words;
    final matches = wordMatch.matches;
    final count = words.length < matches.length ? words.length : matches.length;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: List.generate(count, (i) {
        final color = matches[i] ? const Color(0xFF3FAE5A) : const Color(0xFFE0863C);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(words[i], style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        );
      }),
    );
  }
}
