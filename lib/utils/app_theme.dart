import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary brand colors
  static const Color primaryColor = Color(0xFF2D3047); // Deep indigo
  static const Color primaryLightColor = Color(0xFF444967); // Lighter indigo
  static const Color primaryDarkColor = Color(0xFF1A1C2E); // Darker indigo
  static const Color accentColor = Color(0xFFE8C547); // Warm gold

  // Secondary colors
  static const Color secondaryColor = Color(0xFFE8C547); // Warm gold
  static const Color secondaryLightColor = Color(0xFFF2DC86); // Light gold
  static const Color secondaryDarkColor = Color(0xFFCDAC32); // Dark gold

  // Tertiary accent
  static const Color tertiaryColor = Color(0xFF419D78); // Accent green
  static const Color tertiaryLightColor = Color(0xFF5CBF99); // Light green
  static const Color tertiaryDarkColor = Color(0xFF2E7057); // Dark green

  // UI colors
  static const Color surfaceColor = Colors.white;
  static const Color backgroundColor = Color(0xFFF9FAFC); // Light background
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFEEEEF1);
  static const Color shadowColor = Color(0x0D000000); // 5% black shadow
  static const Color errorColor = Color(0xFFE53935); // Red for errors
  static const Color successColor = Color(0xFF43A047); // Green for success

  // Text colors
  static const Color textPrimaryColor = Color(0xFF2D3047); // Same as primary
  static const Color textSecondaryColor = Color(0xFF616E85); // Muted blue-gray
  static const Color textLightColor = Color(0xFF8F9BB3); // Light text color
  static const Color textOnPrimaryColor = Colors.white;
  static const Color textOnSecondaryColor = Color(0xFF2D3047);

  // Spacing system
  static const double spacing_xxxs = 2.0;
  static const double spacing_xxs = 4.0;
  static const double spacing_xs = 8.0;
  static const double spacing_s = 12.0;
  static const double spacing_m = 16.0;
  static const double spacing_l = 24.0;
  static const double spacing_xl = 32.0;
  static const double spacing_xxl = 48.0;
  static const double spacing_xxxl = 64.0;

  // Border radius
  static const double borderRadius_xs = 4.0;
  static const double borderRadius_s = 8.0;
  static const double borderRadius_m = 12.0;
  static const double borderRadius_l = 16.0;
  static const double borderRadius_xl = 24.0;
  static const double borderRadius_xxl = 32.0;
  static const double borderRadius_circle = 500.0;

  // Elevations
  static List<BoxShadow> shadowElevation1 = [
    BoxShadow(
      color: shadowColor.withOpacity(0.08),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowElevation2 = [
    BoxShadow(
      color: shadowColor.withOpacity(0.08),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowElevation3 = [
    BoxShadow(
      color: shadowColor.withOpacity(0.1),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  static List<BoxShadow> shadowElevation4 = [
    BoxShadow(
      color: shadowColor.withOpacity(0.12),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  // Typography - Using Google Fonts with refined pairings
  static final TextStyle displayLarge = GoogleFonts.playfairDisplay(
    fontSize: 56,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.5,
    color: textPrimaryColor,
  );

  static final TextStyle displayMedium = GoogleFonts.playfairDisplay(
    fontSize: 42,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    color: textPrimaryColor,
  );

  static final TextStyle displaySmall = GoogleFonts.playfairDisplay(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.25,
    color: textPrimaryColor,
  );

  static final TextStyle headingLarge = GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.25,
    color: textPrimaryColor,
  );

  static final TextStyle headingMedium = GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.25,
    color: textPrimaryColor,
  );

  static final TextStyle headingSmall = GoogleFonts.playfairDisplay(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.25,
    color: textPrimaryColor,
  );

  static final TextStyle bodyLarge = GoogleFonts.workSans(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
    color: textPrimaryColor,
  );

  static final TextStyle bodyMedium = GoogleFonts.workSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
    color: textPrimaryColor,
  );

  static final TextStyle bodySmall = GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.4,
    color: textSecondaryColor,
  );

  static final TextStyle labelLarge = GoogleFonts.workSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
    color: textPrimaryColor,
  );

  static final TextStyle labelMedium = GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
    color: textPrimaryColor,
  );

  static final TextStyle labelSmall = GoogleFonts.workSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
    color: textPrimaryColor,
  );

  static final TextStyle priceText = GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0,
    color: primaryColor,
  );

  // Button Styles
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: EdgeInsets.symmetric(horizontal: spacing_l, vertical: spacing_m),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius_m),
    ),
    textStyle: labelMedium.copyWith(color: Colors.white, letterSpacing: 0.5),
  );

  static final ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: secondaryColor,
    foregroundColor: textOnSecondaryColor,
    elevation: 0,
    padding: EdgeInsets.symmetric(horizontal: spacing_l, vertical: spacing_m),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius_m),
    ),
    textStyle: labelMedium.copyWith(letterSpacing: 0.5),
  );

  static final ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: BorderSide(color: primaryColor, width: 1.5),
    padding: EdgeInsets.symmetric(horizontal: spacing_l, vertical: spacing_m),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius_m),
    ),
    textStyle: labelMedium.copyWith(letterSpacing: 0.5),
  );

  static final ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    padding: EdgeInsets.symmetric(horizontal: spacing_m, vertical: spacing_s),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius_m),
    ),
    textStyle: labelMedium.copyWith(letterSpacing: 0.5),
  );

  // Input Decoration
  static final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(
      horizontal: spacing_m,
      vertical: spacing_m,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius_m),
      borderSide: BorderSide(color: dividerColor, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius_m),
      borderSide: BorderSide(color: dividerColor, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius_m),
      borderSide: BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius_m),
      borderSide: BorderSide(color: errorColor, width: 1.5),
    ),
    labelStyle: bodyMedium.copyWith(color: textSecondaryColor),
    hintStyle: bodyMedium.copyWith(color: textLightColor),
    floatingLabelStyle: labelMedium.copyWith(color: primaryColor),
  );

  // App Bar Theme
  static final AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: surfaceColor,
    elevation: 0,
    centerTitle: false,
    foregroundColor: textPrimaryColor,
    iconTheme: IconThemeData(color: primaryColor, size: 24),
    titleTextStyle: headingSmall,
    titleSpacing: spacing_m,
  );

  // Card Theme
  static final CardTheme cardTheme = CardTheme(
    color: cardColor,
    elevation: 0,
    margin: EdgeInsets.all(spacing_xs),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius_m),
    ),
    clipBehavior: Clip.antiAlias,
  );

  // Bottom Navigation Bar Theme
  static final BottomNavigationBarThemeData bottomNavBarTheme =
      BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textLightColor,
        selectedLabelStyle: labelSmall,
        unselectedLabelStyle: labelSmall,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      );

  // Create ThemeData for the app
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      surface: surfaceColor,
      background: backgroundColor,
      error: errorColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: appBarTheme,
    cardTheme: cardTheme,
    dividerColor: dividerColor,
    dividerTheme: DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: spacing_m,
    ),
    iconTheme: IconThemeData(color: textSecondaryColor, size: 24),
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
    textButtonTheme: TextButtonThemeData(style: textButtonStyle),
    inputDecorationTheme: inputDecorationTheme,
    bottomNavigationBarTheme: bottomNavBarTheme,
    textTheme: TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineLarge: headingLarge,
      headlineMedium: headingMedium,
      headlineSmall: headingSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    ),
    useMaterial3: true,
  );
}
