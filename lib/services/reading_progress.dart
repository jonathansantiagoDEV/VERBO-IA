import 'package:shared_preferences/shared_preferences.dart';

/// Guarda no aparelho onde o usuário parou de ler e o tamanho da fonte.
class ReadingProgress {
  static const _kBookId = 'last_book_id';
  static const _kBookName = 'last_book_name';
  static const _kChapter = 'last_chapter_number';
  static const _kFont = 'reader_font_size';

  static Future<void> save({
    required String bookId,
    required String bookName,
    required int chapterNumber,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kBookId, bookId);
    await p.setString(_kBookName, bookName);
    await p.setInt(_kChapter, chapterNumber);
  }

  /// Retorna null se o usuário ainda não leu nada.
  static Future<({String bookId, String bookName, int chapterNumber})?>
      load() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getString(_kBookId);
    final name = p.getString(_kBookName);
    final ch = p.getInt(_kChapter);
    if (id == null || name == null || ch == null) return null;
    return (bookId: id, bookName: name, chapterNumber: ch);
  }

  static Future<double> loadFontSize() async {
    final p = await SharedPreferences.getInstance();
    return p.getDouble(_kFont) ?? 17;
  }

  static Future<void> saveFontSize(double size) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kFont, size);
  }
}
