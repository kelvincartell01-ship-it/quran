import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colors =
        ColorScheme.fromSeed(
          seedColor: AppColors.emerald,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? const Color(0xFF8AC9AE) : AppColors.emerald,
          onPrimary: isDark ? AppColors.charcoal : Colors.white,
          secondary: AppColors.gold,
          surface: isDark ? AppColors.charcoal : AppColors.warmWhite,
          onSurface: isDark ? AppColors.warmWhite : AppColors.charcoal,
          surfaceContainerHighest: isDark
              ? AppColors.darkSurface
              : AppColors.warmSurface,
          outline: isDark ? const Color(0xFF46534B) : const Color(0xFFDCD8CD),
        );
    final textTheme = ThemeData(useMaterial3: true, brightness: brightness)
        .textTheme
        .copyWith(
          headlineSmall: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.35,
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: const TextStyle(fontSize: 16, height: 1.5),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.45),
          bodySmall: const TextStyle(fontSize: 12, height: 1.4),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: isDark
          ? AppColors.charcoal
          : AppColors.warmWhite,
      textTheme: textTheme,
      dividerColor: colors.outline.withValues(alpha: 0.6),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.charcoal : AppColors.warmWhite,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: colors.onSurface),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.outline.withValues(alpha: 0.65)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmWhite,
        indicatorColor: colors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected
                ? colors.primary
                : colors.onSurface.withValues(alpha: 0.65),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.primary,
        thumbColor: colors.primary,
        inactiveTrackColor: colors.primary.withValues(alpha: 0.18),
      ),
    );
  }
}
