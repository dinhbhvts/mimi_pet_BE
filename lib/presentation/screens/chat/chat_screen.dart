import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/domain/entities/chat_message.dart';
import 'package:mimi_pet/domain/entities/child_avatar.dart';
import 'package:mimi_pet/domain/entities/pet_character.dart';
import 'package:mimi_pet/domain/entities/pet_mood.dart';
import 'package:mimi_pet/domain/entities/pet_palette.dart';
import 'package:mimi_pet/presentation/state/chat_controller.dart';
import 'package:mimi_pet/presentation/state/child_avatar_controller.dart';
import 'package:mimi_pet/presentation/state/pet_character_controller.dart';
import 'package:mimi_pet/presentation/state/pet_inventory_controller.dart';
import 'package:mimi_pet/presentation/state/pet_palette_controller.dart';
import 'package:mimi_pet/presentation/widgets/pet_avatar.dart';

/// Tab "Chat": tâm sự tự do với thú cưng - bé có thể gõ chữ HOẶC bấm mic
/// nói. Dùng LLM (Gemini) khi đã có API key, và TỰ ĐỘNG chuyển sang chatbot
/// offline (câu trả lời có sẵn) khi chưa có key hoặc Gemini tạm thời không
/// gọi được - xem `CompositeChatService`. Vì vậy màn hình này KHÔNG BAO GIỜ
/// khoá bé lại chỉ vì thiếu key, chỉ hiện 1 banner nhỏ báo chế độ đang dùng.
///
/// Khác biệt quan trọng với tab Play: đây KHÔNG phải bài học có đúng/sai,
/// không trừ tim, không cộng sao - chỉ là trò chuyện vui vẻ, an toàn (xem
/// System Prompt trong `GeminiChatService`, và bộ câu trả lời có sẵn trong
/// `OfflineChatService`).
///
/// THÊM (2026-08-22) cho đỡ đơn điệu (chỉ toàn chữ): 1 [PetAvatar] lớn ở đầu
/// màn hình, "diễn" đúng trạng thái hiện tại (lắng nghe/suy nghĩ/đang nói)
/// qua [ChatController.isListening]/[isSending]/[isSpeaking] - cùng nhân
/// vật + màu + phụ kiện bé đã chọn ở Home (xem [PetCharacterController]/
/// [PetPaletteController]/[PetInventoryController]); 1 avatar tròn nhỏ cạnh
/// mỗi tin nhắn của thú cưng; và nút "Nghe lại" (🔁) ở mỗi tin nhắn đó - CHỈ
/// đọc lại giọng đọc + animation, KHÔNG gọi lại AI (xem
/// [ChatController.replay]).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleSend(ChatController chat) {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    chat.sendText(text);
  }

  /// "Diễn" đúng trạng thái hiện tại của cuộc trò chuyện qua [PetMood] -
  /// nghe (mic đang mở) > suy nghĩ (đang chờ AI/offline trả lời) > đang nói
  /// (đang đọc to câu trả lời, kể cả khi bấm "Nghe lại") > mặc định đứng yên.
  PetMood _moodFor(ChatController chat) {
    if (chat.isListening) return PetMood.listening;
    if (chat.isSending) return PetMood.thinking;
    if (chat.isSpeaking) return PetMood.talking;
    return PetMood.idle;
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final character = context.watch<PetCharacterController>().character;
    final characterName = PetCharacterInfo.all[character]!.displayName;
    final palette = context.watch<PetPaletteController>().paletteFor(character);
    final inventory = context.watch<PetInventoryController>();
    final childAvatar = context.watch<ChildAvatarController>().avatar;

    _scrollToBottomSoon();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Text(
            'Tâm sự với $characterName 💬',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          PetAvatar(
            mood: _moodFor(chat),
            character: character,
            palette: palette,
            headAccessory: inventory.equippedHead,
            neckAccessory: inventory.equippedNeck,
            size: 110,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: chat.messages.isEmpty
                ? _EmptyState(petName: characterName)
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: chat.messages.length,
                    itemBuilder: (context, i) => _MessageBubble(
                      message: chat.messages[i],
                      // Chỉ hiện ghi chú "(câu trả lời có sẵn)" khi bé ĐANG ở
                      // chế độ AI (có key) nhưng lượt này lỡ phải dùng tạm
                      // offline (mất mạng...) - lúc chưa hề có key, banner ở
                      // trên đã báo rồi nên không lặp lại ở từng tin nhắn.
                      showOfflineTag: chat.isAiConfigured,
                      character: character,
                      palette: palette,
                      childAvatar: childAvatar,
                      replayEnabled: !chat.isSpeaking,
                      onReplay: () => chat.replay(chat.messages[i]),
                      translationVisible: chat.isTranslationVisible(i),
                      isTranslating: chat.isTranslating(i),
                      translatedText: chat.messages[i].translatedText,
                      onToggleTranslate: () => chat.toggleTranslate(i),
                    ),
                  ),
          ),
          if (chat.isSending)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (chat.lastError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: chat.clearError,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.happyBubble,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ChatController.friendlyErrorMessage(chat.lastError!),
                    style: const TextStyle(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          _InputRow(controller: _textController, chat: chat, onSend: () => _handleSend(chat)),
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  final TextEditingController controller;
  final ChatController chat;
  final VoidCallback onSend;

  const _InputRow({required this.controller, required this.chat, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final busy = chat.isSending || chat.isListening;
    final isTextMode = chat.inputMode == ChatInputMode.text;

    return Row(
      children: [
        IconButton(
          onPressed: busy
              ? null
              : () => chat.setInputMode(isTextMode ? ChatInputMode.voice : ChatInputMode.text),
          icon: Icon(isTextMode ? Icons.mic_none_rounded : Icons.keyboard_rounded),
          tooltip: isTextMode ? 'Chuyển sang nói' : 'Chuyển sang gõ chữ',
        ),
        Expanded(
          child: isTextMode
              ? TextField(
                  controller: controller,
                  enabled: !busy,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: 'Gõ điều bé muốn nói...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                )
              : Material(
                  color: chat.isListening ? AppColors.listeningBubble : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    // SỬA (2026-08-23): trước đây nút này bị VÔ HIỆU HOÁ hoàn
                    // toàn trong lúc đang nghe (vì `busy` gồm cả isListening),
                    // nên bé phải đợi hết giờ hoặc im lặng đủ lâu mic mới tự
                    // tắt. Giờ cho bấm lại để chủ động báo "nói xong" ngay -
                    // đặc biệt hữu ích vì thời gian nghe tối đa đã tăng lên
                    // 20 giây (xem `ChatController.startVoiceInput`).
                    onTap: chat.isSending
                        ? null
                        : (chat.isListening ? chat.stopVoiceInput : chat.startVoiceInput),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text(
                          chat.isListening ? 'Đang nghe... (chạm để dừng)' : 'Chạm để nói',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        if (isTextMode) ...[
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: busy ? null : onSend,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showOfflineTag;

  /// Nhân vật + màu đang chọn - CHỈ dùng để vẽ avatar tròn nhỏ cạnh tin
  /// nhắn của thú cưng (xem [_MiniPetAvatar]), không ảnh hưởng gì tới tin
  /// nhắn của bé.
  final PetCharacter character;
  final PetPalette palette;

  /// Avatar CỦA BÉ đang chọn ở Cài đặt (emoji hoặc ảnh từ máy) - vẽ cạnh tin
  /// nhắn của chính bé (xem [_MiniChildAvatar]), tương tự avatar nhỏ của thú
  /// cưng cạnh tin nhắn của thú cưng.
  final ChildAvatar childAvatar;

  /// true nếu bé có thể bấm "Nghe lại" NGAY BÂY GIỜ (tắt trong lúc thú cưng
  /// đang đọc 1 câu khác, tránh 2 giọng đọc chồng lên nhau).
  final bool replayEnabled;
  final VoidCallback onReplay;

  /// Chỉ có ý nghĩa với tin nhắn CỦA THÚ CƯNG - xem
  /// `ChatController.toggleTranslate`/`isTranslationVisible`/`isTranslating`.
  final bool translationVisible;
  final bool isTranslating;
  final String? translatedText;
  final VoidCallback onToggleTranslate;

  const _MessageBubble({
    required this.message,
    this.showOfflineTag = false,
    required this.character,
    required this.palette,
    required this.childAvatar,
    required this.replayEnabled,
    required this.onReplay,
    this.translationVisible = false,
    this.isTranslating = false,
    this.translatedText,
    required this.onToggleTranslate,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final showTag = showOfflineTag && !isUser && message.viaOffline;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _MiniPetAvatar(character: character, palette: palette),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15),
                  ),
                ),
              ),
              if (!isUser) ...[
                _ReplayButton(enabled: replayEnabled, onTap: onReplay),
                _TranslateButton(
                  isTranslating: isTranslating,
                  isActive: translationVisible,
                  onTap: onToggleTranslate,
                ),
              ] else ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _MiniChildAvatar(avatar: childAvatar),
                ),
              ],
            ],
          ),
          if (showTag)
            const Padding(
              padding: EdgeInsets.only(left: 44, bottom: 4),
              child: Text(
                '📶 Mất kết nối, đây là câu trả lời có sẵn',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          // Bản dịch tiếng Việt của tin nhắn CỦA THÚ CƯNG (nếu bé đã bấm nút
          // dịch 🌐 và có kết quả - xem `ChatController.toggleTranslate`).
          if (!isUser && translationVisible && translatedText != null)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 4),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.thinkingBubble.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🌐 $translatedText',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),
          // Gợi ý sửa lỗi ngữ pháp cho tin nhắn CỦA BÉ (nếu có - xem
          // `ChatController._checkGrammar`) - hiện SAU khi phân tích xong
          // (thường vài giây sau khi tin nhắn đã hiển thị), không chặn/ảnh
          // hưởng gì tới việc gửi/nhận tin nhắn.
          if (isUser && message.grammarNote != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.thinkingBubble.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '💡 ${message.grammarNote}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Avatar tròn nhỏ (emoji nhân vật trên nền màu đang chọn) cạnh mỗi tin nhắn
/// của thú cưng - KHÔNG animate (chỉ [PetAvatar] lớn ở đầu màn hình mới có
/// animation, tránh vẽ CustomPaint tốn kém cho từng dòng chat khi danh sách
/// dài).
class _MiniPetAvatar extends StatelessWidget {
  final PetCharacter character;
  final PetPalette palette;

  const _MiniPetAvatar({required this.character, required this.palette});

  @override
  Widget build(BuildContext context) {
    final info = PetCharacterInfo.all[character]!;
    final swatch = PetPaletteInfo.all[palette]!.swatch;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: swatch,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4),
        ],
      ),
      alignment: Alignment.center,
      child: Text(info.emoji, style: const TextStyle(fontSize: 15)),
    );
  }
}

/// Avatar tròn nhỏ CỦA BÉ cạnh tin nhắn của chính bé - hiện emoji bé đã chọn
/// (nền màu trung tính, khác màu bong bóng nhân vật để không gây nhầm lẫn)
/// hoặc ảnh bé chọn từ máy (xem `ChildAvatarController`/`settings_screen.dart`).
/// Nếu file ảnh lỗi/không đọc được (ví dụ bị xoá ngoài ý muốn), tự động hiện
/// lại emoji mặc định thay vì vỡ layout hay hiện icon lỗi xấu xí.
class _MiniChildAvatar extends StatelessWidget {
  final ChildAvatar avatar;

  const _MiniChildAvatar({required this.avatar});

  @override
  Widget build(BuildContext context) {
    // base64Decode ném lỗi NGAY (đồng bộ) nếu chuỗi hỏng - errorBuilder của
    // Image.memory chỉ bắt lỗi lúc tải/vẽ ảnh, không bắt lỗi lúc decode bytes
    // đầu vào - phải tự try/catch để tránh crash cả màn Chat.
    Uint8List? photoBytes;
    if (avatar.kind == ChildAvatarKind.photo) {
      try {
        photoBytes = base64Decode(avatar.value);
      } catch (_) {
        photoBytes = null;
      }
    }

    return Container(
      width: 30,
      height: 30,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE0D6F5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4),
        ],
      ),
      alignment: Alignment.center,
      child: photoBytes != null
          ? Image.memory(
              photoBytes,
              fit: BoxFit.cover,
              width: 30,
              height: 30,
              // Dùng thẳng emoji mặc định thay vì tham chiếu
              // `ChildAvatar.fallback.value` - truy cập field của 1 hằng số
              // instance KHÔNG phải là hằng số hợp lệ trong Dart nên không
              // thể dùng trực tiếp trong `const Text(...)` ở đây.
              errorBuilder: (context, error, stackTrace) =>
                  const Text('🧒', style: TextStyle(fontSize: 15)),
            )
          : Text(
              avatar.kind == ChildAvatarKind.photo ? '🧒' : avatar.value,
              style: const TextStyle(fontSize: 15),
            ),
    );
  }
}

/// Nút "Nghe lại" (🔁) - chỉ đọc lại giọng đọc + animation của avatar lớn,
/// KHÔNG gọi lại AI (xem [ChatController.replay]).
class _ReplayButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _ReplayButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: const Icon(Icons.replay_circle_filled_rounded),
      iconSize: 22,
      color: enabled ? AppColors.primary : AppColors.disabled,
      tooltip: 'Nghe lại',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}

/// Nút dịch 🌐 - dịch (hoặc ẩn/hiện lại bản dịch đã có) câu thoại của thú
/// cưng sang tiếng Việt (xem [ChatController.toggleTranslate]). Hiện vòng
/// xoay nhỏ trong lúc đang chờ Gemini dịch, đổi màu khi bản dịch đang HIỆN.
class _TranslateButton extends StatelessWidget {
  final bool isTranslating;
  final bool isActive;
  final VoidCallback onTap;

  const _TranslateButton({required this.isTranslating, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (isTranslating) {
      return const Padding(
        padding: EdgeInsets.all(6),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      onPressed: onTap,
      icon: const Icon(Icons.translate_rounded),
      iconSize: 20,
      color: isActive ? AppColors.primary : AppColors.disabled,
      tooltip: 'Dịch sang tiếng Việt',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String petName;

  const _EmptyState({required this.petName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💬', style: TextStyle(fontSize: 50)),
            const SizedBox(height: 12),
            Text(
              '$petName rất muốn nghe bé kể chuyện!\nThử gõ hoặc nói "Hello!" xem sao nhé.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

