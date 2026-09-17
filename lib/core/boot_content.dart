/// Dữ liệu TĨNH cho màn chờ lúc backend Render (gói Free) đang "ngủ" cần
/// thời gian thức dậy (xem `presentation/screens/boot/boot_screen.dart`) -
/// KHÔNG phụ thuộc gì vào server (server lúc này có thể chưa trả lời được gì
/// cả), theo đúng nguyên tắc tham khảo từ app khác (ManHinhCho.md, 2026-09-17):
/// hiện màn chờ NGAY LẬP TỨC bằng nội dung dựng sẵn phía client, chuỗi trạng
/// thái tính theo THỜI GIAN TRÔI QUA (không phải tiến độ thực của server, vì
/// client không có cách nào biết chính xác server đang làm gì).
library;

/// 1 mốc thời gian (giây kể từ lúc bắt đầu chờ) -> câu trạng thái + % thanh
/// tiến trình hiển thị tại mốc đó. [BootContent.stageFor] tìm mốc GẦN NHẤT
/// đã đi qua theo elapsed time hiện tại.
class BootStage {
  final int atSeconds;
  final String text;
  final double progress; // 0.0 - 1.0

  const BootStage({required this.atSeconds, required this.text, required this.progress});
}

class BootContent {
  BootContent._();

  /// Timeout cho request "đánh thức" server - xem [ApiClient.getJson]/
  /// [AuthService.login] (dùng chung 1 hằng số này để 2 nơi luôn khớp nhau).
  static const wakeTimeoutSeconds = 100;

  /// Bảng mốc trạng thái - progress KHÔNG BAO GIỜ chạm 100% (chỉ nhích lên
  /// tạo cảm giác "vẫn đang chạy"), chỉ THỰC SỰ đóng màn chờ khi có phản hồi
  /// thật từ server (xem `BootScreen`).
  static const List<BootStage> stages = [
    BootStage(atSeconds: 0, text: '⏳ Đang kết nối với Mimi...', progress: 0.15),
    BootStage(atSeconds: 8, text: '🚀 Máy chủ đang thức dậy...', progress: 0.40),
    BootStage(atSeconds: 25, text: '📦 Đang tải tiến độ của bé...', progress: 0.70),
    BootStage(atSeconds: 45, text: '✨ Sắp xong rồi, cảm ơn bé đã kiên nhẫn chờ Mimi...', progress: 0.92),
  ];

  static BootStage stageFor(int elapsedSeconds) {
    var current = stages.first;
    for (final stage in stages) {
      if (elapsedSeconds >= stage.atSeconds) current = stage;
    }
    return current;
  }

  /// Lời chào theo giờ trong ngày (giờ hệ thống thiết bị) - làm màn chờ có
  /// cảm giác "sống", không phải 1 khối tĩnh vô cảm.
  static String greetingFor(DateTime now) {
    final hour = now.hour;
    if (hour < 5) return 'Bé thức khuya thế! 🌙';
    if (hour < 11) return 'Chào buổi sáng! ☀️';
    if (hour < 13) return 'Chào buổi trưa! 🌤️';
    if (hour < 18) return 'Chào buổi chiều! 🌇';
    return 'Chào buổi tối! 🌃';
  }

  /// Từ vựng TOEIC hay gặp - xoay vòng hiển thị trong lúc chờ (tận dụng thời
  /// gian chết thay vì để bé nhìn thanh tiến trình vô nghĩa), theo đúng gợi ý
  /// đã trao đổi. Chọn từ THÔNG DỤNG, xuất hiện nhiều ở Part 5/6/7 (công sở/
  /// văn phòng) hơn là từ hiếm.
  static const List<(String, String)> toeicVocabTips = [
    ('invoice', 'hoá đơn'),
    ('deadline', 'hạn chót'),
    ('colleague', 'đồng nghiệp'),
    ('warehouse', 'nhà kho'),
    ('shipment', 'lô hàng'),
    ('reimbursement', 'khoản hoàn tiền'),
    ('supervisor', 'người giám sát'),
    ('itinerary', 'lịch trình'),
    ('attachment', 'tệp đính kèm'),
    ('negotiate', 'đàm phán'),
    ('applicant', 'người ứng tuyển'),
    ('inventory', 'hàng tồn kho'),
    ('subscription', 'gói đăng ký (dịch vụ)'),
    ('renovation', 'việc cải tạo/sửa chữa'),
    ('reservation', 'việc đặt chỗ'),
    ('agenda', 'chương trình nghị sự'),
    ('vendor', 'nhà cung cấp'),
    ('feedback', 'phản hồi'),
    ('productivity', 'năng suất'),
    ('headquarters', 'trụ sở chính'),
  ];
}
