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
    // Văn phòng / hành chính
    ('invoice', 'hoá đơn'),
    ('deadline', 'hạn chót'),
    ('colleague', 'đồng nghiệp'),
    ('attachment', 'tệp đính kèm'),
    ('agenda', 'chương trình nghị sự'),
    ('memo', 'thông báo nội bộ'),
    ('stationery', 'văn phòng phẩm'),
    ('photocopier', 'máy photocopy'),
    ('receptionist', 'lễ tân'),
    ('workplace', 'nơi làm việc'),
    ('overtime', 'làm thêm giờ'),
    ('shift', 'ca làm việc'),
    ('extension', 'số máy lẻ (điện thoại)'),
    ('voicemail', 'hộp thư thoại'),
    ('printout', 'bản in'),
    // Họp hành / dự án
    ('supervisor', 'người giám sát'),
    ('negotiate', 'đàm phán'),
    ('feedback', 'phản hồi'),
    ('productivity', 'năng suất'),
    ('headquarters', 'trụ sở chính'),
    ('conference', 'hội nghị'),
    ('presentation', 'bài thuyết trình'),
    ('proposal', 'bản đề xuất'),
    ('postpone', 'hoãn lại'),
    ('reschedule', 'sắp xếp lại lịch'),
    ('participant', 'người tham gia'),
    ('brainstorm', 'động não, tìm ý tưởng'),
    ('minutes', 'biên bản cuộc họp'),
    ('milestone', 'cột mốc quan trọng'),
    ('collaborate', 'hợp tác, cộng tác'),
    // Nhân sự / tuyển dụng
    ('applicant', 'người ứng tuyển'),
    ('résumé', 'sơ yếu lý lịch'),
    ('candidate', 'ứng viên'),
    ('interview', 'buổi phỏng vấn'),
    ('qualification', 'bằng cấp/trình độ'),
    ('promotion', 'thăng chức'),
    ('salary', 'lương'),
    ('benefits', 'phúc lợi'),
    ('vacancy', 'vị trí tuyển dụng còn trống'),
    ('probation', 'thời gian thử việc'),
    ('resignation', 'đơn xin nghỉ việc'),
    ('orientation', 'buổi định hướng nhân viên mới'),
    // Tài chính / kế toán
    ('reimbursement', 'khoản hoàn tiền'),
    ('budget', 'ngân sách'),
    ('revenue', 'doanh thu'),
    ('expense', 'chi phí'),
    ('profit', 'lợi nhuận'),
    ('discount', 'giảm giá'),
    ('receipt', 'biên lai'),
    ('installment', 'khoản trả góp'),
    ('surplus', 'phần dư/thặng dư'),
    ('deficit', 'thâm hụt'),
    ('audit', 'kiểm toán'),
    ('fiscal', 'thuộc về tài khoá'),
    // Kho vận / sản xuất
    ('warehouse', 'nhà kho'),
    ('shipment', 'lô hàng'),
    ('inventory', 'hàng tồn kho'),
    ('vendor', 'nhà cung cấp'),
    ('supplier', 'nhà cung ứng'),
    ('delivery', 'việc giao hàng'),
    ('logistics', 'hậu cần/vận chuyển'),
    ('manufacture', 'sản xuất'),
    ('defective', 'bị lỗi, hư hỏng'),
    ('quality control', 'kiểm soát chất lượng'),
    ('packaging', 'đóng gói'),
    ('freight', 'hàng hoá vận chuyển'),
    // Du lịch / khách sạn
    ('itinerary', 'lịch trình'),
    ('reservation', 'việc đặt chỗ'),
    ('boarding pass', 'thẻ lên máy bay'),
    ('luggage', 'hành lý'),
    ('departure', 'chuyến khởi hành'),
    ('customs', 'hải quan'),
    ('accommodation', 'chỗ ở'),
    ('receptacle', 'nơi tiếp nhận/thùng chứa'),
    ('checkout', 'thủ tục trả phòng'),
    ('concierge', 'nhân viên hỗ trợ khách sạn'),
    // Marketing / bán hàng
    ('subscription', 'gói đăng ký (dịch vụ)'),
    ('customer', 'khách hàng'),
    ('advertisement', 'quảng cáo'),
    ('brand', 'thương hiệu'),
    ('giveaway', 'chương trình quà tặng khuyến mãi'),
    ('retail', 'bán lẻ'),
    ('wholesale', 'bán sỉ'),
    ('client', 'khách hàng (doanh nghiệp)'),
    ('discount coupon', 'phiếu giảm giá'),
    ('warranty', 'bảo hành'),
    ('refund', 'hoàn tiền'),
    ('complaint', 'lời than phiền/khiếu nại'),
    // Công nghệ / IT
    ('software', 'phần mềm'),
    ('upgrade', 'nâng cấp'),
    ('password', 'mật khẩu'),
    ('malfunction', 'trục trặc, hỏng hóc'),
    ('technician', 'kỹ thuật viên'),
    ('database', 'cơ sở dữ liệu'),
    ('device', 'thiết bị'),
    ('backup', 'sao lưu dữ liệu'),
    // Cơ sở vật chất / xây dựng
    ('renovation', 'việc cải tạo/sửa chữa'),
    ('maintenance', 'bảo trì'),
    ('facility', 'cơ sở vật chất'),
    ('construction', 'công trình xây dựng'),
    ('inspection', 'việc kiểm tra'),
    ('contractor', 'nhà thầu'),
    ('elevator', 'thang máy'),
    // Hợp đồng / pháp lý
    ('contract', 'hợp đồng'),
    ('agreement', 'thoả thuận'),
    ('signature', 'chữ ký'),
    ('confidential', 'bảo mật'),
    ('regulation', 'quy định'),
    ('policy', 'chính sách'),
    ('permit', 'giấy phép'),
    // Ngân hàng / bảo hiểm
    ('account', 'tài khoản'),
    ('deposit', 'khoản tiền gửi'),
    ('withdrawal', 'việc rút tiền'),
    ('interest rate', 'lãi suất'),
    ('loan', 'khoản vay'),
    ('mortgage', 'khoản vay mua nhà'),
    ('premium', 'phí bảo hiểm'),
    ('claim', 'yêu cầu bồi thường'),
    ('transaction', 'giao dịch'),
    ('currency', 'tiền tệ'),
    // Y tế / sức khoẻ
    ('appointment', 'cuộc hẹn'),
    ('prescription', 'đơn thuốc'),
    ('symptom', 'triệu chứng'),
    ('checkup', 'khám sức khoẻ định kỳ'),
    ('pharmacy', 'nhà thuốc'),
    ('insurance', 'bảo hiểm'),
    ('diagnosis', 'chẩn đoán'),
    ('treatment', 'phương pháp điều trị'),
    // Giáo dục / đào tạo
    ('curriculum', 'chương trình học'),
    ('certificate', 'chứng chỉ'),
    ('enrollment', 'việc đăng ký nhập học'),
    ('scholarship', 'học bổng'),
    ('lecture', 'bài giảng'),
    ('tuition', 'học phí'),
    ('graduate', 'sinh viên tốt nghiệp'),
    // Bất động sản / nhà ở
    ('lease', 'hợp đồng thuê nhà'),
    ('tenant', 'người thuê nhà'),
    ('landlord', 'chủ nhà cho thuê'),
    ('property', 'bất động sản'),
    ('utility bill', 'hoá đơn tiện ích (điện, nước...)'),
    ('deposit slip', 'phiếu nộp tiền'),
    // Giao thông / ô tô
    ('commute', 'việc di chuyển đi làm hằng ngày'),
    ('traffic jam', 'kẹt xe'),
    ('fare', 'giá vé'),
    ('mechanic', 'thợ máy'),
    ('vehicle', 'phương tiện'),
    ('license plate', 'biển số xe'),
    // Sự kiện / giải trí
    ('venue', 'địa điểm tổ chức sự kiện'),
    ('audience', 'khán giả'),
    ('performance', 'buổi biểu diễn'),
    ('ticket', 'vé'),
    ('exhibit', 'triển lãm'),
    ('sponsor', 'nhà tài trợ'),
    // Môi trường làm việc chung
    ('efficient', 'hiệu quả'),
    ('punctual', 'đúng giờ'),
    ('flexible', 'linh hoạt'),
    ('reliable', 'đáng tin cậy'),
    ('thorough', 'kỹ lưỡng, cẩn thận'),
    ('urgent', 'khẩn cấp'),
    ('temporary', 'tạm thời'),
    ('permanent', 'lâu dài, cố định'),
    ('accurate', 'chính xác'),
    ('outdated', 'lỗi thời, cũ'),
    // Động từ công sở hay gặp ở Part 5/7
    ('submit', 'nộp (hồ sơ, báo cáo)'),
    ('approve', 'phê duyệt'),
    ('implement', 'triển khai, thực hiện'),
    ('allocate', 'phân bổ'),
    ('comply with', 'tuân thủ'),
    ('verify', 'xác minh'),
    ('estimate', 'ước tính; bản ước tính'),
    ('assign', 'giao (việc)'),
    ('attend', 'tham dự'),
    ('recruit', 'tuyển dụng'),
    ('launch', 'ra mắt (sản phẩm)'),
    ('expand', 'mở rộng'),
    ('exceed', 'vượt quá'),
    ('acquire', 'mua lại, giành được'),
    ('merge', 'sáp nhập'),
    ('outsource', 'thuê ngoài'),
    ('renew', 'gia hạn'),
    ('expire', 'hết hạn'),
    ('refrain from', 'tránh, kiềm chế không làm'),
    ('accommodate', 'đáp ứng, có sức chứa'),
    ('inquire', 'hỏi thông tin'),
    ('confirm', 'xác nhận'),
    ('distribute', 'phân phát, phân phối'),
    ('evaluate', 'đánh giá'),
    ('anticipate', 'dự đoán, lường trước'),
    // Cụm động từ (phrasal verbs)
    ('fill out', 'điền (mẫu đơn)'),
    ('set up', 'thiết lập, sắp đặt'),
    ('look into', 'xem xét, điều tra'),
    ('call off', 'huỷ bỏ'),
    ('put off', 'trì hoãn'),
    ('turn down', 'từ chối'),
    ('carry out', 'tiến hành'),
    ('hand in', 'nộp'),
    ('run out of', 'hết, cạn'),
    ('sign up for', 'đăng ký'),
    ('pick up', 'đón; lấy (hàng)'),
    ('drop off', 'giao, để lại (ai/cái gì)'),
    ('go over', 'xem lại kỹ'),
    ('take over', 'tiếp quản'),
    ('fill in for', 'làm thay (ai)'),
    ('catch up on', 'bắt kịp, làm bù'),
    ('follow up', 'theo dõi tiếp, liên hệ lại'),
    ('back up', 'sao lưu; ủng hộ'),
    // Trạng từ/tính từ hay ra trong bẫy Part 5
    ('approximately', 'xấp xỉ, khoảng'),
    ('promptly', 'ngay lập tức, đúng giờ'),
    ('previously', 'trước đây'),
    ('currently', 'hiện tại'),
    ('temporarily', 'tạm thời'),
    ('recently', 'gần đây'),
    ('frequently', 'thường xuyên'),
    ('immediately', 'ngay lập tức'),
    ('regularly', 'đều đặn'),
    ('significantly', 'đáng kể'),
    ('complimentary', 'miễn phí (tặng kèm)'),
    ('mandatory', 'bắt buộc'),
    ('eligible', 'đủ điều kiện'),
    ('available', 'có sẵn, rảnh'),
    ('affordable', 'giá phải chăng'),
    ('durable', 'bền'),
    ('competitive', 'cạnh tranh'),
    ('substantial', 'đáng kể, lớn'),
    ('tentative', 'dự kiến, tạm thời'),
    ('preliminary', 'sơ bộ'),
    ('comprehensive', 'toàn diện'),
    ('relevant', 'liên quan'),
    ('adjacent', 'liền kề'),
    ('spacious', 'rộng rãi'),
    ('prestigious', 'danh giá, uy tín'),
    // Danh từ kinh doanh bổ sung
    ('quote', 'báo giá'),
    ('merchandise', 'hàng hoá'),
    ('consumer', 'người tiêu dùng'),
    ('competitor', 'đối thủ cạnh tranh'),
    ('shareholder', 'cổ đông'),
    ('board of directors', 'hội đồng quản trị'),
    ('executive', 'giám đốc điều hành, quản lý cấp cao'),
    ('personnel', 'nhân sự'),
    ('workshop', 'buổi hội thảo thực hành'),
    ('seminar', 'hội thảo chuyên đề'),
    ('deadline extension', 'gia hạn thời hạn'),
    ('questionnaire', 'bảng câu hỏi khảo sát'),
    ('survey', 'khảo sát'),
    ('statement', 'bản sao kê; tuyên bố'),
    ('outage', 'sự cố mất (điện, mạng)'),
    ('shortage', 'sự thiếu hụt'),
    ('expansion', 'sự mở rộng'),
    ('acquisition', 'sự mua lại (công ty)'),
    ('commission', 'tiền hoa hồng'),
    ('estimate request', 'yêu cầu báo giá'),
    ('trade fair', 'hội chợ thương mại'),
    ('keynote speech', 'bài phát biểu chính'),
    ('press release', 'thông cáo báo chí'),
    ('job opening', 'vị trí đang tuyển'),
    ('reference letter', 'thư giới thiệu'),
    // Collocation hay gặp
    ('meet a deadline', 'kịp hạn chót'),
    ('place an order', 'đặt hàng'),
    ('make a reservation', 'đặt chỗ trước'),
    ('hold a meeting', 'tổ chức cuộc họp'),
    ('pay attention to', 'chú ý tới'),
    ('take into account', 'cân nhắc, tính đến'),
    ('on behalf of', 'thay mặt cho'),
    ('in charge of', 'phụ trách'),
    ('in advance', 'trước (thời hạn)'),
    ('out of stock', 'hết hàng'),
    ('free of charge', 'miễn phí'),
    ('due to', 'do, bởi vì'),
  ];
}
