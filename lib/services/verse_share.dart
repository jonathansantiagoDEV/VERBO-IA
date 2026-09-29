import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Formata, copia e compartilha versículos.
class VerseShare {
  static String format({
    required String reference,
    required String text,
    String? translation,
  }) {
    final suffix = translation == null ? '' : ' ($translation)';
    return '“$text”\n— $reference$suffix';
  }

  static Future<void> copy(String formatted) =>
      Clipboard.setData(ClipboardData(text: formatted));

  static Future<void> share(String formatted) => Share.share(formatted);
}
