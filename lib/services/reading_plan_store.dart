import 'package:shared_preferences/shared_preferences.dart';
import '../data/reading_plans.dart';

/// Situação do plano ativo, já calculada para a tela.
class PlanSnapshot {
  final ReadingPlan plan;
  final DateTime start;
  final Set<String> read; // chaves "livro:capítulo" lidas neste plano
  final int streak; // dias seguidos lendo
  final int today; // dia atual do plano (1..plan.days)

  const PlanSnapshot({
    required this.plan,
    required this.start,
    required this.read,
    required this.streak,
    required this.today,
  });

  int get totalChapters => plan.chapters.length;
  int get readCount => plan.chapters.where((c) => read.contains(c.key)).length;
  double get progress => totalChapters == 0 ? 0 : readCount / totalChapters;
  bool get finished => readCount >= totalChapters;

  List<ChapterRef> get todayChapters => plan.chaptersForDay(today);
  bool get todayDone => todayChapters.every((c) => read.contains(c.key));

  /// Dias anteriores a hoje que ainda têm capítulo por ler.
  List<int> pendingDays() => [
        for (var d = 1; d < today; d++)
          if (plan.chaptersForDay(d).any((c) => !read.contains(c.key))) d,
      ];
}

/// Guarda no aparelho o plano ativo, o que foi lido e os dias de leitura.
class ReadingPlanStore {
  static const _kActive = 'plan_active';
  static const _kDays = 'read_days';
  static String _kStart(String id) => 'plan_start_$id';
  static String _kRead(String id) => 'plan_read_$id';

  static String fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime? parseDate(String s) {
    final p = s.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// Dias de calendário entre [a] e [b] (ignora horas e horário de verão).
  static int daysBetween(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day)
          .difference(DateTime.utc(a.year, a.month, a.day))
          .inDays;

  /// Dias seguidos com leitura, contando até hoje. Se hoje ainda não teve
  /// leitura, a sequência de ontem continua valendo.
  static int streakFor(Set<String> days, DateTime today) {
    var cursor = DateTime(today.year, today.month, today.day);
    if (!days.contains(fmtDate(cursor))) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    var n = 0;
    while (days.contains(fmtDate(cursor))) {
      n++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return n;
  }

  static Future<String?> activePlanId() async =>
      (await SharedPreferences.getInstance()).getString(_kActive);

  /// Ativa o plano com o calendário começando hoje. Os capítulos que já
  /// tinham sido marcados nesse plano continuam marcados.
  static Future<void> activate(String planId, {DateTime? now}) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kActive, planId);
    await p.setString(_kStart(planId), fmtDate(now ?? DateTime.now()));
  }

  /// Volta ao dia 1 e apaga o que foi marcado como lido neste plano.
  static Future<void> restart(String planId, {DateTime? now}) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kRead(planId));
    await activate(planId, now: now);
  }

  /// Sai do plano atual (o progresso fica guardado).
  static Future<void> deactivate() async =>
      (await SharedPreferences.getInstance()).remove(_kActive);

  static Future<bool> isRead(
      String planId, String bookId, int chapter) async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_kRead(planId)) ?? [])
        .contains('$bookId:$chapter');
  }

  static Future<void> setRead(
      String planId, String bookId, int chapter, bool read,
      {DateTime? now}) async {
    final p = await SharedPreferences.getInstance();
    final set = (p.getStringList(_kRead(planId)) ?? []).toSet();
    final key = '$bookId:$chapter';
    read ? set.add(key) : set.remove(key);
    await p.setStringList(_kRead(planId), set.toList());
    if (read) {
      final days = (p.getStringList(_kDays) ?? []).toSet();
      days.add(fmtDate(now ?? DateTime.now()));
      await p.setStringList(_kDays, days.toList());
    }
  }

  /// null se não houver plano ativo.
  static Future<PlanSnapshot?> snapshot({DateTime? now}) async {
    final p = await SharedPreferences.getInstance();
    final id = p.getString(_kActive);
    if (id == null) return null;
    final plan = ReadingPlans.byId(id);
    if (plan == null) return null;

    final today = now ?? DateTime.now();
    final start = parseDate(p.getString(_kStart(id)) ?? '') ??
        DateTime(today.year, today.month, today.day);
    var day = daysBetween(start, today) + 1;
    if (day < 1) day = 1;
    if (day > plan.days) day = plan.days;

    return PlanSnapshot(
      plan: plan,
      start: start,
      read: (p.getStringList(_kRead(id)) ?? []).toSet(),
      streak: streakFor((p.getStringList(_kDays) ?? []).toSet(), today),
      today: day,
    );
  }
}
