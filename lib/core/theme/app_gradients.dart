import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Reusable gradient definitions for NexChat's Gen-Z aesthetic
class AppGradients {
  AppGradients._();

  /// Primary gradient (purple → cyan → pink)
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.neonPurple, AppColors.neonCyan, AppColors.neonPink],
  );

  /// Purple → Blue gradient
  static const LinearGradient purpleBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.neonPurple, AppColors.neonBlue],
  );

  /// Cyan → Green gradient
  static const LinearGradient cyanGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.neonCyan, AppColors.neonGreen],
  );

  /// Pink → Orange gradient
  static const LinearGradient pinkOrange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.neonPink, AppColors.neonOrange],
  );

  /// Dark vertical gradient for backgrounds
  static const LinearGradient darkBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bgDark, AppColors.bgDarkSecondary, AppColors.bgDarkTertiary],
  );

  /// Shimmer gradient
  static const LinearGradient shimmer = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.shimmerBase, AppColors.shimmerHighlight, AppColors.shimmerBase],
  );

  /// Glass overlay gradient
  static const LinearGradient glass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1AFFFFFF), Color(0x05FFFFFF)],
  );
}
