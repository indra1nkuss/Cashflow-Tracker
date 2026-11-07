import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Brand Colors
  static const Color _primaryColor = Color(0xFF2563EB);     // Blue 600
  static const Color _secondaryColor = Color(0xFF7C3AED);   // Violet 600
  static const Color _incomeColor = Color(0xFF16A34A);      // Green 600
  static const Color _expenseColor = Color(0xFFDC2626);     // Red 600
  static const Color _warningColor = Color(0xFFF59E0B);     // Amber 500

  // Semantic color extensions accessible via Theme.of(context).extension<AppColors>()
  static const AppColors _lightColors = AppColors(
    income: _incomeColor,
    expense: _expenseColor,
    warning: _warningColor,
  );

  static const AppColors _darkColors = AppColors(
    income: Color(0xFF4ADE80),   // Green 400
    expense: Color(0xFFF87171),  // Red 400
    warning: Color(0xFFFBBF24),  // Amber 400
  );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: _primaryColor,
        fontFamily: 'Inter',
        extensions: const [_lightColors],
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );

  static ThemeData get darkTheme => lightTheme.copyWith(
        brightness: Brightness.dark,
        extensions: const [_darkColors],
      );
}

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.income,
    required this.expense,
    required this.warning,
  });

  final Color income;
  final Color expense;
  final Color warning;

  @override
  AppColors copyWith({Color? income, Color? expense, Color? warning}) {
    return AppColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

