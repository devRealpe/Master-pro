import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoPageTransitionsBuilder;
import 'package:flutter/services.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_layout.dart';
import '../tokens/app_typography.dart';

/// Construye el tema de Material a partir de los tokens. Los componentes de
/// Material heredan de aquí; nada define colores ni tamaños por su cuenta.
abstract final class AppTheme {
  static final light = _build(AppColors.light);
  static final dark = _build(AppColors.dark);

  static ThemeData _build(AppColors c) {
    final text = AppTypography.textTheme(ink: c.ink, inkSoft: c.inkSoft);

    final scheme = ColorScheme(
      brightness: c.brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primaryContainer,
      onPrimaryContainer: c.onPrimaryContainer,
      secondary: c.accent,
      onSecondary: c.onAccent,
      secondaryContainer: c.accentContainer,
      onSecondaryContainer: c.onAccentContainer,
      tertiary: c.info,
      onTertiary: c.surface,
      tertiaryContainer: c.infoContainer,
      onTertiaryContainer: c.onInfoContainer,
      error: c.danger,
      onError: c.onDanger,
      errorContainer: c.dangerContainer,
      onErrorContainer: c.onDangerContainer,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.inkSoft,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surfaceRaised,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.surfaceRaised,
      outline: c.inkMuted,
      outlineVariant: c.outline,
      inverseSurface: c.ink,
      onInverseSurface: c.canvas,
      inversePrimary: c.primaryContainer,
      surfaceTint: Colors.transparent,
      shadow: const Color(0xFF1B2452),
      scrim: Colors.black,
    );

    final buttonShape = const RoundedRectangleBorder(borderRadius: AppRadii.md);
    const buttonSize = Size(64, AppSpacing.touchTarget);
    const buttonPadding = EdgeInsets.symmetric(horizontal: AppSpacing.lg);

    OutlineInputBorder fieldBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadii.md,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: c.canvas,
      canvasColor: c.canvas,
      dividerColor: c.outline,
      splashFactory: InkSparkle.splashFactory,
      extensions: [c],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: overlayStyle(c),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: c.surface,
        indicatorColor: c.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall!.copyWith(
            letterSpacing: 0,
            color: states.contains(WidgetState.selected)
                ? c.primary
                : c.inkMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? c.onPrimaryContainer
                : c.inkMuted,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
          side: BorderSide(color: c.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        hintStyle: text.bodyLarge!.copyWith(color: c.inkMuted),
        labelStyle: text.bodyLarge!.copyWith(color: c.inkSoft),
        floatingLabelStyle: text.labelLarge!.copyWith(color: c.primary),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall!.copyWith(color: c.danger),
        border: fieldBorder(Colors.transparent),
        enabledBorder: fieldBorder(Colors.transparent),
        focusedBorder: fieldBorder(c.primary, 1.5),
        errorBorder: fieldBorder(c.danger),
        focusedErrorBorder: fieldBorder(c.danger, 1.5),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.lg,
          side: BorderSide(color: c.outline),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: c.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.xl),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium!.copyWith(color: c.inkSoft),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: text.bodyMedium!.copyWith(color: c.canvas),
        actionTextColor: c.primaryContainer,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: c.outline, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: c.inkSoft,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.surfaceRaised,
        circularTrackColor: c.surfaceRaised,
      ),
      iconTheme: IconThemeData(color: c.inkSoft, size: 24),
    );
  }

  /// Barras del sistema transparentes, con iconos legibles sobre el tema.
  static SystemUiOverlayStyle overlayStyle(AppColors c) {
    final icons = c.isDark ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
      statusBarBrightness: c.brightness,
      systemNavigationBarColor: c.surface,
      systemNavigationBarIconBrightness: icons,
    );
  }
}
