import 'package:flutter/material.dart';

const Color ink = Color(0xFF17201D);
const Color mutedInk = Color(0xFF5B6661);
const Color divider = Color(0xFFB7C0BB);
const Color softDivider = Color(0xFFE1E6E2);
const Color paper = Color(0xFFFFFFFF);
const Color canvas = Color(0xFFFAFBF8);
const Color softSurface = Color(0xFFF0F3EF);

/// Acento sobrio para acciones y selección.
const Color accent = Color(0xFF126B5B);
const Color accentSoft = Color(0xFFE3F0EB);
const Color accentDark = Color(0xFF0B4D41);

/// Colores semánticos. Siempre se acompañan de texto e icono.
const Color paidInk = Color(0xFF1C6B4C);
const Color paidSoft = Color(0xFFE5F2EA);
const Color soonInk = Color(0xFF8F5A00);
const Color soonSoft = Color(0xFFF8EEDC);
const Color lateInk = Color(0xFFAE2A22);
const Color lateSoft = Color(0xFFF9E7E4);

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: accent,
    onPrimary: paper,
    secondary: accentDark,
    onSecondary: paper,
    surface: paper,
    onSurface: ink,
    surfaceContainerLowest: paper,
    surfaceContainerLow: softSurface,
    surfaceContainer: Color(0xFFEDEDED),
    surfaceContainerHigh: Color(0xFFE4E4E4),
    onSurfaceVariant: mutedInk,
    outline: divider,
    outlineVariant: softDivider,
    error: lateInk,
    onError: paper,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: canvas,
  );

  final textTheme = base.textTheme
      .copyWith(
        displaySmall: const TextStyle(
          fontSize: 32,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: const TextStyle(
          fontSize: 24,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: const TextStyle(
          fontSize: 22,
          height: 1.25,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          height: 1.3,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.45),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.45),
        labelLarge: const TextStyle(
          fontSize: 14,
          height: 1.2,
          fontWeight: FontWeight.w600,
        ),
        bodySmall: const TextStyle(fontSize: 13, height: 1.4),
      )
      .apply(bodyColor: ink, displayColor: ink);

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: canvas,
      surfaceTintColor: Colors.transparent,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: ink,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: softDivider),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: softDivider,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: mutedInk, fontSize: 16),
      floatingLabelStyle: const TextStyle(color: ink, fontSize: 16),
      hintStyle: const TextStyle(color: mutedInk, fontSize: 16),
      helperStyle: const TextStyle(color: mutedInk, fontSize: 13),
      errorStyle: const TextStyle(color: ink, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: lateInk, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: lateInk, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: paper,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentDark,
        side: const BorderSide(color: divider),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentDark,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(44, 44),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: canvas,
      indicatorColor: accentSoft,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 13,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? accentDark : ink,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? accentDark : mutedInk,
          size: 24,
        ),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: canvas,
      selectedIconTheme: IconThemeData(color: accentDark, size: 24),
      unselectedIconTheme: IconThemeData(color: mutedInk, size: 24),
      selectedLabelTextStyle: TextStyle(
        color: accentDark,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: mutedInk,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      indicatorColor: accentSoft,
      useIndicator: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: divider),
      ),
      titleTextStyle: const TextStyle(
        color: ink,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: const TextStyle(color: ink, fontSize: 15, height: 1.45),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ink,
      contentTextStyle: const TextStyle(color: paper, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      actionTextColor: paper,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: accent,
      linearTrackColor: Color(0xFFDDE5E0),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: ink,
      textColor: ink,
      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: softSurface,
      side: const BorderSide(color: softDivider),
      labelStyle: const TextStyle(color: ink, fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(color: paper, fontSize: 13),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: softDivider),
      ),
      textStyle: const TextStyle(color: ink, fontSize: 14),
    ),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: paper,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: accentDark,
      headerForegroundColor: paper,
    ),
  );
}
