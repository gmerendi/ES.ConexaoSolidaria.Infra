# Conexão Solidária — Infraestrutura

Repositório de **Infraestrutura** da plataforma **Conexão Solidária**, desenvolvido para a ONG Esperança Solidária como parte do Hackathon POSTECH/FIAP. Utilizando esse repositório, é possivel rodar o projeto completo, localmente ou em Cloud AWS.

Responsável por:
- Rodar a configuração local no Docker Desktop utilizando docker-compose.
- Rodar a configuração local no Docker Desktop, utilizando manifestos Kunernetes.
- Criar a configuração em cloud IAAS utilizando Terraform.
- Rodar a configuração em Cloud AWS, utilizando manifestos Kubernetes.

---

## Sumário
- [Repositorios do Projeto](#repositorios-do-projeto)
- [Arquitetura](#arquitetura)
- [Stack Tecnológica](#stack-tecnológica)
- [Perfis e Regras de Acesso](#perfis-e-regras-de-acesso)
- [Endpoints](#endpoints)
- [Como Rodar Localmente](#como-rodar-localmente)
- [Variáveis de Ambiente](#variáveis-de-ambiente)
- [Observabilidade](#observabilidade)
- [Eventos de Domínio](#eventos-de-dominio)
- [Testes](#testes)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Github Actions](#github-actions)

---

## Repositorios do Projeto

| Repositório | Descrição | Roda onde | Substituto no Cloud |
|---|---|---|---|
| [ES.ConexaoSolidaria.Usuarios](https://github.com/gmerendi/ES.ConexaoSolidaria.Usuarios) | API de autenticação, JWT, RBAC e gestão de usuários | Projeto local ou AWS | NA |
| [ES.ConexaoSolidaria.Campanhas](https://github.com/gmerendi/ES.ConexaoSolidaria.Campanhas)  | API de gerenciamento de campanhas | Projeto local ou AWS | NA |
| [ES.ConexaoSolidaria.Worker](https://github.com/gmerendi/ES.ConexaoSolidaria.Worker)  | Worker de processamento de doações | Projeto local ou AWS | NA |
| [ES.ConexaoSolidaria.DynamoPgProxy](https://github.com/gmerendi/ES.ConexaoSolidaria.DynamoPgProxy)  | Proxy para disponibilizar dados do Dynamo no Grafana | Projeto local ou AWS | NA |
| [ES.ConexaoSolidaria.Frontend](https://github.com/gmerendi/ES.ConexaoSolidaria.Frontend)  | Frontend Blazor | Projeto local ou AWS | NA |
| [ES.ConexaoSolidaria.Notificacoes](https://github.com/gmerendi/ES.ConexaoSolidaria.Notificacoes) | Consumer de eventos e envio de emails | Projeto local | SNS |
| [ES.ConexaoSolidaria.Gateway](https://github.com/gmerendi/ES.ConexaoSolidaria.Gateway) | API Gateway (YARP) | Projeto local | AWS Api Gateway |
| [ES.ConexaoSolidaria.Infra](https://github.com/gmerendi/ES.ConexaoSolidaria.Infra) | *(este repositório)* K8s, docker-compose, terraform e documentação | NA | NA | 

---

## Documentação

- [Casos de Uso](./docs/use-cases/)
- [Diagramas](./docs/diagrams/)
- [User Stories](./docs/user-stories/)
- [ADR — Architecture Decision Records](./docs/adr/)
- [Matriz de Rastreabilidade](./docs/traceability-matrix/)
- [Glossário de Domínio](./docs/glossary/)
- [LGPD Compliance](./docs/lgpd/)
- [Contratos de API](./docs/api-contracts/)


- Crie as pastas:<br>
FIAP <br>
|---- ES.ConexaoSolidaria.Usuarios <br>
|---- ES.ConexaoSolidaria.Campanhas <br>
|---- ES.ConexaoSolidaria.Infra <br>
|---- ES.ConexaoSolidaria.Notificacoes <br>
|---- ES.ConexaoSolidaria.Worker <br>
|---- ES.ConexaoSolidaria.Gateway <br>
|---- ES.ConexaoSolidaria.Frontend <br>
|---- ES.ConexaoSolidaria.DynamoPgProxy <br>

<br>
<br>
Siga as instrucoes no ES.ConexaoSolidaria.Infra/docs/Como rodar

---
O sistema possui os seguintes features implementados: <br>
- [Sistema de Logging Estruturado](#sistema-de-logging-estruturado)
- [Sistema de Cache - Redis](#sistema-de-cache)
- [Sistema de Busca Avançada - Elasticsearch](#sistema-de-busca-avancada-elasticsearch)
---


## Sistema de Logging Estruturado

### Visão Geral

O sistema de logging do Conexão Solidária foi desenvolvido com uma arquitetura própria de **logging estruturado**, inspirada no Serilog, porém completamente customizada para as necessidades da plataforma. O design prioriza **observabilidade**, **rastreabilidade de ponta a ponta** e **flexibilidade de storage** — sem depender de bibliotecas de terceiros para a lógica central.  Logs podem ser gravados em base de dados caso a opção CustomLogging:SendLogToDB seja configurada para "True". Logs relativos a eventos, são sempre armazenados, independentemente dessa configuração, para que exista um Event Sourcing.<br>
Quando o projeto é rodado localmente, utilizamos um conteiner com a imagem do DynamoD para armazenar os logs. Caso a escolha seja rodar em Cloud AWS, a instância na nuvem do DynamoDb é utilizada.

---

### Arquitetura

```
Application / Domain
      │
      ▼
IBaseLogger<T>          ← contrato único exposto ao domínio
      │
      ▼
BaseLogger<T>           ← renderiza templates, enriquece com CorrelationId
      │
      ▼
IBaseLoggerDbWriter     ← contrato de persistência (infra ↔ infra)
      │
      ▼
BaseLoggerDbWriter      ← implementação DynamoDB (única classe que conhece o banco)
```

A separação entre **lógica de logging** (`BaseLogger`) e **mecanismo de persistência** (`BaseLoggerDbWriter`) segue o princípio de **Responsabilidade Única (SRP)** e o **Princípio da Inversão de Dependência (DIP)**. Trocar o banco de dados de logs — de DynamoDB para PostgreSQL, Elasticsearch ou qualquer outro — exige modificar **apenas uma classe**, sem impacto algum nos serviços de aplicação.

---

### Message Templates Estruturados

Diferente do logging tradicional, onde a mensagem é uma string concatenada e as informações se perdem em texto livre, o sistema utiliza **message templates nomeados** estilo Serilog:

```csharp
// cada propriedade é um campo estruturado e consultável
_logger.LogInformation("Login de {Email} via {Ip}", BaseLogType.LOG, new { Email = email, Ip = ip });
```

O `BaseLogger` renderiza o template para exibição no console (`Login de user@test.com via 10.0.0.1`) e **simultaneamente** persiste as propriedades como campos individuais no DynamoDB — habilitando consultas precisas, sem varredura de texto.

---

### Correlação de Traces (CorrelationId)

Cada requisição recebe um `CorrelationId` único, gerado automaticamente na entrada e propagado por toda a cadeia de execução — do controller ao repositório, passando pelos domain services e event handlers.

Com o CorrelationId, é possível reconstruir **o trace completo de qualquer requisição** consultando diretamente no DynamoDB ou no dashboard do Grafana — sem precisar correlacionar logs manualmente.

TODO - Inserir figura grafana

---

### Schema do DynamoDB — Tabela `cs-app-log`

| Campo            | Tipo | Descrição                                              |
|------------------|------|--------------------------------------------------------|
| `CorrelationId`  | PK   | ID único do trace — agrupa todos os logs de uma requisição |
| `Timestamp`      | SK   | ISO 8601 UTC — garante ordenação cronológica           |
| `LogLevel`       | S    | `Information` \| `Warning` \| `Error`                 |
| `Type`           | N    | Enum `BaseLogType` — distingue Log de Evento           |
| `Caller`         | S    | FQDN da classe que gerou o log                         |
| `Template`       | S    | Template original: `"Login de {Email} via {Ip}"`       |
| `Message`        | S    | Mensagem renderizada com os valores reais              |
| `Properties`     | S    | JSON estruturado com todas as propriedades nomeadas    |
| `TTL`            | N    | Expiração automática — evita acúmulo infinito de dados |

### GSIs disponíveis para consulta eficiente

| GSI                | HASH KEY   | RANGE KEY   | Caso de uso                              |
|--------------------|------------|-------------|------------------------------------------|
| `GSI_EventSourcing`| `Type`     | `Timestamp` | Separar logs de eventos de domínio       |
| `GSI_LogLevel`     | `LogLevel` | `Timestamp` | Filtrar todos os erros ordenados por hora |
| `GSI_Caller`       | `Caller`   | `Timestamp` | Rastrear logs de um controller específico|

---

### Tratamento de Exceções

O sistema possui um overload dedicado para exceções que enriquece automaticamente os logs com campos estruturados — sem necessidade de serialização manual:

```csharp
_logger.LogError("Falha ao processar doação: {Email}", BaseLogType.LOG, ex, new { Email = email, Valor = valor });
```

O DynamoDB recebe automaticamente:

```json
{
  "ExceptionType": "System.InvalidOperationException",
  "ExceptionMsg":  "O valor deve ser maior que 0",
  "StackTrace":    "at Usuarios.Application...",
  "Email":         "user@test.com",
  "Valor":         0
}
```

---

### Benefícios

#### 🔍 Rastreabilidade Total
Qualquer requisição pode ser rastreada do início ao fim com um único `CorrelationId` — do controller ao banco de dados, passando por cache, mensageria e eventos de domínio. Isso reduz o tempo médio de diagnóstico de incidentes de horas para minutos.

#### 🏗️ Arquitetura Desacoplada
A interface `IBaseLoggerDbWriter` isola completamente o mecanismo de persistência. O time pode migrar de DynamoDB para qualquer outro storage sem tocar em nenhum serviço de aplicação — zero impacto no domínio.

#### 📊 Logs como Dados
Ao usar templates estruturados e armazenar propriedades como campos individuais no DynamoDB, os logs deixam de ser texto livre e se tornam **dados consultáveis**. É possível agregar, filtrar e criar alertas em cima de qualquer campo — algo impossível com logging tradicional.

#### 🛡️ Auditoria Completa
O `AuditInterceptor` captura automaticamente toda alteração no banco relacional (PostgreSQL) via Entity Framework e persiste o diff no DynamoDB — sem que os serviços de aplicação precisem saber que a auditoria existe. Cada entidade alterada gera um registro com o estado anterior e o novo estado.

#### ⏱️ Performance sem Impacto
A persistência no DynamoDB é **fire-and-forget** — o request do usuário não aguarda a gravação do log. Falhas na gravação são capturadas internamente e logadas no console sem propagar exceções para o fluxo principal.

#### 🔒 Segurança por Design
Dados sensíveis como senhas e CPFs **nunca chegam aos logs** — o CPF é automaticamente anonimizado (`256*****`) antes de qualquer serialização, e senhas são descartadas no nível do domain service, antes de qualquer chamada ao logger.

#### ♻️ Retenção Automática
O TTL nativo do DynamoDB elimina automaticamente logs antigos sem necessidade de jobs de limpeza ou manutenção manual — mantendo os custos de storage controlados em produção.

---
## ⚡ Sistema de Cache

### Visão Geral

O Conexão Solidária utiliza **Redis** como camada de cache distribuído, implementando um `CacheService` que centraliza as operações de leitura e escrita em memória. O design prioriza **resiliência**, **segurança** e **transparência** — o sistema continua funcionando mesmo quando o Redis está indisponível, e o código de aplicação não precisa saber dos detalhes do cache.

---

### Arquitetura

```
Application / Domain
      │
      ▼
ICacheService            ← contrato único exposto ao domínio
      │
      ▼
CacheService             ← implementação Redis (StackExchange.Redis)
      │
      ├── Redis (leitura/escrita de dados)
      └── Blacklist (tokens JWT revogados)
```

---

### Funcionalidades

#### 1. Cache de Entidades

Entidades são armazenadas em cache após a primeira busca no banco. Nas requisições seguintes, os dados são retornados diretamente do Redis — sem consultar o PostgreSQL. Caso os dados da entidade sejam modificados ou caso a entidade seja deletada, os dados são removidos do cache.
Para as campanhas, o cache possui TTL configuravel.  Campanhas ativas e não ativas, possuem ttls diferentes, pois a campanha ativa tem o seu total arrecadado constantemente modificado.  O TTL para campanhas ativas é de 1 minuto (o total arrecadado não tem impacto na operação se houver delay de 1 minuto), mas pode ser modificado via variavel de ambiente.:<br>
<br>
Cache:CampanhaAtivaTTLSeconds: "60"
Cache:CampanhaNaoAtivaTTLSeconds: "86400"
<br>

```
GET /api/v1/usuario?Email=user@test.com
  │
  ├── Cache HIT  → retorna em < 1ms  (Redis)
  └── Cache MISS → busca no PostgreSQL → armazena no Redis → retorna
```

A chave segue o padrão `entidade:{identificador}`, garantindo unicidade e facilidade de invalidação:

```csharp
var cacheKey = $"entidade:{identificador}";
var usuario  = await _cacheService.GetAsync<UsuarioDTO>(cacheKey);
```

#### 2. Blacklist de Tokens JWT

Quando um usuário faz logout ou tem a senha alterada, o token JWT atual é inserido na **blacklist do Redis** pelo tempo restante de validade. Mesmo que o token seja interceptado ou reutilizado, ele será rejeitado antes de chegar a qualquer endpoint.

```
POST /api/v1/auth/logout
  │
  └── Token → blacklist:{hash_do_token} → TTL = tempo restante do JWT
```

O middleware de autenticação verifica a blacklist em **cada requisição**, antes de qualquer processamento:

```
Request → [BlacklistMiddleware] → [AuthMiddleware] → Controller
               │
               └── Token na blacklist? → 401 Unauthorized (imediato)
```

---

### Estratégias de Cache

#### Cache-Aside (Lazy Loading)

O padrão adotado é **Cache-Aside**: a aplicação consulta o cache primeiro, e só acessa o banco se o dado não estiver disponível. Após buscar no banco, o dado é inserido no cache automaticamente.

```
┌─────────────┐    HIT     ┌───────┐
│  Application │ ◄──────── │ Redis │
│             │            └───────┘
│             │  MISS           │
│             │ ──────► ┌──────────────┐
│             │ ◄─────── │ PostgreSQL   │
│             │  SET     └──────────────┘
└─────────────┘ ──────► ┌───────┐
                         │ Redis │
                         └───────┘
```

#### Invalidação Proativa

Quando uma entidade é **alterada**, o cache é invalidado imediatamente — garantindo que a próxima requisição busque os dados atualizados do banco:

```csharp
// Exemplo: Após qualquer alteração no usuário:
var cacheKey = $"usuario:{command.Email}";
await _cacheService.RemoveAsync(cacheKey);
```

---

#### Resiliência

O `CacheService` foi projetado para **nunca derrubar a aplicação** em caso de falha do Redis. Todas as operações verificam a conectividade antes de executar e tratam exceções internamente:

```csharp
// O sistema continua funcionando — Redis indisponível não é erro fatal
if (!_redis.IsConnected)
{
    _logger.LogWarning("Redis não está conectado - tentativa de busca.", ...);
    return default; // retorna null → aplicação busca no banco
}
```

| Cenário                    | Comportamento                                        |
|----------------------------|------------------------------------------------------|
| Redis indisponível (leitura) | Retorna `null` → busca no banco                    |
| Redis indisponível (escrita) | Log de warning → operação ignorada silenciosamente |
| Redis indisponível (blacklist)| Retorna `true` (bloqueio por segurança)            |
| Erro de deserialização      | Log de erro → retorna `null` → busca no banco      |

> **Decisão de segurança:** quando o Redis está indisponível para verificar a blacklist, o sistema assume que o token **está** na blacklist (`return true`). Isso garante que tokens revogados nunca sejam aceitos mesmo em cenários de falha — priorizando segurança em detrimento de disponibilidade temporária.

---

### Configuração das Chaves
 
 Prefixo       | Exemplo                         | TTL       | Uso                              |
|---------------|---------------------------------|-----------|----------------------------------|
| `usuario:`    | `usuario:user@test.com`         | 30 min    | Dados do usuário autenticado     |
| `blacklist:`  | `blacklist:{jwt_token_hash}`    | Dinâmico* | Tokens JWT revogados             |
| `campanha:`  | `camnpanha:{801ac5fa-7399-4ee2-9f2d-1a111edb9ca4}`    | Dinâmico** | Dados da campanha            |

*O TTL da blacklist é calculado dinamicamente com base no tempo restante de expiração do JWT — o token expira do Redis exatamente quando expiraria naturalmente, sem deixar entradas desnecessárias.
** O TTL da campanha é configurado via environment variable. Como default, temos 1 minuto para campanhas ativas (para permitir atualização de valor arrecadado) e de 1 dia para campanhas não ativas (que podem ser consultadas pelo Gestor).

---

## Observabilidade

Todas as operações de cache são registradas no sistema de **logging estruturado**, incluindo hits, misses, erros e avisos de conectividade — visíveis nos dashboards do Grafana com filtro por `Caller = "CacheService"`:

```
[INFO]  Dado retornado do Redis.          { Key: "usuario:user@test.com" }
[INFO]  Dado gravado no Redis.            { Key: "usuario:user@test.com" }
[INFO]  Dado removido do Redis.           { Key: "usuario:user@test.com" }
[WARN]  Token na Blacklist detectado.     { Key: "blacklist:eyJhbG..." }
[WARN]  Redis não está conectado.         { Key: "usuario:user@test.com" }
[ERROR] Erro ao deserializar chave.       { Key: "usuario:user@test.com" }
```

---

## Benefícios

### ⚡ Performance
A camada de cache reduz drasticamente a latência em endpoints de leitura frequente. Dados de usuário — consultados em **cada requisição autenticada** para validação de perfil e permissões — são retornados em menos de 1ms pelo Redis, em vez dos 5-50ms de uma consulta ao PostgreSQL.

### 🔒 Segurança com Blacklist
A implementação de blacklist de tokens JWT resolve um problema clássico de autenticação stateless: **logout imediato e definitivo**. Em sistemas que usam apenas JWT sem blacklist, um token roubado permanece válido até expirar naturalmente. No Conexão Solidária, o logout invalida o token instantaneamente.

### 🛡️ Resiliência por Design
O Redis é tratado como **otimização**, não como dependência crítica. A aplicação degrada graciosamente quando o cache está indisponível — buscando os dados diretamente do banco — sem propagar erros para o usuário final.

### 💰 Redução de Custo
Em arquiteturas cloud com cobrança por operação de banco de dados (como RDS na AWS), a camada de cache reduz diretamente o número de consultas ao PostgreSQL — traduzindo em economia real de infraestrutura em produção.

### 🔄 Consistência Garantida
A invalidação proativa do cache em toda operação de escrita garante que os dados exibidos ao usuário **nunca sejam stale** após uma modificação — eliminando a classe de bugs de "dado desatualizado na tela".

### 📊 Rastreabilidade
Toda operação de cache é correlacionada ao `CorrelationId` da requisição original, permitindo reconstruir no Grafana exatamente quais dados foram lidos do cache e quais vieram do banco em qualquer trace específico.

---

##    Sistema de Busca Avançada - Elasticsearch

O sistema de busca de campanhas utiliza **Elasticsearch 8.11** para oferecer uma experiência de busca rápida, tolerante a erros de digitação e inteligente.

---

### Como funciona

Ao buscar por uma campanha, o sistema executa simultaneamente duas estratégias de busca sobre os campos `titulo`, `descricao`, `statusCampanha`, `dataInicio` e `dataFim`:

**1. Busca Fuzzy (MultiMatch — BestFields)**  
Tolera erros de digitação. Se o usuário digitar "Alimntos" em vez de "Alimentos", o sistema ainda encontra a campanha correta. O campo `titulo` tem peso 3x maior que os demais — campanhas com o termo no título aparecem primeiro.

**2. Busca por Prefixo (MultiMatch — BoolPrefix)**  
Busca enquanto o usuário digita. Ao digitar "Camp", já retorna campanhas que começam com esse termo, oferecendo uma experiência de busca em tempo real.

---

### Indexação

Cada campanha é indexada automaticamente no Elasticsearch quando:
- Uma campanha é **criada**
- Uma campanha é **alterada** (título, descrição, status, datas)
- Uma campanha é **cancelada** ou **concluída**

> O campo `valorArrecadado` **não é indexado** no Elasticsearch — ele é lido diretamente do banco de dados para garantir sempre o valor mais atualizado, evitando reindexação a cada doação recebida.

---

### Dados indexados por campanha

| Campo | Tipo | Descrição |
|---|---|---|
| `guid` | keyword | Identificador único |
| `titulo` | text | Nome da campanha (peso 3x na busca) |
| `descricao` | text | Descrição completa |
| `statusCampanha` | keyword | ATIVA, CANCELADA, CONCLUÍDA |
| `dataInicio` | text | Data de início da campanha |
| `dataFim` | text | Data de encerramento |

---

### Tolerância a erros

A busca utiliza `Fuzziness: AUTO`, que ajusta automaticamente a tolerância com base no tamanho do termo:

| Tamanho do termo | Erros tolerados |
|---|---|
| 1–2 caracteres | 0 (busca exata) |
| 3–5 caracteres | 1 erro |
| 6+ caracteres | 2 erros |

---

### Infraestrutura

- **Modo:** `single-node` (adequado para o ambiente atual)
- **Segurança:** `xpack.security` desabilitado na rede interna do cluster
- **Persistência:** volume dedicado via PVC no Kubernetes
- **Memória:** mínimo 1Gi, limite 1.5Gi (`ES_JAVA_OPTS: -Xms512m -Xmx512m`)
- **Health check:** `/\_cluster/health?wait_for_status=yellow`

--- 

### Benefícios

- **Velocidade** — respostas em milissegundos, independente do volume de campanhas cadastradas, sem impacto no banco de dados principal

- **Tolerância a erros de digitação** — o usuário pode errar a escrita e ainda encontrar a campanha correta, reduzindo a fricção na experiência de busca

- **Busca em tempo real** — resultados aparecem enquanto o usuário digita, sem necessidade de pressionar "buscar"

- **Relevância inteligente** — campanhas com o termo buscado no título aparecem antes das que têm o termo apenas na descrição, entregando os resultados mais relevantes primeiro

- **Escalabilidade** — o Elasticsearch escala horizontalmente, suportando crescimento no volume de campanhas e de usuários simultâneos sem degradação de performance

- **Desacoplamento** — a busca não concorre com as operações transacionais do banco de dados PostgreSQL, garantindo que buscas intensas não impactem o cadastro de campanhas e doações

- **Índice sempre atualizado** — qualquer alteração em uma campanha é refletida automaticamente no índice, garantindo que os resultados de busca estejam sempre sincronizados com o estado real do sistema

---

### Observabilidade com Grafana - Inserir em grafana

Os logs estruturados são visualizados em tempo real no **Grafana**, com dashboards dedicados para:

- **Audit Log** (`cs-audit-log`) — todas as operações de criação, alteração e exclusão de entidades, com diff de campos modificados
- **Application Logs** (`cs-app-log`) — logs de aplicação com filtros por nível, caller e **pesquisa por CorrelationId** para rastrear traces completos

O campo `Properties` em JSON permite ao Grafana parsear e filtrar por qualquer propriedade nomeada:

```logql
{app="cs-app-logs"} | json | email = "user@test.com"
{app="cs-app-logs", level="Error"} | json | caller =~ "Auth.*"
```

---
