// Função serverless (Vercel) do "Me explicar". Guarda a chave da IA fora do app.
// Variáveis de ambiente: ANTHROPIC_API_KEY (obrigatória), APP_KEY (opcional),
// AI_MODEL (opcional, padrão claude-haiku-4-5-20251001).

const SYSTEM = `Você ajuda a estudar a Bíblia, em português do Brasil, com tom respeitoso e claro.
Ao explicar um versículo:
- Situe o contexto (livro, quem fala, a quem, o que acontece em volta).
- Explique o significado das palavras-chave. Se receber números Strong, use-os para comentar o sentido no hebraico, aramaico ou grego, sem inventar o que não sabe.
- Se houver interpretações diferentes entre tradições cristãs, apresente-as com equilíbrio, sem impor uma.
- Termine com uma aplicação prática curta.
- Não invente citações, datas ou referências. Se não tiver certeza, diga.
- No máximo 250 palavras, em parágrafos curtos, sem títulos.`;

function limpa(v, max) {
  return typeof v === 'string' ? v.trim().slice(0, max) : '';
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'content-type, x-app-key');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Método não permitido.' });

  if (process.env.APP_KEY && req.headers['x-app-key'] !== process.env.APP_KEY) {
    return res.status(401).json({ error: 'Acesso não autorizado.' });
  }
  if (!process.env.ANTHROPIC_API_KEY) {
    return res.status(500).json({ error: 'Servidor sem chave da IA configurada.' });
  }

  const body = req.body || {};
  const reference = limpa(body.reference, 80);
  const text = limpa(body.text, 1500);
  const translation = limpa(body.translation, 40);
  const strongs = Array.isArray(body.strongs)
    ? body.strongs.slice(0, 40).map((s) => limpa(s, 60)).filter(Boolean)
    : [];
  if (!reference || !text) return res.status(400).json({ error: 'Faltam reference e text.' });

  let pedido = `Explique ${reference}${translation ? ` (${translation})` : ''}:\n"${text}"`;
  if (strongs.length) pedido += `\n\nPalavras com número Strong (palavra=número): ${strongs.join('; ')}`;

  try {
    const r = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': process.env.ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: process.env.AI_MODEL || 'claude-haiku-4-5-20251001',
        max_tokens: 700,
        system: SYSTEM,
        messages: [{ role: 'user', content: pedido }],
      }),
    });
    const data = await r.json();
    if (!r.ok) {
      return res.status(502).json({ error: data?.error?.message || 'A IA não respondeu.' });
    }
    const answer = (data.content || [])
      .filter((b) => b.type === 'text')
      .map((b) => b.text)
      .join('\n')
      .trim();
    return res.status(200).json({ answer });
  } catch (e) {
    return res.status(502).json({ error: 'Falha ao falar com a IA.' });
  }
};
