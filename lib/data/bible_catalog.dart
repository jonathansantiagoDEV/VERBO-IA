/// Catálogo fixo dos 66 livros da Bíblia (ordem canônica protestante).
/// A ordem da lista é usada para ler as traduções em JSON: o livro de
/// índice 0 é Gênesis, o de índice 65 é Apocalipse.
enum Testament { ot, nt }

class BookInfo {
  final String id; // identificador curto (gn, ex, jo...)
  final String name;
  final String abbr;
  final Testament testament;
  final int chapters;
  const BookInfo(this.id, this.name, this.abbr, this.testament, this.chapters);
}

class BibleCatalog {
  static const List<BookInfo> books = [
  BookInfo('gn', 'Gênesis', 'Gn', Testament.ot, 50),
  BookInfo('ex', 'Êxodo', 'Êx', Testament.ot, 40),
  BookInfo('lv', 'Levítico', 'Lv', Testament.ot, 27),
  BookInfo('nm', 'Números', 'Nm', Testament.ot, 36),
  BookInfo('dt', 'Deuteronômio', 'Dt', Testament.ot, 34),
  BookInfo('js', 'Josué', 'Js', Testament.ot, 24),
  BookInfo('jz', 'Juízes', 'Jz', Testament.ot, 21),
  BookInfo('rt', 'Rute', 'Rt', Testament.ot, 4),
  BookInfo('1sm', '1 Samuel', '1Sm', Testament.ot, 31),
  BookInfo('2sm', '2 Samuel', '2Sm', Testament.ot, 24),
  BookInfo('1rs', '1 Reis', '1Rs', Testament.ot, 22),
  BookInfo('2rs', '2 Reis', '2Rs', Testament.ot, 25),
  BookInfo('1cr', '1 Crônicas', '1Cr', Testament.ot, 29),
  BookInfo('2cr', '2 Crônicas', '2Cr', Testament.ot, 36),
  BookInfo('ed', 'Esdras', 'Ed', Testament.ot, 10),
  BookInfo('ne', 'Neemias', 'Ne', Testament.ot, 13),
  BookInfo('et', 'Ester', 'Et', Testament.ot, 10),
  BookInfo('job', 'Jó', 'Jó', Testament.ot, 42),
  BookInfo('sl', 'Salmos', 'Sl', Testament.ot, 150),
  BookInfo('pv', 'Provérbios', 'Pv', Testament.ot, 31),
  BookInfo('ec', 'Eclesiastes', 'Ec', Testament.ot, 12),
  BookInfo('ct', 'Cantares', 'Ct', Testament.ot, 8),
  BookInfo('is', 'Isaías', 'Is', Testament.ot, 66),
  BookInfo('jr', 'Jeremias', 'Jr', Testament.ot, 52),
  BookInfo('lm', 'Lamentações', 'Lm', Testament.ot, 5),
  BookInfo('ez', 'Ezequiel', 'Ez', Testament.ot, 48),
  BookInfo('dn', 'Daniel', 'Dn', Testament.ot, 12),
  BookInfo('os', 'Oseias', 'Os', Testament.ot, 14),
  BookInfo('jl', 'Joel', 'Jl', Testament.ot, 3),
  BookInfo('am', 'Amós', 'Am', Testament.ot, 9),
  BookInfo('ob', 'Obadias', 'Ob', Testament.ot, 1),
  BookInfo('jn', 'Jonas', 'Jn', Testament.ot, 4),
  BookInfo('mq', 'Miqueias', 'Mq', Testament.ot, 7),
  BookInfo('na', 'Naum', 'Na', Testament.ot, 3),
  BookInfo('hc', 'Habacuque', 'Hc', Testament.ot, 3),
  BookInfo('sf', 'Sofonias', 'Sf', Testament.ot, 3),
  BookInfo('ag', 'Ageu', 'Ag', Testament.ot, 2),
  BookInfo('zc', 'Zacarias', 'Zc', Testament.ot, 14),
  BookInfo('ml', 'Malaquias', 'Ml', Testament.ot, 4),
  BookInfo('mt', 'Mateus', 'Mt', Testament.nt, 28),
  BookInfo('mc', 'Marcos', 'Mc', Testament.nt, 16),
  BookInfo('lc', 'Lucas', 'Lc', Testament.nt, 24),
  BookInfo('jo', 'João', 'Jo', Testament.nt, 21),
  BookInfo('at', 'Atos', 'At', Testament.nt, 28),
  BookInfo('rm', 'Romanos', 'Rm', Testament.nt, 16),
  BookInfo('1co', '1 Coríntios', '1Co', Testament.nt, 16),
  BookInfo('2co', '2 Coríntios', '2Co', Testament.nt, 13),
  BookInfo('gl', 'Gálatas', 'Gl', Testament.nt, 6),
  BookInfo('ef', 'Efésios', 'Ef', Testament.nt, 6),
  BookInfo('fp', 'Filipenses', 'Fp', Testament.nt, 4),
  BookInfo('cl', 'Colossenses', 'Cl', Testament.nt, 4),
  BookInfo('1ts', '1 Tessalonicenses', '1Ts', Testament.nt, 5),
  BookInfo('2ts', '2 Tessalonicenses', '2Ts', Testament.nt, 3),
  BookInfo('1tm', '1 Timóteo', '1Tm', Testament.nt, 6),
  BookInfo('2tm', '2 Timóteo', '2Tm', Testament.nt, 4),
  BookInfo('tt', 'Tito', 'Tt', Testament.nt, 3),
  BookInfo('fm', 'Filemom', 'Fm', Testament.nt, 1),
  BookInfo('hb', 'Hebreus', 'Hb', Testament.nt, 13),
  BookInfo('tg', 'Tiago', 'Tg', Testament.nt, 5),
  BookInfo('1pe', '1 Pedro', '1Pe', Testament.nt, 5),
  BookInfo('2pe', '2 Pedro', '2Pe', Testament.nt, 3),
  BookInfo('1jo', '1 João', '1Jo', Testament.nt, 5),
  BookInfo('2jo', '2 João', '2Jo', Testament.nt, 1),
  BookInfo('3jo', '3 João', '3Jo', Testament.nt, 1),
  BookInfo('jd', 'Judas', 'Jd', Testament.nt, 1),
  BookInfo('ap', 'Apocalipse', 'Ap', Testament.nt, 22),
  ];

  static List<BookInfo> byTestament(Testament t) =>
      books.where((b) => b.testament == t).toList();

  static BookInfo? byId(String id) {
    for (final b in books) {
      if (b.id == id) return b;
    }
    return null;
  }

  static int indexOf(String id) => books.indexWhere((b) => b.id == id);
}
