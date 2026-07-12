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

| `conexao-solidaria-infra` | *(este repositório)* K8s, Helm, docker-compose, documentação |

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

## Arquitetura

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

## Funcionalidades

### 1. Cache de Entidades

Usuários autenticados são armazenados em cache após a primeira busca no banco. Nas requisições seguintes, os dados são retornados diretamente do Redis — sem consultar o PostgreSQL. Caso os dados do usuario sejam modificados ou caso o usuario efetue logoff, os dados são removidos do cache, sendo inseridos novamente no próximo logon ou busca no banco.

```
GET /api/v1/usuario?Email=user@test.com
  │
  ├── Cache HIT  → retorna em < 1ms  (Redis)
  └── Cache MISS → busca no PostgreSQL → armazena no Redis → retorna
```

A chave segue o padrão `usuario:{email}`, garantindo unicidade e facilidade de invalidação:

```csharp
var cacheKey = $"usuario:{email}";
var usuario  = await _cacheService.GetAsync<UsuarioDTO>(cacheKey);
```

### 2. Blacklist de Tokens JWT

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

## Estratégias de Cache

### Cache-Aside (Lazy Loading)

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

### Invalidação Proativa

Quando um usuário é **alterado, suspenso, ativado ou removido**, o cache é invalidado imediatamente — garantindo que a próxima requisição busque os dados atualizados do banco:

```csharp
// Após qualquer alteração no usuário:
var cacheKey = $"usuario:{command.Email}";
await _cacheService.RemoveAsync(cacheKey);
```

---

## Resiliência

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

## Configuração das Chaves

| Prefixo       | Exemplo                         | TTL       | Uso                              |
|---------------|---------------------------------|-----------|----------------------------------|
| `usuario:`    | `usuario:user@test.com`         | 30 min    | Dados do usuário autenticado     |
| `blacklist:`  | `blacklist:{jwt_token_hash}`    | Dinâmico* | Tokens JWT revogados             |

*O TTL da blacklist é calculado dinamicamente com base no tempo restante de expiração do JWT — o token expira do Redis exatamente quando expiraria naturalmente, sem deixar entradas desnecessárias.

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
