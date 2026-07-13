# Architecture Decision Records — Conexão Solidária

Registro das decisões arquiteturais tomadas durante a fase de planejamento da plataforma Conexão Solidária. Cada ADR documenta o contexto, a justificativa técnica e as alternativas consideradas antes da decisão final.

---

## ADR-001 — Banco de Dados Relacional: PostgreSQL

### Descrição

Adoção do **PostgreSQL 15** como banco de dados relacional primário para todos os microsserviços transacionais da plataforma — Usuários, Campanhas e Doações. Cada microsserviço possui seu próprio schema isolado dentro do mesmo cluster, seguindo o padrão de **Database-per-Service** com shared infrastructure.

### Justificativa

A natureza dos dados da plataforma — usuários, campanhas com ciclo de vida bem definido e doações com rastreabilidade fiscal — exige **ACID compliance** estrita e suporte robusto a transações distribuídas. O PostgreSQL se destacou pela combinação de maturidade, extensibilidade e conformidade com o padrão SQL:

- **Transações ACID**: a operação de persistir uma doação e atualizar o `valor_arrecadado` da campanha é executada em uma única transação atômica (`BEGIN → INSERT doacao + UPDATE campanha → COMMIT`), garantindo que não haja estado inconsistente mesmo em cenários de falha parcial com múltiplos pods no Kubernetes.

- **UPDATE atômico como mecanismo anti-race condition**: em vez de um padrão read-modify-write sujeito a race conditions em ambientes com N replicas, utilizamos `UPDATE campanhas SET valor_arrecadado = valor_arrecadado + @valor WHERE guid = @guid` — operação serializada nativamente pelo lock de linha do PostgreSQL, eliminando a necessidade de otimistic concurrency ou distributed locks.

- **Integração nativa com EF Core via Npgsql**: o driver Npgsql oferece suporte a tipos nativos do PostgreSQL (UUID, JSONB, `timestamp with time zone`), migrations automáticas e interceptors — base para o `AuditInterceptor` que captura o diff de entidades sem acoplamento ao código de negócio.

- **Schema isolation**: cada microsserviço opera em seu próprio schema (`identidade`, `operacao`), garantindo isolamento lógico de dados sem a complexidade operacional de múltiplos clusters de banco.

- **Conformidade com LGPD e legislação fiscal**: o modelo relacional permite deleção física de usuários (Art. 18, VI da LGPD) enquanto mantém os registros de doações — necessário para conformidade com a Lei nº 9.532/1997 e o Código Civil Art. 1.194 (guarda de documentos fiscais por 10 anos).

### Alternativas Consideradas

| Alternativa | Razão da não adoção |
|---|---|
| **MySQL / MariaDB** | Menor suporte a tipos avançados, semântica de transações ligeiramente diferente e ecossistema .NET menos maduro que o Npgsql |
| **SQL Server** | Custo de licenciamento incompatível com o modelo de ONG; lock-in de fornecedor em ambiente AWS |
| **MongoDB** | Modelo de dados de campanhas e doações é inerentemente relacional — referências entre entidades e integridade referencial são requisitos, não opcionais |
| **CockroachDB** | Distributed SQL com latência adicional desnecessária para o volume atual; complexidade operacional não justificada |

---

## ADR-002 — Cache: Redis

### Descrição

O uso de cache é uma das estratégias mais eficazes para melhorar a performance, a escalabilidade e a eficiência de uma aplicação. Em termos simples, 
o cache guarda dados temporários que são frequentemente acessados em um local de leitura ultrarrápida (geralmente na memória RAM), evitando que a aplicação 
precise refazer um trabalho pesado toda vez que alguém pede a mesma informação.

### Justificativa
Adotamos o **Redis** como camada de cache distribuído e store de sessão da plataforma, com dois casos de uso primários: 
- cache de entidades com TTL configurável
- **Token Blacklist** para invalidação imediata de JWTs no logout.
O JWT é, por natureza, stateless — uma vez emitido, permanece válido até expirar. Isso cria um problema fundamental de segurança: o logout não invalida o token.
A adoção do Redis como **Token Blacklist** resolve esse problema de forma elegante e performática.<br><br>

Com isso temos os seguintes benefícios:

- **Latência Sub-milissegundo**: operações `GET/SET` no Redis têm latência em microssegundos,
- tornando a checagem de entidades ou blacklist imperceptível no pipeline de cada requisição.

- **TTL nativo por chave**: ao revogar um token, calculamos o tempo restante de vida (`GetTokenTimeToExpire`) e definimos o TTL da chave Redis exatamente com esse valor. O token expira do Redis no mesmo instante em que expiraria naturalmente — zero custo de manutenção, zero acúmulo de dados obsoletos.

- **Redução de Carga no Banco de Dados**: O banco de dados costuma ser o principal gargalo (gargalo de garrafa) de aplicações que crescem. Muitas requisições idênticas vindas de milhares de usuários podem derrubar o banco. O cache absorve a maior parte dessas leituras repetitivas.

- **Cache de entidades com TTL estratificado**: campanhas ativas são cacheadas com TTL de 60 segundos (configurável via variável de ambiente para tuning em produção), enquanto campanhas concluídas — que nunca mais mudarão — recebem TTL de 86.400 segundos (1 dia). Isso implementa o padrão **Cache-Aside** com invalidação diferenciada por estado da entidade.

- **Escalabilidade horizontal**: como o Redis é um serviço centralizado (ElastiCache em produção), múltiplas réplicas de pods no Kubernetes compartilham o mesmo estado de blacklist e cache — sem inconsistências de sessão entre instâncias.

- **Integração com StackExchange.Redis**: client battle-tested, com suporte a connection pooling, retry policies e operações pipeline que minimizam round-trips ao servidor.

### Alternativas Consideradas

| Alternativa | Razão da não adoção |
|---|---|
| **Memcached** | Não suporta TTL por chave de forma nativa para todos os tipos de dados; ausência de estruturas de dados avançadas; sem persistência |
| **In-Memory Cache (.NET IMemoryCache)** | Cache local por pod — inviável em ambiente Kubernetes com múltiplas réplicas, pois cada pod teria sua própria blacklist isolada, permitindo que tokens revogados continuassem válidos em outros pods |
| **Hazelcast** | Complexidade operacional desproporcional ao problema; custo de licenciamento para features avançadas |
| **Sessão em banco relacional** | Introduz latência de I/O de disco em operações que devem ser sub-milissegundo; o banco relacional não deve ser usado como store de sessão |

---

## ADR-003 — Audit Trail e Logs: DynamoDB

### Descrição

Adoção do **AWS DynamoDB** como store de dois tipos de registros: **Audit Log** (`cs-audit-log`) — trilha de auditoria de todas as operações no banco relacional — e **Application Log** (`cs-app-logs`) — logs operacionais e eventos de negócio com suporte a tracing distribuído via `CorrelationId`.

### Justificativa

Logs e registros de auditoria possuem um padrão de acesso radicalmente diferente dos dados transacionais: são write-heavy, append-only, têm volume crescente e previsível, e raramente são consultados após o período de retenção. Esse perfil descarta bancos relacionais como opção viável:

- **Modelo de acesso otimizado para append-only**: o DynamoDB é projetado para workloads de alta taxa de escrita com baixíssima latência. O `AuditInterceptor` persiste registros de forma assíncrona (`Task.Run`) sem bloquear o fluxo principal da requisição — o DynamoDB absorve picos de escrita sem degradar o banco relacional primário.

- **TTL nativo por item**: logs operacionais (`Type = LOG`) recebem TTL de 30 dias diretamente no item. O DynamoDB deleta esses registros automaticamente após o período de retenção — sem jobs de limpeza, sem custo adicional de operação. Eventos de negócio (`Type = EVENT`) não recebem TTL, sendo retidos indefinidamente para fins de Event Sourcing e compliance.

- **Escalabilidade serverless com PAY_PER_REQUEST**: o modelo de billing baseado em requisições elimina o provisionamento manual de throughput. Em momentos de baixo tráfego, o custo é praticamente zero; em picos, o DynamoDB escala automaticamente sem intervenção.

- **GSI para padrões de consulta específicos**: o `ResourceIdIndex` (GSI sobre `ResourceId`) permite recuperar todo o histórico de alterações de uma entidade específica pelo GUID, sem full scan — padrão fundamental para investigações de auditoria e compliance com LGPD (Art. 37).

- **Separação de concerns de armazenamento**: ao isolar logs e auditoria em um banco NoSQL separado, protegemos o PostgreSQL de picos de I/O causados por operações de logging intensivo — um princípio fundamental de design resiliente.

### Alternativas Consideradas

| Alternativa | Razão da não adoção |
|---|---|
| **PostgreSQL (mesma instância)** | Contamina o banco transacional com volume de logs; crescimento ilimitado sem TTL nativo; degradação de performance em queries transacionais |
| **Elasticsearch** | Custo operacional elevado para logs; já utilizado para busca full-text de campanhas — separação de responsabilidades |
| **CloudWatch Logs** | Custo por GB ingerido torna-se proibitivo em escala; menos flexibilidade para estruturar os documentos de auditoria com GSIs customizados |
| **Loki (Grafana)** | Adequado para logs de infraestrutura, não para audit trail estruturado com modelo de dados específico e consultas por entidade |

---

## ADR-004 — Mensageria: RabbitMQ + MassTransit / Amazon SQS

### Descrição

Adoção de uma **arquitetura event-driven** com dois brokers intercambiáveis via abstração MassTransit: **RabbitMQ** no ambiente local e **Amazon SQS** em LAB/produção. Os eventos de domínio (`DonationCreatedEvent`, `DonationProcessedEvent`, `UserCreatedEvent`) trafegam de forma assíncrona entre microsserviços, garantindo desacoplamento temporal e espacial.

### Justificativa

O fluxo de doação é o processo mais crítico da plataforma e não pode ser executado de forma síncrona no ciclo de vida de uma requisição HTTP. Persistir a doação, atualizar o valor arrecadado da campanha, enviar e-mail de confirmação e publicar eventos para outros sistemas em uma única transação HTTP resultaria em alta latência, acoplamento forte e baixa resiliência:

- **Desacoplamento temporal**: o microsserviço de Campanhas publica `DonationCreatedEvent` e retorna `201 Created` imediatamente. O processamento — persistência, atualização atômica da campanha e envio de e-mail — ocorre de forma assíncrona no Worker de Doações. O usuário recebe confirmação sem aguardar a cadeia completa de processamento.

- **MassTransit como abstraction layer**: a interface `IPublishEndpoint` e `IConsumer<T>` são agnósticas ao transporte subjacente. A troca entre RabbitMQ e SQS é feita exclusivamente na camada de configuração (`Application__Type`), sem alterar uma linha de código de negócio — eliminando lock-in de broker.

- **InMemoryOutbox pattern**: o MassTransit `UseInMemoryOutbox()` garante que mensagens publicadas dentro do handler só são enviadas ao broker após o commit da transação principal. Se a transação falhar, nenhum evento órfão é publicado — prevenindo inconsistências entre o estado do banco e os eventos em fila.

- **Retry com backoff exponencial e Dead Letter Queue**: a política de retry (1s → 5s → 30s no MassTransit, mais 3 tentativas a cada 5s na fila SQS) garante que falhas transitórias não resultem em perda de mensagens. Após esgotar as tentativas, a mensagem vai para a DLQ para análise manual — zero loss em qualquer cenário de falha.

- **Idempotência via CorrelationId**: o `CorrelationId` gerado no handler de Campanhas é propagado em todos os eventos derivados. O Consumer verifica a existência do `CorrelationId` antes de processar — `ObterPorCorrelationIdAsync` — garantindo que retries do broker após falha de ACK nunca gerem doações duplicadas (exatamente-uma-vez semântica por design de domínio).

- **Escalabilidade independente**: o Worker de Doações pode escalar horizontalmente no Kubernetes de forma independente do microsserviço de Campanhas, sem que nenhuma coordenação explícita seja necessária — o RabbitMQ/SQS distribui as mensagens automaticamente entre as instâncias.

### Alternativas Consideradas

| Alternativa | Razão da não adoção |
|---|---|
| **Apache Kafka** | Overhead operacional desproporcional ao volume atual; modelo de consumer groups com offset management adiciona complexidade sem benefício para este caso de uso; custo de provisionamento em AWS (MSK) |
| **Comunicação síncrona (HTTP/gRPC)** | Acoplamento temporal e espacial entre serviços; falha em qualquer elo da cadeia propaga-se para o usuário final; impossível escalar componentes de forma independente |
| **SNS (fanout puro)** | Adequado para notificações broadcast, não para processamento transacional com garantias de entrega e retry |

---

## ADR-005 — API Gateway: YARP / AWS API Gateway v2

### Descrição

Adoção de uma estratégia de **dual-gateway**: **YARP (Yet Another Reverse Proxy)** para o ambiente local, rodando como microsserviço .NET no cluster Kubernetes, e **AWS API Gateway v2 (HTTP API)** em produção, integrado ao EKS via **VPC Link** sobre **Network Load Balancer**.

### Justificativa

O API Gateway é o único ponto de entrada externo da plataforma — todos os microsserviços são expostos como `ClusterIP` e inacessíveis publicamente. Essa decisão implementa o padrão **Backend for Frontend (BFF)** com responsabilidades claras de borda:

- **Defense in Depth**: a validação do JWT ocorre em duas camadas independentes — no gateway e em cada microsserviço individualmente. Se uma requisição conseguir bypassar o gateway (via acesso direto ao ClusterIP interno), ainda encontrará o `[Authorize]` do microsserviço como segunda linha de defesa. Segurança não depende de um único ponto de falha.

- **Rate Limiting com Sliding Window**: o `RateLimitingExtension` implementa dois limitadores: `default` (proteção geral configurável via env var) e `login` (10 req/min — proteção específica contra brute force de credenciais). O Sliding Window com 6 segmentos distribui o limite uniformemente dentro da janela, evitando o comportamento de burst do Fixed Window.

- **YARP para desenvolvimento local**: o YARP oferece roteamento declarativo via `appsettings.json`, load balancing nativo entre pods (`UseLoadBalancing()`), Swagger proxy dinâmico com substituição de `servers` URL em runtime, e pipeline de middlewares customizável — tudo em um único pod .NET sem infraestrutura adicional.

- **AWS API Gateway v2 para produção**: em produção, o gateway gerenciado elimina a operação de um pod adicional no EKS, oferece throttling nativo por stage, logs estruturados no CloudWatch e alta disponibilidade gerenciada pela AWS. O VPC Link garante que o tráfego entre o API Gateway e o EKS nunca sai da rede privada da AWS.

- **CORS centralizado**: o CORS é configurado exclusivamente no gateway, com `WithOrigins(frontendUrl)` — microsserviços não precisam configurar CORS individualmente, simplificando a manutenção e garantindo consistência de política.

- **Swagger aggregation**: o gateway agrega os `swagger.json` de todos os microsserviços em uma única interface, com substituição dinâmica do campo `servers` pela URL do gateway em runtime — sem hardcode de URLs, funcionando corretamente em qualquer ambiente.

### Alternativas Consideradas

| Alternativa | Razão da não adoção |
|---|---|
| **Kong Gateway** | Complexidade operacional de um cluster Cassandra/PostgreSQL adicional para persistência de configuração; plugin ecosystem pago para features avançadas |
| **AWS API Gateway v1 (REST API)** | HTTP API v2 oferece menor latência, menor custo e CORS nativo; REST API v1 é considerada legada para novos projetos |
| **Ocelot** | YARP foi construído pela própria Microsoft utilizando a infraestrutura de rede ultra-otimizada do ASP.NET Core (como o servidor Kestrel e System.IO.Pipelines). Benchmarks mostram que o YARP entrega maior vazão de requisições por segundo (throughput) e menor latência, consumindo CPU de forma mais eficiente que o Ocelot. |
| **KrakenD** | KrakenD funciona como uma caixa preta (você o roda em um container separado e configura via JSON/YAML). Com o YARP, seu API Gateway é um projeto .NET. Você pode usar suas bibliotecas de logs, Nugets corporativos, mecanismos de autenticação customizados e ferramentas de monitoramento que seu time já domina. |

---

## ADR-006 — Busca Full-Text: Elasticsearch

### Descrição

Adoção do **Elasticsearch 8.11** como motor de busca avançada para campanhas, com índice dedicado alimentado assincronamente pela camada de Application. 
A tolerância a falhas (fuziness) e relevância na busca otimizam o processo de procura das campanhas.

### Justificativa

Busca textual em banco relacional (PostgreSQL `ILIKE '%termo%'`) resulta em full table scan, degrada sob carga e não oferece relevância semântica. A separação do concern de busca em um motor especializado segue o princípio de **Polyglot Persistence** — cada tipo de dado no store mais adequado para seu padrão de acesso:

- **Relevância com boosting por campo**: o campo `titulo` recebe peso 3x (`titulo^3`) em relação a `descricao` e demais campos — campanhas com o termo buscado no título aparecem primeiro, sem necessidade de ordenação manual. Esse comportamento é inerente ao modelo TF-IDF/BM25 do Lucene, motor subjacente ao Elasticsearch.

- **Dual query strategy (BestFields + BoolPrefix)**: a query `Bool.Should` combina simultaneamente `MultiMatch.BestFields` com `Fuzziness: AUTO` (tolerância a erros de digitação) e `MultiMatch.BoolPrefix` (busca enquanto o usuário digita). O resultado é uma experiência de busca que funciona tanto para termos completos com erros quanto para prefixos parciais — sem múltiplas chamadas ao servidor.

- **Fuzziness AUTO calibrada por tamanho**: termos de 1-2 caracteres exigem match exato; 3-5 caracteres toleram 1 erro; 6+ caracteres toleram 2 erros. Esse comportamento automático elimina false positives em termos curtos e garante resiliência em termos longos sem configuração manual.

- **Desacoplamento do fluxo de doação**: a decisão de não indexar `valorArrecadado` é intencional. A cada doação processada, atualizar o Elasticsearch geraria uma operação de reindexação desnecessária em um campo de alta volatilidade. O valor é servido com TTL de 60s via Redis, que se auto-invalida — eliminando escrita no Elasticsearch a cada doação sem sacrificar a consistência.

- **Índice atualizado apenas em mudanças estruturais**: o Elasticsearch é atualizado exclusivamente quando a campanha sofre alterações semânticas (criação, edição, cancelamento, conclusão) — eventos de baixa frequência. Isso mantém o índice consistente sem overhead de reindexação constante.

### Alternativas Consideradas

| Alternativa | Razão da não adoção |
|---|---|
| **PostgreSQL Full-Text Search (pg_trgm / tsvector)** | Full table scan em queries LIKE; ausência de relevância semântica nativa; degradação de performance sob carga sem índice GIN dedicado; não oferece BoolPrefix para busca em tempo real |
| **Algolia** | Custo por operação incompatível com modelo de ONG; dependência de serviço externo pago; dados de campanhas saindo da infraestrutura controlada |
| **OpenSearch** | Fork compatível com Elasticsearch, mas o client oficial `Elastic.Clients.Elasticsearch` não oferece suporte nativo, exigindo client alternativo |

---

## ADR-007 — Observabilidade: Prometheus + Grafana + Zabbix

### Descrição

Adoção de uma stack de observabilidade em três camadas complementares: **Prometheus** para coleta de métricas de aplicação (business metrics + runtime .NET), **Grafana** como plataforma unificada de visualização com múltiplos datasources, e **Zabbix** para monitoramento de infraestrutura do servidor host. Todos os dashboards são provisionados como código via ConfigMaps Kubernetes.

### Justificativa

Observabilidade não é um afterthought — é um requisito arquitetural de primeira classe. A distinção entre métricas de negócio, métricas de runtime e métricas de infraestrutura exige ferramentas especializadas para cada camada:

- **prometheus-net com métricas de negócio customizadas**: além das métricas de runtime .NET (GC, threads, memória, CPU), cada microsserviço expõe Counters e Histogramas de domínio (`usuarios_login_total`, `campanhas_criadas_total`, `donation_worker_doacoes_total`). Isso permite correlacionar comportamento técnico com comportamento de negócio — um pico de CPU coincidindo com um aumento em `campanha_intencoes_total` indica crescimento orgânico, não incidente.

- **Histograma de latência com percentis**: o `http_request_duration_seconds` com buckets calibrados para APIs REST (5ms a 5s) e labels por `method`, `route` e `status_code` permite calcular p90/p95/p99 por rota específica no Grafana. A média oculta outliers — os percentis revelam a experiência real do usuário nos piores casos.

- **Grafana como single pane of glass**: a integração de três datasources distintos (Prometheus, Zabbix, DynamoDB-PG Proxy) em uma única interface elimina a necessidade de alternar entre ferramentas durante investigações de incidentes. Um analista consegue correlacionar um pico de erros (Prometheus) com uma anomalia de memória (Zabbix) e rastrear o trace completo pelo CorrelationId (DynamoDB-PG) sem sair do Grafana.

- **Dashboards como código**: todos os dashboards são definidos em JSON e provisionados via ConfigMaps Kubernetes. Isso garante que o ambiente de observabilidade é versionado, reproduzível e aplicado automaticamente no deploy — eliminando o risco de dashboards desatualizados em relação ao código.

- **Zabbix para infraestrutura**: métricas de kernel (CPU steal, iowait, swap usage, network throughput) que o Prometheus não coleta sem exporters adicionais são capturadas nativamente pelo Zabbix Agent. Um Job Kubernetes de inicialização configura automaticamente o host e o dashboard via API JSON-RPC — zero intervenção manual.

### Alternativas Consideradas

| Alternativa | Razão da não adoção |
|---|---|
| **Datadog** | Custo por host proibitivo para o orçamento de uma ONG; dependência de agente proprietário; dados de observabilidade em infraestrutura de terceiro |
| **New Relic** | Mesmo problema de custo e lock-in do Datadog; modelo de ingestão de dados cobrado por GB |

---

## ADR-008 — Frontend Web: Blazor WebAssembly

### Descrição

Adoção do **Blazor WebAssembly (.NET 8)** com **MudBlazor** como framework de frontend, resultando em uma SPA (Single Page Application) que executa inteiramente no browser via WebAssembly, com estado de autenticação gerenciado via JWT no localStorage e comunicação exclusiva com o API Gateway.

### Justificativa

A escolha do frontend é estratégica para um time com expertise consolidada em .NET — Blazor WebAssembly elimina a necessidade de dominar um segundo ecossistema (JavaScript/TypeScript) sem abrir mão de uma experiência de usuário moderna e responsiva:

- **Unificação do stack tecnológico**: todo o código da plataforma — microsserviços, workers, gateway e frontend — é escrito em C#. Isso elimina o context-switching entre paradigmas, permite compartilhar modelos de domínio (records de request/response), e reduz o risco de inconsistências semânticas entre frontend e backend.

- **JwtAuthStateProvider com verificação de expiração client-side**: ao invés de depender de cookies gerenciados pelo servidor ou de chamadas periódicas para verificar autenticidade, o `JwtAuthStateProvider` lê o JWT do localStorage, extrai a claim `exp` diretamente via `JwtSecurityTokenHandler.ReadJwtToken()` e verifica a expiração localmente — sem round-trip ao servidor. Tokens expirados são limpos do localStorage automaticamente, mantendo o estado de UI consistente com o estado de autenticação.

- **MudBlazor com Material Design**: biblioteca de componentes production-ready com grid responsivo, formulários com validação reativa, progress bars para o termômetro de doações e dialogs — sem necessidade de criar componentes do zero. A curva de aprendizado para desenvolvedores .NET é mínima comparada a React/Vue com bibliotecas de UI externas.

- **Deploy como assets estáticos**: o `dotnet publish` gera arquivos estáticos servidos pelo Nginx Alpine — sem servidor de aplicação, sem processo Node.js, sem SSR. O Dockerfile multistage resulta em uma imagem de ~50MB que serve o frontend com Nginx e substitui `${GATEWAY_URL}` em runtime via `entrypoint.sh`, permitindo a mesma imagem em qualquer ambiente.

- **Roteamento client-side com proteção por perfil**: `@attribute [Authorize(Roles = "GESTOR_ONG")]` protege rotas administrativas diretamente na declaração do componente Razor — sem lógica de guarda customizada. O `RedirectToLogin` intercepta automaticamente tentativas de acesso não autorizado.

### Alternativas Consideradas

| Alternativa | Razão da não adoção |
|---|---|
| **React + TypeScript** | Exige domínio de um segundo ecossistema; state management (Redux/Zustand) adiciona camadas de complexidade; build toolchain (Vite/Webpack) com dependências npm frágeis |
| **Next.js** | SSR adequado para SEO de campanhas públicas, mas introduz um servidor Node.js adicional na infraestrutura; complexidade de hidratação; time sem experiência em React |
| **Blazor Server** | Depende de conexão WebSocket persistente (SignalR) — inviável em cenários de conectividade instável; não escala horizontalmente sem sticky sessions ou backplane Redis |
| **Angular** | Curva de aprendizado elevada; TypeScript obrigatório; ecosystem e breaking changes frequentes entre versões major |
| **Vue.js** | Sem vantagem sobre React para o perfil do time; mesmo problema de ecossistema JavaScript |

---

## ADR-009 — Comunicação DynamoDB → Grafana: DynamoDB PG Proxy

### Descrição

Implementação de um **proxy TCP custom em Python** que emula o protocolo wire do PostgreSQL v3 e traduz queries SQL recebidas em operações de `Scan` no DynamoDB, permitindo que o Grafana consulte logs e auditoria do DynamoDB usando o **datasource PostgreSQL nativo** — sem plugins pagos ou drivers proprietários.

### Justificativa

O Grafana suporta DynamoDB exclusivamente via plugin `grafana-amazonwebservices-datasource`, disponível apenas no plano Enterprise (pago). As tabelas `cs-app-logs` e `cs-audit-log` no DynamoDB precisam ser consultáveis via Grafana para a stack de observabilidade — criar uma solução alternativa foi a decisão arquitetural mais pragmática:

- **Implementação do PostgreSQL Wire Protocol v3**: o proxy implementa manualmente as mensagens do protocolo binário do PostgreSQL (`AuthenticationOk`, `RowDescription`, `DataRow`, `CommandComplete`, `ReadyForQuery`) usando `asyncio` e `struct.pack`. Para o Grafana, o proxy é indistinguível de um banco PostgreSQL real — sem plugin, sem configuração especial, sem custo adicional.

- **SQL Parser customizado para DynamoDB**: o parser reconhece `SELECT`, `SELECT DISTINCT`, `COUNT(*)`, operadores `=`, `>=`, `<=`, `LIKE` (traduzido para `contains()`) e `BETWEEN` (traduzido para `>=` e `<=` no FilterExpression). Macros do Grafana (`$__timeFilter`, `$__timeGroup`) são substituídas por `1=1` — ignoradas graciosamente sem erros que impediriam a execução da query.

- **Paginação automática do DynamoDB Scan**: o DynamoDB retorna no máximo 1MB por operação de Scan. O proxy pagina automaticamente via `LastEvaluatedKey` até consumir todos os resultados, retornando o dataset completo ao Grafana sem que o usuário perceba as limitações da API DynamoDB.

- **Remoção de prefixos temporais transparente**: o campo `SK` da tabela `cs-audit-log` armazena o timestamp com prefixo `TS#` (ex: `TS#2026-06-25T14:00:00Z`) para garantir ordenação lexicográfica correta no DynamoDB. O proxy remove o prefixo automaticamente ao retornar os dados ao Grafana, expondo um timestamp ISO 8601 limpo sem que o dashboard precise tratar esse detalhe de implementação.

- **Zero dependências além do boto3**: o proxy é ~450 linhas de Python puro com uma única dependência (`boto3==1.34.0`). A imagem Docker final tem ~50MB (Python 3.12 Alpine + boto3) — footprint mínimo, sem frameworks web, sem ORMs, sem camadas desnecessárias.

- **Multi-ambiente com configuração por variável de ambiente**: `DYNAMO_ENDPOINT` vazio aponta para o DynamoDB real da AWS; preenchido, aponta para o DynamoDB Local no docker-compose. A mesma imagem funciona em qualquer ambiente sem rebuild.

### Alternativas Consideradas

| Alternativa | Razão da não adoção |
|---|---|
| **Plugin Enterprise do Grafana** | Custo de licenciamento incompatível com orçamento de ONG; lock-in de vendor; todas as alternativas foram exploradas antes de recorrer a solução proprietária |
| **AWS Athena como intermediário** | Latência de consultas Athena (segundos) incompatível com dashboards interativos do Grafana; custo por consulta em escala |
| **Lambda + API REST** | Exigiria um datasource customizado no Grafana ou o plugin JSON Datasource — ambos com limitações de query language e sem suporte a variáveis de template do Grafana |
| **Migrar logs para PostgreSQL** | Contradiz ADR-003 — logs e auditoria no PostgreSQL degradariam o banco transacional primário |
| **Duplicar dados no PostgreSQL para Grafana** | Dual-write introduz complexidade de sincronização e risco de inconsistência; custo de storage duplicado |
