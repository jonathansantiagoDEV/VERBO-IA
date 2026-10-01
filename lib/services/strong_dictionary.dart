import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'strong_text.dart';

/// Verbete do dicionário Strong (hebraico, aramaico ou grego).
class StrongEntry {
  final String id;
  final String lemma; // palavra no alfabeto original
  final String? translit;
  final String? pron;
  final String? derivation;
  final String? def; // definição de Strong (inglês)
  final String? kjvDef; // como a KJV traduz
  final String? pt; // significado em português, quando instalado

  const StrongEntry({
    required this.id,
    required this.lemma,
    this.translit,
    this.pron,
    this.derivation,
    this.def,
    this.kjvDef,
    this.pt,
  });

  bool get isGreek => id.startsWith('G');

  /// O dicionário de Strong marca as palavras aramaicas como "Chaldee".
  bool get isAramaic => !isGreek && (derivation ?? '').contains('Chaldee');

  String get language => isGreek ? 'Grego' : (isAramaic ? 'Aramaico' : 'Hebraico');

  String? get meaning => pt ?? def;

  factory StrongEntry.fromJson(String id, Map<String, dynamic> j) => StrongEntry(
        id: id,
        lemma: (j['l'] ?? '') as String,
        translit: j['x'] as String?,
        pron: j['p'] as String?,
        derivation: j['d'] as String?,
        def: j['s'] as String?,
        kjvDef: j['k'] as String?,
        pt: j['t'] as String?,
      );
}

Map<String, dynamic> _decode(String raw) =>
    jsonDecode(raw) as Map<String, dynamic>;

/// Lê assets/strongs/hebrew.json e greek.json (criados por
/// tools/montar_strong.py). Se os arquivos não existirem, devolve null.
class StrongDictionary {
  static final Map<String, Map<String, dynamic>?> _files = {};

  static Future<Map<String, dynamic>?> _file(String prefix) async {
    if (_files.containsKey(prefix)) return _files[prefix];
    try {
      final name = prefix == 'H' ? 'hebrew' : 'greek';
      final raw = await rootBundle.loadString('assets/strongs/$name.json');
      _files[prefix] = await compute(_decode, raw);
    } catch (_) {
      _files[prefix] = null;
    }
    return _files[prefix];
  }

  static Future<StrongEntry?> entry(String id) async {
    final nid = StrongText.normalizeId(id);
    if (nid == null) return null;
    final file = await _file(nid[0]);
    final j = file?[nid];
    if (j is! Map<String, dynamic>) return null;
    return StrongEntry.fromJson(nid, j);
  }
}
