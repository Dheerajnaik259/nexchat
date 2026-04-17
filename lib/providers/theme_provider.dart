import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme provider — NexChat is dark-only by design,
/// but this manages the dark theme variant preference.
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

class ThemeState {
  final bool useAmoledBlack;   // true = pure black bg, false = dark gray
  final bool useDynamicColors; // Material You dynamic colors (future)
  final double fontScale;      // User-adjustable text scale

  const ThemeState({
    this.useAmoledBlack = true,
    this.useDynamicColors = false,
    this.fontScale = 1.0,
  });

  ThemeState copyWith({
    bool? useAmoledBlack,
    bool? useDynamicColors,
    double? fontScale,
  }) {
    return ThemeState(
      useAmoledBlack: useAmoledBlack ?? this.useAmoledBlack,
      useDynamicColors: useDynamicColors ?? this.useDynamicColors,
      fontScale: fontScale ?? this.fontScale,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _loadPreferences();
  }

  static const String _amoledKey = 'theme_amoled';
  static const String _dynamicKey = 'theme_dynamic';
  static const String _fontScaleKey = 'theme_font_scale';

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    state = ThemeState(
      useAmoledBlack: prefs.getBool(_amoledKey) ?? true,
      useDynamicColors: prefs.getBool(_dynamicKey) ?? false,
      fontScale: prefs.getDouble(_fontScaleKey) ?? 1.0,
    );
  }

  Future<void> toggleAmoledBlack() async {
    state = state.copyWith(useAmoledBlack: !state.useAmoledBlack);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_amoledKey, state.useAmoledBlack);
  }

  Future<void> toggleDynamicColors() async {
    state = state.copyWith(useDynamicColors: !state.useDynamicColors);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dynamicKey, state.useDynamicColors);
  }

  Future<void> setFontScale(double scale) async {
    state = state.copyWith(fontScale: scale.clamp(0.8, 1.4));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, state.fontScale);
  }
}
