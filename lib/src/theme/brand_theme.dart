import 'package:flutter/material.dart';

class BrandTheme {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textOnPrimary;
  final Color inputBackground;
  final Color placeholder;
  final Color disabledText;
  final Color disabledBackground;
  final Color success;
  final Color warning;
  final Color danger;
  final double cardRadius;
  final double inputRadius;
  final double buttonRadius;
  final ThemeMode themeMode;
  final bool useCinematicBackgrounds;
  final bool useLogoGlow;
  final bool useHeavyBlur;

  const BrandTheme({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textOnPrimary,
    required this.inputBackground,
    required this.placeholder,
    required this.disabledText,
    required this.disabledBackground,
    required this.success,
    required this.warning,
    required this.danger,
    required this.cardRadius,
    required this.inputRadius,
    required this.buttonRadius,
    required this.themeMode,
    required this.useCinematicBackgrounds,
    required this.useLogoGlow,
    required this.useHeavyBlur,
  });

  factory BrandTheme.fromJson(
    Map<String, dynamic> json, {
    BrandTheme? fallback,
  }) {
    final base = fallback ?? BrandTheme.generic();
    final colors = _mapOf(json['colors']);
    final appearance = _mapOf(json['appearance']);
    final preset = appearance['theme_preset']?.toString() ?? '';

    return BrandTheme(
      primary: _colorValue(
        colors['primary'] ?? colors['primary_gold'],
        base.primary,
      ),
      primaryLight: _colorValue(
        colors['primary_light'] ?? colors['primary_gold_light'],
        base.primaryLight,
      ),
      primaryDark: _colorValue(
        colors['primary_dark'] ?? colors['primary_gold_dark'],
        base.primaryDark,
      ),
      secondary: _colorValue(colors['secondary'], base.secondary),
      accent: _colorValue(colors['accent'], base.accent),
      background: _colorValue(colors['background'], base.background),
      surface: _colorValue(colors['surface'], base.surface),
      card: _colorValue(colors['card'], base.card),
      border: _colorValue(colors['border'], base.border),
      textPrimary: _colorValue(colors['text_primary'], base.textPrimary),
      textSecondary: _colorValue(colors['text_secondary'], base.textSecondary),
      textOnPrimary: _colorValue(colors['text_on_primary'], base.textOnPrimary),
      inputBackground: _colorValue(
        colors['input_background'],
        base.inputBackground,
      ),
      placeholder: _colorValue(colors['placeholder'], base.placeholder),
      disabledText: _colorValue(colors['disabled_text'], base.disabledText),
      disabledBackground: _colorValue(
        colors['disabled_background'],
        base.disabledBackground,
      ),
      success: _colorValue(colors['success'], base.success),
      warning: _colorValue(colors['warning'], base.warning),
      danger: _colorValue(colors['danger'], base.danger),
      cardRadius: _doubleValue(appearance['card_radius'], base.cardRadius),
      inputRadius: _doubleValue(appearance['input_radius'], base.inputRadius),
      buttonRadius: _doubleValue(
        appearance['button_radius'],
        base.buttonRadius,
      ),
      themeMode: _themeMode(
        appearance['theme_mode']?.toString() ?? _themeModeFromPreset(preset),
        base.themeMode,
      ),
      useCinematicBackgrounds: _boolValue(
        appearance['use_cinematic_backgrounds'],
        base.useCinematicBackgrounds,
      ),
      useLogoGlow: _boolValue(appearance['use_logo_glow'], base.useLogoGlow),
      useHeavyBlur: _boolValue(appearance['use_heavy_blur'], base.useHeavyBlur),
    );
  }

  static BrandTheme generic() {
    return const BrandTheme(
      primary: Color(0xFF4C8BF5),
      primaryLight: Color(0xFF93B8FF),
      primaryDark: Color(0xFF1E4FA8),
      secondary: Color(0xFFB7CCFF),
      accent: Color(0xFF3D67B4),
      background: Color(0xFF0B1020),
      surface: Color(0xFF151C31),
      card: Color(0xFF10172A),
      border: Color(0x22FFFFFF),
      textPrimary: Colors.white,
      textSecondary: Color(0xFFB9C3DD),
      textOnPrimary: Color(0xFF0B1020),
      inputBackground: Color(0xFF151C31),
      placeholder: Color(0xFFB9C3DD),
      disabledText: Color(0xFF7D8CB3),
      disabledBackground: Color(0xFF10172A),
      success: Color(0xFF04B155),
      warning: Color(0xFFF4B740),
      danger: Color(0xFFEB3B5A),
      cardRadius: 24,
      inputRadius: 18,
      buttonRadius: 18,
      themeMode: ThemeMode.dark,
      useCinematicBackgrounds: true,
      useLogoGlow: true,
      useHeavyBlur: false,
    );
  }

  static BrandTheme barbershop() {
    return const BrandTheme(
      primary: Color(0xFFD4A84F),
      primaryLight: Color(0xFFE8C36A),
      primaryDark: Color(0xFF9B6F24),
      secondary: Color(0xFFE8D8B8),
      accent: Color(0xFFB77A3E),
      background: Color(0xFF090909),
      surface: Color(0xFF1A1512),
      card: Color(0xFF120E0B),
      border: Color(0x22FFFFFF),
      textPrimary: Colors.white,
      textSecondary: Color(0xFFB9AFA5),
      textOnPrimary: Color(0xFF090909),
      inputBackground: Color(0xFF1A1512),
      placeholder: Color(0xFFB9AFA5),
      disabledText: Color(0xFF7C736C),
      disabledBackground: Color(0xFF120E0B),
      success: Color(0xFF04B155),
      warning: Color(0xFFF4B740),
      danger: Color(0xFFEB3B5A),
      cardRadius: 24,
      inputRadius: 18,
      buttonRadius: 18,
      themeMode: ThemeMode.dark,
      useCinematicBackgrounds: true,
      useLogoGlow: true,
      useHeavyBlur: false,
    );
  }

  static BrandTheme salon() {
    return const BrandTheme(
      primary: Color(0xFFE6B7A9),
      primaryLight: Color(0xFFF3D4CC),
      primaryDark: Color(0xFFA66A5E),
      secondary: Color(0xFFF4DDD7),
      accent: Color(0xFFC87D6E),
      background: Color(0xFF120F14),
      surface: Color(0xFF201A21),
      card: Color(0xFF171218),
      border: Color(0x26FFFFFF),
      textPrimary: Colors.white,
      textSecondary: Color(0xFFE1CFC9),
      textOnPrimary: Color(0xFF120F14),
      inputBackground: Color(0xFF201A21),
      placeholder: Color(0xFFE1CFC9),
      disabledText: Color(0xFFAA9A96),
      disabledBackground: Color(0xFF171218),
      success: Color(0xFF1D9A73),
      warning: Color(0xFFF0A63B),
      danger: Color(0xFFDE5770),
      cardRadius: 24,
      inputRadius: 18,
      buttonRadius: 18,
      themeMode: ThemeMode.dark,
      useCinematicBackgrounds: true,
      useLogoGlow: true,
      useHeavyBlur: false,
    );
  }

  static BrandTheme jcStudio() {
    return const BrandTheme(
      primary: Color(0xFFC98F86),
      primaryLight: Color(0xFFE7C9C3),
      primaryDark: Color(0xFF8D5A52),
      secondary: Color(0xFFEFE0DC),
      accent: Color(0xFFA86E63),
      background: Color(0xFFFBF7F3),
      surface: Color(0xFFF4EDE8),
      card: Color(0xFFFFFFFF),
      border: Color(0x22A86E63),
      textPrimary: Color(0xFF1F1614),
      textSecondary: Color(0xFF6D5751),
      textOnPrimary: Color(0xFF1F1614),
      inputBackground: Color(0xFFF4EDE8),
      placeholder: Color(0xFF8D7A74),
      disabledText: Color(0xFFAA9F9A),
      disabledBackground: Color(0xFFF4EDE8),
      success: Color(0xFF1D9A73),
      warning: Color(0xFFC98B2C),
      danger: Color(0xFFC94D5A),
      cardRadius: 24,
      inputRadius: 18,
      buttonRadius: 18,
      themeMode: ThemeMode.light,
      useCinematicBackgrounds: false,
      useLogoGlow: false,
      useHeavyBlur: false,
    );
  }

  ThemeData buildThemeData() {
    final brightness = themeMode == ThemeMode.light
        ? Brightness.light
        : Brightness.dark;
    final onSurface = _bestTextFor(surface);
    final onPrimary = _bestAccessibleText(primary, textOnPrimary);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      disabledColor: disabledText,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        onSecondary: _bestTextFor(secondary),
        error: danger,
        onError: _bestTextFor(danger),
        surface: surface,
        onSurface: onSurface,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBackground,
        hintStyle: TextStyle(color: placeholder),
        labelStyle: TextStyle(color: textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: disabledBackground),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: danger),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: .2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border),
          backgroundColor: surface.withValues(alpha: .45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryLight),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        labelStyle: TextStyle(color: textPrimary),
        selectedColor: primary,
        shape: const StadiumBorder(),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textPrimary,
        textColor: textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius - 6),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius + 4),
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(color: textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        contentTextStyle: TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius - 4),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        circularTrackColor: border,
        linearTrackColor: border,
      ),
    );
  }

  static Map<String, dynamic> _mapOf(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    return const <String, dynamic>{};
  }

  static Color _colorValue(dynamic value, Color fallback) {
    if (value is int) return Color(value);
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return fallback;
    var hex = text.replaceAll('#', '').replaceAll('0x', '');
    if (hex.length == 3) {
      hex = hex.split('').map((part) => '$part$part').join();
    } else if (hex.length == 4) {
      hex = hex.split('').map((part) => '$part$part').join();
    } else if (hex.length == 6) {
      hex = 'FF$hex';
    }
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return fallback;
    return Color(parsed);
  }

  static double _doubleValue(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _boolValue(dynamic value, bool fallback) {
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase();
    if (text == null || text.isEmpty) return fallback;
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return fallback;
  }

  static ThemeMode _themeMode(String? value, ThemeMode fallback) {
    switch (value?.trim().toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return fallback;
    }
  }

  static String _themeModeFromPreset(String preset) {
    switch (preset) {
      case 'elegant_light':
      case 'generic_light':
        return 'light';
      default:
        return 'dark';
    }
  }

  static Color _bestTextFor(Color background) {
    return background.computeLuminance() > .5 ? Colors.black : Colors.white;
  }

  static Color _bestAccessibleText(Color background, Color candidate) {
    return _contrastRatio(candidate, background) >= 4.5
        ? candidate
        : _bestTextFor(background);
  }

  static double _contrastRatio(Color foreground, Color background) {
    final l1 = foreground.computeLuminance();
    final l2 = background.computeLuminance();
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }
}
