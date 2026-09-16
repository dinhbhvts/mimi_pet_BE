import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme dùng chung cho MaterialApp. Tách riêng khỏi app.dart để dễ tìm/sửa
/// khi cần đổi font, màu, hoặc thêm dark mode sau này.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      fontFamily: 'Arial',
      textTheme: const TextTheme().apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
    );
  }
}
