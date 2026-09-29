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

  /// Inverso de [key]. Retorna null se a chave estiver malformada.
  static ({String bookId, int chapter, int verse})? parseKey(String key) {
    final p = key.split(':');
    if (p.length != 3) return null;
    final c = int.tryParse(p[1]);
    final v = int.tryParse(p[2]);
    if (c == null || v == null) return null;
    return (bookId: p[0], chapter: c, verse: v);
  }

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

  /// Liga ou desliga o favorito de um versículo.
  static Future<void> setBookmark(String verseKey, bool on) async {
    final p = await SharedPreferences.getInstance();
    final set = (p.getStringList(_kBookmarks) ?? []).toSet();
    on ? set.add(verseKey) : set.remove(verseKey);
    await p.setStringList(_kBookmarks, set.toList());
  }

  static Future<Map<String, List<String>>> notes() async {
    final raw = (await SharedPreferences.getInstance()).getString(_kNotes);
    if (raw == null) return {};
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return m.map((k, v) => MapEntry(k, List<String>.from(v as List)));
  }

  static Future<void> _saveNotes(Map<String, List<String>> all) async =>
      (await SharedPreferences.getInstance())
          .setString(_kNotes, jsonEncode(all));

  static Future<void> addNote(String verseKey, String text) async {
    final all = await notes();
    all.putIfAbsent(verseKey, () => []).add(text);
    await _saveNotes(all);
  }

  static Future<void> updateNote(
      String verseKey, int index, String text) async {
    final all = await notes();
    final list = all[verseKey];
    if (list == null || index < 0 || index >= list.length) return;
    list[index] = text;
    await _saveNotes(all);
  }

  static Future<void> removeNote(String verseKey, int index) async {
    final all = await notes();
    final list = all[verseKey];
    if (list == null || index < 0 || index >= list.length) return;
    list.removeAt(index);
    if (list.isEmpty) all.remove(verseKey);
    await _saveNotes(all);
  }
}
