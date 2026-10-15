import 'package:flutter/material.dart';

/// Brand colours from the project specification.
class AppColors {
  static const Color pink = Color(0xFFE9007F); // primary branding and CTAs
  static const Color yellow = Color(0xFFFFD400); // highlights and promos
  static const Color cyan = Color(0xFF00B9D6); // secondary actions
  static const Color white = Color(0xFFFFFFFF); // main background

  static const Color pinkDark = Color(0xFFB80063);
  static const Color cyanDark = Color(0xFF008CA3); // readable cyan for text
  static const Color ink = Color(0xFF1F2430);
  static const Color muted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color success = Color(0xFF1B9E5A);
  static const Color danger = Color(0xFFD92D20);

  static const Color pinkTint = Color(0xFFFDE7F3);
  static const Color cyanTint = Color(0xFFE0F7FB);
  static const Color yellowTint = Color(0xFFFFF6CC);
  static const Color successTint = Color(0xFFE3F6EC);
  static const Color dangerTint = Color(0xFFFEE4E2);
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.pink).copyWith(
      primary: AppColors.pink,
      onPrimary: AppColors.white,
      secondary: AppColors.cyan,
      onSecondary: AppColors.white,
      tertiary: AppColors.yellow,
      onTertiary: AppColors.ink,
      surface: AppColors.white,
      onSurface: AppColors.ink,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.white,
    );
  }
}

/// Shared look for every text field.
InputDecoration appInput({
  required String label,
  IconData? icon,
  Widget? suffix,
  String? hint,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon, color: AppColors.muted),
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    border: border(AppColors.border),
    enabledBorder: border(AppColors.border),
    focusedBorder: border(AppColors.pink, 2),
    errorBorder: border(AppColors.danger),
    focusedErrorBorder: border(AppColors.danger, 2),
  );
}
