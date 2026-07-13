# Diagramas de Fluxo de Utilização para as APIs - Principais APIs
## Criação de usuário

### Local

```mermaid
sequenceDiagram
    actor U as Usuário
    participant MS as Microsserviço Usuários
    participant RMQ as RabbitMQ
    participant N as Worker Notificações
    participant MP as Mailpit

    U->>MS: POST /api/v1/usuario
    MS->>MS: Valida dados (nome, email, CPF, senha)
    MS->>MS: Verifica unicidade (email e CPF)
    MS->>MS: Gera hash BCrypt da senha
    MS->>MS: INSERT usuário (status: ACTIVE, perfil: DOADOR)
    MS->>RMQ: Publica UserCreatedEvent
    MS-->>U: 201 Created {guid, email, perfil, status}

    Note over RMQ,MP: Processamento assíncrono

    RMQ->>N: Consome UserCreatedEvent
    N->>MP: SMTP :1025 (e-mail de boas-vindas)
    Note over MP: E-mail capturado localhost:8025
```

### AWS

```mermaid
sequenceDiagram
    actor U as Usuário
    participant MS as Microsserviço Usuários (EKS)
    participant SQS as Amazon SQS
    participant L as Lambda (Python 3.9)
    participant SNS as Amazon SNS
    participant MT as Mailtrap API

    U->>MS: POST /api/v1/usuario (via AWS API Gateway)
    MS->>MS: Valida dados (nome, email, CPF, senha)
    MS->>MS: Verifica unicidade (email e CPF)
    MS->>MS: Gera hash BCrypt da senha
    MS->>MS: INSERT usuário (status: ACTIVE, perfil: DOADOR)
    MS->>SQS: Publica UserCreatedEvent (user-created-queue)
    MS-->>U: 201 Created {guid, email, perfil, status}

    Note over SQS,MT: Processamento assíncrono

    SQS->>L: Trigger batch:5 (ReportBatchItemFailures)
    L->>MT: POST /api/send (e-mail de boas-vindas)
    Note over MT: E-mail enviado
```
---

## Criação de campanha

### Local
```mermaid
sequenceDiagram
    actor G as Gestor ONG
    participant GW as Gateway (YARP)
    participant MS as Microsserviço Campanhas
    participant PG as PostgreSQL
    participant RD as Redis
    participant ES as Elasticsearch

    G->>GW: POST /api/v1/Campanhas (Bearer token)
    GW->>GW: Valida JWT
    GW->>MS: Repassa requisição
    MS->>MS: Verifica perfil GESTOR_ONG
    MS->>MS: Valida dados (titulo, descricao, meta, datas)
    MS->>MS: Verifica unicidade do título
    MS->>MS: Cria entidade Campanha (status: ATIVA)
    MS->>PG: INSERT campanha
    MS->>RD: Invalida cache campanhas:ativas
    MS->>ES: Indexa documento da campanha
    MS-->>G: 201 Created {guid, titulo, status: ATIVA}
```

### AWS
```mermaid
sequenceDiagram
    actor G as Gestor ONG
    participant APIGW as AWS API Gateway
    participant MS as Microsserviço Campanhas (EKS)
    participant PG as RDS PostgreSQL
    participant RD as ElastiCache Redis
    participant ES as Elasticsearch

    G->>APIGW: POST /api/v1/Campanhas (Bearer token)
    APIGW->>APIGW: Valida JWT + throttling
    APIGW->>MS: Repassa via VPC Link
    MS->>MS: Verifica perfil GESTOR_ONG
    MS->>MS: Valida dados (titulo, descricao, meta, datas)
    MS->>MS: Verifica unicidade do título
    MS->>MS: Cria entidade Campanha (status: ATIVA)
    MS->>PG: INSERT campanha
    MS->>RD: Invalida cache campanhas:ativas
    MS->>ES: Indexa documento da campanha
    MS-->>G: 201 Created {guid, titulo, status: ATIVA}
```

## Criação de Doação
### Local

```mermaid
sequenceDiagram
    actor D as Doador
    participant GW as Gateway (YARP)
    participant MS as Microsserviço Campanhas
    participant PG as PostgreSQL
    participant RMQ as RabbitMQ
    participant W as Worker Doações
    participant N as Worker Notificações
    participant MP as Mailpit

    D->>GW: POST /api/v1/Doacoes (Bearer token)
    GW->>GW: Valida JWT
    GW->>MS: Repassa requisição
    MS->>MS: Verifica autenticação
    MS->>PG: Busca campanha por GUID
    MS->>MS: Verifica status ATIVA
    MS->>MS: Valida valor > 0
    MS->>MS: Encripta CPF (AES-256)
    MS->>RMQ: Publica DonationCreatedEvent
    MS-->>D: 201 Created {guidCampanha, valor, nomeUsuario}

    Note over RMQ,MP: Processamento assíncrono

    RMQ->>W: Consome DonationCreatedEvent
    W->>PG: Verifica idempotência (CorrelationId)
    W->>PG: Verifica existência da campanha
    W->>W: Valida valor > 0 na entidade
    W->>PG: BEGIN TRANSACTION
    W->>PG: INSERT doacao
    W->>PG: UPDATE campanha SET valor_arrecadado = valor_arrecadado + @valor
    W->>PG: COMMIT
    W->>RMQ: Publica DonationProcessedEvent

    Note over RMQ,MP: Processamento assíncrono

    RMQ->>N: Consome DonationProcessedEvent
    N->>MP: SMTP :1025 (e-mail confirmação doação)
    Note over MP: E-mail capturado localhost:8025
```

### AWS
```mermaid
sequenceDiagram
    actor D as Doador
    participant APIGW as AWS API Gateway
    participant MS as Microsserviço Campanhas (EKS)
    participant PG as RDS PostgreSQL
    participant SQS as Amazon SQS
    participant W as Worker Doações (EKS)
    participant L as Lambda (Python 3.9)
    participant SNS as Amazon SNS
    participant MT as Mailtrap API

    D->>APIGW: POST /api/v1/Doacoes (Bearer token)
    APIGW->>APIGW: Valida JWT + throttling
    APIGW->>MS: Repassa via VPC Link
    MS->>MS: Verifica autenticação
    MS->>PG: Busca campanha por GUID
    MS->>MS: Verifica status ATIVA
    MS->>MS: Valida valor > 0
    MS->>MS: Encripta CPF (AES-256)
    MS->>SQS: Publica DonationCreatedEvent (donation-created-queue)
    MS-->>D: 201 Created {guidCampanha, valor, nomeUsuario}

    Note over SQS,W: Processamento assíncrono (Event Source Mapping)

    SQS->>W: Consome DonationCreatedEvent
    W->>PG: Verifica idempotência (CorrelationId)
    W->>PG: Verifica existência da campanha
    W->>W: Valida valor > 0 na entidade
    W->>PG: BEGIN TRANSACTION
    W->>PG: INSERT doacao
    W->>PG: UPDATE campanha SET valor_arrecadado = valor_arrecadado + @valor
    W->>PG: COMMIT
    W->>SQS: Publica DonationProcessedEvent (donation-processed-queue)

    Note over SQS,MT: Processamento assíncrono 

    SQS->>L: Trigger batch:5 (ReportBatchItemFailures)
    L->>MT: POST /api/send (e-mail confirmação doação)
    Note over MT: E-mail enviado
```
---

## Login
### Local
```mermaid
sequenceDiagram
    actor U as Usuário
    participant GW as Gateway (YARP)
    participant MS as Microsserviço Usuários
    participant PG as PostgreSQL
    participant RD as Redis

    U->>GW: POST /api/v1/auth/login
    GW->>GW: Rota pública (sem validação JWT)
    GW->>MS: Repassa requisição
    MS->>MS: Valida formato do e-mail
    MS->>PG: Busca usuário por e-mail
    MS->>MS: Verifica status (bloqueia SUSPENDED e REMOVED)
    MS->>MS: BCrypt.Verify(senha, hash)
    MS->>MS: Gera token JWT (HMAC SHA256)
    MS->>MS: Encripta CPF no claim (AES-256)
    MS->>RD: SET usuario:{email} TTL 30min
    MS-->>GW: 200 OK {token, dataExpiracao, guid, email, status}
    GW-->>U: 200 OK {token, dataExpiracao, guid, email, status}
```

### AWS
```mermaid
sequenceDiagram
    actor U as Usuário
    participant APIGW as AWS API Gateway
    participant MS as Microsserviço Usuários (EKS)
    participant PG as RDS PostgreSQL
    participant RD as ElastiCache Redis

    U->>APIGW: POST /api/v1/auth/login
    APIGW->>APIGW: Rota pública + throttling (10 req/min anti brute force)
    APIGW->>MS: Repassa via VPC Link
    MS->>MS: Valida formato do e-mail
    MS->>PG: Busca usuário por e-mail
    MS->>MS: Verifica status (bloqueia SUSPENDED e REMOVED)
    MS->>MS: BCrypt.Verify(senha, hash)
    MS->>MS: Gera token JWT (HMAC SHA256)
    MS->>MS: Encripta CPF no claim (AES-256)
    MS->>RD: SET usuario:{email} TTL 30min
    MS-->>APIGW: 200 OK {token, dataExpiracao, guid, email, status}
    APIGW-->>U: 200 OK {token, dataExpiracao, guid, email, status}
```

---

## Logout
### Local
```mermaid
sequenceDiagram
    actor U as Usuário
    participant GW as Gateway (YARP)
    participant MS as Microsserviço Usuários
    participant RD as Redis

    U->>GW: POST /api/v1/auth/logout (Bearer token)
    GW->>GW: Valida JWT (assinatura, expiração)
    GW->>GW: Verifica blacklist no Redis
    GW->>MS: Repassa requisição
    MS->>MS: Calcula tempo restante do token (GetTokenTimeToExpire)
    MS->>RD: SET blacklist:{token} TTL = tempo restante
    MS->>RD: DEL usuario:{email}
    MS-->>GW: 200 OK {true}
    GW-->>U: 200 OK {true}

    Note over U,RD: Token imediatamente inválido em qualquer requisição subsequente
```

## AWS
```mermaid
sequenceDiagram
    actor U as Usuário
    participant APIGW as AWS API Gateway
    participant MS as Microsserviço Usuários (EKS)
    participant RD as ElastiCache Redis

    U->>APIGW: POST /api/v1/auth/logout (Bearer token)
    APIGW->>APIGW: Valida JWT (assinatura, expiração, issuer, audience)
    APIGW->>APIGW: Rate limiting (throttling por stage)
    APIGW->>MS: Repassa via VPC Link
    MS->>MS: Valida JWT (Defense in Depth)
    MS->>MS: Calcula tempo restante do token (GetTokenTimeToExpire)
    MS->>RD: SET blacklist:{token} TTL = tempo restante
    MS->>RD: DEL usuario:{email}
    MS-->>APIGW: 200 OK {true}
    APIGW-->>U: 200 OK {true}

    Note over U,RD: Token imediatamente inválido em qualquer requisição subsequente
```
---
## Buscar Campanhas Ativas

### Local
```mermaid
sequenceDiagram
    actor U as Usuário
    participant GW as Gateway (YARP)
    participant MS as Microsserviço Campanhas
    participant RD as Redis
    participant PG as PostgreSQL

    U->>GW: GET /api/v1/Campanhas/todas?Pagina=1&TamanhoPagina=9
    GW->>GW: Rota pública (sem validação JWT)
    GW->>MS: Repassa requisição
    MS->>RD: GET campanhas:ativas:{pagina}:{tamanho}

    alt Cache hit
        RD-->>MS: Retorna lista cacheada
    else Cache miss
        MS->>PG: SELECT campanhas WHERE status = ATIVA
        PG-->>MS: Lista de campanhas
        MS->>RD: SET campanhas:ativas:{pagina}:{tamanho} TTL 60s
    end

    MS-->>GW: 200 OK {campanhas, totalRegistros, pagina}
    GW-->>U: 200 OK {campanhas, totalRegistros, pagina}
```
### AWS
```mermaid
sequenceDiagram
    actor U as Usuário
    participant APIGW as AWS API Gateway
    participant MS as Microsserviço Campanhas (EKS)
    participant RD as ElastiCache Redis
    participant PG as RDS PostgreSQL

    U->>APIGW: GET /api/v1/Campanhas/todas?Pagina=1&TamanhoPagina=9
    APIGW->>APIGW: Rota pública + throttling por stage
    APIGW->>MS: Repassa via VPC Link
    MS->>RD: GET campanhas:ativas:{pagina}:{tamanho}

    alt Cache hit
        RD-->>MS: Retorna lista cacheada
    else Cache miss
        MS->>PG: SELECT campanhas WHERE status = ATIVA
        PG-->>MS: Lista de campanhas
        MS->>RD: SET campanhas:ativas:{pagina}:{tamanho} TTL 60s
    end

    MS-->>APIGW: 200 OK {campanhas, totalRegistros, pagina}
    APIGW-->>U: 200 OK {campanhas, totalRegistros, pagina}
```
---
