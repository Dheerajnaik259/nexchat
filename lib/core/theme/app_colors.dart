import 'package:flutter/material.dart';

/// Gen-Z neon color palette for NexChat
class AppColors {
  AppColors._();

  // ── Primary Neon Palette ──────────────────────────────
  static const Color neonPurple = Color(0xFF9D4EDD);
  static const Color neonCyan = Color(0xFF00F5FF);
  static const Color neonPink = Color(0xFFFF006E);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonOrange = Color(0xFFFF9100);
  static const Color neonBlue = Color(0xFF4361EE);

  // ── Background Colors ─────────────────────────────────
  static const Color bgDark = Color(0xFF0A0A0F);
  static const Color bgDarkSecondary = Color(0xFF12121A);
  static const Color bgDarkTertiary = Color(0xFF1A1A2E);
  static const Color bgCard = Color(0xFF16162A);
  static const Color bgBottomSheet = Color(0xFF1E1E36);

  // ── Surface / Glass ───────────────────────────────────
  static const Color glassBg = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassBgDark = Color(0x0DFFFFFF);

  // ── Text Colors ───────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textTertiary = Color(0xFF6C6C80);
  static const Color textOnNeon = Color(0xFF0A0A0F);

  // ── Status Indicators ─────────────────────────────────
  static const Color online = Color(0xFF39FF14);
  static const Color offline = Color(0xFF6C6C80);
  static const Color typing = Color(0xFF00F5FF);
  static const Color unread = Color(0xFF9D4EDD);

  // ── Message Bubbles ───────────────────────────────────
  static const Color myBubble = Color(0xFF9D4EDD);
  static const Color otherBubble = Color(0xFF1E1E36);
  static const Color myBubbleText = Color(0xFFFFFFFF);
  static const Color otherBubbleText = Color(0xFFE0E0E0);

  // ── Semantic Colors ───────────────────────────────────
  static const Color error = Color(0xFFFF4757);
  static const Color success = Color(0xFF2ED573);
  static const Color warning = Color(0xFFFFAB00);
  static const Color info = Color(0xFF4361EE);

  // ── Misc ──────────────────────────────────────────────
  static const Color divider = Color(0xFF2A2A3E);
  static const Color shimmerBase = Color(0xFF1A1A2E);
  static const Color shimmerHighlight = Color(0xFF2A2A3E);
}
