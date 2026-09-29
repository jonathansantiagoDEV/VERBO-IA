import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Dados pessoais guardados no aparelho: tradução escolhida, favoritos
/// e notas. Independe de internet e de conta.
class LocalStore {
  static const _kTranslation = 'translation_id';
  static const _kBookmarks = 'bookmarks';
  static const _kNotes = 'notes';

  /// Chave de um versículo, igual para todas as traduções.
  static String key(String bookId, int chapter, int verse) =>
      '$bookId:$chapter:$verse';

  static Future<String?> translationId() async =>
      (await SharedPreferences.getInstance()).getString(_kTranslation);

  static Future<void> setTranslationId(String id) async =>
      (await SharedPreferences.getInstance()).setString(_kTranslation, id);

  static Future<Set<String>> bookmarks() async =>
      ((await SharedPreferences.getInstance()).getStringList(_kBookmarks) ??
              [])
          .toSet();

  /// Retorna true se o versículo ficou favoritado.
  static Future<bool> toggleBookmark(String verseKey) async {
    final p = await SharedPreferences.getInstance();
    final set = (p.getStringList(_kBookmarks) ?? []).toSet();
    final added = set.add(verseKey);
    if (!added) set.remove(verseKey);
    await p.setStringList(_kBookmarks, set.toList());
    return added;
  }

  static Future<Map<String, List<String>>> notes() async {
    final raw = (await SharedPreferences.getInstance()).getString(_kNotes);
    if (raw == null) return {};
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return m.map((k, v) => MapEntry(k, List<String>.from(v as List)));
  }

  static Future<void> addNote(String verseKey, String text) async {
    final p = await SharedPreferences.getInstance();
    final all = await notes();
    all.putIfAbsent(verseKey, () => []).add(text);
    await p.setString(_kNotes, jsonEncode(all));
  }
}
