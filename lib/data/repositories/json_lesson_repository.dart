import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../domain/entities/lesson.dart';
import '../../domain/entities/word.dart';
import '../../domain/repositories/lesson_repository.dart';

/// Implementation của [LessonRepository] đọc bài học từ file JSON tĩnh
/// (assets/lessons/lessons.json) - dễ thêm/sửa bài học mà không cần sửa
/// code, và là bước đệm dễ dàng nếu sau này muốn chuyển sang SQLite (chỉ cần
/// viết thêm 1 implementation khác của [LessonRepository]).
class JsonLessonRepository implements LessonRepository {
  JsonLessonRepository({this.assetPath = 'assets/lessons/lessons.json'});

  final String assetPath;

  List<Lesson>? _cache;

  @override
  Future<List<Lesson>> getAllLessons() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final lessonsJson = (decoded['lessons'] as List<dynamic>).cast<Map<String, dynamic>>();
    _cache = lessonsJson.map(_parseLesson).toList();
    return _cache!;
  }

  Lesson _parseLesson(Map<String, dynamic> json) {
    final wordsJson = (json['words'] as List<dynamic>).cast<Map<String, dynamic>>();
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      emoji: json['emoji'] as String,
      words: wordsJson.map(_parseWord).toList(),
    );
  }

  Word _parseWord(Map<String, dynamic> json) {
    final swatchHex = json['swatchColor'] as String?;
    final sentenceWordsJson = json['sentenceWords'] as List<dynamic>?;
    return Word(
      id: json['id'] as String,
      en: json['en'] as String,
      vi: json['vi'] as String,
      emoji: json['emoji'] as String?,
      swatchColor: swatchHex != null ? Color(int.parse(swatchHex, radix: 16)) : null,
      promptType: (json['promptType'] as String?) == 'repeat'
          ? PromptType.repeat
          : PromptType.identify,
      sentenceTemplate: json['sentenceTemplate'] as String?,
      sentenceWords: sentenceWordsJson?.cast<String>(),
    );
  }
}
