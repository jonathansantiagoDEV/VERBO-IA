import 'package:flutter_test/flutter_test.dart';
import 'package:verbo_ia/services/reference_parser.dart';

void main() {
  test('João 3:16', () {
    final r = ReferenceParser.parse('João 3:16')!;
    expect(r.book.name, 'João');
    expect(r.chapter, 3);
    expect(r.verse, 16);
  });

  test('abreviações e formatos', () {
    expect(ReferenceParser.parse('Sl 23')!.book.id, 'sl');
    expect(ReferenceParser.parse('Sl 23')!.chapter, 23);
    final c = ReferenceParser.parse('1 Co 13.4-7')!;
    expect(c.book.id, '1co');
    expect([c.chapter, c.verse, c.verseEnd], [13, 4, 7]);
    expect(ReferenceParser.parse('1co13')!.chapter, 13);
  });

  test('Jó e João não se confundem', () {
    expect(ReferenceParser.parse('Jó 1')!.book.id, 'job');
    expect(ReferenceParser.parse('Jo 1')!.book.id, 'jo');
  });

  test('livro de um capítulo: "Jd 3" é o versículo 3', () {
    final r = ReferenceParser.parse('Jd 3')!;
    expect([r.chapter, r.verse], [1, 3]);
  });

  test('começo do nome só vale com capítulo', () {
    expect(ReferenceParser.parse('gen 1')!.book.name, 'Gênesis');
    expect(ReferenceParser.parse('gen'), isNull);
  });

  test('não é referência', () {
    expect(ReferenceParser.parse('amor'), isNull);
    expect(ReferenceParser.parse('João 99'), isNull);
  });
}
