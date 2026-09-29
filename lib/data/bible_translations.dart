/// Traduções que o app sabe carregar. Cada uma vira um arquivo
/// `assets/bibles/<id>.json`. A tradução só aparece no app se o arquivo
/// existir, então basta colocar o JSON na pasta e recompilar.
class TranslationInfo {
  final String id;
  final String name;
  final String shortName;
  final String language;
  final bool publicDomain;
  const TranslationInfo(
      this.id, this.name, this.shortName, this.language, this.publicDomain);

  String get asset => 'assets/bibles/$id.json';
}

class BibleTranslations {
  static const List<TranslationInfo> all = [
    TranslationInfo('arc', 'Almeida Revista e Corrigida', 'ARC', 'pt', true),
    TranslationInfo('kjv', 'King James Version', 'KJV', 'en', true),
    // Abaixo: têm direitos autorais. Só inclua o arquivo se você tiver
    // licença para distribuir o texto dentro do app.
    TranslationInfo(
        'acf', 'Almeida Corrigida Fiel', 'ACF', 'pt', false),
    TranslationInfo(
        'aa', 'Almeida Revisada Imprensa Bíblica', 'AA', 'pt', false),
    TranslationInfo('ara', 'Almeida Revista e Atualizada', 'ARA', 'pt', false),
    TranslationInfo('naa', 'Nova Almeida Atualizada', 'NAA', 'pt', false),
    TranslationInfo('nvi', 'Nova Versão Internacional', 'NVI', 'pt', false),
    // Amostra pequena só para testar o app (João 1:1-5).
    TranslationInfo('demo', 'Demonstração (João 1:1-5)', 'DEMO', 'pt', true),
  ];

  static TranslationInfo? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}
