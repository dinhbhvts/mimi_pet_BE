import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mimi_pet/core/theme/app_colors.dart';
import 'package:mimi_pet/domain/entities/child_avatar.dart';
import 'package:mimi_pet/domain/entities/pet_character.dart';
import 'package:mimi_pet/presentation/state/child_avatar_controller.dart';
import 'package:mimi_pet/presentation/state/child_name_controller.dart';
import 'package:mimi_pet/presentation/state/gem_reward_controller.dart';
import 'package:mimi_pet/presentation/state/pet_character_controller.dart';
import 'package:mimi_pet/presentation/state/pet_inventory_controller.dart';
import 'package:mimi_pet/presentation/state/progress_controller.dart';
import 'package:mimi_pet/services/api_client.dart';
import 'package:mimi_pet/services/auth_service.dart';
import 'package:mimi_pet/services/tts_service.dart';

/// Màn hình cài đặt: kiểm tra giọng nói, làm lại từ đầu, thông tin app.
/// Cố tình để rất tối giản cho MVP - dễ mở rộng thêm mục sau (chọn giọng
/// đọc, chọn nhân vật, phụ huynh xem báo cáo tiến độ...).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final progress = context.read<ProgressController>();
    final inventory = context.read<PetInventoryController>();
    final gems = context.read<GemRewardController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Làm lại từ đầu?'),
        content: const Text(
          'Toàn bộ sao, từ đã học, phụ kiện đang mặc và mốc ngọc đã nhận sẽ bị '
          'xoá. Bạn chắc chắn chứ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await progress.resetProgress();
      // Cởi hết phụ kiện đang mặc - tránh còn hiển thị món đã mở khoá bằng
      // số sao vừa bị xoá về 0 (xem `PetInventoryController.resetEquipped`).
      await inventory.resetEquipped();
      // Đưa số viên ngọc ĐÃ NHẬN về 0 - tránh "vượt trước" số sao mới kiếm
      // lại được (xem doc comment `GemRewardController.resetClaimed`).
      await gems.resetClaimed();
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final auth = context.read<AuthService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn cần đăng nhập lại bằng tên đăng nhập và mật khẩu để dùng tiếp.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (confirmed == true) {
      await auth.logout();
    }
  }

  void _openChangePasswordDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => const _ChangePasswordDialog(),
    );
  }

  /// Mở bottom sheet cho bé chọn avatar riêng - emoji có sẵn hoặc ảnh từ máy
  /// (xem [ChildAvatarController]). Dùng `context.read` bên trong sheet (qua
  /// `builder`) để luôn lấy đúng controller hiện tại, không cần truyền tay.
  void _openAvatarPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => const _AvatarPickerSheet(),
    );
  }

  /// Mở dialog nhập/sửa TÊN RIÊNG của bé (xem [ChildNameController]) - thú
  /// cưng sẽ dùng tên này để gọi bé khi trò chuyện (Chat, và 1 số câu chào ở
  /// Home) thay vì chỉ xưng hô chung chung. Dùng `context.read` bên trong
  /// builder để luôn thao tác đúng controller hiện tại.
  Future<void> _openNamePicker(BuildContext context) async {
    final controller = context.read<ChildNameController>();
    final textController = TextEditingController(text: controller.name ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tên riêng của bé'),
        content: TextField(
          controller: textController,
          autofocus: true,
          maxLength: 20,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Ví dụ: Bông',
            counterText: '',
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(''),
            child: const Text('Xoá tên'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(textController.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    textController.dispose();
    // null nghĩa là bấm "Huỷ" (hoặc bấm ra ngoài) - giữ nguyên tên cũ, KHÔNG
    // gọi setName. Chuỗi rỗng (kể cả từ "Xoá tên") thì [ChildNameController.
    // setName] tự hiểu là xoá.
    if (result == null) return;
    await controller.setName(result);
  }

  @override
  Widget build(BuildContext context) {
    final characterName = PetCharacterInfo.all[context.watch<PetCharacterController>().character]!.displayName;
    final childAvatar = context.watch<ChildAvatarController>().avatar;
    final childName = context.watch<ChildNameController>().name;
    final username = context.watch<AuthService>().username;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsTile(
            icon: Icons.account_circle_rounded,
            title: 'Tài khoản',
            subtitle: username == null ? 'Đang đăng nhập' : 'Đang đăng nhập: $username',
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.lock_reset_rounded,
            title: 'Đổi mật khẩu',
            subtitle: 'Đổi mật khẩu đang dùng cho tài khoản này',
            onTap: () => _openChangePasswordDialog(context),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: 'Đăng xuất',
            subtitle: 'Thoát khỏi tài khoản hiện tại trên thiết bị này',
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            leading: _AvatarPreview(avatar: childAvatar, size: 28),
            title: 'Avatar của bé',
            subtitle: 'Chọn emoji hoặc ảnh riêng, hiển thị cạnh tin nhắn ở Chat',
            onTap: () => _openAvatarPicker(context),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.badge_rounded,
            title: 'Tên riêng của bé',
            subtitle: childName == null || childName.isEmpty
                ? 'Chưa đặt - thú cưng đang gọi chung là "bạn"'
                : 'Thú cưng sẽ gọi bé là "$childName"',
            onTap: () => _openNamePicker(context),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.mic_rounded,
            title: 'Kiểm tra micro & giọng nói',
            subtitle: '$characterName sẽ nói thử một câu tiếng Anh',
            onTap: () => context.read<TtsService>().speak('Hello! Can you hear me?'),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.refresh_rounded,
            title: 'Làm lại từ đầu',
            subtitle: 'Xoá toàn bộ sao và từ đã học',
            onTap: () => _confirmReset(context),
          ),
          const SizedBox(height: 12),
          const _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Về Mimi',
            subtitle: 'Mimi English Pet - vừa chơi vừa học tiếng Anh cùng thú cưng',
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  /// Icon Material đơn giản - dùng khi KHÔNG truyền [leading] (hầu hết các
  /// mục cài đặt cũ). Bỏ trống nếu đã truyền [leading].
  final IconData? icon;

  /// Widget tuỳ ý thay cho [icon] - dùng cho mục "Avatar của bé" để hiện
  /// đúng avatar hiện tại (emoji/ảnh) thay vì 1 icon Material cố định.
  final Widget? leading;

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    this.icon,
    this.leading,
    required this.title,
    required this.subtitle,
    this.onTap,
  }) : assert(icon != null || leading != null, 'Cần icon hoặc leading');

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              leading ?? Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hình tròn nhỏ hiện avatar HIỆN TẠI của bé (emoji hoặc ảnh) - dùng làm
/// "leading" cho mục "Avatar của bé" ở Cài đặt, và làm avatar đang được
/// chọn (viền đậm) trong [_AvatarPickerSheet]. Nếu ảnh lỗi/không đọc được,
/// tự rơi về hiện emoji mặc định thay vì icon lỗi xấu xí.
class _AvatarPreview extends StatelessWidget {
  final ChildAvatar avatar;
  final double size;
  final bool selected;

  const _AvatarPreview({required this.avatar, required this.size, this.selected = false});

  @override
  Widget build(BuildContext context) {
    // base64Decode ném lỗi NGAY (đồng bộ) nếu chuỗi hỏng - KHÔNG được
    // `Image.memory`'s errorBuilder bắt (errorBuilder chỉ bắt lỗi xảy ra
    // trong lúc tải/vẽ ảnh, không bắt lỗi lúc decode bytes đầu vào) - phải tự
    // try/catch ở đây để tránh crash cả màn hình vì 1 chuỗi base64 hỏng.
    Uint8List? photoBytes;
    if (avatar.kind == ChildAvatarKind.photo) {
      try {
        photoBytes = base64Decode(avatar.value);
      } catch (_) {
        photoBytes = null;
      }
    }

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F0FF),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFF8B6FD9) : Colors.transparent,
          width: 2.5,
        ),
      ),
      alignment: Alignment.center,
      child: photoBytes != null
          ? Image.memory(
              photoBytes,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (context, error, stackTrace) =>
                  Text('🧒', style: TextStyle(fontSize: size * 0.55)),
            )
          : Text(
              avatar.kind == ChildAvatarKind.photo ? '🧒' : avatar.value,
              style: TextStyle(fontSize: size * 0.55),
            ),
    );
  }
}

/// Nội dung bottom sheet "Avatar của bé" - lưới emoji có sẵn để chọn nhanh,
/// cộng 1 nút mở thư viện ảnh của máy (package `image_picker`, xem
/// [ChildAvatarController.pickPhoto]). Avatar đang chọn được viền tím đậm,
/// giống cách Home đánh dấu nhân vật/màu đang chọn.
class _AvatarPickerSheet extends StatelessWidget {
  const _AvatarPickerSheet();

  Future<void> _handlePickPhoto(BuildContext context) async {
    final controller = context.read<ChildAvatarController>();
    // Không cần phân biệt "bấm huỷ" hay "lỗi" (quyền bị từ chối, plugin
    // lỗi...) - cả 2 đều trả về false và đều nên coi là "không có gì thay
    // đổi", tránh làm phiền bé/phụ huynh bằng thông báo lỗi kỹ thuật không
    // cần thiết (xem [ChildAvatarController.pickPhoto]).
    await controller.pickPhoto();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChildAvatarController>();
    final current = controller.avatar;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Avatar của bé 🧑',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Chọn 1 emoji hoặc dùng ảnh riêng - avatar sẽ hiện cạnh tin nhắn của bé ở Chat.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Material(
              color: const Color(0xFFF6F0FF),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _handlePickPhoto(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Row(
                    children: [
                      _AvatarPreview(avatar: current, size: 40, selected: current.kind == ChildAvatarKind.photo),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          '📷 Chọn ảnh từ máy',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hoặc chọn emoji có sẵn',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: curatedChildAvatarEmojis.map((emoji) {
                final selected = current.kind == ChildAvatarKind.emoji && current.value == emoji;
                return GestureDetector(
                  onTap: () => controller.selectEmoji(emoji),
                  child: _AvatarPreview(
                    avatar: ChildAvatar(kind: ChildAvatarKind.emoji, value: emoji),
                    size: 46,
                    selected: selected,
                  ),
                );
              }).toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog đổi mật khẩu tài khoản đang đăng nhập (mục "Đổi mật khẩu" ở Cài
/// đặt) - yêu cầu nhập đúng mật khẩu hiện tại (xác nhận lại danh tính, tránh
/// người khác cầm máy đã mở sẵn app đổi trộm mật khẩu), mật khẩu mới phải
/// nhập 2 lần khớp nhau (tránh gõ nhầm rồi tự khoá mình khỏi tài khoản).
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final oldPassword = _oldController.text;
    final newPassword = _newController.text;
    final confirm = _confirmController.text;
    if (oldPassword.isEmpty || newPassword.isEmpty) {
      setState(() => _error = 'Nhập đủ mật khẩu hiện tại và mật khẩu mới.');
      return;
    }
    if (newPassword.length < 6) {
      setState(() => _error = 'Mật khẩu mới cần ít nhất 6 ký tự.');
      return;
    }
    if (newPassword != confirm) {
      setState(() => _error = 'Mật khẩu mới nhập lại không khớp.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().changePassword(oldPassword, newPassword);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đổi mật khẩu thành công.')),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Không đổi được mật khẩu. Kiểm tra kết nối mạng rồi thử lại.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đổi mật khẩu'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _oldController,
              obscureText: true,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newController,
              obscureText: true,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: true,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu mới'),
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
        TextButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Đổi mật khẩu'),
        ),
      ],
    );
  }
}
