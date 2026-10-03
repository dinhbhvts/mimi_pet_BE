import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/toeic_vocab.dart';
import '../../services/cloud_state_store.dart';

/// Tự đọc khi sang thẻ mới (màn "Từ vựng TOEIC").
enum VocabAutoRead {
  off('Tắt'),
  word('Đọc từ'),
  wordAndExample('Từ + câu ví dụ');

  const VocabAutoRead(this.label);
  final String label;
}

/// Nơi lưu từ đã thuộc + tuỳ chọn - tách interface để test dùng bản trong bộ nhớ.
abstract class VocabStorage {
  List<String> loadKnown();
  void saveKnown(List<String> words);
  Map<String, dynamic> loadPrefs();
  void savePrefs(Map<String, dynamic> prefs);
}

/// Lưu trong state đồng bộ cloud: đổi máy (web/Android) vẫn giữ từ đã thuộc.
class CloudVocabStorage implements VocabStorage {
  CloudVocabStorage(this._store);

  final CloudStateStore _store;
  static const knownKey = 'toeicVocabKnown';
  static const prefsKey = 'toeicVocabPrefs';

  @override
  List<String> loadKnown() => (_store.getRaw<List<dynamic>>(knownKey) ?? const []).whereType<String>().toList();

  @override
  void saveKnown(List<String> words) => _store.setRaw(knownKey, words);

  @override
  Map<String, dynamic> loadPrefs() => _store.getMap(prefsKey);

  @override
  void savePrefs(Map<String, dynamic> prefs) => _store.setRaw(prefsKey, prefs);
}

/// Thẻ từ vựng TOEIC trong phần ôn luyện: giống thẻ xoay vòng ở màn chờ
/// (vẫn TỰ CHUYỂN TỪ), thêm lọc theo chủ đề, trộn ngẫu nhiên, tua lại, đánh
/// dấu "đã thuộc" (ẩn khỏi lượt học) và tự đọc từ/câu ví dụ. Bộ đếm giờ nằm
/// ở màn hình (cần vsync); lớp này chỉ giữ bộ thẻ + tuỳ chọn để test được.
class ToeicVocabController extends ChangeNotifier {
  ToeicVocabController({
    VocabStorage? storage,
    this._topics = ToeicVocab.topics,
    Random? random,
  })  : _storage = storage,
        _random = random ?? Random() {
    _known.addAll(storage?.loadKnown() ?? const []);
    final prefs = storage?.loadPrefs() ?? const {};
    final seconds = prefs['seconds'];
    if (seconds is int && cardSecondsOptions.contains(seconds)) _cardSeconds = seconds;
    _autoAdvance = prefs['auto'] is bool ? prefs['auto'] as bool : true;
    _autoRead = VocabAutoRead.values.where((m) => m.name == prefs['read']).firstOrNull ?? VocabAutoRead.word;
    _shuffle = prefs['shuffle'] is bool ? prefs['shuffle'] as bool : true;
    _hideKnown = prefs['hideKnown'] is bool ? prefs['hideKnown'] as bool : true;
    _rebuildDeck();
  }

  static const cardSecondsOptions = [5, 8, 12, 20];

  final VocabStorage? _storage;
  final List<ToeicVocabTopic> _topics;
  final Random _random;
  final Set<String> _known = {};

  String? _topicId;
  bool _shuffle = true;
  bool _hideKnown = true;
  bool _autoAdvance = true;
  VocabAutoRead _autoRead = VocabAutoRead.word;
  int _cardSeconds = 12;
  List<ToeicWord> _deck = const [];
  int _index = 0;

  List<ToeicVocabTopic> get topics => _topics;
  String? get topicId => _topicId;
  bool get shuffle => _shuffle;
  bool get hideKnown => _hideKnown;
  bool get autoAdvance => _autoAdvance;
  VocabAutoRead get autoRead => _autoRead;
  int get cardSeconds => _cardSeconds;

  List<ToeicWord> get deck => List.unmodifiable(_deck);
  int get index => _index;
  ToeicWord? get current => _deck.isEmpty ? null : _deck[_index];

  bool isKnown(ToeicWord w) => _known.contains(w.word);
  int get knownCount => _allWords.where(isKnown).length;
  int get totalCount => _allWords.length;
  int knownCountIn(ToeicVocabTopic t) => t.words.where(isKnown).length;

  /// Số từ trong chủ đề đang chọn (kể cả từ đã thuộc) - để hiện "đã thuộc x/y".
  List<ToeicWord> get topicWords => _topicId == null ? _allWords : _topics.firstWhere((t) => t.id == _topicId).words;

  List<ToeicWord> get _allWords => [for (final t in _topics) ...t.words];

  void _rebuildDeck({ToeicWord? keep}) {
    final words = topicWords.where((w) => !_hideKnown || !isKnown(w)).toList();
    if (_shuffle) words.shuffle(_random);
    _deck = words;
    final keepIndex = keep == null ? -1 : _deck.indexOf(keep);
    _index = keepIndex >= 0 ? keepIndex : 0;
  }

  void selectTopic(String? id) {
    if (id == _topicId) return;
    _topicId = id;
    _rebuildDeck();
    notifyListeners();
  }

  void next() {
    if (_deck.isEmpty) return;
    _index = (_index + 1) % _deck.length;
    // Hết 1 vòng thẻ trộn -> trộn lại để vòng sau khác thứ tự.
    if (_index == 0 && _shuffle && _deck.length > 1) {
      final last = _deck.last;
      _deck = List.of(_deck)..shuffle(_random);
      if (_deck.first == last) _deck.add(_deck.removeAt(0));
    }
    notifyListeners();
  }

  void previous() {
    if (_deck.isEmpty) return;
    _index = (_index - 1 + _deck.length) % _deck.length;
    notifyListeners();
  }

  /// Đánh dấu/bỏ đánh dấu "đã thuộc". Đang ẩn từ đã thuộc thì từ vừa đánh
  /// dấu rời khỏi bộ thẻ và thẻ KẾ TIẾP hiện ra ngay ở đúng vị trí đó.
  void toggleKnown(ToeicWord w) {
    if (!_known.remove(w.word)) _known.add(w.word);
    _storage?.saveKnown(_known.toList()..sort());
    if (_hideKnown && isKnown(w)) {
      final at = _deck.indexOf(w);
      if (at >= 0) {
        _deck = List.of(_deck)..removeAt(at);
        if (_index >= _deck.length) _index = 0;
      }
    }
    notifyListeners();
  }

  void setHideKnown(bool value) {
    if (value == _hideKnown) return;
    _hideKnown = value;
    _rebuildDeck(keep: current);
    _savePrefs();
    notifyListeners();
  }

  void setShuffle(bool value) {
    if (value == _shuffle) return;
    _shuffle = value;
    _rebuildDeck(keep: current);
    _savePrefs();
    notifyListeners();
  }

  void setAutoAdvance(bool value) {
    if (value == _autoAdvance) return;
    _autoAdvance = value;
    _savePrefs();
    notifyListeners();
  }

  void setAutoRead(VocabAutoRead mode) {
    if (mode == _autoRead) return;
    _autoRead = mode;
    _savePrefs();
    notifyListeners();
  }

  void setCardSeconds(int seconds) {
    if (seconds == _cardSeconds || !cardSecondsOptions.contains(seconds)) return;
    _cardSeconds = seconds;
    _savePrefs();
    notifyListeners();
  }

  void _savePrefs() => _storage?.savePrefs({
        'seconds': _cardSeconds,
        'auto': _autoAdvance,
        'read': _autoRead.name,
        'shuffle': _shuffle,
        'hideKnown': _hideKnown,
      });
}
