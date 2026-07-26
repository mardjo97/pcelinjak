import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const meadow = Color(0xFF2F6B4F);
  static const meadowDark = Color(0xFF1E4634);
  static const honey = Color(0xFFD4A017);
  static const honeySoft = Color(0xFFF3E2A8);
  static const cream = Color(0xFFF7F3E8);
  static const ink = Color(0xFF1C241F);
  static const mist = Color(0xFFE8EFE9);

  static const apiaryPalette = [
    Color(0xFF2B6CB0), // plava
    Color(0xFFC53030), // crvena
    Color(0xFF2F855A), // zelena
    Color(0xFFB7791F), // amber
    Color(0xFF6B46C1), // ljubičasta
    Color(0xFF2C7A7B), // teal
  ];
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.meadow,
        primary: AppColors.meadow,
        secondary: AppColors.honey,
        surface: AppColors.cream,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.cream,
    );

    return base.copyWith(
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.meadowDark,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static ThemeData dark() {
    const surface = Color(0xFF15201A);
    const card = Color(0xFF1E2C24);
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.meadow,
        primary: const Color(0xFF6FBF8F),
        secondary: AppColors.honey,
        surface: surface,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: surface,
    );

    return base.copyWith(
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFFE8F0EA),
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F1813),
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      popupMenuTheme: const PopupMenuThemeData(color: card),
    );
  }

  static TextStyle brandTitle({double size = 40, Color? color}) => GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.meadowDark,
        height: 1.05,
      );
}

/// International queen marking color by last digit of year.
Color queenMarkColor(int year) {
  switch (year % 10) {
    case 1:
    case 6:
      return Colors.white;
    case 2:
    case 7:
      return const Color(0xFFF6E05E);
    case 3:
    case 8:
      return const Color(0xFFE53E3E);
    case 4:
    case 9:
      return const Color(0xFF38A169);
    default: // 0, 5
      return const Color(0xFF3182CE);
  }
}

const hiveTypes = ['LR', 'DB', 'Farar', 'Voja', 'Pološka', 'AŽ', 'Nukleus', 'Drugo'];
const pastureTypes = ['Bagrem', 'Suncokret', 'Livada', 'Uljana repica', 'Šumska', 'Drugo'];

const queenEndReasons = {
  'DIED': 'Uginula',
  'REPLACED': 'Zamenjena',
  'SUPERSEDED': 'Zamenjena novom',
  'OTHER': 'Drugo',
};

/// Status košnice (lokalno + sync).
const hiveStatuses = {
  'ACTIVE': 'Aktivna',
  'ARCHIVED': 'Arhivirana',
  'DEAD': 'Ugašena',
};

const workGroupTypes = {
  'MOVED': 'Seljene košnice',
  'GOOD_PASTURE': 'Dobre u paši',
  'QUEEN_CHANGE': 'Zamena matica',
  'CONTROL': 'Za kontrolu',
  'FEEDING': 'Za dohranu',
  'REPRODUCTION': 'Za reprodukciju',
};

const workGroupColors = {
  'MOVED': Color(0xFF2B6CB0), // plava – selidba
  'GOOD_PASTURE': Color(0xFFD69E2E), // zlato – dobra paša
  'QUEEN_CHANGE': Color(0xFFC05621), // narandžasta – matica
  'CONTROL': Color(0xFF6B46C1), // ljubičasta – kontrola
  'FEEDING': Color(0xFF2F855A), // zelena – dohrana
  'REPRODUCTION': Color(0xFFB83280), // magenta – reprodukcija
};

Color workGroupColor(String type) => workGroupColors[type] ?? AppColors.meadow;
