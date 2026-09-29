import 'dart:convert';
import 'package:flutter/services.dart';
import '../data/bible_catalog.dart';
import '../data/bible_translations.dart';

class SearchHit {
  final BookInfo book;
  final int chapter;
  final int verse;
  final String text;
  const SearchHit(this.book, this.chapter, this.verse, this.text);
  String get reference => '${book.name} $chapter:$verse';
}

/// Lê as traduções da Bíblia embutidas no app (assets/bibles/*.json).
///
/// Formato aceito: lista de 66 livros na ordem canônica, cada um com
/// `chapters` = lista de capítulos, cada capítulo = lista de versículos
/// (strings). Também aceita `{"books": [...]}`.
class LocalBible {
  static final Map<String, List<List<List<String>>>> _cache = {};
  static List<TranslationInfo>? _available;

  /// Traduções cujo arquivo existe em assets/bibles/.
  static Future<List<TranslationInfo>> availableTranslations() async {
    if (_available != null) return _available!;
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().toSet();
    _available = [
      for (final t in BibleTranslations.all)
        if (assets.contains(t.asset)) t
    ];
    return _available!;
  }

  static Future<List<List<List<String>>>> _load(String translationId) async {
    final cached = _cache[translationId];
    if (cached != null) return cached;
    final info = BibleTranslations.byId(translationId);
    if (info == null) throw 'Tradução desconhecida: $translationId';

    var raw = await rootBundle.loadString(info.asset);
    if (raw.startsWith('\uFEFF')) raw = raw.substring(1); // remove BOM
    final data = jsonDecode(raw);
    final list = (data is Map ? data['books'] : data) as List;

    final books = <List<List<String>>>[];
    for (final b in list) {
      final chapters = (b['chapters'] as List)
          .map<List<String>>(
              (c) => (c as List).map((v) => v.toString().trim()).toList())
          .toList();
      books.add(chapters);
    }
    if (books.length != BibleCatalog.books.length) {
      throw 'O arquivo ${info.asset} tem ${books.length} livros '
          '(esperado: ${BibleCatalog.books.length}).';
    }
    return _cache[translationId] = books;
  }

  /// Versículos do capítulo (lista vazia se a tradução não tem o capítulo).
  static Future<List<String>> verses(
      String translationId, String bookId, int chapter) async {
    final books = await _load(translationId);
    final i = BibleCatalog.indexOf(bookId);
    if (i < 0 || chapter < 1 || chapter > books[i].length) return [];
    return books[i][chapter - 1];
  }

  static String _norm(String s) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const to = 'aaaaaeeeeiiiiooooouuuucn';
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final k = from.indexOf(ch);
      b.write(k >= 0 ? to[k] : ch);
    }
    return b.toString();
  }

  /// Busca por palavras (todas precisam aparecer), sem diferenciar acentos.
  static Future<List<SearchHit>> search(String translationId, String query,
      {int limit = 100}) async {
    final words =
        _norm(query).split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
    if (words.isEmpty) return [];
    final books = await _load(translationId);
    final hits = <SearchHit>[];
    for (var b = 0; b < books.length; b++) {
      for (var c = 0; c < books[b].length; c++) {
        for (var v = 0; v < books[b][c].length; v++) {
          final text = books[b][c][v];
          final n = _norm(text);
          if (words.every(n.contains)) {
            hits.add(SearchHit(BibleCatalog.books[b], c + 1, v + 1, text));
            if (hits.length >= limit) return hits;
          }
        }
      }
    }
    return hits;
  }
}
