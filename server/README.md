# Servidor do "Me explicar"

Função serverless para a Vercel. A chave da IA fica aqui, nunca dentro do app.

## Publicar
1. Instale o Node e rode, dentro desta pasta `server`:
       npx vercel
   (aceite os padrões; ele cria um projeto novo).
2. No painel da Vercel, em Settings -> Environment Variables, crie:
   - `ANTHROPIC_API_KEY`: sua chave da API da Anthropic (console.anthropic.com).
   - `APP_KEY` (recomendado): uma senha qualquer, a mesma que o app vai enviar.
   - `AI_MODEL` (opcional): padrão `claude-haiku-4-5-20251001` (barato e rápido).
3. Rode `npx vercel --prod` para publicar com as variáveis.

## Rodar o app apontando para ele
    flutter run -d chrome --dart-define=VERBO_API_URL=https://SEU-PROJETO.vercel.app --dart-define=VERBO_APP_KEY=a_mesma_senha

## Cuidados
- O `APP_KEY` dentro do app pode ser extraído por quem examinar o aplicativo. Ele só barra uso casual.
  Para uso público, defina um limite de gasto na sua conta da Anthropic e, depois, adicione login
  (o app já tem Supabase) ou limite de pedidos por usuário.
- O texto do versículo e as palavras Strong vão para a IA; nada de dados pessoais é enviado.
