import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF1565C0);       // Deep blue
  static const primaryLight = Color(0xFF42A5F5);
  static const primaryDark = Color(0xFF0D47A1);
  static const secondary = Color(0xFF00BCD4);
  static const accent = Color(0xFF7C4DFF);

  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFF44336);
  static const info = Color(0xFF2196F3);

  static const priorityHigh = Color(0xFFE53935);
  static const priorityMedium = Color(0xFFFF8F00);
  static const priorityLow = Color(0xFF43A047);

  static const statusSubmitted = Color(0xFF1565C0);
  static const statusAssigned = Color(0xFF7B1FA2);
  static const statusInProgress = Color(0xFFE65100);
  static const statusResolved = Color(0xFF2E7D32);
  static const statusClosed = Color(0xFF546E7A);
  static const statusEscalated = Color(0xFFC62828);

  static const background = Color(0xFFF5F7FF);
  static const surface = Color(0xFFFFFFFF);
  static const cardBg = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF1A237E);
  static const textSecondary = Color(0xFF546E7A);
  static const textHint = Color(0xFF90A4AE);

  static const divider = Color(0xFFE3E8F0);
  static const border = Color(0xFFCFD8DC);

  // Dark mode
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkCard = Color(0xFF252525);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      background: AppColors.background,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      headlineLarge: GoogleFonts.poppins(
        fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.poppins(fontSize: 16, color: AppColors.textPrimary),
      bodyMedium: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
      bodySmall: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBg,
      elevation: 2,
      shadowColor: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 14),
      labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primary.withOpacity(0.1),
      labelStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textHint,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  // Status colors
  static Color getStatusColor(String status) {
    switch (status) {
      case 'submitted': return AppColors.statusSubmitted;
      case 'assigned': return AppColors.statusAssigned;
      case 'in_progress': return AppColors.statusInProgress;
      case 'resolved': return AppColors.statusResolved;
      case 'closed': return AppColors.statusClosed;
      case 'escalated': return AppColors.statusEscalated;
      default: return AppColors.textSecondary;
    }
  }

  static Color getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return AppColors.priorityHigh;
      case 'medium': return AppColors.priorityMedium;
      case 'low': return AppColors.priorityLow;
      default: return AppColors.textSecondary;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category) {
      case 'road_pothole': return const Color(0xFF795548);
      case 'water_leakage': return const Color(0xFF0288D1);
      case 'drainage': return const Color(0xFF00695C);
      case 'street_light': return const Color(0xFFF57F17);
      case 'garbage_sanitation': return const Color(0xFF558B2F);
      case 'others': return const Color(0xFF546E7A);
      default: return AppColors.primary;
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'road_pothole': return Icons.construction;
      case 'water_leakage': return Icons.water_drop;
      case 'drainage': return Icons.water;
      case 'street_light': return Icons.lightbulb;
      case 'garbage_sanitation': return Icons.delete;
      case 'others': return Icons.report_problem;
      default: return Icons.help_outline;
    }
  }
}
