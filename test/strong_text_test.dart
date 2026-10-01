import 'package:flutter_test/flutter_test.dart';
import 'package:verbo_ia/services/strong_text.dart';

void main() {
  test('liga o número à palavra anterior', () {
    final t = StrongText.parse('Filho<H1121> meu, atende<H7181> a mim');
    final filho = t.firstWhere((x) => x.text == 'Filho');
    expect(filho.ids, ['H1121']);
    expect(t.firstWhere((x) => x.text == 'meu,').ids, isEmpty);
    expect(t.firstWhere((x) => x.text == 'atende').ids, ['H7181']);
  });

  test('várias marcações na mesma palavra e espaço antes da marcação', () {
    final t = StrongText.parse('Deus <H430><H0430> criou');
    final deus = t.firstWhere((x) => x.text == 'Deus');
    expect(deus.ids, ['H430']); // sem repetir
  });

  test('strip remove marcações sem sobrar espaço duplo', () {
    expect(StrongText.strip('No princípio<G746> era<G2258> o Verbo<G3056>.'),
        'No princípio era o Verbo.');
    expect(StrongText.strip('palavra <H1> outra'), 'palavra outra');
  });

  test('normalizeId e hasTags', () {
    expect(StrongText.normalizeId('h0430'), 'H430');
    expect(StrongText.normalizeId('G3056'), 'G3056');
    expect(StrongText.normalizeId('430'), isNull);
    expect(StrongText.hasTags('a<H1>'), isTrue);
    expect(StrongText.hasTags('sem marcação'), isFalse);
  });
}
