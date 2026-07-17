# Justificativa de Escolha dos Bancos de Dados — Conexão Solidária

> **FIAP Pós Tech — Tech Challenge Fase 5**
> Grupo 1: Gustavo Merendi & Thiago Galante
> Documento entregável obrigatório conforme requisito do Hackathon.

---

## 1. Visão Geral da Estratégia de Dados

A plataforma Conexão Solidária adota o padrão **Database per Service** — cada microsserviço possui seu próprio banco de dados isolado. Esta decisão evita acoplamento entre serviços, permite escalonamento independente e alinha-se com os princípios de microsserviços.

Foram escolhidos três tipos de banco de dados, cada um para um propósito distinto:

| Banco | Tipo | Serviços | Propósito Principal |
|---|---|---|---|
| **PostgreSQL 16** | Relacional (SQL) | Usuários, Campanhas, Doações | Dados transacionais com consistência ACID |
| **Redis 7** | In-Memory (NoSQL) | Todos | Cache, sessões, idempotência |
| **AWS DynamoDB** | Documento (NoSQL) | Todos | Audit trail, logs, notificações |

---

## 2. PostgreSQL — Banco Relacional

### Por que PostgreSQL?

**Consistência ACID é obrigatória para dados financeiros.** Uma doação envolve múltiplas operações (inserir doação + atualizar total da campanha) que devem ser atômicas. Se o sistema falhar no meio do processo, não pode haver doações registradas sem atualização do total, nem totais atualizados sem doação registrada.

**Relacionamentos são naturais no domínio.** Campanhas têm muitas Doações. Usuários realizam muitas Doações. Estas relações são melhor expressas em um modelo relacional com integridade referencial (Foreign Keys).

**Operações atômicas nativas** — o Worker usa `UPDATE campaigns SET raised_amount = raised_amount + @value` como operação única e atômica, evitando race conditions com múltiplos workers processando doações simultâneas. Bancos NoSQL geralmente não suportam isso nativamente.

**Excelente suporte no ecossistema .NET** via EF Core + Npgsql. Migrations versionadas garantem evolução controlada do schema.

### Por que não outros relacionais?

| Alternativa | Motivo da Rejeição |
|---|---|
| SQL Server | Custo de licença para produção; overhead desnecessário |
| MySQL | Menor suporte a UUID nativo; Postgres implementa muito mais do padrão SQL; JSONB nativo com indexação (GIN), arrays; Postgres roda em .NET com Npgsql/EF Core, que tem suporte excelente e maduro pro Postgres  |
| SQLite | Sem suporte a múltiplas conexões concorrentes (Worker + API) |

### Modelo de Dados por Serviço

**Usuários:**
```
users (id, full_name, email, cpf_encrypted, password_hash, role, status, created_at)
```

**Campanhas:**
```
campaigns (id, title, description, start_date, end_date, financial_goal, raised_amount, status, created_at, updated_at)
```

**Doações:**
```
donations (id, campaign_id, donor_id, amount, status, idempotency_key, created_at, processed_at)
```

---

## 3. Redis — Cache e Sessões

### Por que Redis?

**Velocidade sub-milissegundo** — dados em memória acessados em microssegundos. Ideal para operações de alta frequência.

**TTL (Time To Live) nativo** — fundamental para:
- RefreshTokens (expiram em 7 dias — sem necessidade de job de limpeza)
- Tokens de reset de senha (30 minutos)
- Cache de campanhas (2 minutos — invalidado após doação processada)
- Chaves de idempotência (24 horas)

**Não é adequado como banco principal** — Redis é volátil por padrão (dados podem ser perdidos em reinicialização). Por isso é usado apenas para dados regeneráveis (cache pode ser reconstruído do PostgreSQL) ou de curta duração (tokens).

### Casos de Uso no Projeto

| Chave | TTL | Valor | Serviço |
|---|---|---|---|
| `refresh:{userId}:{tokenId}` | 7 dias | hash do token | Usuários |
| `reset:{token}` | 30 min | userId | Usuários |
| `profile:{userId}` | 5 min | JSON do perfil | Usuários |
| `campaign:active:page:{n}` | 2 min | JSON da página | Campanhas |
| `campaign:{id}` | 1 min | JSON da campanha | Campanhas |
| `idempotency:{key}` | 24h | donationId | Doações |

### Teorema CAP

Redis prioriza **CP** (Consistência + Tolerância a Partição) em modo cluster, ou **AP** (Disponibilidade + Tolerância a Partição) em configurações de alta disponibilidade. Para nosso caso de uso (cache e tokens de curta duração), eventual consistency é aceitável — o pior cenário é um cache miss (que recarrega do PostgreSQL) ou um token válido não invalidado por milissegundos.

---

## 4. AWS DynamoDB — Audit Trail e Logs

### Por que DynamoDB?

**Schema-less para dados heterogêneos** — cada evento de auditoria tem estrutura diferente. Um evento de login tem campos diferentes de um evento de doação ou de alteração de campanha. Com DynamoDB, não há migrations — cada item pode ter atributos diferentes.

**Escala infinita sem configuração** — audit trail cresce indefinidamente. DynamoDB escala horizontalmente de forma transparente, sem necessidade de sharding manual ou reconfiguração.

**Acesso por chave primária é O(1)** — consultar o histórico de um usuário específico (`userId`) é instantâneo. Não há scans de tabela completa.

**TTL nativo para retenção** — logs configurados para expirar automaticamente (ex: logs de acesso por 90 dias, eventos de auditoria por 1 ano). Sem necessidade de jobs de limpeza.

**Audit trail não tem relacionamentos** — não há JOINs em audit trail. Cada evento é independente. Usar PostgreSQL para isso seria desperdiçar capacidade relacional.

### Modelo de Dados

```
Partition Key: entityType#entityId
  Exemplos: "user#uuid-123", "campaign#uuid-456", "donation#uuid-789"

Sort Key: timestamp#eventId
  Exemplo: "2025-06-15T14:30:00Z#uuid-event"

Atributos: action, performedBy, correlationId, metadata{before, after}, ttl
```

Este modelo permite:
- Buscar todos os eventos de um usuário: `PK = "user#uuid"` (sem scan)
- Buscar eventos em um período: `PK = "user#uuid" AND SK BETWEEN "2025-06-01" AND "2025-06-30"`

### Logs Estruturados Adicionais

Quando `SAVE_LOGS=true` no environment, logs JSON de todos os serviços são gravados no DynamoDB com:
- `correlationId` — rastreamento ponta a ponta
- `service` — nome do microsserviço
- `level` — DEBUG, INFO, WARN, ERROR
- `traceId` — OpenTelemetry trace ID
- `ttl` — expiração automática (90 dias)

### Por que não MongoDB?

| Critério | DynamoDB | MongoDB |
|---|---|---|
| Operacional | Serverless (zero config) | Requer gerenciamento |
| Escala | Automática | Manual/Atlas |
| TTL nativo | Sim | Sim |
| Integração AWS | Nativa | Via driver |
| Custo no projeto | Free tier generoso | Requer cluster |

Para um projeto que já usa AWS (DynamoDB Local para desenvolvimento), DynamoDB é a escolha natural e operacionalmente mais simples.

---

## 5. Elasticsearch — Busca Full-Text

### Por que Elasticsearch e não PostgreSQL LIKE?

| Critério | Elasticsearch | PostgreSQL LIKE/ILIKE |
|---|---|---|
| Ranking por relevância | Sim (TF-IDF/BM25) | Não |
| Fuzzy search | Sim | Não |
| Highlights | Sim | Não |
| Análise morfológica | Sim (pt-BR) | Não |
| Performance em textos longos | Índice invertido (O(1)) | Scan O(n) |
| Boost por campo | Sim | Não |

Uma busca por "criança" no Elasticsearch encontra campanhas sobre "crianças", "criançada", "criancinha" — a análise morfológica do idioma português é feita automaticamente pelo analisador `portuguese`.

**PostgreSQL não foi projetado para busca full-text com ranking** — é um banco relacional excelente para o que faz, mas busca com relevância é um caso de uso que Elasticsearch resolve de forma muito superior.

---

## 6. Comparativo — Teorema CAP por Banco

```
        Consistência
             |
PostgreSQL   |   DynamoDB (modo CP)
    (CA)     |       (CP)
             |
─────────────┼─────────────
             |
  Redis (AP) |
 (cache/TTL) |   
             |
    Disponibilidade ──── Tolerância a Partição
```

| Banco | CAP | Justificativa |
|---|---|---|
| PostgreSQL | CA | Dados financeiros — consistência obrigatória |
| Redis | AP | Cache — eventual consistency aceitável |
| DynamoDB | CP/AP (configurável) | Audit trail — disponibilidade preferível |
| Elasticsearch | AP | Busca — eventual consistency aceitável (índice pode estar 1-2s atrás) |

---

## 7. Decisão Final

A escolha de três bancos diferentes pode parecer complexidade adicional, mas cada um resolve um problema específico de forma ótima:

- **PostgreSQL** quando precisamos de **garantias ACID e relacionamentos** (dados financeiros)
- **Redis** quando precisamos de **velocidade e TTL automático** (cache e tokens)
- **DynamoDB** quando precisamos de **escala, schema flexível e TTL** (auditoria e logs)
- **Elasticsearch** quando precisamos de **busca relevante em texto** (painel público)

Usar PostgreSQL para tudo seria mais simples, mas resultaria em: degradação de performance no cache (banco relacional não é otimizado para isso), schema migrations para cada novo tipo de evento de auditoria, e busca full-text de qualidade inferior para o painel de campanhas.

A escolha poliglota é justificada pelos benefícios tangíveis e está alinhada com as práticas de microsserviços onde cada serviço escolhe o armazenamento mais adequado para seu domínio.
