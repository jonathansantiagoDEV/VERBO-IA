import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiException implements Exception {
  final String message;
  const AiException(this.message);
  @override
  String toString() => message;
}

/// Fala com o servidor do "Me explicar" (veja a pasta server/).
/// Configure ao rodar:
///   --dart-define=VERBO_API_URL=https://seu-projeto.vercel.app
///   --dart-define=VERBO_APP_KEY=senha   (a mesma APP_KEY do servidor)
class AiService {
  static const baseUrl = String.fromEnvironment('VERBO_API_URL');
  static const appKey = String.fromEnvironment('VERBO_APP_KEY');
  static bool get configured => baseUrl.isNotEmpty;

  static const _kCache = 'ai_explain_cache';
  static const _maxCache = 200;

  static Future<Map<String, String>> _readCache() async {
    final raw = (await SharedPreferences.getInstance()).getString(_kCache);
    if (raw == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  /// Explicação do versículo. Respostas já geradas ficam guardadas no
  /// aparelho (para economizar e funcionar offline); [force] gera de novo.
  static Future<String> explain({
    required String reference,
    required String text,
    required String translation,
    List<String> strongs = const [],
    bool force = false,
  }) async {
    final key = '$translation|$reference';
    if (!force) {
      final hit = (await _readCache())[key];
      if (hit != null) return hit;
    }
    if (!configured) {
      throw const AiException(
          'O servidor da IA ainda não foi configurado. Veja server/README.md.');
    }
    final http.Response r;
    try {
      r = await http
          .post(
            Uri.parse('$baseUrl/api/explain'),
            headers: {
              'content-type': 'application/json',
              if (appKey.isNotEmpty) 'x-app-key': appKey,
            },
            body: jsonEncode({
              'reference': reference,
              'text': text,
              'translation': translation,
              'strongs': strongs,
            }),
          )
          .timeout(const Duration(seconds: 40));
    } on TimeoutException {
      throw const AiException('A IA demorou demais. Tente de novo.');
    } catch (_) {
      throw const AiException(
          'Sem conexão com o servidor da IA. Confira a internet.');
    }
    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {}
    final answer = (data['answer'] as String?)?.trim() ?? '';
    if (r.statusCode != 200 || answer.isEmpty) {
      throw AiException((data['error'] as String?) ??
          'Não foi possível gerar a explicação (código ${r.statusCode}).');
    }
    final cache = await _readCache();
    cache.remove(key);
    cache[key] = answer;
    while (cache.length > _maxCache) {
      cache.remove(cache.keys.first);
    }
    await (await SharedPreferences.getInstance())
        .setString(_kCache, jsonEncode(cache));
    return answer;
  }
}
