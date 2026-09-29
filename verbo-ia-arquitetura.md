# VERBO IA — Arquitetura da Plataforma
**Fase 0 — Entregável de Arquitetura (pré-implementação)**

> Nome provisório. Identidade visual, textos e marca 100% originais — nenhum conteúdo proprietário de apps concorrentes é referenciado ou copiado aqui.

---

## 1. Visão Geral da Arquitetura

VERBO IA é um SaaS modular composto por 4 grandes domínios, todos desacoplados via API:

1. **Apresentação** — apps Flutter (iOS/Android) e Next.js (Web/SEO/Admin).
2. **Domínio/API** — camada de regras de negócio, nunca exposta diretamente ao frontend sem autorização (Edge Functions / API própria em frente ao Supabase).
3. **Dados** — PostgreSQL (Supabase) com RLS como linha de defesa principal, pgvector para embeddings.
4. **IA/Automação** — pipeline RAG orquestrado por n8n, mas com lógica crítica (auth, limites, cobrança) fora do n8n.

Princípio central: **o frontend nunca decide permissão nem confia em si mesmo** — toda checagem de plano, limite e RLS acontece no backend/banco.

## 2. Stack Final Recomendada

| Camada | Tecnologia | Observação |
|---|---|---|
| Mobile | Flutter | app único iOS/Android |
| Web | Next.js + TypeScript | site, marketing, admin web |
| Backend/API | Supabase Edge Functions (Deno/TS) + PostgreSQL functions (RPC) | lógica crítica aqui, não no n8n |
| Banco | PostgreSQL (Supabase) | RLS ativo em toda tabela sensível |
| Busca semântica | pgvector | embeddings de chunks |
| Automação/IA | n8n | orquestração RAG, geração assíncrona, notificações |
| IA/LLM | API de modelo de linguagem (via n8n ou Edge Function) | prompts versionados em tabela `ai_prompts` |
| Pagamentos | Stripe (internacional) + Mercado Pago (BR) | webhooks validados por assinatura |
| Notificações | Firebase Cloud Messaging | push mobile |
| Analytics | PostHog (self-host ou cloud) | eventos de produto |
| Observabilidade | Logs estruturados (JSON) + dashboard (Grafana/Supabase Logs) | P50/P95/P99 |

## 3. Diagrama da Arquitetura

```
                         MOBILE (Flutter)        WEB (Next.js)
                                 \                    /
                                  \                  /
                                   v                v
                          ┌───────────────────────────┐
                          │   API Gateway / Edge Fns   │
                          │  (auth, planos, limites)   │
                          └───────────┬───────────────┘
                                      │
                     ┌────────────────┼─────────────────┐
                     v                v                 v
              ┌────────────┐  ┌─────────────┐   ┌──────────────┐
              │  Supabase  │  │  Supabase    │   │  Supabase    │
              │  Auth      │  │  Storage     │   │  PostgreSQL  │
              └────────────┘  └─────────────┘   │  + pgvector  │
                                                  └──────┬───────┘
                                                         │
                                                         v
                                                 ┌───────────────┐
                                                 │      n8n      │
                                                 │ (orquestração)│
                                                 └───────┬───────┘
                                    ┌────────────────────┼────────────────────┐
                                    v                    v                    v
                            ┌──────────────┐    ┌────────────────┐   ┌───────────────┐
                            │   RAG        │    │  Modelo de IA   │   │  Serviços      │
                            │ (retrieval)  │───▶│  (LLM API)      │   │  externos      │
                            └──────┬───────┘    └────────┬────────┘   │ (Stripe, FCM,  │
                                   │                      │            │  PostHog)      │
                                   v                      v            └───────────────┘
                            ┌──────────────────────────────────┐
                            │   Validação de resposta / parser  │
                            └──────────────┬─────────────────────┘
                                           v
                                  Resposta ao usuário
```

## 4. Modelo de Banco de Dados (DDL essencial)

Convenções: `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`, `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()`, `deleted_at TIMESTAMPTZ` (soft delete onde fizer sentido).

### 4.1 Usuários e Assinaturas
```sql
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  avatar_url text,
  plan text not null default 'FREE' check (plan in ('FREE','PREMIUM','PRO','ADMIN')),
  bible_version_default_id uuid,
  font_size int default 16,
  theme text default 'auto' check (theme in ('light','dark','auto')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table subscription_plans (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,          -- FREE, PREMIUM, PRO
  name text not null,
  price_cents int not null,
  currency text default 'BRL',
  ai_daily_limit int,
  features jsonb,
  active boolean default true
);

create table subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  plan_id uuid references subscription_plans(id),
  status text check (status in ('active','canceled','past_due','trialing')),
  provider text check (provider in ('stripe','mercadopago')),
  provider_subscription_id text,
  current_period_end timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  subscription_id uuid references subscriptions(id),
  amount_cents int not null,
  currency text default 'BRL',
  provider text not null,
  provider_payment_id text,
  status text check (status in ('pending','paid','failed','refunded')),
  created_at timestamptz default now()
);

create table user_preferences (
  user_id uuid primary key references profiles(id) on delete cascade,
  notifications_enabled boolean default true,
  reading_reminder_time time,
  preferred_language text default 'pt-BR'
);
```

### 4.2 Bíblia
```sql
create table bible_versions (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,          -- ex: NVI, ARA
  name text not null,
  language text not null default 'pt-BR',
  license text,
  copyright_status text check (copyright_status in ('public_domain','licensed')),
  is_active boolean default true
);

create table bible_books (
  id uuid primary key default gen_random_uuid(),
  version_id uuid references bible_versions(id),
  book_number int not null,
  name text not null,
  abbreviation text,
  testament text check (testament in ('OT','NT'))
);

create table bible_chapters (
  id uuid primary key default gen_random_uuid(),
  book_id uuid references bible_books(id),
  chapter_number int not null
);

create table bible_verses (
  id uuid primary key default gen_random_uuid(),
  chapter_id uuid references bible_chapters(id),
  verse_number int not null,
  text text not null,
  search_vector tsvector
);
create index idx_bible_verses_search on bible_verses using gin(search_vector);

create table cross_references (
  id uuid primary key default gen_random_uuid(),
  verse_id uuid references bible_verses(id),
  related_verse_id uuid references bible_verses(id),
  relation_type text
);

create table bible_topics (
  id uuid primary key default gen_random_uuid(),
  name text unique not null
);

create table bible_keywords (
  id uuid primary key default gen_random_uuid(),
  verse_id uuid references bible_verses(id),
  keyword text not null
);

create table dictionary_terms (
  id uuid primary key default gen_random_uuid(),
  term text not null,
  language text default 'pt-BR'
);

create table dictionary_entries (
  id uuid primary key default gen_random_uuid(),
  term_id uuid references dictionary_terms(id),
  content text not null,
  source_id uuid
);
```

### 4.3 RAG / Conhecimento
```sql
create extension if not exists vector;

create table document_sources (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type text check (type in ('commentary','historical','theological','dictionary','other')),
  license text,
  copyright_status text check (copyright_status in ('public_domain','licensed')),
  language text default 'pt-BR'
);

create table documents (
  id uuid primary key default gen_random_uuid(),
  source_id uuid references document_sources(id),
  title text,
  book text,
  chapter int,
  verse int,
  topic text,
  language text default 'pt-BR'
);

create table document_chunks (
  id uuid primary key default gen_random_uuid(),
  document_id uuid references documents(id),
  content text not null,
  chunk_index int not null,
  metadata jsonb
);

create table embeddings (
  id uuid primary key default gen_random_uuid(),
  chunk_id uuid references document_chunks(id) on delete cascade,
  embedding vector(1536),
  model text
);
create index idx_embeddings_vector on embeddings using ivfflat (embedding vector_cosine_ops);

create table commentaries (
  id uuid primary key default gen_random_uuid(),
  source_id uuid references document_sources(id),
  verse_id uuid references bible_verses(id),
  content text
);

create table theological_sources (
  id uuid primary key default gen_random_uuid(),
  name text,
  tradition text,
  description text
);

create table historical_sources (
  id uuid primary key default gen_random_uuid(),
  name text,
  period text,
  description text
);
```

### 4.4 Estudos, Sermões, Devocionais, EBD
```sql
create table studies (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id),
  title text not null,
  is_public boolean default false,
  created_at timestamptz default now()
);
create table study_sections (
  id uuid primary key default gen_random_uuid(),
  study_id uuid references studies(id) on delete cascade,
  order_index int,
  content text
);
create table study_questions (
  id uuid primary key default gen_random_uuid(),
  study_id uuid references studies(id) on delete cascade,
  question text,
  answer text
);

create table sermons (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id),
  title text,
  base_text text,
  audience text,
  duration_minutes int,
  style text,
  created_at timestamptz default now()
);
create table sermon_sections (
  id uuid primary key default gen_random_uuid(),
  sermon_id uuid references sermons(id) on delete cascade,
  section_type text,   -- intro, ponto, ilustracao, conclusao, apelo
  order_index int,
  content text
);

create table devotionals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id),
  title text,
  passage text,
  reflection text,
  application text,
  prayer text,
  created_at timestamptz default now()
);
```

### 4.5 Planos, Notas, Destaques, Quiz, Conversas com IA
```sql
create table reading_plans (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type text check (type in ('annual','nt','gospels','psalms','custom')),
  created_by uuid references profiles(id)
);
create table reading_plan_days (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid references reading_plans(id) on delete cascade,
  day_number int,
  passage_reference text
);
create table user_reading_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  plan_id uuid references reading_plans(id),
  day_number int,
  completed_at timestamptz
);

create table notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  verse_id uuid references bible_verses(id),
  content text not null,
  tags text[],
  created_at timestamptz default now()
);
create table highlights (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  verse_id uuid references bible_verses(id),
  color text
);
create table bookmarks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  verse_id uuid references bible_verses(id)
);

create table ai_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  mode text,   -- explicacao, exegese, estudo, sermao, etc.
  title text,
  created_at timestamptz default now()
);
create table ai_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid references ai_conversations(id) on delete cascade,
  role text check (role in ('user','assistant','system')),
  content text,
  sources jsonb,
  created_at timestamptz default now()
);
create table ai_usage (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id),
  model text,
  request_type text,
  tokens_input int,
  tokens_output int,
  estimated_cost numeric(10,6),
  created_at timestamptz default now()
);
create table ai_feedback (
  id uuid primary key default gen_random_uuid(),
  message_id uuid references ai_messages(id),
  user_id uuid references profiles(id),
  rating int check (rating between 1 and 5),
  comment text
);
create table ai_prompts (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  version int not null,
  content text not null,
  active boolean default true,
  created_at timestamptz default now(),
  unique(name, version)
);

create table quizzes (
  id uuid primary key default gen_random_uuid(),
  title text,
  source_type text  -- ebd, study, general
);
create table quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid references quizzes(id) on delete cascade,
  question text,
  type text check (type in ('multiple_choice','true_false','fill_blank','interpretation'))
);
create table quiz_answers (
  id uuid primary key default gen_random_uuid(),
  question_id uuid references quiz_questions(id) on delete cascade,
  answer_text text,
  is_correct boolean
);
create table quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  quiz_id uuid references quizzes(id),
  score numeric,
  duration_seconds int,
  created_at timestamptz default now()
);
```

### 4.6 Notificações, Admin, Auditoria, Referências
```sql
create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  title text,
  body text,
  read_at timestamptz,
  created_at timestamptz default now()
);

create table admin_users (
  id uuid primary key references profiles(id),
  role text check (role in ('superadmin','content_manager','support'))
);

create table audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid,
  action text,
  entity text,
  entity_id uuid,
  metadata jsonb,
  created_at timestamptz default now()
);

create table referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid references profiles(id),
  referred_id uuid references profiles(id),
  status text,
  created_at timestamptz default now()
);
create table coupons (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  discount_percent int,
  valid_until timestamptz,
  active boolean default true
);
```

## 5. Relacionamentos (resumo)

- `profiles` é o hub central: 1:N com `subscriptions`, `notes`, `highlights`, `bookmarks`, `studies`, `sermons`, `devotionals`, `ai_conversations`, `quiz_attempts`, `user_reading_progress`.
- `bible_versions → bible_books → bible_chapters → bible_verses` (cadeia hierárquica 1:N).
- `documents → document_chunks → embeddings` é a cadeia do pipeline RAG; `document_chunks.metadata` guarda `book/chapter/verse/topic/source_type/copyright_status` para filtragem antes do reranking.
- `ai_conversations → ai_messages`, com `ai_messages.sources` (jsonb) registrando quais versículos/documentos embasaram a resposta.
- `subscription_plans → subscriptions → payments`, e `ai_usage` referenciando `user_id` para cálculo de limite/custo por plano.

## 6. Row Level Security (RLS)

Padrão aplicado a **toda** tabela com `user_id`:

```sql
alter table notes enable row level security;

create policy "select_own_notes" on notes
  for select using (auth.uid() = user_id);

create policy "modify_own_notes" on notes
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```

Aplicar o mesmo padrão em: `highlights`, `bookmarks`, `studies` (privados), `sermons`, `devotionals`, `ai_conversations`, `ai_messages` (via join com conversation), `ai_usage`, `quiz_attempts`, `user_reading_progress`, `subscriptions`, `payments`, `notifications`, `user_preferences`.

Conteúdo público (`bible_verses`, `bible_books`, `dictionary_entries`, `commentaries`, `reading_plans` públicos, `studies` com `is_public = true`):
```sql
create policy "public_read" on bible_verses for select using (true);
```

Conteúdo administrativo (`admin_users`, `audit_logs`, `ai_prompts`, `document_sources`):
```sql
create policy "admin_only" on ai_prompts
  for all using (exists (
    select 1 from admin_users a where a.id = auth.uid()
  ));
```

Regra geral: **toda operação sensível é revalidada em Edge Function/RPC** — RLS é a segunda camada, nunca a única (o app nunca decide sozinho se pode gravar).

## 7. Arquitetura RAG

```
Pergunta do usuário
   ↓
1. Classificação (intenção: versículo específico / tema / pergunta livre / pedido de sermão etc.)
   ↓
2. Identificação da passagem (regex/parser de referências + resolução via bible_books/chapters)
   ↓
3. Busca bíblica direta (texto exato, se referência identificada)
   ↓
4. Busca semântica (embedding da pergunta × pgvector em `embeddings`, filtrado por metadata)
   ↓
5. Busca de fontes (commentaries, theological_sources, historical_sources relacionadas)
   ↓
6. Reranking (score textual + score semântico + prioridade de fonte confiável)
   ↓
7. Construção do contexto (montagem do prompt com trechos + metadata de origem)
   ↓
8. Chamada ao modelo de IA (com system prompt versionado de `ai_prompts`)
   ↓
9. Validação da resposta (parser checa: referências existem no banco? fontes citadas batem com o contexto enviado? algum trecho sem lastro?)
   ↓
10. Resposta final + lista de fontes consultadas
```

Se a validação falhar (referência inexistente, fonte não encontrada no contexto), a resposta é reescrita com: *"Não encontrei informação suficiente para afirmar isso."*

## 8. Arquitetura n8n (workflows)

| # | Workflow | Gatilho |
|---|---|---|
| 01 | AI - Explain Verse | chamada de Edge Function |
| 02 | AI - Bible Study | chamada de Edge Function |
| 03 | AI - Exegesis | chamada de Edge Function |
| 04 | AI - Sermon | chamada de Edge Function |
| 05 | AI - Devotional | chamada de Edge Function |
| 06 | AI - EBD | chamada de Edge Function |
| 07 | AI - Quiz | chamada de Edge Function |
| 08 | AI - Semantic Search | chamada de Edge Function |
| 09 | AI - RAG (pipeline central, chamado pelos workflows 01-08) | interno |
| 10 | AI - Source Validation | interno, pós-geração |
| 11 | Daily Devotional | cron diário |
| 12 | Reading Reminder | cron + FCM |
| 13 | Subscription Verification | cron / webhook Stripe-MP |
| 14 | Payment Webhook | webhook |
| 15 | Usage Tracking | interno, após cada chamada de IA |
| 16 | Admin Notifications | eventos administrativos |

**Importante**: n8n nunca é o único guardião de autorização/limite. A Edge Function valida usuário, plano e limite *antes* de acionar o webhook do n8n; o n8n apenas orquestra a geração de conteúdo e devolve o resultado.

## 9. APIs (endpoints principais)

```
POST /ai/explain
POST /ai/study
POST /ai/exegesis
POST /ai/sermon
POST /ai/devotional
POST /ai/ebd
POST /ai/quiz
POST /ai/search

POST /payments/webhook

GET  /bible/search
GET  /bible/verse

POST /notes
POST /highlights
POST /bookmarks
```

Cada endpoint `/ai/*` segue o mesmo contrato: `auth → checagem de plano/limite → RAG (via n8n) → validação → registro em ai_usage → resposta`.

## 10. Estrutura de Diretórios (proposta)

```
verbo-ia/
├── apps/
│   ├── mobile/                # Flutter
│   └── web/                   # Next.js
├── backend/
│   ├── edge-functions/        # Deno/TS - auth, limites, RAG trigger
│   ├── db/
│   │   ├── migrations/
│   │   └── policies/          # RLS
│   └── shared/                # tipos, contratos, validação
├── automation/
│   └── n8n-workflows/         # export JSON versionado dos 16 workflows
├── ai/
│   ├── prompts/                # versionados, espelham tabela ai_prompts
│   └── pipelines/              # descrição do RAG por modo
├── docs/
│   ├── architecture.md
│   ├── er-diagram.md
│   └── roadmap.md
└── tests/
    ├── unit/
    ├── integration/
    └── e2e/
```

## 11. Estratégia de Autenticação

- Supabase Auth (email/senha + login social quando disponível).
- Sessão validada em toda Edge Function via JWT do Supabase.
- `profiles.plan` é a fonte de verdade de nível de acesso, sincronizada por webhook de pagamento (nunca editável pelo cliente).
- RLS usa `auth.uid()` como base de todas as políticas de dados pessoais.

## 12. Estratégia de Planos

| Plano | Limite de IA/dia | Recursos |
|---|---|---|
| FREE | baixo (ex.: 5 interações) | Bíblia, busca, recursos básicos |
| PREMIUM | médio | + estudos, devocionais, sermões, planos |
| PRO | alto | + exportação, ferramentas para professores/pastores |
| ADMIN | ilimitado (interno) | painel administrativo |

Limites concretos (número exato de interações, preços) ficam para definição de produto/negócio antes da Fase 5 — aqui só a estrutura de controle (`subscription_plans.ai_daily_limit`).

## 13. Estratégia de Custos de IA

Pipeline antes de qualquer chamada ao modelo:
1. Verificar usuário autenticado.
2. Verificar assinatura ativa (`subscriptions.status`).
3. Verificar limite diário restante (`ai_usage` agregada por dia).
4. Estimar custo pela contagem de tokens de entrada esperada.
5. Executar a chamada.
6. Registrar `tokens_input`, `tokens_output`, `estimated_cost` em `ai_usage`.

Cache de respostas para perguntas frequentes/idempotentes (ex.: "explique João 3:16") reduz custo repetido — chave de cache por `(mode, passage/tema, versão bíblica)`.

## 14. Riscos Técnicos

- **Alucinação da IA**: mitigado pela validação pós-geração (passo 9 do RAG) e pela regra de nunca inventar fonte/versículo.
- **Custo de IA imprevisível**: mitigado por limites por plano + estimativa prévia + cache.
- **Vazamento de dados entre usuários**: mitigado por RLS + testes E2E dedicados ("usuário A não acessa dados do usuário B").
- **Dependência excessiva do n8n**: mitigado por manter auth/limites/cobrança fora do n8n, em Edge Functions.
- **Direitos autorais de traduções bíblicas e comentários**: mitigado por `bible_versions.copyright_status` e `document_sources.copyright_status`, começando com conteúdo de domínio público.
- **Escala do pgvector em milhares de usuários simultâneos**: mitigado por índice `ivfflat`, paginação e cache de embeddings de perguntas recorrentes.
- **Divergência teológica**: mitigado pela regra de sempre apresentar múltiplas perspectivas sem afirmar uma como verdade absoluta.

## 15. Roadmap

| Fase | Escopo |
|---|---|
| 1 | Infraestrutura, banco, Auth, Bíblia digital |
| 2 | Pesquisa (textual/semântica), IA, RAG |
| 3 | Estudos, sermões, devocionais, EBD |
| 4 | Planos de leitura, quiz, gamificação |
| 5 | Assinaturas e pagamentos |
| 6 | Admin dashboard |
| 7 | Analytics, performance, escalabilidade |

---

**Próximo passo sugerido**: aprovar esta arquitetura e iniciar a Fase 1 (infraestrutura + banco + Auth + Bíblia digital), entregando, testando e documentando antes de avançar para a Fase 2.
