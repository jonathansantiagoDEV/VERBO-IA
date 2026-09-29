import 'bible_catalog.dart';

/// Um capítulo dentro de um plano de leitura.
class ChapterRef {
  final String bookId;
  final int chapter;
  const ChapterRef(this.bookId, this.chapter);

  String get key => '$bookId:$chapter';
}

/// Plano que divide uma lista de capítulos, em ordem, por [days] dias.
class ReadingPlan {
  final String id;
  final String name;
  final String description;
  final int days;
  final List<ChapterRef> chapters;

  ReadingPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.days,
    required this.chapters,
  }) : assert(days > 0 && days <= chapters.length);

  /// Capítulos do dia [day] (1 até [days]).
  List<ChapterRef> chaptersForDay(int day) {
    if (day < 1 || day > days) return const [];
    final n = chapters.length;
    return chapters.sublist(((day - 1) * n) ~/ days, (day * n) ~/ days);
  }

  late final Map<String, int> _dayByKey = () {
    final m = <String, int>{};
    for (var d = 1; d <= days; d++) {
      for (final c in chaptersForDay(d)) {
        m[c.key] = d;
      }
    }
    return m;
  }();

  /// Dia do plano em que o capítulo aparece (null se não faz parte).
  int? dayOf(String bookId, int chapter) => _dayByKey['$bookId:$chapter'];
}

class ReadingPlans {
  static List<ChapterRef> _chaptersOf(Iterable<BookInfo> books) => [
        for (final b in books)
          for (var c = 1; c <= b.chapters; c++) ChapterRef(b.id, c),
      ];

  static final List<ReadingPlan> all = [
    ReadingPlan(
      id: 'ano',
      name: 'Bíblia em um ano',
      description: 'Do Gênesis ao Apocalipse, cerca de 3 capítulos por dia.',
      days: 365,
      chapters: _chaptersOf(BibleCatalog.books),
    ),
    ReadingPlan(
      id: 'nt90',
      name: 'Novo Testamento em 90 dias',
      description: 'De Mateus ao Apocalipse, cerca de 3 capítulos por dia.',
      days: 90,
      chapters: _chaptersOf(BibleCatalog.byTestament(Testament.nt)),
    ),
    ReadingPlan(
      id: 'slpv30',
      name: 'Salmos e Provérbios em 30 dias',
      description: 'Um mês de sabedoria e louvor, cerca de 6 capítulos por dia.',
      days: 30,
      chapters: _chaptersOf(
          BibleCatalog.books.where((b) => b.id == 'sl' || b.id == 'pv')),
    ),
  ];

  static ReadingPlan? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
