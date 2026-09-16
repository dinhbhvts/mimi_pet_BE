import 'package:flutter/foundation.dart';

import '../../domain/repositories/child_name_repository.dart';

/// Quản lý TÊN RIÊNG của bé - đọc/lưu qua [ChildNameRepository], dùng để thú
/// cưng gọi tên bé khi tương tác (Chat, Home...) thay vì chỉ xưng hô chung
/// chung "bạn"/"con". Giữ đơn giản, cùng pattern với [ChildAvatarController]
/// (load 1 lần lúc khởi động app, các thay đổi sau đó qua [setName]).
class ChildNameController extends ChangeNotifier {
  ChildNameController(this._repository);

  final ChildNameRepository _repository;

  String? _name;
  bool _loaded = false;

  /// null nghĩa là chưa đặt tên - dùng [displayName] để có sẵn cách xưng hô
  /// mặc định thay vì phải tự kiểm tra null ở khắp nơi gọi tới.
  String? get name => _name;
  bool get loaded => _loaded;

  /// Cách gọi bé dùng trong câu thoại của thú cưng - tên riêng nếu đã đặt,
  /// hoặc "bạn" (xưng hô chung chung, thân thiện, trung tính) nếu chưa.
  String get displayName => (_name == null || _name!.trim().isEmpty) ? 'bạn' : _name!.trim();

  Future<void> load() async {
    _name = await _repository.getName();
    _loaded = true;
    notifyListeners();
  }

  /// Truyền chuỗi rỗng hoặc null để XOÁ tên đã đặt (quay lại xưng hô chung
  /// chung).
  Future<void> setName(String? name) async {
    final trimmed = name?.trim();
    _name = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    notifyListeners();
    await _repository.setName(_name);
  }
}
