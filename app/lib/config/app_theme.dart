import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Figma "TrendFit" 디자인의 컬러/타이포 토큰. (Figma 파일 5JTRyO4MvvkJuwFhWCJeIA, 2026-07-28 동기화)
/// 미니멀 에디토리얼 톤: 오프화이트 배경 + 블랙 텍스트/CTA, 트래킹을 넓게 준 대문자 라벨.
class AppColors {
  const AppColors._();

  static const background = Color(0xFFF9F9F9);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A1C1C);
  static const textSecondary = Color(0xFF4C4546);
  static const textTertiary = Color(0xFF5E5E5E);
  static const textPlaceholder = Color(0xFFDADADA);
  static const borderLight = Color(0xFFE2E2E2);
  static const borderSubtle = Color(0x337E7576); // rgba(126,117,118,0.2)
  static const borderHairline = Color(0x1A000000); // rgba(0,0,0,0.1)
  static const chipBackground = Color(0xFFEEEEEE);
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const danger = Color(0xFFB3261E);
}

/// 대문자 + 넓은 트래킹 라벨에 쓰는 헬퍼 (예: "STEP 01", "HOME", "TODAY'S STREAK").
class AppTextStyles {
  const AppTextStyles._();

  /// Syne/Plus Jakarta Sans에는 한글 글리프가 없어, 라벨·버튼처럼 한/영이 섞이는 텍스트
  /// ("GOOGLE로 계속하기" 등)에 쓰는 스타일은 전부 이 폴백을 붙여야 두부 박스가 안 뜬다.
  static final List<String> _koreanFallback = [GoogleFonts.notoSansKr().fontFamily!];

  static TextStyle get wordmark => GoogleFonts.syne(
        fontWeight: FontWeight.w700,
        fontSize: 24,
        letterSpacing: -1.2,
        color: AppColors.textPrimary,
        height: 32 / 24,
      ).copyWith(fontFamilyFallback: _koreanFallback);

  static TextStyle get displayHeavy => GoogleFonts.syne(
        fontWeight: FontWeight.w700,
        fontSize: 32,
        letterSpacing: -0.64,
        color: AppColors.textPrimary,
        height: 38 / 32,
      ).copyWith(fontFamilyFallback: _koreanFallback);

  static TextStyle get headingBold => GoogleFonts.syne(
        fontWeight: FontWeight.w700,
        fontSize: 24,
        color: AppColors.textPrimary,
        height: 32 / 24,
      ).copyWith(fontFamilyFallback: _koreanFallback);

  static TextStyle get koreanHeadline => GoogleFonts.notoSansKr(
        fontWeight: FontWeight.w500,
        fontSize: 26,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle get body => GoogleFonts.notoSansKr(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get bodyOnDark => GoogleFonts.notoSansKr(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: AppColors.white,
        height: 1.5,
      );

  static TextStyle get trackedLabel => GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w500,
        fontSize: 12,
        letterSpacing: 1.2,
        color: AppColors.textTertiary,
        height: 16 / 12,
      ).copyWith(fontFamilyFallback: _koreanFallback);

  static TextStyle get trackedLabelBig => GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        letterSpacing: 1.4,
        color: AppColors.textSecondary,
        height: 20 / 14,
      ).copyWith(fontFamilyFallback: _koreanFallback);

  static TextStyle get buttonLabel => GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        letterSpacing: 1.4,
        color: AppColors.white,
        height: 20 / 14,
      ).copyWith(fontFamilyFallback: _koreanFallback);
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        surface: AppColors.background,
        primary: AppColors.black,
        onPrimary: AppColors.white,
      ),
      textTheme: GoogleFonts.notoSansKrTextTheme(base.textTheme).copyWith(
        headlineMedium: AppTextStyles.displayHeavy,
        titleLarge: AppTextStyles.headingBold,
        titleMedium: AppTextStyles.koreanHeadline,
        bodyLarge: AppTextStyles.body,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: AppTextStyles.wordmark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.textPlaceholder,
          disabledForegroundColor: AppColors.white,
          shape: const RoundedRectangleBorder(),
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: AppTextStyles.buttonLabel,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.black),
          shape: const RoundedRectangleBorder(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: AppTextStyles.trackedLabelBig.copyWith(color: AppColors.textPrimary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderLight)),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderLight)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.black, width: 1.5)),
        hintStyle: GoogleFonts.notoSansKr(color: AppColors.textPlaceholder, fontSize: 18),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.borderLight, thickness: 1),
    );
  }
}
