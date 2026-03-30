import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF00E5FF);
  static const Color primaryDark = Color(0xFF00B8D4);
  static const Color primaryContainer = Color(0xFF003D42);
  static const Color onPrimary = Color(0xFF000000);

  // Surface
  static const Color surface = Color(0xFF0D0D0F);
  static const Color surfaceContainer = Color(0xFF1A1A1E);
  static const Color surfaceContainerHigh = Color(0xFF252529);
  static const Color surfaceContainerHighest = Color(0xFF303036);
  static const Color surfaceBright = Color(0xFF3A3A42);

  // Text
  static const Color onSurface = Color(0xFFE8E8ED);
  static const Color onSurfaceVariant = Color(0xFF9E9EA8);
  static const Color onSurfaceDim = Color(0xFF6D6D78);

  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color successContainer = Color(0xFF1B3A1C);
  static const Color error = Color(0xFFFF5252);
  static const Color errorContainer = Color(0xFF3A1C1C);
  static const Color warning = Color(0xFFFFB74D);
  static const Color warningContainer = Color(0xFF3A2E1C);

  // Chart colors
  static const Color chartLine1 = Color(0xFF00E5FF);
  static const Color chartLine2 = Color(0xFF7C4DFF);
  static const Color chartLine3 = Color(0xFFFF6E40);
  static const Color chartGradientStart = Color(0x4000E5FF);
  static const Color chartGradientEnd = Color(0x0000E5FF);

  // PR badge
  static const Color prGold = Color(0xFFFFD700);
  static const Color prGoldContainer = Color(0xFF3A3320);

  // Heatmap intensity levels
  static const Color heatmapEmpty = Color(0xFF1A1A1E);
  static const Color heatmapLevel1 = Color(0xFF003D42);
  static const Color heatmapLevel2 = Color(0xFF006064);
  static const Color heatmapLevel3 = Color(0xFF00838F);
  static const Color heatmapLevel4 = Color(0xFF00E5FF);

  // Muscle group colors
  static const Map<String, Color> muscleGroupColors = {
    'chest': Color(0xFFFF5252),
    'back': Color(0xFF448AFF),
    'shoulders': Color(0xFFFF9800),
    'biceps': Color(0xFF7C4DFF),
    'triceps': Color(0xFFE040FB),
    'legs': Color(0xFF4CAF50),
    'hamstrings': Color(0xFF66BB6A),
    'glutes': Color(0xFFAB47BC),
    'core': Color(0xFFFFEB3B),
    'calves': Color(0xFF26A69A),
    'forearms': Color(0xFF8D6E63),
    'cardio': Color(0xFFEF5350),
    'full_body': Color(0xFF00E5FF),
  };
}
