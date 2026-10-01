import 'dart:convert';
import 'package:flutter/services.dart';
import '../data/bible_catalog.dart';
import '../data/bible_translations.dart';
import 'local_store.dart';
import 'strong_text.dart';
import 'text_utils.dart';

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
  static final Map<String, List<List<List<String>>>> _cache = {}; // sem marcações
  static final Map<String, List<List<List<String>>>> _raw = {}; // com <H1121>
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
    _raw[translationId] = books;
    if (!StrongText.hasTags(raw)) return _cache[translationId] = books;
    return _cache[translationId] = [
      for (final b in books)
        [
          for (final c in b) [for (final v in c) StrongText.strip(v)]
        ]
    ];
  }

  /// Tradução escolhida pelo usuário (ou a primeira disponível).
  static Future<TranslationInfo?> currentTranslation() async {
    final list = await availableTranslations();
    if (list.isEmpty) return null;
    final saved = await LocalStore.translationId();
    return list.firstWhere((t) => t.id == saved, orElse: () => list.first);
  }

  /// Texto de um único versículo (null se não existir na tradução).
  static Future<String?> verseText(
      String translationId, String bookId, int chapter, int verse) async {
    final list = await verses(translationId, bookId, chapter);
    if (verse < 1 || verse > list.length) return null;
    return list[verse - 1];
  }

  /// Versículos com as marcações Strong (`palavra<H1121>`), se houver.
  static Future<List<String>> versesRaw(
      String translationId, String bookId, int chapter) async {
    await _load(translationId);
    final books = _raw[translationId]!;
    final i = BibleCatalog.indexOf(bookId);
    if (i < 0 || chapter < 1 || chapter > books[i].length) return [];
    return books[i][chapter - 1];
  }

  /// Versículos em que o número Strong [id] (ex.: "H430") aparece.
  static Future<List<SearchHit>> findStrong(String translationId, String id,
      {int limit = 300}) async {
    final plain = await _load(translationId);
    final raw = _raw[translationId]!;
    final nid = StrongText.normalizeId(id);
    if (nid == null) return [];
    final re = RegExp('<${nid[0]}0*${nid.substring(1)}>');
    final hits = <SearchHit>[];
    for (var b = 0; b < raw.length; b++) {
      for (var c = 0; c < raw[b].length; c++) {
        for (var v = 0; v < raw[b][c].length; v++) {
          if (re.hasMatch(raw[b][c][v])) {
            hits.add(SearchHit(
                BibleCatalog.books[b], c + 1, v + 1, plain[b][c][v]));
            if (hits.length >= limit) return hits;
          }
        }
      }
    }
    return hits;
  }

  /// Versículos do capítulo (lista vazia se a tradução não tem o capítulo).
  static Future<List<String>> verses(
      String translationId, String bookId, int chapter) async {
    final books = await _load(translationId);
    final i = BibleCatalog.indexOf(bookId);
    if (i < 0 || chapter < 1 || chapter > books[i].length) return [];
    return books[i][chapter - 1];
  }

  static String _norm(String s) => normalizeText(s);

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
