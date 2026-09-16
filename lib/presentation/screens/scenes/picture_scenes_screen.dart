import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/domain/entities/picture_scene.dart';
import 'package:mimi_pet/presentation/screens/scenes/picture_scene_play_screen.dart';
import 'package:mimi_pet/presentation/state/picture_scenes_controller.dart';
import 'package:mimi_pet/presentation/state/progress_controller.dart';
import 'package:mimi_pet/presentation/state/scene_play_controller.dart';
import 'package:mimi_pet/presentation/widgets/scene_illustrations.dart';
import 'package:mimi_pet/services/sound_service.dart';
import 'package:mimi_pet/services/speech_service.dart';
import 'package:mimi_pet/services/tts_service.dart';

/// Màn hình danh sách "Bài tranh" - mở từ 1 thẻ riêng ở Home (KHÔNG phải tab
/// mới ở thanh dưới, xem `HomeScreen`), tách biệt hoàn toàn với con đường
/// bài học từ vựng ở tab Play theo đúng lựa chọn của người dùng.
///
/// Mỗi "bài tranh" (xem [PictureScene]) là 1 khung cảnh minh hoạ kèm nhiều
/// câu hỏi tiếng Anh xoay quanh khung cảnh đó - giúp bé luyện HIỂU CÂU/miêu
/// tả cảnh vật, gần với dạng bài "miêu tả tranh" trong đề thi Cambridge YLE
/// Movers/Flyers, khác với Play (từ vựng đơn lẻ).
class PictureScenesScreen extends StatelessWidget {
  const PictureScenesScreen({super.key});

  void _openScene(BuildContext context, PictureScene scene) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => ChangeNotifierProvider<ScenePlayController>(
          create: (providerContext) => ScenePlayController(
            scene: scene,
            ttsService: providerContext.read<TtsService>(),
            speechService: providerContext.read<SpeechService>(),
            progressController: providerContext.read<ProgressController>(),
            soundService: providerContext.read<SoundService>(),
          )..start(),
          child: const PictureScenePlayScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scenesCtrl = context.watch<PictureScenesController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Bài tranh 🖼️', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (!scenesCtrl.loaded) {
              return const Center(child: CircularProgressIndicator());
            }
            if (scenesCtrl.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    scenesCtrl.error!,
                    style: const TextStyle(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final scenes = scenesCtrl.scenes;
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              itemCount: scenes.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Xem tranh, nghe Mimi hỏi và trả lời bằng tiếng Anh nhé!',
                      style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                    ),
                  );
                }
                final scene = scenes[index - 1];
                return _SceneCard(scene: scene, onTap: () => _openScene(context, scene));
              },
            );
          },
        ),
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  final PictureScene scene;
  final VoidCallback onTap;

  const _SceneCard({required this.scene, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                child: SceneIllustration(illustrationId: scene.illustrationId),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene.title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scene.titleVi,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${scene.questions.length} câu hỏi',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
