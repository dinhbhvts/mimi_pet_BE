import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/services/tts_service.dart';

/// Chỉnh 2 hồ sơ giọng đọc độc lập (xem [VoiceKind]): giọng của bé (bài học,
/// trò chuyện với thú cưng) và giọng TOEIC (luyện nghe thi thử của phụ
/// huynh), cùng tuỳ chọn đọc hội thoại bằng nhiều giọng. Lưu theo THIẾT BỊ.
class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    context.read<TtsService>().ensureLoaded().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tts = context.read<TtsService>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Giọng đọc & tốc độ'),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _ProfileCard(
                  kind: VoiceKind.kid,
                  title: '🧒 Giọng của bé',
                  subtitle: 'Bài học, trò chuyện với thú cưng, đề YLE',
                  sample: 'Hello! I am your pet. Let\'s learn English together!',
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 16),
                _ProfileCard(
                  kind: VoiceKind.toeic,
                  title: '💼 Giọng TOEIC',
                  subtitle: 'Luyện nghe & thi thử TOEIC, từ vựng màn chờ',
                  sample: 'Attention, passengers. The flight to Tokyo has been delayed by one hour.',
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                  child: SwitchListTile(
                    value: tts.dialogueVoicesEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) async {
                      await tts.setDialogueVoicesEnabled(v);
                      setState(() {});
                    },
                    title: const Text('Đọc hội thoại bằng nhiều giọng',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                      'Mỗi người nói (A/B, Man/Woman...) một giọng riêng - dễ phân biệt ai đang nói, '
                      'giống đề TOEIC Part 3 thật.',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => tts.speakScript(
                    'A: Hi, Tom. Did you finish the sales report? '
                    'B: Almost. I just need the numbers from Linda. '
                    'A: Great, please send it to me by noon.',
                    kind: VoiceKind.toeic,
                  ),
                  icon: const Icon(Icons.record_voice_over_rounded),
                  label: const Text('Nghe thử 1 đoạn hội thoại'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Giọng đọc có sẵn khác nhau theo máy/trình duyệt (Chrome, Safari, Android...). '
                  'Nếu máy chỉ có 1 giọng tiếng Anh, app đổi CAO ĐỘ để phân biệt người nói. '
                  'Cài đặt lưu riêng trên thiết bị này.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final VoiceKind kind;
  final String title;
  final String subtitle;
  final String sample;
  final VoidCallback onChanged;

  const _ProfileCard({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.sample,
    required this.onChanged,
  });

  String _speedLabel(double speed) => '${(speed * 100).round()}%';

  String _pitchLabel(double pitch) {
    if (pitch < 0.9) return 'Trầm';
    if (pitch <= 1.1) return 'Vừa';
    return 'Cao';
  }

  @override
  Widget build(BuildContext context) {
    final tts = context.read<TtsService>();
    final profile = tts.profile(kind);
    final isDefault = profile.speed == TtsService.defaults[kind]!.speed &&
        profile.pitch == TtsService.defaults[kind]!.pitch;

    Future<void> update(VoiceProfile value) async {
      await tts.setProfile(kind, value);
      onChanged();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 70, child: Text('Tốc độ')),
              Expanded(
                child: Slider(
                  value: profile.speed,
                  min: TtsService.minSpeed,
                  max: TtsService.maxSpeed,
                  divisions: 30,
                  label: _speedLabel(profile.speed),
                  activeColor: AppColors.primary,
                  onChanged: (v) => update(profile.copyWith(speed: v)),
                ),
              ),
              SizedBox(width: 48, child: Text(_speedLabel(profile.speed), textAlign: TextAlign.end)),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 70, child: Text('Cao độ')),
              Expanded(
                child: Slider(
                  value: profile.pitch,
                  min: 0.6,
                  max: 1.6,
                  divisions: 20,
                  label: _pitchLabel(profile.pitch),
                  activeColor: AppColors.primary,
                  onChanged: (v) => update(profile.copyWith(pitch: v)),
                ),
              ),
              SizedBox(width: 48, child: Text(_pitchLabel(profile.pitch), textAlign: TextAlign.end)),
            ],
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => tts.speak(sample, kind: kind),
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Nghe thử'),
              ),
              const Spacer(),
              TextButton(
                onPressed: isDefault ? null : () => update(TtsService.defaults[kind]!),
                child: const Text('Mặc định'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
