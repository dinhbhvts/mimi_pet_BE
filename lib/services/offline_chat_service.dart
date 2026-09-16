import 'dart:math';

import '../domain/entities/chat_message.dart';
import 'chat_reply_service.dart';

/// 1 quy tắc đối chiếu: nếu câu bé gõ/nói chứa BẤT KỲ từ khoá nào trong
/// [keywords], chọn ngẫu nhiên 1 câu trong [replies] (chuỗi "{pet}" sẽ được
/// thay bằng tên thú cưng đang chọn).
class _Rule {
  final List<String> keywords;
  final List<String> replies;
  const _Rule(this.keywords, this.replies);
}

/// "Bộ não" chat OFFLINE - KHÔNG gọi mạng, KHÔNG cần API key, KHÔNG phải AI
/// sinh văn bản thật. Chỉ đối chiếu từ khoá đơn giản trong câu bé vừa
/// gõ/nói với 1 danh sách câu hỏi-đáp đã soạn sẵn phía dưới, rồi chọn ngẫu
/// nhiên 1 câu trả lời phù hợp (hoặc 1 câu chung chung nếu không khớp từ
/// khoá nào). Vì KHÔNG có câu trả lời nào ngoài danh sách cố định này từng
/// được sinh ra, chế độ này an toàn tuyệt đối về nội dung - không cần
/// safetySettings hay System Prompt như [GeminiChatService].
///
/// Dùng làm "lưới an toàn" khi Gemini tạm thời không gọi được (mất mạng,
/// backend chưa cấu hình `GEMINI_API_KEY`, hết hạn mức...) - xem
/// [CompositeChatService].
///
/// Nhược điểm: bé chỉ "trò chuyện" được trong phạm vi các mẫu câu bên dưới,
/// không tự do và thông minh như AI thật.
class OfflineChatService implements ChatReplyService {
  final Random _random;

  OfflineChatService({Random? random}) : _random = random ?? Random();

  static final List<_Rule> _rules = [
    _Rule(['hello', 'hi there', ' hi ', 'hi!', 'hiya', 'hey'], [
      "Hi {child}! I'm {pet}! 🐰 How are you today?",
      "Hello there, {child}! So happy to see you!",
      "Hey {child}! I missed you!",
    ]),
    _Rule(['how are you'], [
      "I'm super happy! Thank you for asking! 😊 How are you?",
      "I feel great today! What about you?",
    ]),
    _Rule(['your name', "what's your name", 'who are you'], [
      "My name is {pet}! What is your name?",
      "I'm {pet}, your English learning friend!",
    ]),
    _Rule(['bye', 'goodbye', 'see you', 'good night', 'gtg'], [
      'Bye bye! See you soon! 👋',
      'Goodbye, friend! Come back and play with me again!',
    ]),
    _Rule(['love you', 'i like you', 'you are my friend', "you're my friend"], [
      'Aww, I love you too! You are my best friend! 💕',
      "That makes me so happy! You're my best friend too!",
    ]),
    _Rule(['favorite color', 'favourite colour', 'favorite colour', 'favourite color'], [
      'I love purple! What is your favorite color?',
      'My favorite color is pink! What about you?',
    ]),
    _Rule(['favorite animal', 'favourite animal'], [
      'I love bunnies and cats! What is your favorite animal?',
      'Rabbits are my favorite! Do you like animals too?',
    ]),
    _Rule(['how old', 'your age'], [
      "I'm a magical pet, I don't have an age! I'm always young at heart! 😄",
    ]),
    _Rule(['play', 'game', 'games'], [
      "Yes! Let's play a game! Go to the Play tab with me! 🎮",
      "I love playing! Let's go learn some new words in the Play tab!",
    ]),
    _Rule(['sad', 'cry', 'crying', "i'm sad", 'im sad'], [
      "Oh no, I'm sorry you feel sad. I'm here for you! 🤗",
      "Sending you a big hug! Want to talk about something fun?",
    ]),
    _Rule(['happy', 'excited', 'yay'], [
      "Yay! I'm happy too! 🎉",
      "That's wonderful! I'm excited too!",
    ]),
    _Rule(['thank you', 'thanks'], [
      "You're welcome! You are so kind! 😊",
      "No problem, friend! You're very welcome!",
    ]),
    _Rule(['sorry'], [
      "It's okay! Let's be friends again! 🤗",
      'No worries at all, friend!',
    ]),
    _Rule(['school'], ['I hope school is fun! What do you learn at school?']),
    _Rule(['family', 'mom', 'mother', 'dad', 'father', 'sister', 'brother'], [
      'Family is so special! Tell me about your family!',
    ]),
    _Rule(['food', 'hungry', 'eat', 'apple', 'banana'], [
      'Yummy! I like fruit too! What is your favorite food?',
    ]),
    _Rule(['weather', 'sunny', 'rainy', 'rain'], [
      'I hope the weather is nice today! Do you like sunny days?',
    ]),
    _Rule(['what can you do', 'help me', 'help'], [
      "I love to chat and cheer for you! For lessons, let's go to the Play tab together!",
    ]),
    _Rule(['funny', 'joke'], [
      'Haha! Why did the cat sit on the computer? Because it wanted to watch the mouse! 😄',
    ]),
  ];

  static const List<String> _fallbackReplies = [
    "That's interesting! Tell me more! 😊",
    'Wow! Can you tell me more about that?',
    'I like talking with you! What is your favorite animal?',
    "Let's learn a new word together! Go to the Play tab! 📚",
    "I'm still learning too! What else do you want to talk about?",
    'Cool! What else happened today?',
  ];

  @override
  Future<ChatReplyResult> sendMessage({
    required String petDisplayName,
    String? childName,
    required List<ChatMessage> history,
  }) async {
    final lastUserMessage = history.isEmpty
        ? null
        : history.lastWhere(
            (m) => m.role == ChatRole.user,
            orElse: () => history.last,
          );
    final normalized = ' ${(lastUserMessage?.text ?? '').toLowerCase()} ';
    // "there" khi chưa đặt tên riêng - đọc tự nhiên trong câu tiếng Anh kiểu
    // "Hi there!", khác với cách xưng hô chung chung tiếng Việt "bạn" dùng ở
    // những chỗ khác trong app (xem `ChildNameController.displayName`).
    final childWord = (childName == null || childName.trim().isEmpty) ? 'there' : childName.trim();

    for (final rule in _rules) {
      if (rule.keywords.any((k) => normalized.contains(k))) {
        final reply = rule.replies[_random.nextInt(rule.replies.length)];
        return ChatReplyResult.success(
          reply.replaceAll('{pet}', petDisplayName).replaceAll('{child}', childWord),
          viaOffline: true,
        );
      }
    }

    final reply = _fallbackReplies[_random.nextInt(_fallbackReplies.length)];
    return ChatReplyResult.success(
      reply.replaceAll('{pet}', petDisplayName).replaceAll('{child}', childWord),
      viaOffline: true,
    );
  }

  /// Chatbot offline chỉ đối chiếu từ khoá, KHÔNG hiểu ngôn ngữ thật, nên
  /// KHÔNG có khả năng phân tích ngữ pháp - luôn trả về null (xem
  /// [ChatReplyService.checkGrammar]).
  @override
  Future<String?> checkGrammar(String childText) async => null;

  /// Chatbot offline chỉ đối chiếu từ khoá, KHÔNG hiểu ngôn ngữ thật, nên
  /// KHÔNG có khả năng dịch - luôn trả về null (xem
  /// [ChatReplyService.translateToVietnamese]).
  @override
  Future<String?> translateToVietnamese(String englishText) async => null;
}
