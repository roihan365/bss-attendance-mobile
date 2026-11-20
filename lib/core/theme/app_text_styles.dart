import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  /// Font dasar menggunakan Plus Jakarta Sans untuk tampilan modern, profesional, dan tajam
  static TextStyle get _base => GoogleFonts.plusJakartaSans();

  /// Header Jam Digital Live dengan Tabular Figures (angka monospaced agar tidak bergetar tiap detik)
  static TextStyle get digitalClock => _base.copyWith(
        fontSize: 38,
        fontWeight: FontWeight.w800,
        color: AppColors.slateNavy,
        letterSpacing: -0.5,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get h1 => _base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get h2 => _base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get h3 => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  static TextStyle get buttonText => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle get badgeText => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      );
}
