import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

TextTheme scaledTextTheme(TextTheme base) {
  TextStyle? scale(TextStyle? style, double fallback) =>
      style?.copyWith(fontSize: (style.fontSize ?? fallback).sp);

  return base.copyWith(
    displayLarge: scale(base.displayLarge, 57),
    displayMedium: scale(base.displayMedium, 45),
    displaySmall: scale(base.displaySmall, 36),
    headlineLarge: scale(base.headlineLarge, 32),
    headlineMedium: scale(base.headlineMedium, 28),
    headlineSmall: scale(base.headlineSmall, 24),
    titleLarge: scale(base.titleLarge, 22),
    titleMedium: scale(base.titleMedium, 16),
    titleSmall: scale(base.titleSmall, 14),
    bodyLarge: scale(base.bodyLarge, 16),
    bodyMedium: scale(base.bodyMedium, 14),
    bodySmall: scale(base.bodySmall, 12),
    labelLarge: scale(base.labelLarge, 14),
    labelMedium: scale(base.labelMedium, 12),
    labelSmall: scale(base.labelSmall, 11),
  );
}
