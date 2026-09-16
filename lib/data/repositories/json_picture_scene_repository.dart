import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/entities/picture_scene.dart';
import '../../domain/repositories/picture_scene_repository.dart';

/// Implementation của [PictureSceneRepository] đọc từ file JSON tĩnh
/// (assets/scenes/scenes.json) - CÙNG PATTERN với [JsonLessonRepository]
/// (đọc 1 lần, cache lại trong RAM cho các lần gọi sau).
class JsonPictureSceneRepository implements PictureSceneRepository {
  JsonPictureSceneRepository({this.assetPath = 'assets/scenes/scenes.json'});

  final String assetPath;

  List<PictureScene>? _cache;

  @override
  Future<List<PictureScene>> getAllScenes() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final scenesJson = (decoded['scenes'] as List<dynamic>).cast<Map<String, dynamic>>();
    _cache = scenesJson.map(_parseScene).toList();
    return _cache!;
  }

  PictureScene _parseScene(Map<String, dynamic> json) {
    final questionsJson = (json['questions'] as List<dynamic>).cast<Map<String, dynamic>>();
    return PictureScene(
      id: json['id'] as String,
      title: json['title'] as String,
      titleVi: json['titleVi'] as String,
      illustrationId: json['illustrationId'] as String,
      questions: questionsJson.map(_parseQuestion).toList(),
    );
  }

  SceneQuestion _parseQuestion(Map<String, dynamic> json) {
    final optionsJson = json['options'] as List<dynamic>?;
    return SceneQuestion(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      kind: _parseKind(json['kind'] as String),
      options: optionsJson?.cast<String>() ?? const [],
      answer: json['answer'] as String,
    );
  }

  SceneQuestionKind _parseKind(String raw) {
    switch (raw) {
      case 'trueFalse':
        return SceneQuestionKind.trueFalse;
      case 'speak':
        return SceneQuestionKind.speak;
      case 'choice':
      default:
        return SceneQuestionKind.choice;
    }
  }
}
