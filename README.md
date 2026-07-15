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
- [Stack Tecnológica](#stack-tecnologica)
- [Endpoints](#endpoints)
- [Features](#features)
- [Testes Unitarios](#testes-unitarios)
- [CI/CD - Github Actions](#github-actions)
- [Documentaçao](#documentaçao)
- [Como rodar](./docs/ComoRodar.md)

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

<br><br>
Crie as pastas abaixo para clonar os repositórios:<br>
C:\FIAP\ <br>
|---- ES.ConexaoSolidaria.Usuarios <br>
|---- ES.ConexaoSolidaria.Campanhas <br>
|---- ES.ConexaoSolidaria.Infra <br>
|---- ES.ConexaoSolidaria.Notificacoes <br>
|---- ES.ConexaoSolidaria.Worker <br>
|---- ES.ConexaoSolidaria.Gateway <br>
|---- ES.ConexaoSolidaria.Frontend <br>
|---- ES.ConexaoSolidaria.DynamoPgProxy <br>

<br>

---

## Arquitetura


---

## Stack Tecnologica

### Linguagens

| Linguagem | Versão | Uso |
|---|---|---|
| **C#** | .NET 8 | Microsserviços, Workers, Gateway, Frontend |
| **Python** | 3.12 | DynamoDB PostgreSQL Proxy |
| **HCL** | Terraform ~5.0 | Provisionamento de infraestrutura AWS |
| **YAML** | — | Manifests Kubernetes, GitHub Actions |

---

### Backend — Microsserviços

| Tecnologia | Versão | Uso |
|---|---|---|
| **ASP.NET Core** | 8.0 | Web API (Usuários, Campanhas) |
| **Entity Framework Core** | 8.0.0 | ORM — PostgreSQL |
| **Npgsql EF Core** | 8.0.0 | Driver PostgreSQL para EF Core |
| **MassTransit** | 8.0.0 | Abstração de mensageria (RabbitMQ / SQS) |
| **MassTransit.RabbitMQ** | 8.0.0 | Transporte RabbitMQ |
| **MassTransit.AmazonSQS** | 8.0.0 | Transporte Amazon SQS |
| **Elastic.Clients.Elasticsearch** | 8.11.0 | Client Elasticsearch |
| **StackExchange.Redis** | 2.13.17 | Client Redis |
| **BCrypt.Net-Next** | 4.2.0 | Hash de senhas |
| **Swashbuckle.AspNetCore** | 6.6.2 | Geração do Swagger/OpenAPI |
| **prometheus-net** | 8.2.1 | Exposição de métricas Prometheus |
| **prometheus-net.AspNetCore** | 8.2.1 | Middleware de métricas HTTP |
| **AWSSDK.DynamoDBv2** | 4.0.19 | Client DynamoDB (logs e auditoria) |
| **AWSSDK.SQS** | 4.0.3.8 | Client SQS |
| **AWSSDK.Extensions.NETCore.Setup** | 4.0.4.3 | Integração AWS com DI do .NET |
| **Microsoft.AspNetCore.Authentication.JwtBearer** | 8.0.0 | Validação JWT |
| **System.IdentityModel.Tokens.Jwt** | 8.19.1 | Geração e leitura de tokens JWT |
| **Microsoft.Extensions.Diagnostics.HealthChecks** | 8.0.0 | Health checks |

---

### Worker Service

| Tecnologia | Versão | Uso |
|---|---|---|
| **Microsoft.Extensions.Hosting** | 8.0.0 | Host para Worker Service |
| **MassTransit.RabbitMQ** | 8.0.0 | Consumer RabbitMQ |
| **MassTransit.AmazonSQS** | 8.0.0 | Consumer SQS |
| **Entity Framework Core** | 8.0.0 | Persistência no PostgreSQL |

---

### Gateway

| Tecnologia | Versão | Uso |
|---|---|---|
| **YARP.ReverseProxy** | 2.3.0 | Reverse proxy e roteamento |
| **Microsoft.AspNetCore.Authentication.JwtBearer** | 8.0.0 | Validação JWT no gateway |
| **prometheus-net** | 8.2.1 | Métricas do gateway |

---

### Frontend

| Tecnologia | Versão | Uso |
|---|---|---|
| **Blazor WebAssembly** | 8.0.27 | SPA em C# rodando no browser |
| **MudBlazor** | 9.5.0 | Componentes UI Material Design |
| **Blazored.LocalStorage** | 4.5.0 | Persistência do JWT no browser |
| **System.IdentityModel.Tokens.Jwt** | 8.0.2 | Leitura de claims do JWT no cliente |
| **Bootstrap** | 5 | Grid e utilitários CSS |

---

### Notificações

| Tecnologia | Versão | Uso |
|---|---|---|
| **MailKit** | 4.16.0 | Envio de e-mail via SMTP |
| **MassTransit.RabbitMQ** | 8.0.0 | Consumer de eventos |

---

### Testes

| Tecnologia | Versão | Uso |
|---|---|---|
| **xUnit** | 2.5.3 | Framework de testes |
| **Moq** | 4.20.72 | Mock de dependências |
| **FluentAssertions** | 6.12.1 | Assertions expressivas |
| **coverlet** | 6.0.2 | Cobertura de código |
| **BCrypt.Net-Next** | 4.2.0 | Testes de hash de senha |

---

### Infraestrutura — Serviços de Dados

| Serviço | Versão | Uso |
|---|---|---|
| **PostgreSQL** | 15 Alpine | Banco relacional (Usuários, Campanhas, Doações) |
| **Redis** | Alpine | Cache de sessão, token blacklist |
| **Amazon DynamoDB** | — | Logs de aplicação (`cs-app-logs`) e auditoria (`cs-audit-log`) |
| **Elasticsearch** | 8.11.0 | Busca full-text de campanhas |
| **RabbitMQ** | 4.1.6 management Alpine | Broker de mensagens (LOCAL) |
| **Amazon SQS** | — | Broker de mensagens (LAB/AWS) |

---

### Infraestrutura — Observabilidade

| Serviço | Versão | Uso |
|---|---|---|
| **Prometheus** | v2.53.0 | Coleta de métricas |
| **Grafana** | 11.1.0 | Dashboards e visualização |
| **Zabbix Appliance** | Alpine latest | Monitoramento de infraestrutura |
| **Zabbix Agent** | Alpine latest | Agente de coleta no servidor |
| **Mailpit** | Latest | Captura de e-mails em desenvolvimento |

---

### Infraestrutura — AWS

| Serviço | Uso |
|---|---|
| **EKS (Elastic Kubernetes Service)** | Orquestração de containers |
| **ECR (Elastic Container Registry)** | Registro de imagens Docker |
| **RDS PostgreSQL** | Banco relacional gerenciado |
| **ElastiCache Redis** | Cache gerenciado |
| **Amazon SQS** | Fila de mensagens gerenciada |
| **Amazon DynamoDB** | Banco NoSQL gerenciado |
| **AWS API Gateway v2** | Gateway HTTP gerenciado |
| **AWS Lambda (Python 3.9)** | Envio de e-mails transacionais |
| **Amazon SNS** | Notificações operacionais |
| **Amazon Mailtrap** | Envio de e-mails (LAB) |

---

### Infraestrutura — IaC e CI/CD

| Tecnologia | Versão | Uso |
|---|---|---|
| **Terraform** | AWS Provider ~5.0 | Provisionamento de infraestrutura AWS |
| **Kubernetes** | — | Orquestração de containers |
| **Docker** | — | Containerização |
| **Nginx** | Alpine | Servidor de arquivos estáticos (Frontend) |
| **GitHub Actions** | — | CI/CD automatizado |
| **Amazon ECR** | — | Registro de imagens Docker |

---

### DynamoDB PG Proxy

| Tecnologia | Versão | Uso |
|---|---|---|
| **Python** | 3.12 Alpine | Runtime |
| **boto3** | 1.34.0 | Client DynamoDB |
| **asyncio** | stdlib | Servidor TCP assíncrono |
| **flake8** | — | Lint (CI) |

---

## Endpoints

Documentação de todos os endpoints dos microsserviços de **Usuários** e **Campanhas**, com funcionalidade, autenticação e perfis de acesso.

---

### Legenda

| Símbolo | Significado |
|---|---|
| 🔓 | Endpoint público — não requer autenticação |
| 🔐 | Endpoint protegido — requer token JWT |
| 👤 | DOADOR |
| 🏢 | GESTOR_ONG |

---

### Microsserviço de Usuários

### Autenticação — `POST /api/v1/auth/...`

| UC | Método | Endpoint | Funcionalidade | Auth | Acesso |
|---|---|---|---|---|---|
| UC-02 | `POST` | `/api/v1/auth/login` | Autentica o usuário com e-mail e senha. Gera token JWT e cacheia dados no Redis. Bloqueia usuários SUSPENDED e REMOVED | 🔓 | Todos |
| UC-03 | `POST` | `/api/v1/auth/logout` | Invalida o token JWT adicionando-o à blacklist no Redis pelo tempo restante de vida. Remove dados do cache | 🔐 | 👤 🏢 |
| UC-06 | `PUT` | `/api/v1/auth/reset-password` | Troca a senha do usuário logado. Exige a senha atual como confirmação de identidade. Invalida o token anterior e retorna um novo token JWT | 🔐 | 👤 🏢 |

---

#### Usuário — `POST /api/v1/usuario/...`

| UC | Método | Endpoint | Funcionalidade | Auth | Acesso | Observação |
|---|---|---|---|---|---|---|
| UC-01 | `POST` | `/api/v1/usuario` | Cadastra um novo usuário. O perfil inicial é sempre **DOADOR** | 🔓 | Todos | E-mail e CPF únicos no sistema |
| UC-04 | `GET` | `/api/v1/usuario?Email=` | Retorna os dados de um usuário pelo e-mail | 🔐 | 👤 🏢 | DOADOR consulta apenas o próprio perfil; GESTOR_ONG consulta qualquer perfil |
| UC-05 | `DELETE` | `/api/v1/usuario?Email=` | Remove fisicamente o usuário do banco (LGPD). Doações permanecem para fins de auditoria fiscal | 🔐 | 👤 🏢 | Apenas o próprio usuário pode solicitar a exclusão |
| UC-07 | `PUT` | `/api/v1/usuario/suspender?Email=` | Atualiza status para **SUSPENDED** — bloqueia o acesso do usuário | 🔐 | 🏢 | Exclusivo para gestores |
| UC-08 | `PUT` | `/api/v1/usuario/ativar?Email=` | Atualiza status para **ACTIVE** — restaura o acesso do usuário | 🔐 | 🏢 | Exclusivo para gestores |
| UC-09 | `PUT` | `/api/v1/usuario/alterar-para-gestor?Email=` | Eleva o perfil do usuário para **GESTOR_ONG** | 🔐 | 🏢 | Gestor não pode alterar o próprio perfil |
| UC-10 | `PUT` | `/api/v1/usuario/alterar-para-doador?Email=` | Rebaixa o perfil do usuário para **DOADOR** | 🔐 | 🏢 | Gestor não pode alterar o próprio perfil |
| UC-11 | `PUT` | `/api/v1/usuario/alterar?NomeCompleto=&Cpf=` | Atualiza nome completo e CPF do usuário logado | 🔐 | 👤 🏢 | Apenas o próprio usuário altera seus dados |

---

### Microsserviço de Campanhas

#### Campanhas — `/api/v1/Campanhas/...`

| UC | Método | Endpoint | Funcionalidade | Auth | Acesso | Observação |
|---|---|---|---|---|---|---|
| UC-12 | `POST` | `/api/v1/Campanhas` | Cria uma nova campanha de doações com status **ATIVA** | 🔐 | 🏢 | Título único no sistema |
| UC-13 | `GET` | `/api/v1/Campanhas?Guid=` | Retorna os dados completos de uma campanha pelo GUID, independente do status | 🔐 | 👤 🏢 | |
| UC-14 | `GET` | `/api/v1/Campanhas/todas?Pagina=&TamanhoPagina=` | **Painel de Transparência** — lista todas as campanhas com status ATIVA, com paginação. Padrão: página 1, tamanho 9999 | 🔓 | Todos | Usado na landing page pública |
| UC-15 | `PUT` | `/api/v1/Campanhas/cancel?Guid=` | Cancela uma campanha ATIVA. Campanha CONCLUÍDA não pode ser cancelada | 🔐 | 🏢 | |
| UC-16 | `PUT` | `/api/v1/Campanhas/concluir?Guid=` | Conclui uma campanha ATIVA | 🔐 | 🏢 | |
| UC-17 | `PUT` | `/api/v1/Campanhas` | Altera título, descrição, meta financeira e datas de uma campanha. A campanha deve estar ATIVA | 🔐 | 🏢 | |
| UC-18 | `GET` | `/api/v1/Campanhas/busca?Termo=` | **Busca avançada via Elasticsearch** — suporta fuzzy search (tolerância a erros de digitação) e busca por prefixo. Pesquisa em título, descrição, status e datas | 🔐 | 👤 🏢 | |

---

#### Doações — `/api/v1/Doacoes/...`

| UC | Método | Endpoint | Funcionalidade | Auth | Acesso | Observação |
|---|---|---|---|---|---|---|
| UC-19 | `POST` | `/api/v1/Doacoes` | Registra uma **intenção de doação** e publica o evento `DonationCreatedEvent` no broker. O processamento efetivo ocorre no Worker de Doações | 🔐 | 👤 🏢 | A campanha deve estar ATIVA |
| UC-20 | `GET` | `/api/v1/Doacoes/campanha?GuidCampanha=` | Lista todas as doações de uma campanha específica | 🔐 | 🏢 | Relatório administrativo |
| UC-21 | `GET` | `/api/v1/Doacoes/usuario?Email=` | Lista todas as doações realizadas por um usuário específico | 🔐 | 🏢 | Relatório administrativo |
| UC-22 | `GET` | `/api/v1/Doacoes/self` | Lista todas as doações do **usuário logado** — sem precisar informar e-mail | 🔐 | 👤 🏢 | Usa claims do JWT para identificar o usuário |

---

### Resumo por Perfil

#### 🔓 Público (sem autenticação)
- `POST /api/v1/auth/login` — login
- `POST /api/v1/usuario` — cadastro de doador
- `GET /api/v1/Campanhas/todas` — listar campanhas ativas

#### 👤 DOADOR
- Consultar e editar o próprio perfil
- Alterar a própria senha
- Excluir a própria conta (LGPD)
- Ver as próprias doações
- Registrar doação em campanha ativa
- Consultar campanhas (por GUID e busca avançada)
- Logout

#### 🏢 GESTOR_ONG — tudo do DOADOR, mais:
- Consultar qualquer usuário
- Suspender e ativar usuários
- Alterar perfil de usuários (DOADOR ↔ GESTOR_ONG)
- Criar, alterar, cancelar e concluir campanhas
- Relatórios de doações por campanha e por usuário

---

## Features

O sistema possui os seguintes features implementados: <br>
- [Sistema de Logging Estruturado](#sistema-de-logging-estruturado)
- [Sistema de Cache - Redis](#sistema-de-cache)
- [Sistema de Busca Avançada - Elasticsearch](#sistema-de-busca-avancada-elasticsearch)
- [Sistema de Gerenciamento de Erros](#sistema-de-gerenciamento-de-erros)
- [Sistema de Audit Log](#sistema-de-audit-log)
- [Sistema de Autenticaçao](#sistema-de-autenticaçao)
- [Sistema de Mensageria](#sistema-de-mensageria)
- [Sistema de Notificaçoes](#sistema-de-notificaçoes)
- [Api Gateway](#api-gateway)
- [Proxy PostGreSql - Dynamo](#proxy-postgresql-dynamo)
- [Frontend](#frontend)
- [Observabilidade](#observabilidade)
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

### Benefícios

#### ⚡ Performance
A camada de cache reduz drasticamente a latência em endpoints de leitura frequente. Dados de usuário — consultados em **cada requisição autenticada** para validação de perfil e permissões — são retornados em menos de 1ms pelo Redis, em vez dos 5-50ms de uma consulta ao PostgreSQL.

#### 🔒 Segurança com Blacklist
A implementação de blacklist de tokens JWT resolve um problema clássico de autenticação stateless: **logout imediato e definitivo**. Em sistemas que usam apenas JWT sem blacklist, um token roubado permanece válido até expirar naturalmente. No Conexão Solidária, o logout invalida o token instantaneamente.

#### 🛡️ Resiliência por Design
O Redis é tratado como **otimização**, não como dependência crítica. A aplicação degrada graciosamente quando o cache está indisponível — buscando os dados diretamente do banco — sem propagar erros para o usuário final.

#### 💰 Redução de Custo
Em arquiteturas cloud com cobrança por operação de banco de dados (como RDS na AWS), a camada de cache reduz diretamente o número de consultas ao PostgreSQL — traduzindo em economia real de infraestrutura em produção.

#### 🔄 Consistência Garantida
A invalidação proativa do cache em toda operação de escrita garante que os dados exibidos ao usuário **nunca sejam stale** após uma modificação — eliminando a classe de bugs de "dado desatualizado na tela".

#### 📊 Rastreabilidade
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

### Benefícios

- ⚡ **Velocidade** — respostas em milissegundos, independente do volume de campanhas cadastradas, sem impacto no banco de dados principal

- 🔤 **Tolerância a erros de digitação** — o usuário pode errar a escrita e ainda encontrar a campanha correta, reduzindo a fricção na experiência de busca

- 🔄 **Busca em tempo real** — resultados aparecem enquanto o usuário digita, sem necessidade de pressionar "buscar"

- 🎯 **Relevância inteligente** — campanhas com o termo buscado no título aparecem antes das que têm o termo apenas na descrição, entregando os resultados mais relevantes primeiro

- 📈 **Escalabilidade** — o Elasticsearch escala horizontalmente, suportando crescimento no volume de campanhas e de usuários simultâneos sem degradação de performance

- 🔀 **Desacoplamento** — a busca não concorre com as operações transacionais do banco de dados PostgreSQL, garantindo que buscas intensas não impactem o cadastro de campanhas e doações

- 🔁 **Índice sempre atualizado** — qualquer alteração em uma campanha é refletida automaticamente no índice, garantindo que os resultados de busca estejam sempre sincronizados com o estado real do sistema

---

## Sistema de Gerenciamento de Erros

O tratamento de erros é feito em **três camadas complementares**, garantindo que nenhuma exceção chegue ao cliente sem ser tratada, categorizada e registrada:

```
Request
  └─ CorrelationMiddleware        → gera/propaga o ID de rastreamento
       └─ ExceptionHandlingMiddleware  → captura e formata todos os erros
            └─ Controller
                 └─ Handler (Application)
                      └─ Entidade / Value Object (Domain)
                           └─ AssertionConcern → lança DomainException
```

---

### Exception Handling Middleware

**Arquivo:** `Middlewares/ExceptionHandlingMiddleware.cs`

Middleware global que intercepta todas as exceções não tratadas e as converte em respostas HTTP padronizadas. Três tipos de exceção são tratados:

#### 1 DomainException — Erros de negócio

Lançada pelas entidades e value objects do domínio quando uma regra de negócio é violada.

```json
{
  "title": "A domain error occurred.",
  "status": 422,
  "errors": {
    "Domain": ["O título deve ter no mínimo 5 e no máximo 200 caracteres."]
  },
  "traceId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "code": "422_TITLE_LENGTH_INVALID"
}
```

O status HTTP é extraído automaticamente do prefixo do `ErrorCode`:

| Prefixo do código | Status HTTP |
|---|---|
| `400_` | 400 Bad Request |
| `401_` | 401 Unauthorized |
| `403_` | 403 Forbidden |
| `404_` | 404 Not Found |
| `422_` | 422 Unprocessable Entity |
| `500_` | 500 Internal Server Error |

#### 2 BadHttpRequestException — Erros de validação de entrada

Captura falhas de Data Annotations e model binding antes mesmo de chegar ao handler.

```json
{
  "code": "400_NAME_REQUIRED",
  "error": "O campo Nome Completo é obrigatório."
}
```

#### 3 Exception — Erros inesperados

Qualquer exceção não prevista retorna um erro genérico sem expor detalhes internos ao cliente, mas registra o stack trace completo no log.

```json
{
  "code": "500_ERRO_INESPERADO",
  "error": "Ocorreu um erro inesperado. Por favor, tente novamente."
}
```

---

### DomainException

**Arquivo:** `Domain/Shared/Exceptions/DomainExceptions.cs`

Exceção customizada que carrega um `ErrorCode` semântico além da mensagem. Possui quatro sobrecargas:

```csharp
// 1. Mensagem buscada automaticamente do arquivo .resx pelo código
throw new DomainException("422_TITLE_LENGTH_INVALID");

// 2. Mensagem customizada manual
throw new DomainException("422_TITLE_LENGTH_INVALID", "Título inválido.");

// 3. Com InnerException — mensagem do .resx
throw new DomainException("500_ERRO_INESPERADO", innerException);

// 4. Com InnerException — mensagem customizada
throw new DomainException("500_ERRO_INESPERADO", "Erro ao processar.", innerException);
```

O `ErrorCode` é sempre normalizado para **UPPER_CASE** e nunca fica em branco — se vazio, recebe o valor padrão `DOMAIN_ERROR`.

---

### AssertionConcern — Validações do Domínio

**Arquivo:** `Domain/Shared/Helpers/AssertionConcern.cs`

Classe utilitária estática com métodos de asserção usados pelas entidades e value objects para validar seus próprios dados antes de se construir. Cada método lança uma `DomainException` com o código de erro correspondente se a condição não for satisfeita.

| Método | O que valida |
|---|---|
| `AssertArgumentNotNull` | Objeto não é nulo |
| `AssertArgumentNotEmpty` | String não é nula, vazia ou só espaços |
| `AssertArgumentLength` | String dentro do tamanho mínimo e máximo (com trim) |
| `AssertArgumentRange` | Decimal dentro de um range min/max |
| `AssertArgumentNotLesserOrEqualZero` | Decimal maior que zero |

**Exemplo de uso em uma entidade:**

```csharp
public static TituloCampanha Create(string valor)
{
    AssertionConcern.AssertArgumentNotEmpty(valor, "400_TITLE_REQUIRED");
    AssertionConcern.AssertArgumentLength(valor, 5, 200, "400_TITLE_LENGTH_INVALID");
    return new TituloCampanha(valor.Trim());
}
```

---

### Result Pattern

**Arquivo:** `Domain/Shared/Primitives/Result.cs`

Os handlers da camada de Application nunca lançam exceções diretamente — retornam um objeto `Result<T>` que encapsula sucesso ou falha. O controller decide como responder com base no `IsSuccess`.

```csharp
// Sucesso
return Result<T>.Success(value);

// Falha — busca a mensagem no .resx pelo código
return Result<T>.Failure("422_EMAIL_ALREADY_EXISTS");
```

```csharp
// No controller
var result = await _handler.HandleAsync(command);

if (!result.IsSuccess)
    return BadRequest(result.Error);  // mensagem amigável do .resx

return Ok(result.Value);
```

Para operações sem retorno de dados, existe o `VoidResult`:

```csharp
return VoidResult.Success();
return VoidResult.Failure("mensagem de erro");
```

---

### Catálogo de Erros — Errors.resx

**Arquivo:** `Domain/Shared/Resources/Errors.resx`

Todos os códigos de erro e suas mensagens amigáveis estão centralizados em um arquivo de recursos `.resx`. Isso garante:

- **Consistência** — a mesma mensagem para o mesmo erro em qualquer parte do sistema
- **Manutenibilidade** — alterar uma mensagem em um único lugar reflete em todo o sistema
- **Internacionalização** — suporte futuro a múltiplos idiomas sem alterar código

```
ErrorCode                    →  Mensagem
─────────────────────────────────────────────────────
400_COMMAND_INVALID          →  O Comando não deve ser nulo.
400_CPF_REQUIRED             →  O campo CPF é obrigatório.
400_EMAIL_REQUIRED           →  O campo E-mail é obrigatório.
400_NAME_REQUIRED            →  O campo Nome Completo é obrigatório.
422_CPF_INVALID              →  O CPF informado é inválido.
422_EMAIL_ALREADY_EXISTS     →  O e-mail informado já está cadastrado.
500_ERRO_INESPERADO          →  Ocorreu um erro inesperado. Por favor, tente novamente.
```

Se um código não existir no `.resx`, o sistema retorna `"Erro não catalogado: {código}"` como fallback — nunca expõe stack traces ou mensagens técnicas ao cliente.

---

### Fluxo Completo de um Erro de Domínio

```
1. Controller recebe request
2. CorrelationMiddleware atribui x-correlation-id: "abc-123"
3. Handler chama entidade
4. Entidade chama AssertionConcern.AssertArgumentLength(titulo, 5, 200, "422_TITLE_LENGTH_INVALID")
5. Título tem 2 caracteres → AssertionConcern lança DomainException("422_TITLE_LENGTH_INVALID")
6. DomainException busca mensagem no .resx → "O título deve ter entre 5 e 200 caracteres."
7. ExceptionHandlingMiddleware captura a exceção
8. Extrai status code do prefixo "422_" → HttpStatusCode.UnprocessableEntity
9. Loga o erro no DynamoDB com correlationId "abc-123"
10. Retorna ao cliente:

HTTP 422 Unprocessable Entity
x-correlation-id: abc-123

{
  "title": "A domain error occurred.",
  "status": 422,
  "errors": { "Domain": ["O título deve ter entre 5 e 200 caracteres."] },
  "traceId": "abc-123",
  "code": "422_TITLE_LENGTH_INVALID"
}
```

---

### Benefícios

- 🎯 **Respostas padronizadas** — todos os erros seguem o mesmo contrato de resposta, facilitando o tratamento no frontend e nos microsserviços consumidores

- 🔍 **Rastreabilidade total** — o `x-correlation-id` percorre toda a cadeia de processamento, permitindo localizar qualquer requisição nos logs do DynamoDB com um único ID

- 🛡️ **Segurança por padrão** — erros inesperados nunca expõem stack traces, mensagens técnicas ou detalhes de infraestrutura ao cliente

- 📋 **Catálogo centralizado de erros** — todas as mensagens ficam no `Errors.resx`, eliminando strings duplicadas no código e facilitando manutenção e futura internacionalização

- ⚡ **Log assíncrono** — a persistência no DynamoDB não bloqueia a resposta ao cliente, mantendo a latência da API independente da disponibilidade do serviço de log

- 🏗️ **Validação no domínio** — o `AssertionConcern` garante que entidades e value objects nunca existam em estado inválido, prevenindo dados corrompidos antes de chegarem ao banco

- 🔀 **Status HTTP semântico automático** — o prefixo do `ErrorCode` (`400_`, `422_`, `403_`) determina o status HTTP sem necessidade de mapeamentos manuais adicionais

- 📊 **Observabilidade integrada** — cada erro é registrado no DynamoDB com nível de severidade, tipo (LOG/EVENT), caller, stack trace e correlation ID, formando uma trilha de auditoria completa

- 🔄 **Result Pattern** — handlers retornam `Result<T>` em vez de lançar exceções como fluxo de controle, tornando o código mais previsível e testável

- 🌐 **Pronto para internacionalização** — a separação entre código de erro e mensagem no `.resx` permite adicionar suporte a múltiplos idiomas sem alterar nenhuma linha de lógica de negócio


---
## Sistema de Audit Log

O Audit Log registra automaticamente **quem alterou o quê e quando** no banco de dados PostgreSQL. É gerado pelo `AuditInterceptor`, um interceptor do EF Core que captura todas as operações de escrita sem nenhuma chamada manual nos repositórios ou handlers.

```
SaveChangesAsync()
  │
  ├─ ANTES do SQL → captura estado das entidades (old/new)
  ├─ EF Core executa SQL no PostgreSQL ✅
  └─ APÓS sucesso → persiste trilha no DynamoDB (cs-audit-log)
```

---

### Tabela — `cs-audit-log`

Armazenada no **AWS DynamoDB**, escolhido por sua escalabilidade, custo por uso e suporte nativo a TTL.

#### Estrutura

| Atributo | Tipo | Descrição |
|---|---|---|
| `PK` | String (PK) | `ENTITY#{TABELA}#{GUID}` — ex: `ENTITY#USUARIO#abc-123` |
| `SK` | String (SK) | `TS#{ISO8601}` — ex: `TS#2026-06-25T14:00:00Z` |
| `ResourceId` | String (GSI PK) | GUID da entidade — permite buscar todo o histórico de uma entidade |
| `ServiceName` | String | Microsserviço que realizou a operação — ex: `CS-USUARIOS-API` |
| `Operation` | String | `ADDED`, `MODIFIED`, `DELETED` |
| `ChangedBy` | String | E-mail do usuário autenticado ou `Worker` para operações automáticas |
| `IpAddress` | String | IP do cliente ou `Internal` para workers e processos internos |
| `Payload` | String | JSON com os dados da operação |
| `TTL` | Number | Unix timestamp — expiração em 1 ano |

#### Índice GSI — `ResourceIdIndex`

Permite buscar todo o histórico de alterações de uma entidade específica pelo seu GUID, independente do serviço que realizou a operação:

```
ResourceIdIndex
  PK: ResourceId  ← GUID da entidade
  SK: SK          ← ordenação cronológica
```

---

### AuditInterceptor — Como Funciona

**Arquivo:** `Infrastructure/Services/ChangesInterceptor/ChangesInterceptor.cs`

Implementa o `SaveChangesInterceptor` do EF Core em **duas fases**:

#### Fase 1 — Captura (antes do SQL)

```
SavingChangesAsync()
  └─ CaptureChanges()
       └─ Percorre o ChangeTracker do EF Core
       └─ Filtra apenas entidades que herdam de EntityBase
       └─ Filtra apenas estados: Added, Modified, Deleted
       └─ Para MODIFIED: gera diff apenas dos campos que mudaram (old → new)
       └─ Para ADDED / DELETED: captura snapshot completo de todos os campos
       └─ Armazena em AsyncLocal<List<AuditLog>> (thread-safe por requisição)
```

#### Fase 2 — Persistência (após sucesso no SQL)

```
SavedChangesAsync()
  └─ PersistAuditAsync()
       └─ Lê as entradas capturadas na Fase 1
       └─ Resolve o usuário autenticado via IUserContext
       └─ Resolve o IP do cliente via IHttpContextAccessor
       └─ Persiste cada entrada no DynamoDB (cs-audit-log)
```

> **Importante:** a auditoria só é gerada **após** o commit bem-sucedido no PostgreSQL. Se a transação falhar, nenhum registro de auditoria é criado — garantindo consistência entre os dois sistemas.

---

### Formato do Payload

**Operação `ADDED`** — snapshot completo do estado inicial:
```json
{
  "Guid": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "NomeCompleto": "João Silva",
  "Email": "joao@email.com",
  "Perfil": "DOADOR",
  "Status": "ACTIVE",
  "CriadoPor": "joao@email.com",
  "DataCriacao": "2026-06-25T14:00:00Z"
}
```

**Operação `MODIFIED`** — apenas os campos que foram alterados, com valor anterior e novo:
```json
{
  "Status": { "old": "ACTIVE", "new": "SUSPENDED" },
  "ModificadoPor": { "old": null, "new": "admin@ong.com" },
  "DataModificacao": { "old": null, "new": "2026-06-25T15:00:00Z" }
}
```

**Operação `DELETED`** — snapshot completo do estado antes da deleção:
```json
{
  "Guid": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "NomeCompleto": "João Silva",
  "Email": "joao@email.com",
  "Status": "ACTIVE"
}
```

---

### Entidades Auditadas

Apenas entidades que herdam de `EntityBase` são interceptadas — garantindo que tabelas auxiliares, de configuração ou de infraestrutura não gerem registros desnecessários.

```csharp
var entries = context.ChangeTracker.Entries()
    .Where(e => e.Entity is EntityBase &&
                (e.State == EntityState.Added ||
                 e.State == EntityState.Modified ||
                 e.State == EntityState.Deleted));
```

---

### Exemplo de Registro

Suspensão de um usuário pelo gestor:

```
PK:          ENTITY#USUARIO#3fa85f64-5717-4562-b3fc-2c963f66afa6
SK:          TS#2026-06-25T15:00:00.000Z
ResourceId:  3fa85f64-5717-4562-b3fc-2c963f66afa6
ServiceName: CS-USUARIOS-API
Operation:   MODIFIED
ChangedBy:   admin@conexao-solidaria.com.br
IpAddress:   192.168.1.100
TTL:         1782000000  (expira em 1 ano)
Payload:     {
               "Status": { "old": "ACTIVE", "new": "SUSPENDED" },
               "ModificadoPor": { "old": null, "new": "admin@conexao-solidaria.com.br" }
             }
```

---

### Configuração por Ambiente

```
LOCAL (docker-compose)
  └─ DynamoDB Local (container amazon/dynamodb-local)
  └─ Credenciais fictícias ("local" / "local")

LAB (AWS com credenciais temporárias)
  └─ DynamoDB real na AWS
  └─ Credenciais via AWS_ACCESS_KEY_ID / AWS_SESSION_TOKEN

PRODUÇÃO (AWS com IAM Role)
  └─ DynamoDB real na AWS
  └─ Credenciais via IAM Role do pod (sem chaves hardcoded)
```

---

### Migration Automática

As tabelas DynamoDB são criadas automaticamente no startup da aplicação:

```csharp
await DynamoDbConfiguration.DynamoDbMigration(app.Services);
```

Se as tabelas já existirem, a migration é ignorada silenciosamente. O TTL é habilitado desde a criação.

---

### Benefícios

- 📜 **Trilha de auditoria completa** — cada criação, alteração e deleção no banco de dados é registrada automaticamente, sem nenhuma linha de código adicional nos repositórios ou handlers

- 🔍 **Histórico por entidade** — o `ResourceIdIndex` permite consultar todas as alterações de qualquer entidade pelo seu GUID em ordem cronológica

- 🕒 **Diff preciso** — operações `MODIFIED` registram apenas os campos que realmente mudaram, com valor anterior e novo, eliminando ruído

- 🛡️ **Conformidade com LGPD** — registra quem acessou e alterou dados pessoais, com e-mail do responsável e IP de origem, atendendo requisitos de rastreabilidade

- ✅ **Consistência garantida** — a auditoria só é gerada após o commit bem-sucedido no PostgreSQL, nunca para transações que falharam

- 💰 **Custo otimizado** — TTL de 1 ano remove registros antigos automaticamente, evitando acúmulo indefinido e custo desnecessário no DynamoDB

- 🏗️ **Transparente e automático** — o `AuditInterceptor` opera como um interceptor do EF Core, invisível para o código de negócio

---

## Sistema de Autenticaçao

A autenticação é baseada em **JWT (JSON Web Token)** com três camadas de segurança complementares:

```
Request
  └─ TokenBlacklistMiddleware   → bloqueia tokens revogados (Redis)
       └─ JwtBearer Middleware  → valida assinatura, issuer, audience e expiração
            └─ [Authorize]      → verifica perfil (Role) por endpoint
```

---

### Fluxo de Autenticação

```
1. POST /api/v1/auth/login
     └─ Verifica se usuário existe e está ACTIVE
     └─ Verifica senha com BCrypt
     └─ Gera token JWT assinado com HMAC SHA256
     └─ Cacheia dados do usuário no Redis (30 min)
     └─ Retorna token + data de expiração

2. Requisições autenticadas
     └─ TokenBlacklistMiddleware → token está na blacklist? → 401
     └─ JwtBearer → valida assinatura, issuer, audience, expiração
     └─ [Authorize(Roles = "...")] → verifica perfil

3. POST /api/v1/auth/logout
     └─ Adiciona token à blacklist no Redis pelo tempo restante de vida
     └─ Remove dados do usuário do cache Redis

4. PUT /api/v1/auth/reset-password
     └─ Verifica senha atual
     └─ Atualiza hash da senha no banco
     └─ Invalida token atual (blacklist)
     └─ Retorna novo token JWT
```

---

### Token JWT

**Arquivo:** `Infrastructure/Services/Authentication/TokenService.cs`

#### Claims

| Claim | Conteúdo | Exemplo |
|---|---|---|
| `ClaimTypes.NameIdentifier` | GUID do usuário | `3fa85f64-...` |
| `ClaimTypes.Name` | Nome completo | `João Silva` |
| `ClaimTypes.Email` | E-mail | `joao@email.com` |
| `ClaimTypes.Role` | Perfil | `DOADOR`, `GESTOR_ONG` |
| `ClaimTypes.SerialNumber` | CPF encriptado (AES-256) | `base64...` |

#### Configuração

```
Algoritmo de assinatura: HMAC SHA256
Validações ativas:
  ✅ Chave de assinatura (IssuerSigningKey)
  ✅ Issuer (quem emitiu)
  ✅ Audience (para quem foi emitido)
  ✅ Lifetime (expiração)
  ✅ ClockSkew = Zero (sem tolerância de 5 min do .NET)
```

#### Variáveis de configuração

```yaml
Jwt__SecretKey:       "chave-secreta-com-mais-de-32-caracteres"
Jwt__Issuer:          "ES-ConexaoSolidariaIssuer"
Jwt__Audience:        "ES-ConexaoSolidariaClient"
Jwt__ExpirationHours: "3"
```

---

### Perfis de Acesso (Roles)

| Perfil | Descrição | Acesso |
|---|---|---|
| `DOADOR` | Usuário doador | Endpoints próprios — ver e editar seu perfil, fazer doações |
| `GESTOR_ONG` | Gestor da ONG | Endpoints administrativos — gerenciar usuários e campanhas |
| `SISTEMA` | Workers e serviços internos | Endpoints internos de comunicação entre microsserviços |

---

### Token Blacklist — Logout Seguro

**Arquivo:** `Middlewares/TokenBlackListMiddleware.cs`

O logout em JWT é desafiador porque o token continua válido até expirar naturalmente. A solução é uma **blacklist no Redis** — o token é adicionado à lista negra com o tempo restante de vida como TTL, garantindo que expire automaticamente do Redis quando o JWT também expiraria.

```
POST /auth/logout
  └─ Calcula tempo restante de vida do token
  └─ Adiciona token ao Redis com TTL = tempo restante
  └─ Remove dados do usuário do cache

Próxima requisição com o mesmo token:
  └─ TokenBlacklistMiddleware consulta Redis
  └─ Token está na blacklist → 401 Unauthorized
       { "message": "Token revogado. Por favor faça login novamente" }
```

O middleware é executado **antes** da validação do JWT — tokens na blacklist são bloqueados imediatamente, antes de qualquer verificação de rota ou perfil.

---

### Reset de Senha

**Arquivo:** `Application/Features/Auth/ResetarSenha/ResetarSenhaCommandHandler.cs`

Fluxo seguro de troca de senha em 5 etapas:

```
1. Verifica que nova senha não é vazia
2. Busca usuário pelo e-mail do token autenticado (não aceita e-mail por parâmetro)
3. Verifica se usuário está ACTIVE
4. Valida a senha ATUAL via BCrypt (dupla confirmação de identidade)
5. Gera novo hash BCrypt para a nova senha e salva no banco
6. Invalida o token atual (blacklist no Redis)
7. Gera e retorna um novo token JWT
```

> **Segurança:** o usuário precisa informar a senha atual para trocar a senha, mesmo já estando autenticado — isso previne ataques onde alguém com acesso temporário ao token tenta trocar a senha.

---

### Criptografia

**Arquivo:** `Infrastructure/Services/Authentication/CryptoService.cs`

O sistema usa dois algoritmos para finalidades distintas:

#### BCrypt — Senhas

```
Cadastro:  senha em texto → BCrypt.HashPassword(workFactor: 12) → hash gravado no banco
Login:     BCrypt.Verify(senhaDigitada, hashDoBanco) → true/false
```

- Algoritmo unidirecional — não é possível reverter o hash
- `workFactor: 12` — custo computacional alto, resistente a brute force
- Salt embutido no hash — cada senha gera um hash diferente mesmo com o mesmo valor

#### AES-256 — CPF

```
Cadastro:  CPF limpo → AES.Encrypt(chaveAes) → valor encriptado no token JWT
Outros microsserviços: AES.Decrypt(chaveAes) → CPF original recuperado
```

- Algoritmo bidirecional — permite recuperar o CPF original
- IV (Initialization Vector) gerado aleatoriamente a cada encriptação — mesmo CPF gera valores diferentes
- IV embutido nos primeiros 16 bytes do resultado em Base64
- Chave AES configurada via variável de ambiente (`AES__KEY`) — nunca hardcoded

```yaml
AES__KEY: "W36tuZgAwZTkvGebRMEQJjGtbLNJRK6unGj1Ow5Rnm8="  # base64 de 32 bytes
```

---

### Validações de Segurança no Login

```
✅ Usuário existe no banco
✅ Status é ACTIVE (rejeita SUSPENDED e REMOVED)
✅ Senha bate com o hash BCrypt
✅ Token gerado com claims corretos e expiração configurada
✅ Dados do usuário cacheados no Redis por 30 minutos
```

---

### Endpoints

| Método | Rota | Auth | Descrição |
|---|---|---|---|
| `POST` | `/api/v1/auth/login` | ❌ Público | Autenticação com e-mail e senha |
| `POST` | `/api/v1/auth/logout` | ✅ DOADOR, GESTOR_ONG | Invalida o token atual |
| `PUT` | `/api/v1/auth/reset-password` | ✅ DOADOR, GESTOR_ONG | Troca a senha e gera novo token |

---

### Resposta do Login

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "dataExpiracao": "2026-06-25T17:00:00Z",
  "usuarioId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "email": "joao@email.com",
  "status": "ACTIVE"
}
```

---

### Benefícios

- 🔑 **Stateless** — o token carrega todas as informações necessárias, sem consulta ao banco a cada requisição

- 🚫 **Logout real** — a blacklist no Redis garante que tokens revogados são imediatamente inválidos, mesmo que ainda estejam dentro do prazo de expiração

- 🛡️ **CPF protegido** — o CPF nunca trafega em texto plano — é encriptado com AES-256 no token e só pode ser decriptado por microsserviços com a chave correta

- 🔒 **Senhas seguras** — BCrypt com workFactor 12 e salt único por senha torna ataques de dicionário e rainbow table inviáveis

- ⏱️ **TTL automático na blacklist** — tokens revogados expiram automaticamente do Redis no mesmo momento em que o JWT expiraria, sem acúmulo de dados

- 🔄 **Troca de senha segura** — exige a senha atual mesmo com o usuário autenticado, e invalida o token anterior automaticamente

- 🎯 **Autorização por perfil** — cada endpoint define explicitamente quais perfis têm acesso via `[Authorize(Roles = "...")]`, sem lógica de permissão espalhada no código

- ⚡ **Cache de sessão** — dados do usuário cacheados no Redis por 30 minutos reduzem consultas ao banco em endpoints autenticados

---

## Sistema de Mensageria

A plataforma utiliza sistema de mensageria assíncrona para desacoplar os microsserviços e garantir que operações críticas, baseado em **RabbitMQ** e **MassTransit** para o ambiente local, e **Amazon SQS** para os ambientes LAB e produção.

O sistema garante que operações críticas — como o processamento de doações — sejam executadas de forma confiável, mesmo em cenários de falha parcial.

```
Microsserviço Campanhas
  └─ Usuário registra intenção de doação
       └─ Publica DonationCreatedEvent
            └─ RabbitMQ / SQS
                 └─ Worker Doações consome
                      ├─ Persiste doação no banco
                      ├─ Atualiza valor arrecadado da campanha (UPDATE atômico)
                      └─ Publica DonationProcessedEvent
```

---

### Eventos

**Arquivo:** `Domain/Events/DomainEvents.cs` (compartilhado entre microsserviços)

| Evento | Publicado por | Consumido por | Descrição |
|---|---|---|---|
| `DonationCreatedEvent` | Microsserviço Campanhas | Worker Doações | Intenção de doação registrada pelo usuário |
| `DonationProcessedEvent` | Worker Doações | Worker Notificações | Doação persistida e campanha atualizada com sucesso |
| `UserCreatedEvent` | Microsserviço Usuários | Worker Notificações | Novo usuário cadastrado na plataforma |

#### Estrutura dos eventos

```csharp
// Publicado quando o usuário registra uma intenção de doação
record DonationCreatedEvent(
    Guid guidUser,
    string nome,
    string email,
    Guid guidCampanha,
    string tituloCampanha,
    string cpf,           // ← CPF encriptado com AES-256
    decimal valor,
    string? correlationId);

// Publicado pelo worker após persistir a doação com sucesso
record DonationProcessedEvent(
    Guid guidUser,
    string nome,
    string email,
    Guid guidCampanha,
    string tituloCampanha,
    decimal valor,
    string? correlationId);

// Publicado quando um novo usuário é cadastrado
record UserCreatedEvent(
    Guid guidUsuario,
    string nomeCompleto,
    string email,
    string cpf,           // ← CPF encriptado com AES-256
    string? correlationId);
```

> **Segurança:** o CPF nunca trafega em texto plano nos eventos. É encriptado com **AES-256** antes da publicação e decriptado pelo consumer usando a mesma chave compartilhada via Kubernetes Secret.

---

#### Transporte por Ambiente

O sistema usa transportes diferentes conforme o ambiente, sem alterar nenhuma linha de código de negócio — apenas a configuração muda:

| Ambiente | Transporte | Configuração |
|---|---|---|
| `LOCAL` | RabbitMQ | Container Docker via docker-compose |
| `CLOUD` | Amazon SQS | AWS com credenciais temporárias (Session Token) |

---

### MassTransit

**Framework:** [MassTransit 8](https://masstransit.io) — abstrai o transporte subjacente (RabbitMQ ou SQS) e fornece retry, outbox, scheduling e consumer pipeline.

#### Configuração LOCAL — RabbitMQ

```
RabbitMQ
  ├─ Host: cs-rabbitmq:5672
  ├─ VHost: /
  ├─ Management UI: localhost:15672
  ├─ InMemoryOutbox habilitado
  └─ Retry: 1s → 5s → 30s
```

**InMemoryOutbox** garante que mensagens publicadas durante o processamento de um consumer só são enviadas ao broker após o handler completar com sucesso — evitando publicação de eventos para transações que falharam.

#### Configuração LAB/AWS — Amazon SQS

```
Amazon SQS
  ├─ Região: us-east-1
  ├─ Serialização: Raw JSON (compatível com payloads enviados fora do MassTransit)
  ├─ Retry: 1s → 5s → 30s (+ 3 tentativas a cada 5s na fila)
  ├─ DiscardFaultedMessages: true  ← não cria fila _error automática
  └─ DiscardSkippedMessages: true
```

---

### Worker Doações — Consumer

**Arquivo:** `DonationWorker/Consumers/DonationCreatedEventConsumer.cs`

O consumer processa cada `DonationCreatedEvent` em **5 etapas ordenadas**, com rollback automático em caso de falha em qualquer etapa transacional:

```
1. Verifica se a campanha existe
     └─ ApplicationException se não encontrada → MassTransit retry

2. Valida se o valor é > 0
     └─ ApplicationException se inválido → MassTransit retry

3. Verifica idempotência pelo CorrelationId
     └─ ApplicationException se já processado → MassTransit retry
     └─ Garante que retries do broker não gerem doações duplicadas

4. Transação atômica no PostgreSQL
     ├─ BeginTransactionAsync()
     ├─ INSERT na tabela doacoes
     ├─ UPDATE campanhas SET valor_arrecadado = valor_arrecadado + @valor (atômico)
     ├─ CommitAsync() → sucesso
     └─ RollbackAsync() → qualquer falha

5. Publica DonationProcessedEvent
     └─ Apenas após commit bem-sucedido
     └─ Lança exceção se falhar → MassTransit retry (banco já commitado, idempotência garante não duplicar)
```

#### Métricas registradas

```csharp
_metrics.IncrementarDoacao();
_metrics.RegistrarDuracaoProcessamentoMensagem(nameof(DonationCreatedEvent), sucesso, elapsed);
```

O consumer registra métricas de negócio e performance via Prometheus a cada mensagem processada, incluindo tempo de processamento e flag de sucesso/falha.

---

### Idempotência

O consumer verifica o `CorrelationId` antes de processar qualquer mensagem. Se uma doação com o mesmo `CorrelationId` já existe no banco, a mensagem é descartada:

```
Cenário: Worker processa, commita no banco, cai antes de enviar ACK ao broker
  └─ RabbitMQ/SQS reenvia a mensagem
  └─ Consumer verifica: ObterPorCorrelationIdAsync(correlationId)
       └─ Doação já existe → lança ApplicationException → MassTransit descarta
       └─ Doação não existe → processa normalmente
```

O `CorrelationId` é gerado no microsserviço de Campanhas e incluído no evento — é o mesmo `x-correlation-id` da requisição HTTP original, garantindo rastreabilidade de ponta a ponta.

---

### Política de Retry

Configurada em dois níveis:

#### Nível 1 — MassTransit (transporte)

```csharp
cfg.UseMessageRetry(r => r.Intervals(
    TimeSpan.FromSeconds(1),   // 1ª tentativa após 1s
    TimeSpan.FromSeconds(5),   // 2ª tentativa após 5s
    TimeSpan.FromSeconds(30)   // 3ª tentativa após 30s
));
```

#### Nível 2 — Fila SQS (ambiente Cloud)

```csharp
e.UseMessageRetry(r => r.Interval(3, TimeSpan.FromSeconds(5)));
// 3 tentativas adicionais a cada 5s antes de ir para dead letter
```

Se todas as tentativas falharem, a mensagem vai para a **dead letter queue** do SQS ou para a fila `_error` do RabbitMQ para análise manual.

---

### Publicação de Eventos — IMessageService

**Arquivo:** `Infrastructure/Services/Messaging/MessageService.cs`

O `IMessageService` abstrai o transporte — o handler de aplicação chama sempre a mesma interface, sem saber se está publicando no RabbitMQ ou no SQS:

```csharp
// Campanhas publica a intenção de doação
await _messageService.SendDonationCreatedEventMessage(
    guidUser, nome, email, guidCampanha, tituloCampanha, cpfEncriptado, valor, ct);

// Worker publica confirmação de processamento
await _messageService.SendDonationProcessedEventMessage(
    guidUser, nome, email, guidCampanha, tituloCampanha, valor, correlationId, ct);
```

Internamente:

```
LOCAL  → IPublishEndpoint.Publish() → RabbitMQ via MassTransit
AWS    → IAmazonSQS.SendMessageAsync() → Amazon SQS (JSON raw)
```

---

### Filas

| Fila | Ambiente | Configuração | Finalidade |
|---|---|---|---|
| `user-created-queue` | LOCAL/AWS | Configurada via variável de ambiente `USER_CREATED_QUEUE` | Após a criação de um novo usuário, é consumida pelo microsserviço de notificações (local) ou SNS (AWS) e envia um e-mail para o usuário |
| `donation-created-queue` | LOCAL/AWS | Configurada via variável de ambiente `DONATION_CREATED_QUEUE` | Após a criação da intenção de doação, é consumida pelo Worker de doações, que grava a doação em bando de dados e atualiza o valor arrecadado da campanha |
| `donation-processed-queue` | LOCAL/AWS | Configurada via variável de ambiente `DONATION_PROCESSED_QUEUE` | É publicada após o processamento da doação e consumida pelo microsserviço de notificações (local) ou SNS (AWS) e envia um e-mail para o usuário |

---

## Benefícios

- ⚡ **Desacoplamento total** — o microsserviço de Campanhas não conhece o Worker Doações, apenas publica um evento e segue — o processamento acontece de forma assíncrona e independente

- 🔄 **Retry automático** — falhas transitórias (banco fora, rede instável) são retentadas automaticamente pelo MassTransit sem intervenção manual

- 🛡️ **Idempotência** — o `CorrelationId` garante que retries do broker nunca gerem doações duplicadas, mesmo em cenários de falha após commit

- 🔒 **Atomicidade** — o UPDATE do valor arrecadado da campanha é feito com SQL atômico (`SET valor = valor + @x`), seguro para múltiplos workers rodando em paralelo no Kubernetes sem race condition

- 🌍 **Multi-ambiente** — RabbitMQ local para desenvolvimento, Amazon SQS em produção, sem alterar código de negócio — apenas variável de ambiente

- 📊 **Observabilidade** — cada mensagem processada registra métricas de sucesso, falha e duração via Prometheus, permitindo monitoramento em tempo real no Grafana

- 🔑 **CPF protegido** — dados sensíveis trafegam encriptados com AES-256 nos eventos, nunca em texto plano no broker

- 🏗️ **Transação garantida** — INSERT de doação e UPDATE de campanha ocorrem na mesma transação PostgreSQL — ou os dois acontecem ou nenhum, sem estados inconsistentes


---

## Sistema de notificaçoes

O sistema de notificações foi criado para consumir eventos do broker de mensagens e enviar e-mails aos usuários de forma assíncrona e desacoplada. Nenhum microsserviço envia e-mail diretamente — toda comunicação por e-mail passa por um worker (local) ou pelo SNS (AWS)

```
Microsserviço Usuários
  └─ publica UserCreatedEvent
       └─ Worker Notificações → envia e-mail de boas-vindas

Worker Doações
  └─ publica DonationProcessedEvent
       └─ Worker Notificações → envia e-mail de confirmação de doação
```

---

### Eventos Consumidos

**Arquivo:** `Domain/Events/DomainEvents.cs`

| Evento | Fila | E-mail enviado |
|---|---|---|
| `UserCreatedEvent` | `user-created-queue` | Boas-vindas ao novo usuário |
| `DonationProcessedEvent` | `donation-processed-queue` | Confirmação de doação processada |

#### Estrutura dos eventos

```csharp
// Novo usuário cadastrado
record UserCreatedEvent(
    Guid guidUsuario,
    string nomeCompleto,
    string email,
    string cpf,           // ← encriptado AES-256
    string? correlationId);

// Doação persistida e campanha atualizada com sucesso
record DonationProcessedEvent(
    Guid guidUser,
    string nome,
    string email,
    Guid guidCampanha,
    string tituloCampanha,
    decimal valor,
    string? correlationId);
```

---

### Consumers (local)

#### UserCreatedEventConsumer

**Arquivo:** `Consumers/UserCreatedEventConsumer.cs`

Disparado quando um novo usuário se cadastra na plataforma. Envia um e-mail de boas-vindas com o CPF do usuário para confirmação do cadastro.

```
UserCreatedEvent recebido
  └─ EmailService.SendUserCreatedEmailAsync(nome, email, cpf)
       └─ E-mail HTML com boas-vindas e link para o site
```

#### DonationProcessedEventConsumer

**Arquivo:** `Consumers/DonationProcessedEventConsumer.cs`

Disparado pelo Worker de Doações após persistir a doação e atualizar o valor arrecadado da campanha. Envia a confirmação da doação ao doador.

```
DonationProcessedEvent recebido
  └─ EmailService.SendDonationProcessedEmailAsync(nome, email, tituloCampanha, valor)
       └─ E-mail HTML com campanha, valor e data da doação
```

---

### Transporte por Ambiente

| Ambiente | Broker | Serviço de E-mail |
|---|---|---|
| `LOCAL` | RabbitMQ | Mailpit (SMTP local — captura e-mails sem enviar) |
| `CLOUD` | Amazon SQS | Lambda + Mailtrap API (e-mails reais em sandbox) |

---

### Configuração LOCAL — RabbitMQ + Mailpit

**Arquivo:** `Infrastructure/Extensions/MessagingExtensions.cs`

O **Mailpit** captura todos os e-mails enviados e os exibe em uma interface web em `http://localhost:8025` — sem enviar nada de verdade. Ideal para desenvolvimento e testes.

#### Política de Retry — RabbitMQ

Dois níveis de retry garantem que falhas transitórias não perdem mensagens:

```
Nível 1 — MassTransit:
  Intervalos: 1s → 5s → 30s

Nível 2 — Por fila:
  3 tentativas a cada 5 segundos
```

Se todas as tentativas falharem, a mensagem vai para a fila `_error` do RabbitMQ para análise manual.

---

### Configuração AWS — SQS + Lambda + SNS + Mailtrap

Em produção, o worker de notificações é substituído por uma **AWS Lambda Python** que consome diretamente do SQS e usa a **API do Mailtrap** para envio de e-mails.

#### Filas SQS

| Fila | Propósito | Retenção | Visibility Timeout | Dead Letter |
|---|---|---|---|---|
| `user-created-queue` | Boas-vindas ao usuário | 1 dia | 60s | `user-created-dlq` |
| `donation-processed-queue` | Confirmação de doação | Padrão SQS | 60s | `donation-processed-dlq` |

Cada fila tem uma **Dead Letter Queue (DLQ)** — após `maxReceiveCount: 3` falhas, a mensagem é movida para a DLQ para investigação sem ser perdida.

#### Lambda de E-mail

**Runtime:** Python 3.9  
**Handler:** `email_sending.handler`  
**Timeout:** 30 segundos

```
SQS Event Source Mapping
  ├─ user-created-queue         → Lambda email_lambda (batch: 5)
  └─ donation-processed-queue   → Lambda email_lambda (batch: 5)
```

O `batch_size: 5` processa até 5 mensagens por invocação — balanceando throughput e custo.

O `ReportBatchItemFailures` permite que a Lambda reporte falhas parciais — se 3 de 5 mensagens falharem, apenas as 3 voltam para a fila, sem reprocessar as 2 que já foram enviadas com sucesso.

#### SNS para notificações operacionais

Um tópico SNS `email-notifications` permite que a Lambda publique os e-mails para um e-mail cadastrado para testes no ambiente AWS LAB. Essa foi a maneira encontrada para enviar os e-mails pois o serviço SES (Simple Email Service) não é disponível utilizando o LabRole.

```
Lambda → SNS topic (email-notifications) → e-mail do usuario (configuravel no terraform).
```

#### Variáveis de ambiente da Lambda - terraform

| Variável | Descrição |
|---|---|
| `SENDER_EMAIL` | E-mail remetente (`noreply@projeto.com`) |
| `SENDER_NAME` | Nome do remetente |
| `MAILTRAP_API_TOKEN` | Token de autenticação do Mailtrap |
| `MAILTRAP_INBOX_ID` | ID da caixa de entrada do Mailtrap |
| `SNS_TOPIC_ARN` | ARN do tópico SNS para notificações operacionais |

---

### Fluxo Completo por Evento

#### Novo usuário cadastrado

```
1. Usuário se cadastra via POST /api/v1/usuario
2. Microsserviço Usuários publica UserCreatedEvent no broker
3. [LOCAL]  RabbitMQ → UserCreatedEventConsumer → MailKit → Mailpit
   [AWS]    SQS → Lambda → Mailtrap API → e-mail real
4. Usuário recebe e-mail de boas-vindas com confirmação do CPF
```

#### Doação processada

```
1. Usuário registra doação via POST /api/v1/Doacoes
2. Microsserviço Campanhas publica DonationCreatedEvent
3. Worker Doações consome, persiste e publica DonationProcessedEvent
4. [LOCAL]  RabbitMQ → DonationProcessedEventConsumer → MailKit → Mailpit
   [AWS]    SQS → Lambda → Mailtrap API → e-mail real
5. Doador recebe e-mail de confirmação com campanha, valor e data
```

---

### Benefícios

- 📨 **Desacoplamento total** — microsserviços publicam eventos e esquecem; o worker cuida de quando e como o e-mail é enviado

- 🔄 **Retry automático** — falhas de SMTP ou rede são retentadas automaticamente sem intervenção manual, em dois níveis (MassTransit + fila)

- 💀 **Dead Letter Queue** — mensagens que falham repetidamente não são perdidas — ficam na DLQ para investigação e reprocessamento manual

- 🧪 **Ambiente local seguro** — Mailpit captura todos os e-mails sem enviar nada de verdade, permitindo testar fluxos completos sem risco de spam

- ⚡ **Processamento em batch** — Lambda processa até 5 mensagens por invocação com `ReportBatchItemFailures`, evitando reprocessamento desnecessário em falhas parciais

- 🏗️ **Infraestrutura como código** — todas as filas SQS, DLQs, Lambda e SNS são provisionados via Terraform, garantindo reproducibilidade entre ambientes

- 🔀 **Multi-ambiente** — RabbitMQ local e SQS em produção, sem alterar o código dos consumers — apenas configuração muda

---

## API Gateway

Documentação da camada de API Gateway adotada na plataforma Conexão Solidária. O sistema usa **dois gateways** conforme o ambiente:

| Ambiente | Gateway | Tecnologia |
|---|---|---|
| `LOCAL` | Gateway próprio | YARP (Yet Another Reverse Proxy) — .NET |
| `CLOUD` | Gateway gerenciado | AWS API Gateway v2 (HTTP API) |

---

### Gateway LOCAL — YARP

**Repositório:** `ES.ConexaoSolidaria.Gateway`

Implementado como uma aplicação .NET com **YARP** — biblioteca da Microsoft para reverse proxy de alta performance. É o único ponto de entrada para todos os microsserviços no ambiente local.

#### Pipeline de middlewares

```
Request
  └─ MetricsMiddleware       → expõe /metrics para Prometheus
       └─ HealthChecks       → /health/live e /health/ready
            └─ CORS          → valida origem (FrontendPolicy)
                 └─ RateLimiter → sliding window por IP
                      └─ Authentication → valida JWT
                           └─ Authorization → verifica política (public/authenticated)
                                └─ SwaggerProxy → proxy dos swagger.json dos microsserviços
                                     └─ YARP ReverseProxy → roteia para o microsserviço correto
                                          └─ LoadBalancing → distribui entre pods
```

---

#### 1. Autenticação e Autorização

**Arquivo:** `Extensions/AuthenticationExtension.cs`

O gateway valida o token JWT como **primeira linha de defesa**. Os microsserviços **também validam o token individualmente** — padrão de segurança conhecido como **Defense in Depth (Defesa em Profundidade)**:

```
Request
  └─ Gateway → valida JWT (1ª camada) ✅
       └─ Microsserviço → valida JWT novamente (2ª camada) ✅
```

Isso garante que mesmo que uma requisição consiga bypassar o gateway e chegar diretamente ao microsserviço via rede interna do cluster, o token ainda será exigido e validado — sem confiança implícita entre serviços.

```
Validações ativas em ambas as camadas:
  ✅ Chave de assinatura (HMAC SHA256)
  ✅ Issuer
  ✅ Audience
  ✅ Lifetime (expiração)
```

O overhead é mínimo — verificar uma assinatura HMAC SHA256 é uma operação criptográfica leve, imperceptível em produção.

Duas políticas de autorização controlam o acesso por rota no gateway:

| Política | Comportamento | Exemplos de rota |
|---|---|---|
| `public` | Qualquer requisição passa | Login, cadastro, listar campanhas |
| `authenticated` | Exige token JWT válido | Perfil, doações, gestão |

---

#### 2. Rate Limiting

**Arquivo:** `Extensions/RateLimitExtension.cs`

Dois limitadores de Sliding Window protegem a API contra abuso:

| Política | Limite | Janela | Uso |
|---|---|---|---|
| `default` | Configurável | Configurável | Todas as rotas |
| `login` | 10 requisições | 1 minuto | Rotas de autenticação — anti brute force |

```
Sliding Window com 6 segmentos:
  → distribui o limite uniformemente dentro da janela
  → mais justo que Fixed Window (evita burst no início do período)

QueueLimit = 10:
  → até 10 requisições ficam em fila aguardando slot disponível
  → além disso, retorna 429 Too Many Requests imediatamente
```

Resposta quando limite excedido:
```json
{
  "title": "Too Many Requests",
  "status": 429,
  "detail": "Limite de requisições excedido. Tente novamente em alguns instantes."
}
```

Configurável via variáveis de ambiente sem redeploy:
```yaml
RateLimiting__PermitLimit:   "100"
RateLimiting__WindowSeconds: "60"
```

---

### 3. Roteamento — YARP

**Arquivo:** `Extensions/ReverseProxyExtension.cs`

O roteamento é declarativo via `appsettings.json` — cada rota define o cluster de destino e a política de autorização:

```
Rota pública (sem token):
  campanhas-todas → GET /api/v1/Campanhas/todas → cs-campanhas-api

Rotas autenticadas:
  auth-publico    → /api/v1/auth/**         → cs-usuarios-api  (política: public)
  usuarios-cadastro → POST /api/v1/usuario  → cs-usuarios-api  (política: public)
  usuarios-autenticado → /api/v1/usuario/** → cs-usuarios-api  (política: authenticated)
  campanhas       → /api/v1/Campanhas/**    → cs-campanhas-api (política: authenticated)
  doacoes         → /api/v1/Doacoes/**      → cs-campanhas-api (política: authenticated)
```

Cada microsserviço é um `ClusterIP` do Kubernetes — acessível apenas internamente, nunca exposto diretamente:

```
Internet
  └─ Gateway (único ponto de entrada público)
       ├─ cs-usuarios-api:8080   (ClusterIP — interno)
       └─ cs-campanhas-api:8080  (ClusterIP — interno)
```

Load balancing entre pods é feito automaticamente via `UseLoadBalancing()` — o YARP distribui requisições entre todas as réplicas disponíveis:

```csharp
app.MapReverseProxy(proxyPipeline =>
{
    proxyPipeline.UseRateLimiter();
    proxyPipeline.UseLoadBalancing();  // ← distribui entre pods
});
```

---

#### 4. CORS

**Arquivo:** `Extensions/CorsExtension.cs`

Configurado para aceitar requisições apenas da URL do frontend — impede que outros domínios chamem a API diretamente:

```csharp
policy.WithOrigins(frontendUrl)  // ← apenas o frontend autorizado
      .AllowAnyMethod()
      .AllowAnyHeader();
```

```yaml
FRONTEND_URL: "https://www.conexaosolidaria.com.br"
```

---

#### 5. Swagger Proxy

**Arquivo:** `Extensions/SwaggerExtension.cs`

O Swagger UI do gateway agrega a documentação de todos os microsserviços em uma única interface. Como os microsserviços são internos (ClusterIP), o browser não consegue acessar seus `swagger.json` diretamente — o gateway faz o proxy:

```
Browser → GET /swagger-proxy/campanhas
  └─ Gateway busca internamente: http://cs-campanhas-api:8080/swagger/v1/swagger.json
  └─ Substitui o campo "servers" pelo host do gateway (URL dinâmica do request)
  └─ Remove rotas /private/ do documento
  └─ Retorna o JSON modificado ao browser
```

O token JWT é persistido no Swagger UI (`persistAuthorization: true`) — uma vez autenticado, o token é mantido entre as requisições sem precisar reinserir.

---

#### Health Checks

Dois endpoints de health check seguindo o padrão Kubernetes:

| Endpoint | Uso |
|---|---|
| `/health/live` | Liveness Probe — o pod está vivo? |
| `/health/ready` | Readiness Probe — o pod está pronto para receber tráfego? |

---

### Gateway AWS — API Gateway v2 (HTTP API)

**Arquivo:** `terraform/modules/apigateway/main.tf`

Em produção, o gateway próprio (YARP) é substituído pelo **AWS API Gateway v2** gerenciado — reduzindo operação e aproveitando a infraestrutura da AWS.

### Arquitetura

```
Internet
  └─ AWS API Gateway v2 (HTTP API)
       └─ VPC Link (conexão privada à VPC)
            └─ Network Load Balancer (NLB)
                 ├─ EKS Node — cs-usuarios-api (porta 5001)
                 └─ EKS Node — cs-campanhas-api (porta 5002)
```

O **VPC Link** é o componente crítico — permite que o API Gateway se comunique com serviços dentro da VPC privada sem expô-los à internet. Os microsserviços continuam inacessíveis publicamente.

---

#### CORS no AWS API Gateway

Configurado diretamente no recurso Terraform:

```hcl
cors_configuration {
  allow_origins     = [var.frontend_url]
  allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
  allow_headers     = ["Content-Type", "Authorization", "Accept"]
  expose_headers    = ["*"]
  allow_credentials = true
  max_age           = 300  # 5 minutos de cache do preflight
}
```

O `OPTIONS` (preflight) não tem rota explícita — é interceptado automaticamente pelo `cors_configuration`, respondendo sem chegar ao microsserviço.

---

#### Roteamento no AWS API Gateway

Cada rota define método HTTP + path e aponta para uma integração (microsserviço):

```
Usuários API (porta 5001):
  POST   /api/v1/auth/{proxy+}       → usuarios-integration
  GET    /api/v1/usuario             → usuarios-integration
  POST   /api/v1/usuario             → usuarios-integration
  GET    /api/v1/usuario/{proxy+}    → usuarios-integration
  PUT    /api/v1/usuario/{proxy+}    → usuarios-integration
  DELETE /api/v1/usuario/{proxy+}    → usuarios-integration

Campanhas API (porta 5002):
  GET    /api/v1/Campanhas           → campanhas-integration
  POST   /api/v1/Campanhas           → campanhas-integration
  GET    /api/v1/Campanhas/{proxy+}  → campanhas-integration
  ...
  GET    /api/v1/Doacoes/{proxy+}    → campanhas-integration  ← Doações são do ms de Campanhas
  POST   /api/v1/Doacoes/{proxy+}    → campanhas-integration
```

---

#### URLs para acesso
TODO

---

#### Rate Limiting no AWS API Gateway

Configurado no Stage via Terraform:

```hcl
default_route_settings {
  throttling_rate_limit  = var.rate_limit_rate   # requisições por segundo sustentadas
  throttling_burst_limit = var.rate_limit_burst  # burst máximo
}
```

O AWS API Gateway retorna `429 Too Many Requests` automaticamente quando os limites são excedidos — sem código adicional.

---

#### Logs — CloudWatch

Cada requisição é registrada no CloudWatch com informações estruturadas:

```json
{
  "requestId": "abc-123",
  "ip": "203.0.113.1",
  "requestTime": "25/Jun/2026:14:00:00",
  "httpMethod": "POST",
  "routeKey": "POST /api/v1/auth/login",
  "status": "200",
  "responseLength": "512",
  "integrationError": null
}
```

Retenção: **7 dias** — configurável via Terraform.

---

### Comparação entre os dois gateways

| Funcionalidade | YARP (LOCAL) | AWS API Gateway v2 |
|---|---|---|
| **Autenticação JWT** | ✅ Gateway + cada microsserviço (Defense in Depth) | ✅ Gateway + cada microsserviço (Defense in Depth) |
| **Rate Limiting** | ✅ Sliding Window configurável | ✅ Rate/Burst por stage |
| **CORS** | ✅ Por origem | ✅ Por origem com preflight automático |
| **Roteamento** | ✅ appsettings.json | ✅ Terraform declarativo |
| **Load Balancing** | ✅ Entre pods via YARP | ✅ Via NLB |
| **Swagger UI** | ✅ Agregado com proxy | ❌ Não disponível em produção |
| **Operação** | Manual (pod no EKS) | Gerenciado pela AWS |

<BR>
TODO - Verificar telas de gateway swagger no AWS


---

### Benefícios

- 🔒 **Único ponto de entrada** — nenhum microsserviço é acessível diretamente da internet, independente do ambiente

- 🛡️ **Autenticação centralizada** — JWT validado no gateway antes de chegar a qualquer microsserviço, sem duplicar lógica de autenticação

- ⚡ **Rate limiting anti-abuso** — proteção contra brute force no login e DDoS em todas as rotas, com resposta padronizada 429

- 🌍 **CORS gerenciado** — frontend autorizado explicitamente, sem configuração duplicada em cada microsserviço

- 🔄 **Portabilidade** — mesma interface de API para o frontend em qualquer ambiente, o gateway abstrai onde os microsserviços estão rodando

- 🏗️ **Infrastructure as Code** — o AWS API Gateway é 100% provisionado via Terraform, garantindo reproducibilidade e histórico de mudanças

---

## Proxy PostGreSql - Dynamo

O Grafana suporta DynamoDB nativamente apenas via plugin pago. As tabelas de logs da plataforma (`cs-audit-log` e `cs-app-logs`) ficam no DynamoDB — inacessíveis pelo Grafana sem custo adicional.  Por esse motivo, criamos um proxy postgres - dynamo que **implementa o protocolo wire do PostgreSQL** e traduz queries SQL em operações de `Scan` no DynamoDB:

```
Grafana (datasource PostgreSQL)
  └─ conecta em cs-dynamo-pg-proxy:5450
       └─ envia SQL: SELECT * FROM audit_log WHERE operation = 'ADDED'
            └─ proxy traduz para DynamoDB Scan com FilterExpression
                 └─ retorna resultado no formato de tabela PostgreSQL
                      └─ Grafana exibe como se fosse um banco relacional
```

Para o Grafana, é um banco PostgreSQL comum. Para o DynamoDB, é um cliente boto3. O proxy faz a tradução no meio.

---

### Arquitetura

**Arquivo:** `pg_dynamo_proxy.py` — ~450 linhas de Python puro, sem framework web.

```
┌─────────────────────────────────────────────────────┐
│              DynamoDB PG Proxy (Python)             │
│                                                     │
│  TCP :5450 ──► PostgreSQL Wire Protocol v3         │
│                    │                                │
│              SQL Parser                             │
│                    │                                │
│         ┌──────────┴──────────┐                    │
│         ▼                     ▼                     │
│    audit_log            app_logs                    │
│    (cs-audit-log)       (cs-app-logs)               │
│         │                     │                     │
│         └──────────┬──────────┘                    │
│                    ▼                                │
│            boto3 DynamoDB Scan                      │
└─────────────────────────────────────────────────────┘
```

---

### Tabelas Disponíveis

#### `audit_log` → `cs-audit-log` (DynamoDB)

| Coluna SQL | Campo DynamoDB | Tipo | Descrição |
|---|---|---|---|
| `timestamp` | `SK` | text | Data/hora (prefixo `TS#` removido automaticamente) |
| `service` | `ServiceName` | text | Microsserviço que realizou a operação |
| `operation` | `Operation` | text | `ADDED`, `MODIFIED`, `DELETED` |
| `changed_by` | `ChangedBy` | text | E-mail do responsável |
| `resource_id` | `ResourceId` | text | GUID da entidade alterada |
| `ip_address` | `IpAddress` | text | IP de origem |
| `pk` | `PK` | text | Chave primária composta |
| `payload` | `Payload` | text | JSON com dados da operação (diff) |

#### `app_logs` → `cs-app-logs` (DynamoDB)

| Coluna SQL | Campo DynamoDB | Tipo | Descrição |
|---|---|---|---|
| `timestamp` | `Timestamp` | text | Data/hora ISO 8601 |
| `level` | `LogLevel` | text | `Information`, `Warning`, `Error` |
| `caller` | `Caller` | text | Classe que gerou o log |
| `message` | `Message` | text | Mensagem do log |
| `correlation_id` | `CorrelationId` | text | ID de rastreamento da requisição |
| `data` | `Data` | text | Payload JSON contextual |
| `type` | `Type` | int | `1` = LOG, `2` = EVENT |

---

### SQL Suportado

O proxy implementa um parser SQL que suporta as operações mais comuns usadas pelo Grafana:

#### SELECT

```sql
-- Todas as colunas
SELECT * FROM audit_log

-- Colunas específicas
SELECT timestamp, service, operation, changed_by FROM audit_log

-- Com filtro
SELECT * FROM app_logs WHERE level = 'Error'

-- Com LIKE (traduzido para contains() no DynamoDB)
SELECT * FROM app_logs WHERE message LIKE '%doacao%'

-- Com BETWEEN
SELECT * FROM audit_log WHERE timestamp BETWEEN '2026-06-01' AND '2026-06-30'

-- Com LIMIT
SELECT * FROM app_logs LIMIT 100

-- Com ORDER BY (ordenação aplicada após o Scan)
SELECT * FROM audit_log WHERE operation = 'MODIFIED' ORDER BY timestamp DESC
```

#### SELECT DISTINCT

```sql
-- Usado pelo Grafana para popular variáveis de template
SELECT DISTINCT service FROM audit_log
SELECT DISTINCT level FROM app_logs
SELECT DISTINCT operation FROM audit_log
```

#### COUNT

```sql
SELECT COUNT(*) AS total FROM audit_log
SELECT COUNT(*) AS total FROM app_logs WHERE level = 'Error'
```

#### Queries de sistema (respondidas localmente)

```sql
SELECT 1                    -- health check do Grafana
SELECT version()            -- versão do "PostgreSQL"
SELECT current_schema()     -- schema atual
SELECT current_database()   -- banco atual
SELECT * FROM information_schema.tables   -- lista as tabelas disponíveis
SELECT * FROM information_schema.columns  -- colunas de uma tabela
```

#### Macros do Grafana (ignoradas graciosamente)

```sql
-- Macros de tempo são substituídas por 1=1 (sem filtro)
$__timeFilter(timestamp)
$__timeGroup(timestamp, '1h')
```

---

### Protocolo PostgreSQL Wire v3

O proxy implementa manualmente as mensagens do protocolo PostgreSQL necessárias para o Grafana funcionar:

| Mensagem | Tipo | Descrição |
|---|---|---|
| `AuthenticationOk` | `R` | Aceita conexão sem senha |
| `ParameterStatus` | `S` | Informa server_version, encoding, etc |
| `ReadyForQuery` | `Z` | Pronto para receber query |
| `RowDescription` | `T` | Schema das colunas do resultado |
| `DataRow` | `D` | Uma linha de dados |
| `CommandComplete` | `C` | Fim da query com contagem de linhas |
| `ErrorResponse` | `E` | Erro com código SQL |
| Simple Query | `Q` | Query SQL simples |
| Parse/Bind/Execute | `P/B/E` | Prepared statements (aceitos, sem execução real) |

---

### Infraestrutura

**Runtime:** Python 3.12 Alpine  
**Dependência:** apenas `boto3==1.34.0`  
**Imagem:** ~50MB (Alpine + Python + boto3)  
**Porta:** 5450 (diferente da 5432 padrão para não conflitar com PostgreSQL real)

---

### Benefícios

- 💰 **Zero custo adicional** — elimina a necessidade do plugin pago do Grafana para DynamoDB, usando o datasource PostgreSQL nativo que já está disponível

- 🔌 **Transparente para o Grafana** — nenhuma configuração especial no Grafana além do datasource PostgreSQL — dashboards, variáveis e alertas funcionam normalmente

- 🪶 **Leve** — ~450 linhas de Python puro, sem framework web, sem ORM, sem dependências além do boto3

- 🔄 **Paginação automática** — o proxy pagina o DynamoDB Scan automaticamente, retornando todos os registros independente do volume

- 🛠️ **Multi-ambiente** — conecta ao DynamoDB Local em desenvolvimento e ao DynamoDB real da AWS em produção, apenas mudando variáveis de ambiente


---
## Frontend

O frontend é uma **SPA (Single Page Application)** que roda completamente no browser, sem dependência de servidor para renderização. Toda a comunicação com o backend é feita via HTTP diretamente para o **API Gateway** e foi desenvolvido em **Blazor WebAssembly** com **MudBlazor** como biblioteca de componentes.

```
Browser
  └─ Blazor WebAssembly (.NET 8)
       └─ HttpClient → API Gateway
            ├─ cs-usuarios-api
            ├─ cs-campanhas-api
            └─ cs-campanhas-api (doações)
```

---

### Stack

| Tecnologia | Versão | Finalidade |
|---|---|---|
| **Blazor WebAssembly** | .NET 8 | Framework SPA em C# |
| **MudBlazor** | 9.5.0 | Componentes UI (Material Design) |
| **Blazored.LocalStorage** | 4.5.0 | Persistência do token JWT no browser |
| **System.IdentityModel.Tokens.Jwt** | 8.0.2 | Leitura de claims do JWT no cliente |
| **Bootstrap** | 5 | Grid e utilitários CSS complementares |
| **Nginx** | Alpine | Servidor de arquivos estáticos em produção |

---

### Estrutura de Páginas

#### Área Pública (sem autenticação)

| Página | Rota | Descrição |
|---|---|---|
| `LandingPage` | `/` | Página inicial com hero, números de impacto, campanhas ativas e footer |
| `Login` | `/login` | Formulário de autenticação com suporte a `returnUrl` |
| `CadastroDoador` | `/cadastro` | Cadastro de novo usuário doador |

#### Portal do Doador (requer autenticação)

| Página | Rota | Descrição |
|---|---|---|
| `Campanhas` | `/campanhas` | Listagem de campanhas ativas com cards |
| `NovaDoacao` | `/doacoes/nova` | Formulário de doação com comprovante de sucesso |
| `MinhasDoacoes` | `/minhas-doacoes` | Histórico de doações do doador logado |
| `Perfil` | `/perfil` | Dados do usuário com edição de nome, CPF e senha |

#### Área Administrativa (requer perfil `GESTOR_ONG`)

| Página | Rota | Descrição |
|---|---|---|
| `GerenciamentoCampanhas` | `/admin/campanhas` | Criar, buscar, editar, cancelar e concluir campanhas |
| `AdminUsuarios` | `/admin/usuarios` | Buscar usuários por e-mail, suspender, ativar e alterar perfil |
| `DoacoesPorCampanha` | `/admin/doacoes/campanha` | Relatório de doações por campanha |
| `DoacoesPorUsuario` | `/admin/doacoes/usuario` | Relatório de doações por usuário |

---

### Autenticação — JwtAuthStateProvider

**Arquivo:** `Auth/JwtAuthStateProvider.cs`

O estado de autenticação do Blazor é gerenciado pelo `JwtAuthStateProvider`, que implementa o `AuthenticationStateProvider` nativo. Não usa cookies — o token JWT é persistido no **localStorage** do browser via Blazored.LocalStorage.

```
Login bem-sucedido
  └─ AuthService chama POST /api/v1/auth/login
       └─ Recebe token JWT
       └─ Extrai perfil e expiração diretamente do JWT (mais confiável que o campo da API)
       └─ Salva no localStorage:
            ├─ "cs_token"   → string JWT
            └─ "cs_usuario" → objeto UsuarioLogado (guid, email, perfil, status, expiração)
       └─ Notifica o Blazor da mudança de estado → componentes reagem automaticamente
```

#### Verificação de expiração

A cada `GetAuthenticationStateAsync()`, o provider verifica se o token já expirou:

```csharp
if (usuario.Expiracao <= DateTime.UtcNow)
{
    // limpa localStorage — token obsoleto
    await _localStorage.RemoveItemAsync(TokenKey);
    await _localStorage.RemoveItemAsync(UsuarioKey);
    return _anonimo;  // usuário vira anônimo automaticamente
}
```

#### Claims disponíveis nos componentes

```csharp
ClaimTypes.NameIdentifier  // GUID do usuário
ClaimTypes.Email           // e-mail
ClaimTypes.Role            // DOADOR ou GESTOR_ONG
"status"                   // ACTIVE, SUSPENDED
```

#### Proteção de rotas

```razor
@attribute [Authorize]                        // qualquer usuário autenticado
@attribute [Authorize(Roles = "GESTOR_ONG")]  // apenas gestores
```

Usuários não autenticados são redirecionados para `/login` automaticamente pelo `RedirectToLogin` shared component.

---

### Serviços

#### AuthService

**Arquivo:** `Services/AuthService.cs`

Responsável por todas as operações de autenticação:

| Método | Endpoint | Autenticação |
|---|---|---|
| `LoginAsync` | `POST /api/v1/auth/login` | Pública |
| `LogoutAsync` | `POST /api/v1/auth/logout` | Bearer token |
| `CadastrarDoadorAsync` | `POST /api/v1/usuario` | Pública |
| `AlterarSenhaAsync` | `PUT /api/v1/auth/reset-password` | Bearer token |

#### CampanhaPublicaService

**Arquivo:** `Services/CampanhaPublicaService.cs`

Consome a rota pública de campanhas — **não exige token**, usada tanto na landing page quanto no portal autenticado:

```csharp
// Busca campanhas ativas com paginação
GET /api/v1/Campanhas/todas?Pagina=1&TamanhoPagina=6
```

#### CampanhaAdminService

**Arquivo:** `Services/CampanhaAdminService.cs`

Consome todas as rotas autenticadas de campanhas para o gestor:

| Método | Endpoint |
|---|---|
| `CriarAsync` | `POST /api/v1/Campanhas` |
| `BuscarAsync` | `GET /api/v1/Campanhas/busca?Termo=` |
| `ObterPorGuidAsync` | `GET /api/v1/Campanhas?Guid=` |
| `AlterarAsync` | `PUT /api/v1/Campanhas` |
| `CancelarAsync` | `PUT /api/v1/Campanhas/cancel?Guid=` |
| `ConcluirAsync` | `PUT /api/v1/Campanhas/concluir?Guid=` |

#### DoacaoService

**Arquivo:** `Services/DoacaoService.cs`

| Método | Endpoint | Descrição |
|---|---|---|
| `CriarDoacaoAsync` | `POST /api/v1/Doacoes` | Registra nova doação |
| `ObterMinhasDoacoesAsync` | `GET /api/v1/Doacoes/self` | Doações do usuário logado |
| `ObterPorCampanhaAsync` | `GET /api/v1/Doacoes/campanha?GuidCampanha=` | Relatório admin por campanha |
| `ObterPorUsuarioAsync` | `GET /api/v1/Doacoes/usuario?Email=` | Relatório admin por usuário |

#### UsuarioService

**Arquivo:** `Services/UsuarioService.cs`

| Método | Endpoint | Perfil |
|---|---|---|
| `ObterPorEmailAsync` | `GET /api/v1/usuario?Email=` | DOADOR / GESTOR_ONG |
| `AlterarAsync` | `PUT /api/v1/usuario/alterar` | DOADOR / GESTOR_ONG |
| `ExcluirAsync` | `DELETE /api/v1/usuario?Email=` | DOADOR (própria conta) |
| `SuspenderAsync` | `PUT /api/v1/usuario/suspender` | GESTOR_ONG |
| `AtivarAsync` | `PUT /api/v1/usuario/ativar` | GESTOR_ONG |
| `AlterarParaGestorAsync` | `PUT /api/v1/usuario/alterar-para-gestor` | GESTOR_ONG |
| `AlterarParaDoadorAsync` | `PUT /api/v1/usuario/alterar-para-doador` | GESTOR_ONG |

---

### Layouts

| Layout | Usado em | Descrição |
|---|---|---|
| `LandingLayout` | Landing page | Sem sidebar, header público com botões Login/Cadastrar |
| `EmptyLayout` | Login, Cadastro | Página limpa, sem navegação |
| `MainLayout` | Portal e Admin | Sidebar com NavMenu, área de conteúdo principal |

---

### Modelo de Dados — CampanhaCard

O componente `CampanhaCard` exibe uma campanha com barra de progresso e calcula automaticamente:

```csharp
// Percentual arrecadado (máximo 100%)
public decimal PercentualArrecadado =>
    MetaFinanceira > 0
        ? Math.Min(Math.Round(ValorArrecadado / MetaFinanceira * 100, 1), 100)
        : 0;

// Dias restantes até o fim da campanha
public int DiasRestantes =>
    DateTime.TryParse(DataFim, out var fim)
        ? Math.Max((int)(fim - DateTime.UtcNow).TotalDays, 0)
        : 0;
```

---

### Configuração

#### GatewayUrl

O frontend se conecta exclusivamente ao API Gateway — nunca aos microsserviços diretamente. A URL é configurada via `appsettings.json` injetado no build:

```json
{
  "GatewayUrl": "${GATEWAY_URL}"
}
```

A variável `${GATEWAY_URL}` é substituída pelo `entrypoint.sh` em tempo de execução do container:

```bash
# entrypoint.sh — substitui a variável no arquivo antes de iniciar o Nginx
sed -i "s|\${GATEWAY_URL}|${GATEWAY_URL}|g" /usr/share/nginx/html/appsettings.json
```

#### docker-compose (LOCAL)

```yaml
cs.frontend:
  environment:
    GATEWAY_URL: "http://localhost:5000"  # URL do gateway YARP local
```

#### Kubernetes (AWS)

```yaml
env:
  - name: GATEWAY_URL
    value: "https://api.conexaosolidaria.com.br"  # URL do AWS API Gateway
```

---

## Benefícios

- 🌐 **SPA em C#** — toda a lógica do frontend em C#, sem trocar de linguagem em relação ao backend, facilitando o compartilhamento de modelos e convenções

- 🔒 **Autenticação stateless** — JWT no localStorage com verificação de expiração automática, sem cookies, sem sessão de servidor

- 🎨 **MudBlazor** — biblioteca de componentes Material Design completa, com grid responsivo, formulários, tabelas, dialogs e progress bars prontos

- 🔑 **Autorização por perfil** — `[Authorize(Roles = "GESTOR_ONG")]` protege rotas administrativas diretamente na declaração da página, sem lógica adicional

- ⚡ **Rota pública de campanhas** — a landing page carrega campanhas ativas sem exigir login, melhorando a conversão de novos doadores

- 🏗️ **Gateway único** — o frontend conhece apenas a URL do gateway, sem hardcode de endpoints de microsserviços — mudanças de infraestrutura são transparentes

- 📦 **Deploy simples** — build gera arquivos estáticos servidos pelo Nginx; sem processo Node.js, sem SSR, sem servidor de aplicação

- 🔧 **Configuração em runtime** — `GatewayUrl` injetada pelo `entrypoint.sh` permite usar a mesma imagem Docker em qualquer ambiente apenas mudando a variável de ambiente

---

## Observabilidade

A plataforma utiliza três ferramentas complementares de observabilidade, todas provisionadas via Kubernetes e com dashboards pré-configurados no Grafana, cobrindo métricas de negócio, métricas de infraestrutura, logs-traces e auditoria.

```
┌─────────────────────────────────────────────────────────────┐
│                        GRAFANA                              │
│   Prometheus  │  Zabbix  │  DynamoDB-PG Proxy              │
└───────┬───────┴─────┬────┴──────────┬──────────────────────┘
        │             │               │
   Métricas      Infraestrutura   Logs / Auditoria
   de negócio    do servidor      (DynamoDB)
   (.NET/HTTP)   (CPU/RAM/Disco)
        │
   /metrics (prometheus-net)
   ├─ cs-usuarios-api
   ├─ cs-campanhas-api
   └─ cs-donationworker
```

---

### 1. Prometheus — Métricas de Aplicação

**Imagem:** `prom/prometheus:v2.53.0`  
**Retenção:** 15 dias  
**Porta:** 9090

#### Scrape targets

| Job | Target | Intervalo |
|---|---|---|
| `usuarios-api` | `cs-usuarios-api-svc:5001/metrics` | 10s |
| `campanhas-api` | `cs-campanhas-api-svc:5002/metrics` | 10s |
| `donationworker` | `cs-donationworker-api-svc:5003/metrics` | 10s |
| `prometheus` | `cs-prometheus-svc:9090` | 15s |

#### Métricas customizadas — prometheus-net

Cada microsserviço implementa `IMetricsService` com métricas específicas de negócio expostas em `/metrics`:

**Usuários API**

| Métrica | Tipo | Descrição |
|---|---|---|
| `usuarios_login_total` | Counter | Logins realizados com sucesso |
| `usuarios_logout_total` | Counter | Logouts realizados |
| `usuarios_criados_total` | Counter | Novos usuários cadastrados |
| `usuarios_removidos_total` | Counter | Usuários removidos (LGPD) |
| `http_request_duration_seconds` | Histogram | Latência HTTP por método, rota e status code |

**Campanhas API**

| Métrica | Tipo | Descrição |
|---|---|---|
| `campanhas_criadas_total` | Counter | Campanhas criadas |
| `campahas_concluidas_total` | Counter | Campanhas concluídas |
| `campanhas_canceladas_total` | Counter | Campanhas canceladas |
| `campanha_intencoes_total` | Counter | Intenções de doação registradas |
| `http_request_duration_seconds` | Histogram | Latência HTTP |

**Worker de Doações**

| Métrica | Tipo | Descrição |
|---|---|---|
| `donation_worker_doacoes_total` | Counter | Doações processadas com sucesso |
| `donation_worker_processing_duration_seconds` | Histogram | Tempo de processamento por tipo de evento |

#### Histograma de latência

Buckets calibrados para APIs REST:

```
0.005s | 0.01s | 0.025s | 0.05s | 0.075s | 0.1s | 0.25s | 0.5s | 0.75s | 1.0s | 2.5s | 5.0s
```

Labels: `method`, `route`, `status_code` — permite filtrar por rota específica no Grafana.

---

### 2. Grafana — Dashboards

**Imagem:** `grafana/grafana:11.1.0`  
**Porta:** 3000  
**Plugin:** `alexanderzobnin-zabbix-app 4.4.5`

Todos os dashboards são provisionados automaticamente via ConfigMap no Kubernetes — sem configuração manual após o deploy.

#### Datasources configurados

| Datasource | Tipo | URL | Uso |
|---|---|---|---|
| `Prometheus` | prometheus | `cs-prometheus-svc:9090` | Métricas de aplicação e runtime |
| `Zabbix` | alexanderzobnin-zabbix-datasource | `cs-zabbix-svc/api_jsonrpc.php` | Infraestrutura do servidor |
| `DynamoDB-PG` | postgres | `cs-dynamo-pg-proxy-svc:5450` | Logs e auditoria do DynamoDB |

#### Dashboards disponíveis

**ConexaoSolidaria — Usuarios API**

| Painel | Métrica |
|---|---|
| CPU — Uso do Processo | `process_cpu_seconds_total` |
| Memória — Heap .NET | `dotnet_total_memory_bytes` |
| Handles Abertos | `process_open_handles` |
| Requisições HTTP/s | `http_request_duration_seconds_count` |
| Logins por Minuto | `usuarios_login_total` |
| Logouts por Minuto | `usuarios_logout_total` |
| Novos Usuários (acumulado) | `usuarios_criados_total` |
| Usuários Removidos (acumulado) | `usuarios_removidos_total` |
| Latência p90 / p95 / p99 | `http_request_duration_seconds` |
| Latência Média por Rota | `http_request_duration_seconds` (label `route`) |
| Threads em Uso | `dotnet_threadpool_threads_total` |
| GC Collections | `dotnet_collection_count_total` |

**ConexaoSolidaria — Campanhas API**

| Painel | Métrica |
|---|---|
| CPU / Memória / Handles | Runtime .NET |
| Requisições HTTP/s | `http_request_duration_seconds_count` |
| Campanhas Criadas | `campanhas_criadas_total` |
| Campanhas Concluídas | `campahas_concluidas_total` |
| Campanhas Canceladas | `campanhas_canceladas_total` |
| Intenções de Doação | `campanha_intencoes_total` |
| Latência p90 / p95 / p99 | Histograma HTTP |
| Threads / GC | Runtime .NET |

**ConexaoSolidaria — Worker Doacoes**

| Painel | Métrica |
|---|---|
| CPU / Memória / Handles | Runtime .NET |
| Mensagens Processadas/s | `donation_worker_processing_duration_seconds_count` |
| Doações (acumulado) | `donation_worker_doacoes_total` |
| Latência de Processamento p90/p95/p99 | `donation_worker_processing_duration_seconds` |
| Latência Média por Evento | label `event_type` |
| Threads / GC | Runtime .NET |

**Application Logs — Traces** ← via DynamoDB-PG Proxy (`cs-app-logs`)

O dashboard de Application Logs funciona como um **sistema de tracing distribuído** — o `CorrelationId` percorre toda a cadeia de processamento de uma requisição e permite reconstruir o trace completo atravessando múltiplos microsserviços:

**Uso como trace:** basta colar um `x-correlation-id` retornado no header de qualquer resposta HTTP no filtro `Correlation ID (Trace)` e o dashboard exibe toda a sequência de logs daquela requisição em ordem cronológica:<br>

<img width="2415" height="383" alt="image" src="https://github.com/user-attachments/assets/13d02808-a1c1-4343-a181-87f8e5ca9bf0" />
<br>

**Audit Log — DynamoDB** ← via DynamoDB-PG Proxy (`cs-audit-log`)

Visualização da trilha de auditoria de todas as operações no banco de dados PostgreSQL, capturadas automaticamente pelo `AuditInterceptor`: <br>
<img width="3147" height="469" alt="image" src="https://github.com/user-attachments/assets/cd56621f-f4c0-4ec1-ae96-6ac7bde30e07" />
<br>


---

### 3. Zabbix — Monitoramento de Infraestrutura

**Imagem:** `zabbix/zabbix-appliance:alpine-latest`  
**Porta:** 80 (UI) / 10051 (trapper)  
**Agente:** `zabbix/zabbix-agent:alpine-latest`

Monitora métricas de infraestrutura do servidor onde o Kubernetes está rodando:

- CPU,
- memória,
- carga,
- disponibilidade de agente,
- uptime do servidor 

<img width="3098" height="826" alt="image" src="https://github.com/user-attachments/assets/7fcd4bdb-b8bb-4fba-8d81-a07fb11f0185" />
<br>

Um **Job Kubernetes** (`cs-zabbix-init`) configura automaticamente o host e o dashboard via API JSON-RPC do Zabbix na primeira inicialização — sem configuração manual.

O dashboard do Zabbix é integrado ao Grafana via plugin `alexanderzobnin-zabbix-app`, centralizando toda a observabilidade em uma única interface.

---

#### Alertas
Configurados os seguintes alertas na observabilidade:
- Memory exceeding 80%
- CPU exceeding 50%
- Disk exceeding 50%
- Doacoes acima de 3

<img width="3112" height="697" alt="image" src="https://github.com/user-attachments/assets/30204225-88e7-4391-8192-aa939f64b6db" />
<br>

---

### Arquitetura no Kubernetes

```
ConfigMap cs-observability-config
  ├─ prometheus.yml         → configuração do Prometheus
  ├─ grafana_datasource_prometheus.yml → datasources (Prometheus, Zabbix, DynamoDB-PG)
  └─ dashboards.yml         → provider de dashboards

ConfigMaps de dashboards (um por dashboard)
  ├─ cs-grafana-user-dash
  ├─ cs-grafana-campaign-dash
  ├─ cs-grafana-donation-dash
  ├─ cs-grafana-zabbix-dash
  ├─ cs-grafana-app-logs-dash
  └─ cs-grafana-audit-log-dash
```

Todos os ConfigMaps são montados como volumes no pod do Grafana — os dashboards ficam disponíveis automaticamente sem nenhuma importação manual.

---

### Benefícios

- 📈 **Métricas de negócio + infraestrutura** — além das métricas técnicas (CPU, memória, latência), o sistema rastreia eventos de negócio como logins, campanhas criadas e doações processadas — permitindo correlacionar comportamento do sistema com comportamento do usuário

- 🔍 **Rastreamento por Correlation ID** — o dashboard de Application Logs permite colar um `x-correlation-id` e ver todos os logs daquela requisição em ordem cronológica, atravessando múltiplos microsserviços

- 🏗️ **Provisionamento automático** — dashboards, datasources e configurações são provisionados via ConfigMap no Kubernetes — zero configuração manual após o deploy

- ⏱️ **Percentis de latência** — histogramas com p90, p95 e p99 por rota identificam gargalos específicos, indo além da média que pode mascarar outliers

- 🔄 **Retenção configurável** — Prometheus retém 15 dias de métricas com `--storage.tsdb.retention.time=15d` e suporte a reload via `--web.enable-lifecycle`

- 🌐 **Observabilidade unificada** — Grafana centraliza três fontes distintas (Prometheus, Zabbix, DynamoDB) em uma única interface, sem precisar alternar entre ferramentas

- 💰 **DynamoDB-PG Proxy** — elimina o custo do plugin pago do Grafana para DynamoDB, usando o datasource PostgreSQL nativo para consultar logs e auditoria

---

## Testes Unitarios

A plataforma possui testes unitários nos microsserviços abaixo, que rodam automaticamente na esteira CI do Github Actions:
- **Usuários** 
- **Campanhas** : 
- **Worker de Doações**
- **DynamoPgProxy**
- **Frontend** 

| Projeto | Testes | Arquivo de projeto |
|---|---|---|
| `Usuarios.Test` | 118 | `tests/Usuarios.Test` |
| `Campanhas.Test` | 78 | `tests/Campanhas.Test` |
| `DonationWorker.Tests` | 58 | `tests/DonationWorker.Tests` |
| `DynamoPgProxy.Tests` | 49 | `tests/test_pg_dynamo_proxy.py` |
| `Frontend.Tests` | 73 | `tests/Frontend.Tests` |
| **Total** | **** | 376 |

---

### Stack de Testes

| Pacote | Finalidade |
|---|---|
| **xUnit** | Framework de testes |
| **Moq** | Mock de dependências (repositórios, serviços, cache) |
| **FluentAssertions** | Assertions expressivas e legíveis |
| **coverlet** | Coleta de cobertura de código |


---

## GitHub Actions

Os repositórios possuem tr^s workflows que formam o pipeline completo:

```
Push/PR → develop
  └─ ci.yml  (CI — Integração Contínua)
       └─ Build + Testes + Cobertura

Push → develop
  └─ cd.yml  (CD — Entrega Contínua)
       └─ CI como gate obrigatório
            └─ Build Docker → ECR → Deploy EKS
Push → develop
  └─ CodeQL  (Testes de vulnerabilidades)
       └─ Analyse (actions)
       └─ Analyze (csharp)
```

O CD **não executa** se o CI falhar — o `ci-gate` é um job de pré-requisito explícito em todos os workflows de entrega.

---
### CI Build & Test

O código é buildado, são realizados os testes unitários e um teste de vulnerabilidade também é realizado com o trivy. <br>
<img width="1988" height="1975" alt="image" src="https://github.com/user-attachments/assets/7da3ac0f-4780-48d3-bf58-4bb94b8468d2" />


---

### CD Build Push & Deploy

---

### CodeQL
Os testes abaixo sao realizados : <br>

<img width="1778" height="1832" alt="image" src="https://github.com/user-attachments/assets/869ad4bd-bb5e-4dd7-9fda-d9dfa52dd35b" />
<br>
<img width="1747" height="1821" alt="image" src="https://github.com/user-attachments/assets/ac8e4c1d-38f0-42d3-8f2d-aa88cad0c9c0" />
<br>

### Workflows por Repositório

| Repositório | CI | CD | Observação |
|---|---|---|---|
| `Usuarios` | ✅ Build + Testes + Analise Vulnerabilidades | ✅ ECR + EKS | Deploy: `cs-usuarios-api` |
| `Campanhas` | ✅ Build + Testes | ✅ ECR + EKS | Deploy: `cs-campanhas-api` |
| `Worker` | ✅ Build + Testes | ✅ ECR + EKS | Deploy: `cs-donationworker` |
| `DynamoPgProxy` | ✅ Lint + Sintaxe | ✅ ECR + EKS | Deploy: `cs-dynamo-pg-proxy` |
| `Frontend` | ✅ Build + Publish | ✅ ECR + EKS | Deploy: `cs-frontend` |
| `ApiGateway` | ✅ Build + Publish | Não publicado para o Cloud |  |
| `Notificacoes` | ✅ Build + Publish | Não publicado para o Cloud |  |

---

## CI — Integração Contínua

**Gatilhos:** `push` e `pull_request` para `develop` e `main`, além de `workflow_call` (chamado pelo CD como gate).

### Projetos .NET (Usuários, Campanhas, Worker, Frontend)

```
1. Checkout do código
2. Setup .NET 9.0.x
3. Cache NuGet → chave baseada no hash dos .csproj (evita downloads repetidos)
4. dotnet restore
5. dotnet build --configuration Release
6. dotnet test --collect:"XPlat Code Coverage"
7. Upload de artefatos:
     ├─ test-results.trx  → resultados dos testes
     └─ coverage.cobertura.xml → cobertura de código
```

Os artefatos de cobertura e resultados de testes ficam disponíveis na aba **Actions** do GitHub após cada execução.

### DynamoDB PG Proxy (Python)

Pipeline diferenciado por ser Python:

```
1. Checkout do código
2. Setup Python 3.12
3. pip install -r requirements.txt + flake8
4. flake8 → lint apenas erros críticos (E9, F63, F7, F82)
5. python -m py_compile → valida sintaxe do arquivo principal
```

---

## CD — Entrega Contínua

**Gatilhos:** `push` para `develop` e `workflow_dispatch` (execução manual).

### Pipeline

```
1. ci-gate (job)
     └─ reutiliza ci.yml via workflow_call
     └─ bloqueia o CD se CI falhar

2. build-push-deploy (job) — executa apenas se ci-gate passar
     ├─ Checkout do repositório da aplicação
     ├─ Checkout do repositório de Infra (manifests K8s)
     │    └─ repositório separado: ES.ConexaoSolidaria.Infra
     │    └─ autenticado via INFRA_REPO_TOKEN (secret)
     ├─ Configurar credenciais AWS (access key + session token)
     ├─ Login no Amazon ECR
     ├─ docker build + docker push
     │    └─ tag: {github.sha}-{github.run_number}
     ├─ aws eks update-kubeconfig
     ├─ kubectl apply -f infra/k8s/aws/services/{manifesto}.yaml
     ├─ kubectl set image deployment/{nome} {nome}={imagem}
     └─ kubectl rollout status --timeout=120s
```

### Tag da imagem Docker

```
{commit_sha}-{run_number}
ex: a1b2c3d4e5f6-42
```

Combina o SHA do commit com o número do run — rastreável e único por build.

---

## Benefícios

- 🚦 **CI como gate obrigatório** — o CD nunca executa se o build ou os testes falharem, impedindo que código quebrado chegue ao EKS

- 🏷️ **Rastreabilidade por commit** — a tag `{sha}-{run_number}` permite identificar exatamente qual commit está rodando em cada pod do Kubernetes

- ⚡ **Cache NuGet** — pacotes são cacheados por hash dos `.csproj`, acelerando builds subsequentes sem downloads desnecessários

- 🔁 **workflow_call** — o CI é reutilizado pelo CD via `workflow_call`, evitando duplicação de etapas e garantindo que o mesmo pipeline de validação seja executado em ambos os contextos

- 🔒 **Secrets centralizados** — credenciais AWS e tokens de repositório nunca ficam no código — apenas nos secrets do GitHub Actions

- 🖐️ **workflow_dispatch** — permite disparar um deploy manualmente pelo GitHub sem precisar fazer um push, útil para rollbacks e deploys de urgência

- 📊 **Artefatos de cobertura** — resultados de testes e cobertura de código publicados como artefatos a cada CI, disponíveis para análise diretamente na aba Actions


## Documentaçao

- [Casos de Uso](./docs/CasosDeUso.md)
- [Diagramas](./docs/diagrams/)
- [ADR — Architecture Decision Records](./docs/Adr.md)
- [Matriz de Rastreabilidade](./docs/traceability-matrix/)
- [Glossário de Domínio](./docs/GlossarioDominio.md)
- [LGPD Compliance](./docs/Lgpd.md/)
- [Comandos de Teste](./docs/ComandosTesteApi.md)
