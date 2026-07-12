import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _seed = Color(0xff6750a4);
  static const _buttonRadius = 8.0;
  static const _buttonMinSize = Size(48, 48);
  static const _iconButtonMinSize = Size.square(48);

  static ThemeData light() => _theme(Brightness.light);

  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.neutral,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surfaceContainerLowest,
      visualDensity: VisualDensity.standard,
      textTheme: ThemeData(brightness: brightness).textTheme.copyWith(
        headlineSmall: const TextStyle(
          fontSize: 24,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          height: 1.3,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.45),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: colors.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: .65)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainer,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.primary, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: colors.surfaceContainerLowest,
        indicatorColor: colors.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: _buttonMinSize,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: _buttonMinSize,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: _buttonMinSize,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(_buttonMinSize),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: colors.outlineVariant),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: _iconButtonMinSize,
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant.withValues(alpha: .7),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
