import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/domain/usecases/evaluate_answer.dart';
import 'package:mimi_pet/presentation/state/dictionary_controller.dart';

/// Tab "Từ điển": tra nghĩa 1 từ hoặc 1 câu (tự động 2 chiều Anh<->Việt), cho
/// bé nghe phát âm chuẩn (TTS) và kiểm tra bé đọc theo có đúng không (mic +
/// so khớp - xem [DictionaryController]).
///
/// KHÁC với Chat: đây KHÔNG phải trò chuyện, chỉ 1 ô nhập + 1 kết quả tại 1
/// thời điểm (tra từ mới sẽ THAY kết quả cũ, không phải danh sách lịch sử) -
/// giữ đơn giản, đúng bản chất "tra từ điển" thay vì hội thoại.
class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleLookup(DictionaryController controller) {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    controller.lookup(text);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DictionaryController>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Từ điển Anh - Việt 📖',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gõ 1 từ hoặc 1 câu bằng tiếng Anh hoặc tiếng Việt để tra nghĩa',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            enabled: !controller.isListening,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _handleLookup(controller),
                            decoration: InputDecoration(
                              hintText: 'Ví dụ: apple, hoặc "con mèo"...',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: (controller.isLookingUp || controller.isListening)
                                ? null
                                : () => _handleLookup(controller),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.search_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (controller.isLookingUp)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    if (controller.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: GestureDetector(
                          onTap: controller.clearError,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.happyBubble,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              DictionaryController.friendlyErrorMessage(controller.error!),
                              style: const TextStyle(fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    if (controller.result != null) ...[
                      const SizedBox(height: 18),
                      _ResultCard(controller: controller),
                    ] else if (!controller.isLookingUp && controller.error == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text('🔎', style: TextStyle(fontSize: 44)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Thẻ kết quả tra cứu - hiện cả 2 phía Anh/Việt, nút "Nghe" (🔊, phát âm
/// tiếng Anh) và nút "Kiểm tra phát âm" (🎤, bé đọc theo rồi so khớp).
class _ResultCard extends StatelessWidget {
  final DictionaryController controller;

  const _ResultCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final result = controller.result!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.english,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: controller.isSpeaking ? null : controller.playPronunciation,
                icon: Icon(
                  Icons.volume_up_rounded,
                  color: controller.isSpeaking ? AppColors.disabled : AppColors.primary,
                ),
                tooltip: 'Nghe phát âm',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            result.vietnamese,
            style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
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
              ),
            ],
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
/// [EvaluateAnswer.wordLevelMatch]) - xanh nếu bé đọc đúng từ đó, đỏ nhạt
/// nếu chưa đúng, giúp bé biết CHÍNH XÁC từ nào cần đọc lại thay vì chỉ 1
/// nhận xét chung chung cho cả câu (xem [_PronunciationFeedback]).
///
/// Hiển thị TRỰC TIẾP [WordMatchResult.words] (đã chuẩn hoá, CÙNG số lượng
/// với [WordMatchResult.matches]) thay vì tự tách lại câu tiếng Anh gốc -
/// SỬA LỖI (2026-08-23): tự tách câu gốc có thể lệch số từ so với danh sách
/// đúng/sai khi câu có dấu nháy đơn (ví dụ "it's" -> 2 từ sau chuẩn hoá
/// nhưng 1 từ ở câu gốc), gây tô màu nhầm vị trí - xem doc comment
/// [WordMatchResult].
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
        final isCorrect = matches[i];
        final color = isCorrect ? const Color(0xFF3FAE5A) : const Color(0xFFE0863C);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            words[i],
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        );
      }),
    );
  }
}

