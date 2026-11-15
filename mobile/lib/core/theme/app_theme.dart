import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Elegant Red & Orange Brand Colors
  static const Color primaryColor = Color(0xFFE11D48);       // Crimson Rose Red
  static const Color primaryDark = Color(0xFFBE123C);        // Deep Ruby
  static const Color secondaryColor = Color(0xFFEA580C);     // Sunset Orange
  static const Color accentOrange = Color(0xFFF97316);      // Warm Tangerine
  static const Color tertiaryColor = Color(0xFFF59E0B);      // Golden Amber
  
  static const Color incomeColor = Color(0xFF10B981);        // Emerald Green
  static const Color expenseColor = Color(0xFFEF4444);       // Coral Red
  static const Color warningColor = Color(0xFFF59E0B);       // Warm Amber

  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE11D48), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFBE123C), Color(0xFFE11D48), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmCardGradient = LinearGradient(
    colors: [Color(0xFFFFF7ED), Color(0xFFFFF1F2)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Semantic color extensions
  static const AppColors _lightColors = AppColors(
    income: incomeColor,
    expense: expenseColor,
    warning: warningColor,
    primaryGradient: primaryGradient,
    sunsetGradient: sunsetGradient,
  );

  static const AppColors _darkColors = AppColors(
    income: Color(0xFF34D399),
    expense: Color(0xFFF87171),
    warning: Color(0xFFFBBF24),
    primaryGradient: primaryGradient,
    sunsetGradient: sunsetGradient,
  );

  static AppColors colorsOf(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ?? _lightColors;
  }

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: secondaryColor,
          tertiary: tertiaryColor,
          surface: const Color(0xFFFCF9F8),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFFFF5F2),
          surfaceContainer: const Color(0xFFFFECE5),
          surfaceContainerHigh: const Color(0xFFFFE4DC),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF7F5),
        fontFamily: 'Inter',
        extensions: const [_lightColors],
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Color(0xFF1C1917),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Color(0xFF1C1917)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFFFE6DE), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFFD7CC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFFE0D6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: primaryColor.withValues(alpha: 0.4),
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 10,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          indicatorColor: const Color(0xFFFFECE5),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: primaryColor, size: 24);
            }
            return const IconThemeData(color: Color(0xFF78716C), size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              );
            }
            return const TextStyle(
              color: Color(0xFF78716C),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: const Color(0xFFFB7185),
          secondary: const Color(0xFFFB923C),
          surface: const Color(0xFF141214),
          surfaceContainerLow: const Color(0xFF1C191C),
          surfaceContainer: const Color(0xFF262226),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0E10),
        fontFamily: 'Inter',
        extensions: const [_darkColors],
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF1A181C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF141214),
          elevation: 8,
          indicatorColor: const Color(0xFFE11D48).withValues(alpha: 0.25),
        ),
      );
}

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.income,
    required this.expense,
    required this.warning,
    required this.primaryGradient,
    required this.sunsetGradient,
  });

  final Color income;
  final Color expense;
  final Color warning;
  final LinearGradient primaryGradient;
  final LinearGradient sunsetGradient;

  @override
  AppColors copyWith({
    Color? income,
    Color? expense,
    Color? warning,
    LinearGradient? primaryGradient,
    LinearGradient? sunsetGradient,
  }) {
    return AppColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      sunsetGradient: sunsetGradient ?? this.sunsetGradient,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      primaryGradient: primaryGradient,
      sunsetGradient: sunsetGradient,
    );
  }
}

