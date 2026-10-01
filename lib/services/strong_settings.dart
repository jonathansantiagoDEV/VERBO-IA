import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferências do destaque das palavras com número Strong.
class StrongSettings {
  static const _kEnabled = 'strong_enabled';
  static const _kColor = 'strong_color';
  static const defaultColor = Color(0xFF1E88E5);

  static Future<({bool enabled, Color color})> load() async {
    final p = await SharedPreferences.getInstance();
    return (
      enabled: p.getBool(_kEnabled) ?? true,
      color: Color(p.getInt(_kColor) ?? defaultColor.value),
    );
  }

  static Future<void> save({required bool enabled, required Color color}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnabled, enabled);
    await p.setInt(_kColor, color.value);
  }
}
