import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/cloud_child_avatar_repository.dart';
import 'data/repositories/cloud_child_name_repository.dart';
import 'data/repositories/cloud_gem_reward_repository.dart';
import 'data/repositories/cloud_hearts_repository.dart';
import 'data/repositories/cloud_pet_character_repository.dart';
import 'data/repositories/cloud_pet_inventory_repository.dart';
import 'data/repositories/cloud_pet_palette_repository.dart';
import 'data/repositories/cloud_progress_repository.dart';
import 'data/repositories/cloud_streak_repository.dart';
import 'data/repositories/json_exam_repository.dart';
import 'data/repositories/json_lesson_repository.dart';
import 'data/repositories/json_picture_scene_repository.dart';
import 'domain/repositories/child_avatar_repository.dart';
import 'domain/repositories/child_name_repository.dart';
import 'domain/repositories/exam_repository.dart';
import 'domain/repositories/gem_reward_repository.dart';
import 'domain/repositories/hearts_repository.dart';
import 'domain/repositories/lesson_repository.dart';
import 'domain/repositories/pet_character_repository.dart';
import 'domain/repositories/pet_inventory_repository.dart';
import 'domain/repositories/pet_palette_repository.dart';
import 'domain/repositories/picture_scene_repository.dart';
import 'domain/repositories/progress_repository.dart';
import 'domain/repositories/streak_repository.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/root/root_shell.dart';
import 'presentation/state/chat_controller.dart';
import 'presentation/state/child_avatar_controller.dart';
import 'presentation/state/child_name_controller.dart';
import 'presentation/state/dictionary_controller.dart';
import 'presentation/state/exam_catalog_controller.dart';
import 'presentation/state/gem_reward_controller.dart';
import 'presentation/state/hearts_controller.dart';
import 'presentation/state/lessons_controller.dart';
import 'presentation/state/pet_character_controller.dart';
import 'presentation/state/pet_controller.dart';
import 'presentation/state/pet_inventory_controller.dart';
import 'presentation/state/pet_palette_controller.dart';
import 'presentation/state/picture_scenes_controller.dart';
import 'presentation/state/progress_controller.dart';
import 'presentation/state/streak_controller.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/chat_reply_service.dart';
import 'services/cloud_state_store.dart';
import 'services/composite_chat_service.dart';
import 'services/dictionary_service.dart';
import 'services/gemini_chat_service.dart';
import 'services/gemini_dictionary_service.dart';
import 'services/offline_chat_service.dart';
import 'services/sound_service.dart';
import 'services/speech_service.dart';
import 'services/tts_service.dart';

/// Composition root của app: đây là NƠI DUY NHẤT "biết" implementation cụ
/// thể phía sau các interface (ví dụ [CloudProgressRepository] cho
/// [ProgressRepository]). Toàn bộ UI/state phía dưới chỉ làm việc với
/// interface hoặc controller, không biết dữ liệu thực sự lưu ở đâu.
///
/// CẤU TRÚC 2 TẦNG (2026-09-16, thêm đăng nhập + đồng bộ cloud - xem
/// `deployment.md`): [MimiApp] chỉ đăng ký [ApiClient]/[AuthService] (không
/// phụ thuộc đã đăng nhập hay chưa) rồi giao cho [_AuthGate] quyết định hiện
/// [LoginScreen] hay [_AuthenticatedApp] (cây Provider ĐẦY ĐỦ, tương đương
/// toàn bộ app trước đây - chỉ khác các repository giờ đọc/ghi qua
/// [CloudStateStore] thay vì `SharedPreferences` trực tiếp) - cây này CHỈ
/// build SAU KHI đăng nhập, vì [CloudStateStore] cần gọi API kèm token.
///
/// QUAN TRỌNG: mỗi nhánh (đang tải/chưa đăng nhập/đã đăng nhập) tự tạo
/// `MaterialApp` RIÊNG, với MultiProvider của nhánh đó BỌC NGOÀI
/// `MaterialApp` (không đặt bên trong `home:`) - `Navigator` do `MaterialApp`
/// tạo ra PHẢI là CON của MultiProvider, không phải ngược lại. Lý do: mọi
/// route được `Navigator.push` (màn Bài học, Cài đặt, Thi thử, Bài tranh...)
/// được Flutter gắn vào `Overlay` của `Navigator` như 1 NHÁNH NGANG HÀNG với
/// route "home", KHÔNG phải hậu duệ của riêng nội dung route home - nên nếu
/// Provider chỉ bọc quanh `home:` (bên trong `MaterialApp`) thay vì bọc
/// quanh chính `MaterialApp`, mọi route được push sẽ KHÔNG thấy được
/// Provider đó (lỗi "Could not find the correct Provider" - đã gặp thực tế
/// khi mở Bài học sau lần refactor đầu tiên thêm đăng nhập).
class MimiApp extends StatelessWidget {
  const MimiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(
          create: (_) => ApiClient(),
          dispose: (_, client) => client.dispose(),
        ),
        ChangeNotifierProvider<AuthService>(
          create: (context) => AuthService(context.read<ApiClient>())..load(),
        ),
      ],
      child: const _AuthGate(),
    );
  }
}

/// Hiện [LoginScreen] khi chưa đăng nhập, hoặc [_AuthenticatedApp] khi đã
/// đăng nhập - lắng nghe [AuthService] để tự chuyển màn ngay khi trạng thái
/// đăng nhập đổi (không cần `Navigator.push` thủ công từ `LoginScreen`). Tự
/// tạo `MaterialApp` riêng cho 2 trạng thái "đang tải"/"chưa đăng nhập" (xem
/// ghi chú ở [MimiApp]) - trạng thái "đã đăng nhập" có `MaterialApp` RIÊNG
/// của nó trong [_AuthenticatedApp].
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!auth.loaded) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    if (!auth.isLoggedIn) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mimi English Pet',
        theme: AppTheme.light,
        home: const LoginScreen(),
      );
    }
    return const _AuthenticatedApp();
  }
}

/// Toàn bộ cây Provider phụ thuộc dữ liệu của bé - chỉ build SAU KHI đã đăng
/// nhập. Tự quản lý vòng đời [CloudStateStore] RIÊNG (StatefulWidget, không
/// dùng `Provider(create: ...)` bên trong `MultiProvider` như các provider
/// khác) để CHỜ [CloudStateStore.load] xong (nạp state từ server) TRƯỚC KHI
/// build các Controller phụ thuộc nó - thiếu bước chờ này, các Controller sẽ
/// đọc phải state RỖNG lúc mới khởi tạo (load() của CloudStateStore chạy bất
/// đồng bộ, không có gì tự động khiến Controller đọc lại sau khi nó xong).
class _AuthenticatedApp extends StatefulWidget {
  const _AuthenticatedApp();

  @override
  State<_AuthenticatedApp> createState() => _AuthenticatedAppState();
}

class _AuthenticatedAppState extends State<_AuthenticatedApp> {
  late final CloudStateStore _store;
  late final Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _store = CloudStateStore(context.read<ApiClient>());
    _loadFuture = _store.load();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        return Provider<CloudStateStore>.value(
          value: _store,
          child: MultiProvider(
            providers: [
              Provider<TtsService>(
                create: (_) => TtsService(),
                dispose: (_, service) => service.dispose(),
              ),
              Provider<SpeechService>(create: (_) => SpeechService()),
              Provider<SoundService>(create: (_) => SoundService()),
              Provider<GeminiChatService>(
                create: (context) => GeminiChatService(context.read<ApiClient>()),
              ),
              Provider<OfflineChatService>(create: (_) => OfflineChatService()),
              // ChatReplyService là interface ChatController thực sự dùng -
              // tự động chọn Gemini (AI thật, qua backend proxy) hoặc offline
              // (câu trả lời có sẵn), và tự chuyển sang offline khi Gemini
              // tạm thời lỗi (mất mạng...). Xem `composite_chat_service.dart`.
              Provider<ChatReplyService>(
                create: (context) => CompositeChatService(
                  gemini: context.read<GeminiChatService>(),
                  offline: context.read<OfflineChatService>(),
                ),
              ),
              Provider<GeminiDictionaryService>(
                create: (context) => GeminiDictionaryService(context.read<ApiClient>()),
              ),
              // DictionaryService là interface DictionaryController thực sự
              // dùng - hiện tại chỉ có 1 implementation thật (Gemini, không
              // có bản offline như Chat vì tra từ điển cần hiểu ngôn ngữ thật
              // sự - xem `dictionary_service.dart`), nhưng vẫn tách interface
              // riêng để nhất quán kiến trúc và dễ thay thế/mock sau này.
              Provider<DictionaryService>(create: (context) => context.read<GeminiDictionaryService>()),
              Provider<ProgressRepository>(
                create: (context) => CloudProgressRepository(context.read<CloudStateStore>()),
              ),
              Provider<PetCharacterRepository>(
                create: (context) => CloudPetCharacterRepository(context.read<CloudStateStore>()),
              ),
              Provider<PetPaletteRepository>(
                create: (context) => CloudPetPaletteRepository(context.read<CloudStateStore>()),
              ),
              Provider<PetInventoryRepository>(
                create: (context) => CloudPetInventoryRepository(context.read<CloudStateStore>()),
              ),
              Provider<ChildAvatarRepository>(
                create: (context) => CloudChildAvatarRepository(context.read<CloudStateStore>()),
              ),
              Provider<ChildNameRepository>(
                create: (context) => CloudChildNameRepository(context.read<CloudStateStore>()),
              ),
              Provider<HeartsRepository>(
                create: (context) => CloudHeartsRepository(context.read<CloudStateStore>()),
              ),
              Provider<GemRewardRepository>(
                create: (context) => CloudGemRewardRepository(context.read<CloudStateStore>()),
              ),
              Provider<StreakRepository>(
                create: (context) => CloudStreakRepository(context.read<CloudStateStore>()),
              ),
              Provider<LessonRepository>(create: (_) => JsonLessonRepository()),
              Provider<PictureSceneRepository>(create: (_) => JsonPictureSceneRepository()),
              Provider<ExamRepository>(create: (_) => JsonExamRepository()),
              ChangeNotifierProvider<PetController>(create: (_) => PetController()),
              ChangeNotifierProvider<ProgressController>(
                create: (context) => ProgressController(context.read<ProgressRepository>())..load(),
              ),
              ChangeNotifierProvider<PetCharacterController>(
                create: (context) => PetCharacterController(context.read<PetCharacterRepository>())..load(),
              ),
              ChangeNotifierProvider<PetPaletteController>(
                create: (context) => PetPaletteController(context.read<PetPaletteRepository>())..load(),
              ),
              ChangeNotifierProvider<PetInventoryController>(
                create: (context) => PetInventoryController(context.read<PetInventoryRepository>())..load(),
              ),
              ChangeNotifierProvider<ChildAvatarController>(
                create: (context) => ChildAvatarController(context.read<ChildAvatarRepository>())..load(),
              ),
              ChangeNotifierProvider<ChildNameController>(
                create: (context) => ChildNameController(context.read<ChildNameRepository>())..load(),
              ),
              ChangeNotifierProvider<HeartsController>(
                create: (context) => HeartsController(context.read<HeartsRepository>())..load(),
              ),
              ChangeNotifierProvider<GemRewardController>(
                create: (context) => GemRewardController(context.read<GemRewardRepository>())..load(),
              ),
              ChangeNotifierProvider<StreakController>(
                create: (context) => StreakController(context.read<StreakRepository>())..load(),
              ),
              ChangeNotifierProvider<LessonsController>(
                create: (context) => LessonsController(context.read<LessonRepository>())..load(),
              ),
              ChangeNotifierProvider<PictureScenesController>(
                create: (context) => PictureScenesController(context.read<PictureSceneRepository>())..load(),
              ),
              ChangeNotifierProvider<ExamCatalogController>(
                create: (context) => ExamCatalogController(context.read<ExamRepository>())..load(),
              ),
              // Đăng ký ở cấp app (không phải riêng tab Chat) để lịch sử hội
              // thoại không bị mất khi bé chuyển qua tab khác rồi quay lại
              // (IndexedStack ở RootShell giữ nguyên cây widget của mỗi tab,
              // nhưng Provider ở đây còn giúp state sống sót cả khi widget
              // tab bị rebuild).
              ChangeNotifierProvider<ChatController>(
                create: (context) => ChatController(
                  chatService: context.read<ChatReplyService>(),
                  ttsService: context.read<TtsService>(),
                  speechService: context.read<SpeechService>(),
                  petCharacterController: context.read<PetCharacterController>(),
                  childNameController: context.read<ChildNameController>(),
                ),
              ),
              ChangeNotifierProvider<DictionaryController>(
                create: (context) => DictionaryController(
                  service: context.read<DictionaryService>(),
                  ttsService: context.read<TtsService>(),
                  speechService: context.read<SpeechService>(),
                ),
              ),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Mimi English Pet',
              theme: AppTheme.light,
              home: const RootShell(),
            ),
          ),
        );
      },
    );
  }
}
