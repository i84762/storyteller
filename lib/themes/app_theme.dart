import 'package:flutter/material.dart';

enum AppThemeMode { sepia, darkPurple }

class AppTheme {
  AppTheme._();

  // ── Sepia colour tokens ──────────────────────────────────────────────────

  static const _sBg        = Color(0xFFF8F0E3); // warm parchment scaffold
  static const _sSurface   = Color(0xFFFFF5E6); // cream card/surface
  static const _sSurfaceCt = Color(0xFFF0DCC0); // tan - elevated container
  static const _sPrimary   = Color(0xFF7B3F00); // dark sienna - buttons/links
  static const _sSecondary = Color(0xFF8B5E3C); // medium brown
  static const _sOnSurface = Color(0xFF2C1A0E); // very dark brown text
  static const _sAppBar    = Color(0xFFEDD8B8); // tan app bar
  static const _sOutline   = Color(0xFFD6C8B0); // subtle dividers

  // ── Dark Purple colour tokens ────────────────────────────────────────────

  static const _dBg        = Color(0xFF100D16); // near-black / slight purple
  static const _dSurface   = Color(0xFF1A1528); // dark purple-grey card
  static const _dSurfaceCt = Color(0xFF221D33); // elevated container
  static const _dPrimary   = Color(0xFF9B8EC4); // soft desaturated lavender
  static const _dSecondary = Color(0xFFB39DDB); // lighter lavender
  static const _dOnSurface = Color(0xFFE8E0F0); // off-white text
  static const _dAppBar    = Color(0xFF151020); // slightly darker than bg
  static const _dOutline   = Color(0xFF2E2640); // subtle purple dividers

  // ── ThemeData factory — Sepia ────────────────────────────────────────────

  static ThemeData get sepia => ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: _sPrimary,
          onPrimary: Colors.white,
          primaryContainer: _sSurfaceCt,
          onPrimaryContainer: _sOnSurface,
          secondary: _sSecondary,
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFFF5DEC0),
          onSecondaryContainer: _sOnSurface,
          tertiary: const Color(0xFFD4840A),
          onTertiary: Colors.white,
          tertiaryContainer: const Color(0xFFFFF0C8),
          onTertiaryContainer: _sOnSurface,
          error: Colors.red,
          onError: Colors.white,
          errorContainer: const Color(0xFFFFDAD6),
          onErrorContainer: const Color(0xFF410002),
          surface: _sSurface,
          onSurface: _sOnSurface,
          surfaceContainerHighest: _sSurfaceCt,
          surfaceContainer: const Color(0xFFF5E6CF),
          outline: _sOutline,
          outlineVariant: const Color(0xFFE8D8C0),
          shadow: Colors.black,
          scrim: Colors.black,
          inverseSurface: _sOnSurface,
          onInverseSurface: _sSurface,
          inversePrimary: _sSurfaceCt,
        ),
        scaffoldBackgroundColor: _sBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: _sAppBar,
          foregroundColor: _sOnSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: _sSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _sOutline),
          ),
        ),
        dividerColor: _sOutline,
        useMaterial3: true,
        fontFamily: 'Roboto',
      );

  // ── ThemeData factory — Dark Purple ──────────────────────────────────────

  static ThemeData get darkPurple => ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: _dPrimary,
          onPrimary: Colors.black,
          primaryContainer: const Color(0xFF2D2540),
          onPrimaryContainer: const Color(0xFFD8C8FF),
          secondary: _dSecondary,
          onSecondary: Colors.black,
          secondaryContainer: const Color(0xFF261E35),
          onSecondaryContainer: const Color(0xFFE0D0FF),
          tertiary: const Color(0xFFB39DDB),
          onTertiary: Colors.black,
          tertiaryContainer: const Color(0xFF1E1830),
          onTertiaryContainer: const Color(0xFFE0D0FF),
          error: const Color(0xFFFFB4AB),
          onError: const Color(0xFF690005),
          errorContainer: const Color(0xFF93000A),
          onErrorContainer: const Color(0xFFFFDAD6),
          surface: _dSurface,
          onSurface: _dOnSurface,
          surfaceContainerHighest: _dSurfaceCt,
          surfaceContainer: _dSurfaceCt,
          outline: const Color(0xFF4A3F5C),
          outlineVariant: _dOutline,
          shadow: Colors.black,
          scrim: Colors.black,
          inverseSurface: _dOnSurface,
          onInverseSurface: _dBg,
          inversePrimary: const Color(0xFF4A3570),
        ),
        scaffoldBackgroundColor: _dBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: _dAppBar,
          foregroundColor: _dOnSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: _dSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dividerColor: _dOutline,
        useMaterial3: true,
        fontFamily: 'Roboto',
      );

  static ThemeData forMode(AppThemeMode mode) =>
      mode == AppThemeMode.sepia ? sepia : darkPurple;
}
