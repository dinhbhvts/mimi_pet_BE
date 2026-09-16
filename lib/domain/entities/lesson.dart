import 'package:flutter/foundation.dart';

import 'word.dart';

/// Một bài học gồm nhiều [Word].
@immutable
class Lesson {
  final String id;
  final String title;
  final String emoji;
  final List<Word> words;

  const Lesson({
    required this.id,
    required this.title,
    required this.emoji,
    required this.words,
  });
}
