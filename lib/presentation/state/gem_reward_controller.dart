import 'package:flutter/foundation.dart';

import '../../domain/repositories/gem_reward_repository.dart';

/// Quản lý mốc thưởng "viên ngọc" 💎 - mốc thưởng LỚN, quy đổi ra TIỀN THẬT
/// (bố thưởng ngoài app), nằm TRÊN cửa hàng phụ kiện (xem `pet_accessory.dart`
/// - phụ kiện đeo được, tối đa 80 sao) để bé không "phá đảo" hết mọi phần
/// thưởng chỉ sau vài ngày học.
///
/// THIẾT KẾ CỐ Ý KHÁC [PetAccessoryInfo] (danh sách CỐ ĐỊNH 6 món): ngọc là
/// mốc LẶP LẠI VÔ HẠN (mỗi [starsPerGem] sao tích luỹ lại được thêm 1 viên),
/// vì sao sẽ tiếp tục cộng dồn mãi mãi khi bé còn học - không hợp lý để liệt
/// kê thành 1 danh sách cố định như phụ kiện (đến 1 lúc nào đó sẽ hết mốc).
/// Nên controller này CHỈ lưu số đã NHẬN THƯỞNG ([_claimedCount], qua
/// [GemRewardRepository]) - số ĐÃ ĐẠT MỐC luôn tính lại từ số sao hiện có của
/// [ProgressController] (truyền vào theo tham số ở mỗi lần gọi, KHÔNG giữ
/// tham chiếu trực tiếp tới [ProgressController] - tránh phụ thuộc 2 chiều
/// giữa 2 controller, đúng nguyên tắc UI tự phối 2 controller lại với nhau).
class GemRewardController extends ChangeNotifier {
  GemRewardController(this._repository);

  final GemRewardRepository _repository;

  /// Cứ đủ 200 sao tích luỹ là được thêm 1 viên ngọc (chốt cùng người dùng
  /// 2026-08-31) - xa hơn hẳn mốc phụ kiện đắt nhất (80 sao) nên không bị đạt
  /// ngay lập tức, nhưng vẫn lặp lại vô hạn về sau.
  static const int starsPerGem = 200;

  /// Giá trị quy đổi 1 viên ngọc ra tiền thật - CHỈ ĐỂ HIỂN THỊ trong app cho
  /// bé/bố mẹ thấy rõ, ứng dụng KHÔNG xử lý bất kỳ giao dịch tiền thật nào,
  /// việc thưởng tiền hoàn toàn do bố mẹ tự thực hiện NGOÀI app (chốt cùng
  /// người dùng 2026-08-31).
  static const int moneyPerGemVnd = 100000;

  int _claimedCount = 0;
  bool _loaded = false;

  bool get loaded => _loaded;

  /// Số viên ngọc bố mẹ ĐÃ xác nhận thưởng tiền (bấm "Đã nhận thưởng ✅").
  int get claimedCount => _claimedCount;

  /// Số viên ngọc đã ĐẠT MỐC tính đến [stars] hiện tại (kể cả đã nhận lẫn
  /// chưa nhận) - luôn tính lại, không lưu trữ riêng (xem doc comment lớp).
  int earnedCountFor(int stars) => stars ~/ starsPerGem;

  /// Số viên ngọc ĐÃ ĐẠT MỐC nhưng CHƯA bấm "Đã nhận thưởng" - đây là số
  /// hiển thị nổi bật ở Rewards để nhắc bố mẹ. `clamp` phòng trường hợp
  /// [_claimedCount] tạm thời lớn hơn [earnedCountFor] (ví dụ ngay sau khi
  /// "làm lại từ đầu" xoá sao về 0 nhưng lúc gọi `resetClaimed()` chưa kịp
  /// hoàn tất) - không để lộ số âm ra UI.
  int pendingCountFor(int stars) => (earnedCountFor(stars) - _claimedCount).clamp(0, 1 << 31);

  /// Còn thiếu bao nhiêu sao nữa để đạt viên ngọc TIẾP THEO (dùng hiển thị
  /// tiến độ "còn X sao nữa" ở Rewards, giống cách phụ kiện hiện "cần thêm
  /// bao nhiêu sao" khi chưa mở khoá).
  int starsUntilNextGem(int stars) => starsPerGem - (stars % starsPerGem);

  Future<void> load() async {
    _claimedCount = await _repository.getClaimedGemCount();
    _loaded = true;
    notifyListeners();
  }

  /// Bố mẹ bấm "Đã nhận thưởng ✅" cho 1 viên ngọc đang chờ - đánh dấu đã
  /// nhận để app KHÔNG hiện nhắc lại mốc này nữa, nhưng vẫn giữ đã từng đạt
  /// (không xoá tiến độ sao). [stars] hiện tại dùng để KHÔNG cho nhận vượt
  /// quá số đã thật sự đạt mốc (phòng bấm nhiều lần liên tiếp/lỗi UI).
  Future<void> claimOne(int stars) async {
    if (_claimedCount >= earnedCountFor(stars)) return;
    _claimedCount++;
    notifyListeners();
    await _repository.setClaimedGemCount(_claimedCount);
  }

  /// Đưa số đã nhận về 0 - dùng khi bé "làm lại từ đầu" ở Settings (cùng lúc
  /// với [ProgressController.resetProgress] xoá sao về 0), tránh tình trạng
  /// [_claimedCount] cũ "vượt trước" số sao mới kiếm lại được, khiến viên
  /// ngọc kế tiếp bé thật sự mới đạt lại không hiện ra vì phép trừ ở
  /// [pendingCountFor] bị âm (đã `clamp` về 0 nên không lỗi hiển thị, nhưng
  /// nếu không reset thì bé phải kiếm sao NHIỀU HƠN mức cần thật mới thấy
  /// viên ngọc mới, sẽ rất khó hiểu).
  Future<void> resetClaimed() async {
    _claimedCount = 0;
    notifyListeners();
    await _repository.setClaimedGemCount(0);
  }
}
