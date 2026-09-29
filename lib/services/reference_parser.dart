import '../data/bible_catalog.dart';
import 'text_utils.dart';

/// Referência bíblica reconhecida a partir de um texto digitado.
class BibleReference {
  final BookInfo book;
  final int? chapter;
  final int? verse;
  final int? verseEnd;
  const BibleReference(this.book, {this.chapter, this.verse, this.verseEnd});

  String get label {
    final b = StringBuffer(book.name);
    if (chapter != null) b.write(' $chapter');
    if (verse != null) b.write(':$verse');
    if (verseEnd != null && verseEnd != verse) b.write('-$verseEnd');
    return b.toString();
  }
}

/// Entende "João 3:16", "Sl 23", "1 Co 13.4-7", "1co13", "Jd 3"...
class ReferenceParser {
  static final _re = RegExp(
    r'^\s*((?:[1-3]\s*)?\p{L}+)\.?\s*'
    r'(?:(\d{1,3})(?:(?:\s*[:.,]\s*|\s+)(\d{1,3})(?:\s*[-–—]\s*(\d{1,3}))?)?)?'
    r'\s*$',
    unicode: true,
  );

  static const _aliases = {
    'canticos': 'ct',
    'cantares': 'ct',
    'salmo': 'sl',
    'apocalipse': 'ap',
  };

  static String _plain(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[\s.]'), '');

  /// Procura o livro pelo nome, abreviação ou id. Só aceita o começo do
  /// nome (ex.: "gen", "mat") quando [allowPrefix] é true.
  static BookInfo? findBook(String raw, {bool allowPrefix = false}) {
    final q = _plain(raw);
    if (q.isEmpty) return null;
    // 1) igual, respeitando acentos (separa "Jo" de "Jó").
    for (final b in BibleCatalog.books) {
      if (_plain(b.name) == q || _plain(b.abbr) == q || b.id == q) return b;
    }
    // 2) igual, sem acentos.
    final n = normalizeText(q);
    for (final b in BibleCatalog.books) {
      if (normalizeText(_plain(b.name)) == n ||
          normalizeText(_plain(b.abbr)) == n) {
        return b;
      }
    }
    final alias = _aliases[n];
    if (alias != null) return BibleCatalog.byId(alias);
    // 3) começo do nome.
    if (allowPrefix && n.length >= 3) {
      for (final b in BibleCatalog.books) {
        if (normalizeText(_plain(b.name)).startsWith(n)) return b;
      }
    }
    return null;
  }

  /// Retorna null se o texto não parecer uma referência válida.
  /// Só o nome do livro ("João") também vale; o começo do nome ("gen")
  /// só é aceito quando há capítulo ("gen 1").
  static BibleReference? parse(String input) {
    final m = _re.firstMatch(input);
    if (m == null) return null;
    var chapter = m.group(2) == null ? null : int.parse(m.group(2)!);
    var verse = m.group(3) == null ? null : int.parse(m.group(3)!);
    final end = m.group(4) == null ? null : int.parse(m.group(4)!);

    final book = findBook(m.group(1)!, allowPrefix: chapter != null);
    if (book == null) return null;

    // Livros de 1 capítulo: "Jd 3" quer dizer versículo 3.
    if (book.chapters == 1 && chapter != null && verse == null) {
      if (chapter != 1) {
        verse = chapter;
        chapter = 1;
      }
    }
    if (chapter != null && (chapter < 1 || chapter > book.chapters)) {
      return null;
    }
    if (verse != null && verse < 1) return null;
    return BibleReference(book,
        chapter: chapter,
        verse: verse,
        verseEnd: (end != null && verse != null && end > verse) ? end : null);
  }
}
