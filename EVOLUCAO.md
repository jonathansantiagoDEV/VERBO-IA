# Evolução do VERBO IA

## Feito nesta rodada
- Leitor: navegação anterior/próximo capítulo, tamanho de letra (salvo no aparelho), versículos favoritados destacados, ícone de nota, feedback de erro/sucesso, botão "tentar novamente".
- Busca textual (tela nova) com referência (Livro cap:vers) e abertura direta no capítulo.
- "Continuar leitura" na Home, lembrando o último capítulo lido.
- Chave anon do Supabase via `--dart-define` (sem colar no código).
- `.gitignore` protegendo keystore e `key.properties`.

## Como rodar
flutter pub get
flutter run --dart-define=SUPABASE_ANON_KEY=sua_chave

## Próximos passos sugeridos
1. Assinatura de release (key.properties + signingConfigs.release).
2. Tela de Favoritos e Notas (aba Perfil ou Estudos).
3. Fase 2: Edge Function "explicar versículo" + botão "Me explicar" no leitor.
4. Seletor de versão da Bíblia (hoje usa sempre a primeira ativa).

## Bíblia local (sem banco)
Livros e traduções agora vivem dentro do app. O Supabase virou opcional (só login).
- `lib/data/bible_catalog.dart`: os 66 livros, com abreviação e nº de capítulos.
- `lib/data/bible_translations.dart`: traduções conhecidas (ARC, KJV, ARA, NAA, NVI, DEMO).
- `assets/bibles/<id>.json`: o texto. A tradução só aparece no app se o arquivo existir.
- Formato: lista de 66 livros na ordem canônica; cada livro tem `chapters` = lista de capítulos = lista de versículos (strings).
- Validar um arquivo: `python tools/check_bible.py assets/bibles/arc.json`
- Favoritos, notas, tradução escolhida e último capítulo ficam no aparelho.
- ARA/NAA/NVI têm direitos autorais: só inclua com licença de distribuição.

## Baixar traduções
`python tools/baixar_biblias.py` baixa ACF, AA, NVI e KJV para assets/bibles/ (precisa de internet).
Depois: `flutter pub get` e `flutter run`. Para outras traduções (ARA, NAA...), coloque seu arquivo em assets/bibles/<id>.json.

## Favoritos e notas (tela única)
- Aba Estudos → "Favoritos e notas": duas abas (Favoritos / Notas), ordenadas pela ordem da Bíblia, com o texto na tradução escolhida.
- Favoritos: deslizar para remover (com "Desfazer"), menu com Copiar, Compartilhar e Remover.
- Notas: agrupadas por versículo, com editar e apagar (apagar pede confirmação).
- Tocar em um item abre o capítulo já rolado e com o versículo destacado (também vale para resultados da busca).
- No leitor, segurar um versículo agora tem Copiar e Compartilhar. Formato: “texto” — Livro cap:vers (TRAD).
- Novo pacote: share_plus. Rode `flutter pub get`.

## Referência direta e comparação de traduções
- Na busca, digitar "Jo 3:16", "Sl 23", "1 Co 13.4-7", "Jd 3" mostra o atalho "Abrir ..." e abre direto no versículo (faixas como 4-7 ficam destacadas). Só o nome do livro abre a lista de capítulos.
- No leitor, segurar um versículo → "Comparar traduções" mostra o versículo em todas as traduções instaladas.

## Plano de leitura (offline)
- Planos: Bíblia em um ano, Novo Testamento em 90 dias, Salmos e Provérbios em 30 dias.
- Tela com progresso, leitura de hoje com caixinhas, dias atrasados e dias seguidos. Atalho na Início e em Estudos.
- No leitor, quando o capítulo faz parte do plano ativo, aparece o botão de "marcar como lido" na barra superior.

## Strong (original hebraico, aramaico e grego)
- Traduções com Strong têm o texto no formato `palavra<H1121>` (igual ao MySword). As palavras marcadas ficam coloridas e tocáveis; o número não aparece no texto.
- Tocar numa palavra abre o verbete: alfabeto original (hebraico/aramaico da direita para a esquerda), transliteração, pronúncia, significado, origem, como a KJV traduz e "Ver ocorrências" (todos os versículos com aquele número na tradução aberta).
- Cor do destaque e liga/desliga: no leitor, botão "Aa" (8 cores prontas + cor personalizada RGB). A escolha fica salva.
- Busca, copiar, compartilhar, comparar e favoritos usam o texto sem as marcações.
- IDs reconhecidos: `kjvs`, `acfs`, `aras` e `demos` (amostra de João 1:1-5, já incluída).
- Dados: `python tools/montar_strong.py dicionario [--pt significados_pt.json]` e `python tools/montar_strong.py biblia ORIGEM.json ID`. Detalhes no topo do script.
- assets/strongs/ traz só uma amostra pequena; o comando `dicionario` a substitui pelo dicionário completo.
- Aramaico: o app reconhece pelas palavras marcadas como "Chaldee" no dicionário de Strong.

## Me explicar (IA)
- No leitor: segurar um versículo -> "Me explicar". Mostra contexto, sentido das palavras (usa os números Strong quando a tradução tem), visões diferentes entre tradições e uma aplicação curta. Pode copiar e gerar de novo.
- Respostas ficam guardadas no aparelho (até 200), então repetir o mesmo versículo não gasta de novo.
- A chave da IA fica no servidor (pasta `server/`, função para a Vercel). Passos em `server/README.md`.
- Rodar o app: `flutter run -d chrome --dart-define=VERBO_API_URL=https://SEU-PROJETO.vercel.app --dart-define=VERBO_APP_KEY=senha`. Sem `VERBO_API_URL`, o botão avisa que falta configurar.
- Novo pacote: http. Rode `flutter pub get`.
