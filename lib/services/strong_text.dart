/// Uma palavra do versículo e os números Strong ligados a ela.
class StrongToken {
  final String text;
  final List<String> ids; // ex.: ['H1121'] ou ['G3056']
  const StrongToken(this.text, this.ids);
}

/// Lê versículos com números Strong no formato `palavra<H1121>`
/// (o mesmo dos módulos MySword). O número pertence à palavra que vem
/// imediatamente antes dele.
class StrongText {
  static final _tag = RegExp(r'<([HG])0*(\d+)>');

  static bool hasTags(String s) => RegExp(r'<[HG]\d+>').hasMatch(s);

  /// "H0430" / "h430" -> "H430". Retorna null se não for um número Strong.
  static String? normalizeId(String s) {
    final m = RegExp(r'^([HhGg])0*(\d+)$').firstMatch(s.trim());
    return m == null ? null : '${m[1]!.toUpperCase()}${m[2]}';
  }

  /// Texto sem as marcações.
  static String strip(String raw) => raw
      .replaceAll(RegExp(r'\s*<[HG]0*\d+>'), '')
      .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
      .trim();

  /// Divide o versículo em palavras e espaços, ligando cada número Strong
  /// à palavra anterior.
  static List<StrongToken> parse(String raw) {
    final texts = <String>[];
    final ids = <List<String>>[];

    void addText(String s) {
      for (final m in RegExp(r'\s+|\S+').allMatches(s)) {
        texts.add(m[0]!);
        ids.add(<String>[]);
      }
    }

    var pos = 0;
    for (final m in _tag.allMatches(raw)) {
      addText(raw.substring(pos, m.start));
      pos = m.end;
      final id = '${m[1]}${m[2]}';
      var k = texts.length - 1;
      while (k >= 0 && texts[k].trim().isEmpty) {
        k--;
      }
      if (k >= 0 && !ids[k].contains(id)) ids[k].add(id);
    }
    addText(raw.substring(pos));
    return [for (var i = 0; i < texts.length; i++) StrongToken(texts[i], ids[i])];
  }
}
