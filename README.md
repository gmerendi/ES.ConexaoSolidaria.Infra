# ES.ConexaoSolidaria.Infra

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
---


## Sistema de Logging Estruturado

### Visão Geral

O sistema de logging do Conexão Solidária foi desenvolvido com uma arquitetura própria de **logging estruturado**, inspirada no Serilog, porém completamente customizada para as necessidades da plataforma. O design prioriza **observabilidade**, **rastreabilidade de ponta a ponta** e **flexibilidade de storage** — sem depender de bibliotecas de terceiros para a lógica central.  Logs podem ser gravados em base de dados caso a opção CustomLogging:SendLogToDB seja configurada para "True". Logs relativos a eventos, são sempre armazenados, independentemente dessa configuração, para que exista um Event Sourcing.

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
