import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/platform/platform_info.dart';

/// Cách mở mic cho 1 lần nghe - tách thành hàm thuần ([SpeechService.planFor])
/// để test được logic riêng cho Safari iOS mà không cần trình duyệt thật.
class SpeechListenPlan {
  /// Nhận kết quả tạm thời trong lúc bé đang nói. Trên web, plugin dùng
  /// CHÍNH cờ này cho chế độ nghe liên tục (`continuous`) của trình duyệt.
  final bool partialResults;

  /// Tự mở lại phiên nghe mới khi bị dừng sớm do im lặng (xem doc lớp
  /// [SpeechService]).
  final bool allowContinuation;

  const SpeechListenPlan({required this.partialResults, required this.allowContinuation});
}

/// Kết quả trả về sau một lần Mimi "lắng nghe" bé nói.
class SpeechListenOutcome {
  final String recognizedText;
  final bool timedOut;

  const SpeechListenOutcome({required this.recognizedText, this.timedOut = false});
}

/// Bọc [stt.SpeechToText] (package speech_to_text) để phần còn lại của app
/// không cần biết chi tiết plugin - chỉ cần gọi [listenOnce] và nhận lại
/// text bé vừa nói.
///
/// SỬA LỖI (2026-09-08): tin nhắn thoại ở Chat (và có thể cả các chỗ dùng
/// giọng nói khác) bị CẮT CỤT giữa câu dù đã tăng `pauseFor` lên 4 giây ở
/// lần sửa trước (2026-08-23). Tra lại tài liệu chính thức của package mới
/// biết đây KHÔNG phải lỗi do app đặt `pauseFor` chưa đủ dài: "on some
/// systems, notably Android, there is a system imposed pause of from one to
/// three seconds that cannot be overridden" - tức trên Android, hệ điều hành
/// tự ý dừng nghe sau ~1-3 giây im lặng, BẤT KỂ app yêu cầu `pauseFor` bao
/// nhiêu. Con số 4 giây ở `ChatController` gần như vô tác dụng trên Android.
///
/// Vì đây là giới hạn ở tầng hệ điều hành/plugin (không thể "xin" recognizer
/// chờ lâu hơn), cách sửa đúng là: khi phiên nghe bị dừng SỚM do im lặng mà
/// bé vẫn chưa chủ động bấm nút "nói xong" ([stopListening]), tự động MỞ LẠI
/// một phiên nghe mới ngay lập tức và NỐI TIẾP kết quả vào phần đã nhận diện
/// được trước đó - với bé, cảm giác như mic vẫn đang nghe liên tục, dù bên
/// dưới là nhiều phiên nghe ngắn nối lại. Chỉ dừng hẳn khi: bé chủ động bấm
/// dừng, hết tổng thời gian [listenFor], hoặc có 2 phiên liên tiếp không
/// nhận thêm được từ nào mới (coi như bé đã nói xong thật, tránh mic treo
/// chờ vô ích tới hết [listenFor]).
///
/// Cơ chế "tự nối phiên" này CHỈ bật khi gọi với `allowContinuation: true`
/// (xem [listenOnce]) - qua review độc lập phát hiện nếu bật mặc định cho
/// MỌI nơi gọi, các màn chỉ cần 1 từ/1 câu ngắn (học từ vựng, tra từ điển,
/// bài tranh, chào hỏi ở Home) sẽ bị CHỜ LÂU HƠN không cần thiết - vì hễ
/// nhận được ít nhất 1 từ, code sẽ tiếp tục mở thêm phiên nghe để chờ xem
/// bé có nói thêm không, thay vì trả kết quả về ngay như hành vi cũ. Nên chỉ
/// [ChatController] (hội thoại tự do, thật sự cần nối câu dài) mới truyền
/// `allowContinuation: true`; các nơi còn lại giữ nguyên hành vi 1-phiên cũ.
class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _hasInitialized = false;

  /// true khi bé (hoặc code) chủ động yêu cầu dừng hẳn qua [stopListening]/
  /// [cancelListening] - vòng lặp tự nối phiên nghe trong [listenOnce] phải
  /// kiểm tra cờ này trước khi mở phiên nghe mới, nếu không nút "nói xong"
  /// sẽ vô tác dụng (vừa dừng phiên hiện tại xong lại bị tự mở phiên khác).
  bool _stopRequested = false;

  /// Số phiên nghe liên tiếp KHÔNG nhận thêm được từ mới nào, tính từ lần
  /// đã nhận được ít nhất 1 từ gần nhất - xem giải thích ở doc comment lớp.
  static const int _maxConsecutiveEmptyRetries = 2;

  Future<bool> initialize() async {
    if (_hasInitialized) return _isAvailable;
    _hasInitialized = true;
    _isAvailable = await _speech.initialize(
      onStatus: (_) {},
      onError: (_) {},
    );
    return _isAvailable;
  }

  bool get isListening => _speech.isListening;

  /// Safari trên iPhone/iPad (2026-10-01): bộ nhận dạng giọng nói của WebKit
  /// chạy được (iOS 14.5+, cần bật Siri/Đọc chính tả) nhưng 2 thứ app dùng
  /// cho Android lại làm hỏng nó:
  /// - Chế độ nghe liên tục + kết quả tạm thời: Safari hay trả lặp chữ
  ///   ("hello hello") và không tự kết thúc phiên.
  /// - Tự mở lại phiên nghe: phiên mới KHÔNG xuất phát từ 1 lần chạm của bé
  ///   nên Safari có thể chặn (lỗi not-allowed) hoặc hỏi lại quyền micro.
  /// Vì vậy trên iOS web luôn nghe 1 phiên, không liên tục - Safari tự dừng
  /// khi bé nói xong câu.
  static SpeechListenPlan planFor({required bool isIosWeb, required bool allowContinuation}) => isIosWeb
      ? const SpeechListenPlan(partialResults: false, allowContinuation: false)
      : SpeechListenPlan(partialResults: true, allowContinuation: allowContinuation);

  /// Bắt đầu nghe, tự dừng khi bé ngừng nói thật sự (hoặc hết [listenFor]).
  /// Trả về text nhận diện được, đã NỐI đầy đủ qua mọi phiên nghe con bên
  /// trong (xem doc comment lớp) - phần còn lại của app không cần biết có
  /// nhiều phiên nghe bên dưới, chỉ nhận về 1 câu hoàn chỉnh duy nhất.
  ///
  /// [allowContinuation]: bật cơ chế tự mở lại phiên nghe khi bị dừng sớm do
  /// im lặng (xem doc comment lớp) - CHỈ nên bật `true` cho hội thoại tự do
  /// nhiều câu (Chat); các nơi chỉ cần 1 từ/1 câu ngắn nên để mặc định
  /// `false` để trả kết quả ngay khi phiên nghe đầu tiên kết thúc, giữ đúng
  /// tốc độ phản hồi như trước (xem lý do ở doc comment lớp).
  Future<SpeechListenOutcome> listenOnce({
    Duration listenFor = const Duration(seconds: 6),
    Duration pauseFor = const Duration(seconds: 2),
    bool allowContinuation = false,
    void Function(String text)? onPartial,
    String localeId = 'en_US',
  }) async {
    final available = await initialize();
    if (!available) {
      return const SpeechListenOutcome(recognizedText: '', timedOut: true);
    }

    final plan = planFor(isIosWeb: PlatformInfo.isIosWeb, allowContinuation: allowContinuation);
    allowContinuation = plan.allowContinuation;
    _stopRequested = false;
    final overallDeadline = DateTime.now().add(listenFor);
    String accumulated = '';
    int consecutiveEmptyRetries = 0;

    while (!_stopRequested) {
      final remaining = overallDeadline.difference(DateTime.now());
      if (remaining <= Duration.zero) break;

      String sessionWords = '';
      try {
        await _speech.listen(
          onResult: (result) {
            sessionWords = result.recognizedWords;
            // Báo phần đã nghe được tới giờ (cả các phiên trước) để UI hiện
            // chữ ngay trong lúc bé đang nói.
            if (onPartial != null && sessionWords.trim().isNotEmpty) {
              onPartial(accumulated.isEmpty ? sessionWords : '$accumulated $sessionWords');
            }
          },
          listenFor: remaining,
          pauseFor: pauseFor,
          partialResults: plan.partialResults,
          // Trình duyệt dùng mã chuẩn BCP 47 có gạch nối (vi-VN), Android/iOS
          // dùng gạch dưới (vi_VN).
          localeId: kIsWeb ? localeId.replaceAll('_', '-') : localeId,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        );

        // Đợi tới khi phiên nghe hiện tại tự dừng (hết pauseFor/listenFor,
        // lỗi, hoặc bị huỷ) hay bị bé chủ động dừng.
        while (_speech.isListening) {
          await Future.delayed(const Duration(milliseconds: 150));
        }
      } catch (_) {
        // SỬA LỖI (qua review độc lập, 2026-09-08): 1 phiên nghe NỐI TIẾP bị
        // lỗi (ví dụ Android từ chối mở recognizer mới ngay sau khi phiên
        // trước vừa đóng) KHÔNG được làm mất phần đã nhận diện đúng từ các
        // phiên TRƯỚC đó - dừng vòng lặp tại đây và trả về những gì đã có,
        // thay vì để lỗi này văng thẳng ra ngoài (caller sẽ coi như "không
        // nghe được gì" dù thực ra đã có 1 phần câu đúng - còn tệ hơn cả
        // hành vi cũ).
        break;
      }

      if (sessionWords.trim().isNotEmpty) {
        accumulated = accumulated.isEmpty ? sessionWords : '$accumulated $sessionWords';
        consecutiveEmptyRetries = 0;
        if (!allowContinuation) break;
        continue;
      }

      // Phiên vừa rồi không nhận thêm được từ nào.
      if (!allowContinuation || accumulated.isEmpty) {
        // Không bật tự nối phiên, HOẶC chưa từng nhận được từ nào từ đầu tới
        // giờ (bé chưa nói gì thật sự, không phải đang ngập ngừng giữa câu)
        // -> dừng luôn, giữ đúng cảm giác "im lặng thì thôi" như trước đây.
        break;
      }
      consecutiveEmptyRetries++;
      if (consecutiveEmptyRetries >= _maxConsecutiveEmptyRetries) {
        // Đã cho bé 2 cơ hội "khoảng lặng" mà vẫn không nói thêm gì -> coi
        // như đã nói xong thật, không mở thêm phiên nghe nữa.
        break;
      }
      // Ngược lại: mở lại 1 phiên nghe mới ngay (vòng while lặp tiếp) để nối
      // tiếp câu đang nói dở - đây chính là phần "vá" giới hạn OS ở trên.
    }

    return SpeechListenOutcome(recognizedText: accumulated);
  }

  Future<void> stopListening() async {
    _stopRequested = true;
    await _speech.stop();
  }

  Future<void> cancelListening() async {
    _stopRequested = true;
    await _speech.cancel();
  }
}
