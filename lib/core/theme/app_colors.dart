import 'package:flutter/material.dart';

/// Gen-Z neon color palette for NexChat
class AppColors {
  AppColors._();

  // ── Primary Neon Palette ──────────────────────────────
  // Slightly brightened neon for high contrast against pure black
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color neonPink = Color(0xFFFF007F);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonOrange = Color(0xFFFF9900);
  static const Color neonBlue = Color(0xFF3B82F6);

  // ── Background Colors (High Contrast Pitch Black) ──────
  static const Color bgDark = Color(0xFF000000);
  static const Color bgDarkSecondary = Color(0xFF080808);
  static const Color bgDarkTertiary = Color(0xFF101010);
  static const Color bgCard = Color(0xFF0C0C0C);
  static const Color bgBottomSheet = Color(0xFF121212);

  // ── Surface / Glass ───────────────────────────────────
  static const Color glassBg = Color(0x26000000);
  static const Color glassBorder = Color(0x4DFFFFFF);
  static const Color glassBgDark = Color(0x1A000000);

  // ── Text Colors ───────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCCCCCC);
  static const Color textTertiary = Color(0xFF888888);
  static const Color textOnNeon = Color(0xFF000000);

  // ── Status Indicators ─────────────────────────────────
  static const Color online = Color(0xFF39FF14);
  static const Color offline = Color(0xFF777777);
  static const Color typing = Color(0xFF00FFFF);
  static const Color unread = Color(0xFFA855F7);

  // ── Message Bubbles ───────────────────────────────────
  static const Color myBubble = Color(0xFFA855F7);
  static const Color otherBubble = Color(0xFF121212);
  static const Color myBubbleText = Color(0xFFFFFFFF);
  static const Color otherBubbleText = Color(0xFFF0F0F0);

  // ── Semantic Colors ───────────────────────────────────
  static const Color error = Color(0xFFFF3333);
  static const Color success = Color(0xFF00FF00);
  static const Color warning = Color(0xFFFFCC00);
  static const Color info = Color(0xFF3B82F6);

  // ── Surfaces ───────────────────────────────────────────
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFF1A1A1A);

  // ── Misc ──────────────────────────────────────────────
  static const Color divider = Color(0xFF222222);
  static const Color shimmerBase = Color(0xFF101010);
  static const Color shimmerHighlight = Color(0xFF222222);
  static const Color onlineDot = online;
}
