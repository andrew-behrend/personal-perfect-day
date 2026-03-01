import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: PdColors.brand,
      brightness: Brightness.light,
    ).copyWith(
      primary: PdColors.brand,
      onPrimary: PdColors.textOnDark,
      secondary: PdColors.accent,
      surface: PdColors.surface,
      onSurface: PdColors.textPrimary,
      outline: PdColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: PdColors.background,
      textTheme: PdTypography.textTheme,
      fontFamily: PdTypography.fontFamily,
      cardTheme: CardThemeData(
        color: PdColors.surface,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PdRadius.lg),
          side: const BorderSide(color: PdColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: PdSpacing.lg,
            vertical: PdSpacing.sm,
          ),
          textStyle: PdTypography.label,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PdRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: PdSpacing.lg,
            vertical: PdSpacing.sm,
          ),
          textStyle: PdTypography.label,
          side: const BorderSide(color: PdColors.brand),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PdRadius.md),
          ),
        ),
      ),
    );
  }
}
