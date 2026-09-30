import 'dart:convert';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 2 "hồ sơ giọng" độc lập: giọng của BÉ (bài học, trò chuyện với Mimi -
/// chậm, cao giọng) và giọng TOEIC (luyện nghe của phụ huynh - gần tốc độ
/// thật). Chỉnh trong Cài đặt (xem `settings_screen.dart`).
enum VoiceKind { kid, toeic }

class VoiceProfile {
  /// Hệ số so với tốc độ GỐC của hồ sơ (xem [TtsService.baseRates]) -
  /// 1.0 = mặc định, 0.5 = chậm một nửa, 2.0 = nhanh gấp đôi. Lưu dạng hệ số
  /// thay vì "rate" thô vì cùng 1 giá trị rate mỗi nền tảng (web/Android/iOS)
  /// đọc nhanh chậm khác nhau.
  final double speed;
  final double pitch;

  const VoiceProfile({required this.speed, required this.pitch});

  VoiceProfile copyWith({double? speed, double? pitch}) =>
      VoiceProfile(speed: speed ?? this.speed, pitch: pitch ?? this.pitch);

  Map<String, dynamic> toJson() => {'speed': speed, 'pitch': pitch};

  factory VoiceProfile.fromJson(Map<String, dynamic> json, VoiceProfile fallback) => VoiceProfile(
        speed: (json['speed'] as num?)?.toDouble() ?? fallback.speed,
        pitch: (json['pitch'] as num?)?.toDouble() ?? fallback.pitch,
      );
}

/// 1 lượt thoại trong kịch bản hội thoại ("A: ... B: ..." hoặc "Mum: ...").
class DialogueLine {
  final String speaker;
  final String text;

  const DialogueLine(this.speaker, this.text);
}

enum SpeakerGender { female, male, unknown }

/// Bọc [FlutterTts] để phần còn lại của app chỉ cần gọi [speak]/[speakScript]
/// mà không phải biết chi tiết cấu hình giọng đọc.
///
/// Cấu hình giọng lưu CỤC BỘ theo thiết bị (SharedPreferences), KHÔNG đồng bộ
/// cloud: mỗi máy có loa/giọng đọc khác nhau, tốc độ vừa tai trên điện thoại
/// chưa chắc hợp trên máy tính.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  /// Tốc độ gốc (rate truyền cho flutter_tts) ứng với hệ số 1.0.
  static const baseRates = {VoiceKind.kid: 0.42, VoiceKind.toeic: 0.5};
  static const defaults = {
    VoiceKind.kid: VoiceProfile(speed: 1.0, pitch: 1.15),
    VoiceKind.toeic: VoiceProfile(speed: 1.0, pitch: 1.0),
  };
  static const minSpeed = 0.5;
  static const maxSpeed = 2.0;
  static const _prefsProfiles = 'mimi.voice.profiles';
  static const _prefsDialogue = 'mimi.voice.dialogueVoices';

  final Map<VoiceKind, VoiceProfile> _profiles = Map.of(defaults);
  bool _dialogueVoices = true;
  Future<void>? _loading;

  /// Tăng mỗi lần có lượt đọc MỚI - vòng đọc hội thoại nhiều lượt kiểm tra
  /// số này sau mỗi câu để dừng ngay khi bé bấm nghe lại/nghe câu khác.
  int _generation = 0;

  /// true khi đang dùng 1 giọng cụ thể cho hội thoại - lượt đọc thường kế
  /// tiếp phải trả lại giọng mặc định (xem [_resetVoice]).
  bool _customVoiceActive = false;
  List<Map<String, String>>? _englishVoices;

  VoiceProfile profile(VoiceKind kind) => _profiles[kind]!;
  bool get dialogueVoicesEnabled => _dialogueVoices;

  /// Nạp cấu hình đã lưu - gọi được nhiều lần (chỉ nạp thật 1 lần).
  Future<void> ensureLoaded() => _loading ??= _loadSettings();

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsProfiles);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final kind in VoiceKind.values) {
          final json = decoded[kind.name];
          if (json is Map<String, dynamic>) {
            _profiles[kind] = VoiceProfile.fromJson(json, defaults[kind]!);
          }
        }
      }
      _dialogueVoices = prefs.getBool(_prefsDialogue) ?? true;
    } catch (_) {
      // Không đọc được (trình duyệt chặn lưu trữ...) - dùng mặc định.
    }
  }

  Future<void> setProfile(VoiceKind kind, VoiceProfile value) async {
    await ensureLoaded();
    _profiles[kind] = VoiceProfile(
      speed: value.speed.clamp(minSpeed, maxSpeed).toDouble(),
      pitch: value.pitch.clamp(0.5, 2.0).toDouble(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsProfiles,
      jsonEncode({for (final k in VoiceKind.values) k.name: _profiles[k]!.toJson()}),
    );
  }

  Future<void> setDialogueVoicesEnabled(bool enabled) async {
    await ensureLoaded();
    _dialogueVoices = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsDialogue, enabled);
  }

  Future<void> _ensureInitialized() async {
    await ensureLoaded();
    if (_initialized) return;
    _initialized = true;
    await _tts.setLanguage('en-US');
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  /// rate thật truyền cho flutter_tts - kẹp trong khoảng mọi nền tảng đều
  /// chấp nhận (iOS chỉ nhận 0..1).
  double rateFor(VoiceKind kind, {double speed = 1.0}) =>
      (baseRates[kind]! * profile(kind).speed * speed).clamp(0.1, 1.0).toDouble();

  Future<void> _resetVoice() async {
    if (!_customVoiceActive) return;
    _customVoiceActive = false;
    // setLanguage đưa giọng về giọng mặc định của ngôn ngữ (web: giọng en-US
    // đầu tiên - đúng giọng dùng lúc khởi tạo).
    await _tts.setLanguage('en-US');
  }

  /// Đọc [text] bằng tiếng Anh theo hồ sơ giọng [kind] và đợi đọc xong.
  /// [speed] là hệ số NHÂN THÊM cho riêng lượt này (vd 0.75 cho nút "Nghe
  /// chậm"), không làm đổi cấu hình đã lưu.
  Future<void> speak(String text, {VoiceKind kind = VoiceKind.kid, double speed = 1.0}) async {
    await _ensureInitialized();
    final generation = ++_generation;
    await _tts.stop();
    if (generation != _generation) return;
    await _resetVoice();
    await _tts.setSpeechRate(rateFor(kind, speed: speed));
    await _tts.setPitch(profile(kind).pitch);
    await _tts.speak(text);
  }

  /// Đọc kịch bản nghe: nếu là HỘI THOẠI (từ 2 người nói trở lên, xem
  /// [parseDialogue]) thì mỗi người 1 giọng/cao độ riêng để dễ phân biệt ai
  /// đang nói - giống đề thật Part 3 có giọng nam/nữ khác nhau. Không phải
  /// hội thoại (hoặc đã tắt trong Cài đặt) thì đọc như [speak].
  Future<void> speakScript(String script, {VoiceKind kind = VoiceKind.kid, double speed = 1.0}) async {
    await _ensureInitialized();
    final lines = parseDialogue(script);
    if (!_dialogueVoices || lines.length < 2) {
      return speak(script, kind: kind, speed: speed);
    }
    final generation = ++_generation;
    await _tts.stop();
    if (generation != _generation) return;

    final voices = await _loadEnglishVoices();
    final base = profile(kind);
    final assignments = assignVoices(lines.map((l) => l.speaker).toList(), voices, basePitch: base.pitch);
    await _tts.setSpeechRate(rateFor(kind, speed: speed));
    for (final line in lines) {
      if (generation != _generation) return;
      final a = assignments[line.speaker]!;
      if (a.voice != null) {
        await _tts.setVoice(a.voice!);
        _customVoiceActive = true;
      } else {
        await _resetVoice();
      }
      await _tts.setPitch(a.pitch);
      if (generation != _generation) return;
      await _tts.speak(line.text);
    }
  }

  Future<List<Map<String, String>>> _loadEnglishVoices() async {
    if (_englishVoices != null && _englishVoices!.isNotEmpty) return _englishVoices!;
    try {
      final raw = await _tts.getVoices;
      final list = <Map<String, String>>[];
      if (raw is List) {
        for (final v in raw) {
          if (v is Map) {
            final name = v['name']?.toString();
            final locale = v['locale']?.toString();
            if (name != null && locale != null && locale.toLowerCase().startsWith('en')) {
              list.add({'name': name, 'locale': locale});
            }
          }
        }
      }
      _englishVoices = list;
    } catch (_) {
      _englishVoices = const [];
    }
    return _englishVoices!;
  }

  Future<void> stop() {
    _generation++;
    return _tts.stop();
  }

  void dispose() {
    _generation++;
    _tts.stop();
  }

  // ------------------------------------------------------------ hàm thuần

  static final _speakerLabel = RegExp(r"(?:^|(?<=[.!?…]\s))([A-Z][a-z]*):\s");

  /// Tách kịch bản thành các lượt thoại theo nhãn người nói ở ĐẦU câu:
  /// "A: ... B: ...", "Man: ... Woman: ...", "Mum: ... Ben: ...". Trả về rỗng
  /// nếu kịch bản không có nhãn hoặc chỉ có 1 người nói (độc thoại).
  static List<DialogueLine> parseDialogue(String script) {
    final matches = _speakerLabel.allMatches(script).toList();
    if (matches.length < 2) return const [];
    final lines = <DialogueLine>[];
    for (var i = 0; i < matches.length; i++) {
      final end = i + 1 < matches.length ? matches[i + 1].start : script.length;
      final text = script.substring(matches[i].end, end).trim();
      if (text.isNotEmpty) lines.add(DialogueLine(matches[i].group(1)!, text));
    }
    if (lines.map((l) => l.speaker).toSet().length < 2) return const [];
    return lines;
  }

  static const _femaleLabels = {
    'woman', 'girl', 'mum', 'mom', 'mother', 'grandma', 'aunt', 'sister', 'lady', 'waitress',
    'maria', 'lisa', 'diane', 'katy', 'kate', 'anna', 'ann', 'emma', 'lucy', 'mia', 'lily', 'sarah', 'sara',
    'susan', 'jenny', 'linda', 'rita', 'nora', 'priya', 'paula', 'karen', 'sophia', 'sofia', 'daisy', 'sally',
    'mary', 'grace', 'helen', 'julia', 'hana', 'mina', 'rachel', 'jane', 'amy', 'laura', 'emily',
  };
  static const _maleLabels = {
    'man', 'boy', 'dad', 'father', 'grandpa', 'uncle', 'brother', 'waiter', 'ken', 'kevin', 'tom', 'ben',
    'harry', 'david', 'jack', 'sam', 'peter', 'paul', 'fred', 'max', 'oliver', 'robert', 'mark', 'omar',
    'diego', 'carlos', 'michael', 'leo', 'tim', 'john', 'james', 'daniel', 'alex', 'nick', 'steve',
  };

  /// Đoán giới tính người nói từ nhãn ("Woman", "Dad", "Maria"...) - nhãn
  /// trung tính như "A"/"B" trả về unknown.
  static SpeakerGender genderOfLabel(String label) {
    final l = label.toLowerCase();
    if (_femaleLabels.contains(l)) return SpeakerGender.female;
    if (_maleLabels.contains(l)) return SpeakerGender.male;
    return SpeakerGender.unknown;
  }

  static const _femaleVoiceHints = [
    'female', 'zira', 'samantha', 'karen', 'moira', 'tessa', 'fiona', 'victoria', 'susan', 'hazel', 'aria',
    'jenny', 'libby', 'sonia', 'natasha', 'catherine', 'serena', 'allison', 'ava', 'google us english',
  ];
  static const _maleVoiceHints = [
    'male', 'david', 'mark', 'daniel', 'alex', 'fred', 'george', 'guy', 'ryan', 'thomas', 'arthur', 'aaron',
  ];

  /// Đoán giới tính giọng từ TÊN giọng của hệ điều hành/trình duyệt (vd
  /// "Microsoft Zira", "Google UK English Male"). Android đặt tên dạng mã
  /// ("en-us-x-sfg-local") nên thường trả về unknown.
  static SpeakerGender genderOfVoice(String name) {
    final n = name.toLowerCase();
    // Kiểm tra "female" TRƯỚC vì chuỗi "female" chứa cả "male".
    if (_femaleVoiceHints.any(n.contains)) return SpeakerGender.female;
    if (_maleVoiceHints.any(n.contains)) return SpeakerGender.male;
    return SpeakerGender.unknown;
  }

  /// Gán giọng + cao độ cho từng người nói (theo thứ tự xuất hiện). Nhãn
  /// trung tính luân phiên nam/nữ (A = nam, B = nữ, C = nam...). Nếu máy có
  /// giọng đúng giới tính thì dùng giọng đó với cao độ gốc; không có thì
  /// giữ giọng mặc định và đổi CAO ĐỘ (trầm cho nam, cao cho nữ) để vẫn
  /// phân biệt được người nói.
  static Map<String, VoiceAssignment> assignVoices(
    List<String> speakers,
    List<Map<String, String>> voices, {
    double basePitch = 1.0,
  }) {
    final ordered = <String>[];
    for (final s in speakers) {
      if (!ordered.contains(s)) ordered.add(s);
    }
    List<Map<String, String>> byGender(SpeakerGender g) {
      final list = voices.where((v) => genderOfVoice(v['name']!) == g).toList();
      // Ưu tiên giọng Mỹ (TOEIC dùng nhiều nhất, khớp giọng mặc định của app).
      list.sort((a, b) => (b['locale']!.toLowerCase() == 'en-us' ? 1 : 0)
          .compareTo(a['locale']!.toLowerCase() == 'en-us' ? 1 : 0));
      return list;
    }

    final pools = {SpeakerGender.female: byGender(SpeakerGender.female), SpeakerGender.male: byGender(SpeakerGender.male)};
    final used = {SpeakerGender.female: 0, SpeakerGender.male: 0};
    var neutralIndex = 0;
    final result = <String, VoiceAssignment>{};
    for (final speaker in ordered) {
      var gender = genderOfLabel(speaker);
      if (gender == SpeakerGender.unknown) {
        gender = neutralIndex.isEven ? SpeakerGender.male : SpeakerGender.female;
        neutralIndex++;
      }
      final pool = pools[gender]!;
      if (pool.isNotEmpty) {
        final voice = pool[used[gender]! % pool.length];
        // Người thứ 2 cùng giới mà dùng lại đúng giọng -> lệch cao độ chút ít.
        final repeat = used[gender]! >= pool.length;
        used[gender] = used[gender]! + 1;
        result[speaker] = VoiceAssignment(voice, basePitch * (repeat ? 1.1 : 1.0));
      } else {
        final nth = used[gender]!;
        used[gender] = nth + 1;
        final shift = gender == SpeakerGender.male ? 0.8 - 0.07 * nth : 1.25 + 0.07 * nth;
        result[speaker] = VoiceAssignment(null, (basePitch * shift).clamp(0.5, 2.0).toDouble());
      }
    }
    return result;
  }
}

class VoiceAssignment {
  /// null = giữ giọng mặc định, chỉ đổi cao độ.
  final Map<String, String>? voice;
  final double pitch;

  const VoiceAssignment(this.voice, this.pitch);
}
