import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mimi_pet/core/platform/platform_info.dart';
import 'package:mimi_pet/domain/entities/chat_message.dart';
import 'package:mimi_pet/domain/entities/pet_character.dart';
import 'package:mimi_pet/domain/repositories/child_name_repository.dart';
import 'package:mimi_pet/domain/repositories/pet_character_repository.dart';
import 'package:mimi_pet/presentation/state/chat_controller.dart';
import 'package:mimi_pet/presentation/state/child_name_controller.dart';
import 'package:mimi_pet/presentation/state/pet_character_controller.dart';
import 'package:mimi_pet/presentation/widgets/ios_web_tips.dart';
import 'package:mimi_pet/services/chat_reply_service.dart';
import 'package:mimi_pet/services/gemini_chat_service.dart';
import 'package:mimi_pet/services/offline_chat_service.dart';
import 'package:mimi_pet/services/speech_service.dart';
import 'package:mimi_pet/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ChatController build(_MemHistory history, {_FakeChat? chat}) => ChatController(
    chatService: chat ?? _FakeChat(),
    ttsService: _SilentTts(),
    speechService: SpeechService(),
    petCharacterController: PetCharacterController(_PetRepo()),
    childNameController: ChildNameController(_NameRepo()),
    historyStorage: history,
  );

  group('Lịch sử chat', () {
    test('ChatMessage toJson/fromJson giữ đủ thông tin, dữ liệu hỏng thì bỏ qua', () {
      final m = ChatMessage(
        role: ChatRole.pet,
        text: 'Hi!',
        sentAt: DateTime.fromMillisecondsSinceEpoch(1000),
        viaOffline: true,
        translatedText: 'Chào!',
      );
      final back = ChatMessage.fromJson(m.toJson())!;
      expect(back.role, ChatRole.pet);
      expect(back.text, 'Hi!');
      expect(back.sentAt, m.sentAt);
      expect(back.viaOffline, isTrue);
      expect(back.translatedText, 'Chào!');
      expect(back.grammarNote, isNull);
      expect(ChatMessage.fromJson({'r': 'alien', 't': 'x', 'at': 1}), isNull);
      expect(ChatMessage.fromJson('rác'), isNull);
    });

    test('gửi tin thì lưu cả câu của bé, câu trả lời và gợi ý ngữ pháp; mở lại vẫn còn', () async {
      final history = _MemHistory();
      final chat = build(history);
      await chat.sendText('I has a dog');
      await pumpEventQueue();
      expect(history.saved.length, 2);
      expect(history.saved.first['g'], 'I have a dog!');

      final reopened = build(history);
      expect(reopened.messages.map((m) => m.text), ['I has a dog', 'Reply 1']);
      expect(reopened.messages.first.grammarNote, 'I have a dog!');
    });

    test('chỉ lưu ${ChatController.maxStoredMessages} tin gần nhất', () async {
      final history = _MemHistory();
      final chat = build(history);
      for (var i = 0; i < 25; i++) {
        await chat.sendText('message $i');
      }
      expect(chat.messages.length, 50);
      expect(history.saved.length, ChatController.maxStoredMessages);
      expect(build(history).messages.last.text, 'Reply 25');
    });

    test('xoá cuộc trò chuyện; gợi ý ngữ pháp về muộn sau khi xoá thì bỏ qua', () async {
      final history = _MemHistory();
      final slow = _FakeChat(grammarGate: Completer<void>());
      final chat = build(history, chat: slow);
      await chat.sendText('I has a cat');
      await chat.clearHistory();
      expect(chat.messages, isEmpty);
      expect(history.saved, isEmpty);
      slow.grammarGate!.complete();
      await pumpEventQueue();
      expect(chat.messages, isEmpty);
      expect(history.saved, isEmpty);
    });
  });

  group('Gộp 1 lượt gọi AI (trả lời + dịch + ngữ pháp + gợi ý)', () {
    const json = '{"reply":"I love cats too! 🐱","reply_vi":"Mình cũng thích mèo! 🐱",'
        '"grammar_tip":"You can say: I have a cat!","suggestions":["My cat is white."," Do you like dogs? ",'
        '"my cat is white.","","Let us play!","Extra one"]}';

    test('đọc đủ các phần; bỏ gợi ý trùng/rỗng, tối đa 3', () {
      final r = GeminiChatService.parseCombinedReply(json, childText: 'I has a cat');
      expect(r.reply, 'I love cats too! 🐱');
      expect(r.translation, 'Mình cũng thích mèo! 🐱');
      expect(r.grammarChecked, isTrue);
      expect(r.grammarTip, 'You can say: I have a cat!');
      expect(r.suggestions, ['My cat is white.', 'Do you like dogs?', 'Let us play!']);
    });

    test('câu của bé quá ngắn (dưới 3 từ) thì không hiện gợi ý ngữ pháp', () {
      final r = GeminiChatService.parseCombinedReply(json, childText: 'cats');
      expect(r.grammarTip, isNull);
      expect(r.grammarChecked, isTrue);
    });

    test('JSON bọc trong ```json``` vẫn đọc được', () {
      final r = GeminiChatService.parseCombinedReply('```json\n$json\n```', childText: 'I has a cat');
      expect(r.reply, 'I love cats too! 🐱');
    });

    test('chữ thường (không phải JSON) -> dùng nguyên văn, ngữ pháp kiểm tra riêng như cũ', () {
      final r = GeminiChatService.parseCombinedReply('Hello friend!', childText: 'hi there you');
      expect(r.reply, 'Hello friend!');
      expect(r.grammarChecked, isFalse);
      expect(r.suggestions, isEmpty);
    });

    test('JSON bị cắt dở -> chỉ lấy câu trả lời, KHÔNG hiện chuỗi JSON thô cho bé', () {
      final r = GeminiChatService.parseCombinedReply('{"reply":"Hi \\"buddy\\"!","reply_vi":"Chà', childText: 'hello');
      expect(r.reply, 'Hi "buddy"!');
      expect(GeminiChatService.parseCombinedReply('{"reply_vi":"Chà', childText: 'x').isSuccess, isFalse);
    });

    test('controller: dùng luôn bản dịch + ngữ pháp có sẵn, không gọi thêm AI', () async {
      final fake = _FakeChat(combined: true);
      final chat = build(_MemHistory(), chat: fake);
      expect(chat.suggestions, ChatController.starterSuggestions);
      await chat.sendText('I has a dog');
      await pumpEventQueue();
      expect(fake.grammarCalls, 0);
      expect(fake.translateCalls, 0);
      expect(chat.messages.first.grammarNote, 'Say: I have a dog!');
      expect(chat.messages.last.translatedText, 'Trả lời 1');
      expect(chat.suggestions, ['Yes!', 'Why?']);
      await chat.toggleTranslate(1);
      expect(chat.isTranslationVisible(1), isTrue);
      expect(fake.translateCalls, 0, reason: 'đã có bản dịch -> hiện ngay');
    });

    test('chatbot offline cũng có 3 câu gợi ý', () async {
      final r = await OfflineChatService().sendMessage(petDisplayName: 'Mimi', history: [
        ChatMessage(role: ChatRole.user, text: 'hello', sentAt: DateTime(2026)),
      ]);
      expect(r.suggestions.length, 3);
      expect(r.suggestions.every(OfflineChatService.suggestionPool.contains), isTrue);
    });
  });

  group('Bản nháp giọng nói & câu gợi ý', () {
    test('chế độ nói: chạm gợi ý -> vào bản nháp; bé sửa rồi mới gửi', () async {
      final chat = build(_MemHistory());
      chat.setInputMode(ChatInputMode.voice);
      chat.useSuggestion('I like cats.');
      expect(chat.voiceDraft, 'I like cats.');
      await chat.sendVoiceDraft('I like big cats.');
      expect(chat.voiceDraft, isNull);
      expect(chat.messages.first.text, 'I like big cats.');
    });

    test('bỏ bản nháp / gửi bản nháp rỗng thì không gửi gì', () async {
      final chat = build(_MemHistory());
      chat.setInputMode(ChatInputMode.voice);
      chat.useSuggestion('Hello!');
      chat.discardVoiceDraft();
      expect(chat.voiceDraft, isNull);
      chat.useSuggestion('Hello!');
      await chat.sendVoiceDraft('   ');
      expect(chat.messages, isEmpty);
    });

    test('chế độ gõ: chạm gợi ý không tạo bản nháp (màn hình tự điền ô nhập)', () {
      final chat = build(_MemHistory());
      chat.useSuggestion('Hello!');
      expect(chat.voiceDraft, isNull);
    });
  });

  group('Mic trên Safari iOS', () {
    test('iOS web: 1 phiên, không nghe liên tục, không tự mở lại phiên', () {
      final ios = SpeechService.planFor(isIosWeb: true, allowContinuation: true);
      expect(ios.partialResults, isFalse);
      expect(ios.allowContinuation, isFalse);
    });

    test('nơi khác giữ nguyên hành vi cũ', () {
      final android = SpeechService.planFor(isIosWeb: false, allowContinuation: true);
      expect(android.partialResults, isTrue);
      expect(android.allowContinuation, isTrue);
      expect(SpeechService.planFor(isIosWeb: false, allowContinuation: false).allowContinuation, isFalse);
    });
  });

  testWidgets('thẻ mẹo iPhone: chỉ hiện trên iOS web, bấm ✕ thì ẩn hẳn (lần sau không hiện lại)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() => PlatformInfo.debugIsIosWebOverride = null);

    PlatformInfo.debugIsIosWebOverride = false;
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: IosWebTipsBanner())));
    await tester.pumpAndSettle();
    expect(find.textContaining('iPhone/iPad'), findsNothing);

    PlatformInfo.debugIsIosWebOverride = true;
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: IosWebTipsBanner(key: ValueKey('ios')))));
    await tester.pumpAndSettle();
    expect(find.textContaining('iPhone/iPad'), findsOneWidget);

    await tester.tap(find.textContaining('iPhone/iPad'));
    await tester.pumpAndSettle();
    expect(find.text('Đã hiểu'), findsOneWidget);
    await tester.tap(find.text('Đã hiểu'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ẩn'));
    await tester.pumpAndSettle();
    expect(find.textContaining('iPhone/iPad'), findsNothing);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: IosWebTipsBanner(key: ValueKey('again')))));
    await tester.pumpAndSettle();
    expect(find.textContaining('iPhone/iPad'), findsNothing);
  });

  test('mẹo iPhone: đã mở từ Màn hình chính thì không nhắc thêm vào Màn hình chính', () {
    final inSafari = iosWebTips(standalone: false);
    final installed = iosWebTips(standalone: true);
    expect(inSafari.first.title, contains('Màn hình chính'));
    expect(installed.any((t) => t.title.contains('Màn hình chính')), isFalse);
    expect(installed.length, inSafari.length - 1);
  });
}

class _MemHistory implements ChatHistoryStorage {
  List<Map<String, dynamic>> saved = [];

  @override
  List<dynamic> load() => saved;

  @override
  void save(List<Map<String, dynamic>> messages) => saved = messages;
}

class _FakeChat implements ChatReplyService {
  _FakeChat({this.grammarGate, this.combined = false});

  final Completer<void>? grammarGate;

  /// true = giả lập Gemini trả JSON gộp (dịch + ngữ pháp + gợi ý).
  final bool combined;
  int _n = 0;
  int grammarCalls = 0;
  int translateCalls = 0;

  @override
  Future<ChatReplyResult> sendMessage({
    required String petDisplayName,
    String? childName,
    required List<ChatMessage> history,
  }) async {
    final n = ++_n;
    if (!combined) return ChatReplyResult.success('Reply $n');
    return ChatReplyResult.success(
      'Reply $n',
      translation: 'Trả lời $n',
      grammarTip: 'Say: I have a dog!',
      grammarChecked: true,
      suggestions: const ['Yes!', 'Why?'],
    );
  }

  @override
  Future<String?> checkGrammar(String childText) async {
    grammarCalls++;
    if (grammarGate != null) await grammarGate!.future;
    return childText.contains(' has ') ? childText.replaceAll(' has ', ' have ').replaceFirst(RegExp(r'$'), '!') : null;
  }

  @override
  Future<String?> translateToVietnamese(String englishText) async {
    translateCalls++;
    return null;
  }
}

class _SilentTts extends TtsService {
  @override
  Future<void> speak(String text, {VoiceKind kind = VoiceKind.kid, double speed = 1.0}) async {}

  @override
  Future<void> stop() async {}
}

class _PetRepo implements PetCharacterRepository {
  @override
  Future<PetCharacter> getSelected() async => PetCharacter.values.first;

  @override
  Future<void> setSelected(PetCharacter character) async {}
}

class _NameRepo implements ChildNameRepository {
  @override
  Future<String?> getName() async => null;

  @override
  Future<void> setName(String? name) async {}
}
