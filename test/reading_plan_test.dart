import 'package:flutter_test/flutter_test.dart';
import 'package:verbo_ia/data/reading_plans.dart';
import 'package:verbo_ia/services/reading_plan_store.dart';

void main() {
  test('cada plano cobre todos os capítulos uma única vez, sem dia vazio', () {
    for (final p in ReadingPlans.all) {
      final vistos = <String>{};
      for (var d = 1; d <= p.days; d++) {
        final dia = p.chaptersForDay(d);
        expect(dia, isNotEmpty, reason: '${p.id} dia $d');
        for (final c in dia) {
          expect(vistos.add(c.key), isTrue, reason: 'repetido ${c.key}');
        }
      }
      expect(vistos.length, p.chapters.length);
    }
  });

  test('Bíblia em um ano tem 1189 capítulos', () {
    expect(ReadingPlans.byId('ano')!.chapters.length, 1189);
    expect(ReadingPlans.byId('ano')!.dayOf('gn', 1), 1);
  });

  test('sequência de dias seguidos', () {
    final hoje = DateTime(2026, 3, 10);
    String f(int dia) => ReadingPlanStore.fmtDate(DateTime(2026, 3, dia));
    expect(ReadingPlanStore.streakFor({}, hoje), 0);
    expect(ReadingPlanStore.streakFor({f(10), f(9), f(8)}, hoje), 3);
    // hoje ainda sem leitura: a sequência de ontem continua
    expect(ReadingPlanStore.streakFor({f(9), f(8)}, hoje), 2);
    // quebrou há 2 dias
    expect(ReadingPlanStore.streakFor({f(8)}, hoje), 0);
    // virada de mês
    expect(
        ReadingPlanStore.streakFor({'2026-02-28', '2026-03-01'}, DateTime(2026, 3, 1)),
        2);
  });

  test('dias de calendário entre datas', () {
    expect(ReadingPlanStore.daysBetween(DateTime(2026, 3, 1), DateTime(2026, 3, 1)), 0);
    expect(ReadingPlanStore.daysBetween(DateTime(2026, 2, 28), DateTime(2026, 3, 2)), 2);
  });
}
