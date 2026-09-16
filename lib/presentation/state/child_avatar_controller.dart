import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/child_avatar.dart';
import '../../domain/repositories/child_avatar_repository.dart';

/// Quản lý avatar CỦA BÉ (khác avatar thú cưng - xem
/// `pet_character_controller.dart`) - đọc/lưu qua [ChildAvatarRepository],
/// và xử lý luồng CHỌN ẢNH TỪ MÁY (package `image_picker`): ảnh được đọc
/// thành bytes qua `XFile.readAsBytes()` rồi mã hoá base64 lưu thẳng vào
/// state đồng bộ (backend) - CHẠY ĐƯỢC TRÊN MỌI NỀN TẢNG kể cả web (khác
/// cách cũ dùng `dart:io File` + `path_provider` để sao chép file vào thư
/// mục lưu trữ lâu dài, chỉ chạy được trên Android/iOS/desktop, KHÔNG có
/// `dart:io` trên web). Lợi ích phụ: ảnh avatar giờ tự động đồng bộ giữa
/// các thiết bị cùng tài khoản, không cần xử lý gì thêm.
class ChildAvatarController extends ChangeNotifier {
  ChildAvatarController(this._repository, {ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ChildAvatarRepository _repository;
  final ImagePicker _imagePicker;

  ChildAvatar _avatar = ChildAvatar.fallback;
  bool _loaded = false;

  ChildAvatar get avatar => _avatar;
  bool get loaded => _loaded;

  Future<void> load() async {
    _avatar = await _repository.getAvatar();
    _loaded = true;
    notifyListeners();
  }

  /// Bé chọn 1 emoji có sẵn (xem `curatedChildAvatarEmojis`) làm avatar.
  Future<void> selectEmoji(String emoji) async {
    final next = ChildAvatar(kind: ChildAvatarKind.emoji, value: emoji);
    _avatar = next;
    notifyListeners();
    await _repository.setAvatar(next);
  }

  /// Mở thư viện ảnh của máy để chọn 1 ảnh làm avatar - trả về true nếu chọn
  /// thành công (đã lưu), false nếu bấm huỷ hoặc có lỗi (quyền truy cập ảnh
  /// bị từ chối, plugin lỗi...). KHÔNG throw ra ngoài - lỗi được coi như
  /// "huỷ" để không làm crash màn Cài đặt (giống nguyên tắc try/catch/finally
  /// đã áp dụng cho `SpeechService` ở `HomeScreen._handleTalkPressed`).
  Future<bool> pickPhoto() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return false;

      final bytes = await picked.readAsBytes();
      final next = ChildAvatar(kind: ChildAvatarKind.photo, value: base64Encode(bytes));
      _avatar = next;
      notifyListeners();
      await _repository.setAvatar(next);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> resetToDefault() async {
    _avatar = ChildAvatar.fallback;
    notifyListeners();
    await _repository.setAvatar(_avatar);
  }
}
