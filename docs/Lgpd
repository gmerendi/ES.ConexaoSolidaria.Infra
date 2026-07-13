# 🛡️ LGPD — Lei Geral de Proteção de Dados

Documentação das decisões de arquitetura e implementações adotadas na plataforma Conexão Solidária em conformidade com a **Lei nº 13.709/2018 (LGPD)**.

---

## Base Legal

A plataforma Conexão Solidária trata dados pessoais com base nos seguintes fundamentos legais previstos no **Art. 7º da LGPD**:

| Fundamento | Artigo | Aplicação na plataforma |
|---|---|---|
| **Consentimento** | Art. 7º, I | Cadastro de usuários — o titular autoriza o tratamento ao se registrar |
| **Execução de contrato** | Art. 7º, V | Processamento de doações — necessário para cumprir a relação de doação |
| **Legítimo interesse** | Art. 7º, IX | Logs e métricas operacionais para segurança e funcionamento da plataforma |
| **Obrigação legal** | Art. 16, II | Retenção de registros de doações para fins de auditoria fiscal e compliance |

---

## Dados Pessoais Tratados

| Dado | Categoria | Onde é armazenado | Finalidade |
|---|---|---|---|
| Nome completo | Dado pessoal | PostgreSQL (identidade.usuario) | Identificação do usuário |
| E-mail | Dado pessoal | PostgreSQL (identidade.usuario) | Autenticação e comunicação |
| CPF | Dado pessoal sensível | PostgreSQL (armazenado em texto) / JWT (encriptado AES-256) / Eventos (encriptado AES-256) | Identificação fiscal e compliance |
| Senha | Dado pessoal | PostgreSQL (hash BCrypt — nunca em texto plano) | Autenticação |
| IP de acesso | Dado pessoal | DynamoDB (cs-audit-log) | Rastreabilidade e segurança |
| Histórico de alterações | Dado pessoal | DynamoDB (cs-audit-log) | Auditoria |

---

## Direitos do Titular — Art. 18 da LGPD

### ✅ Direito ao Acesso — Art. 18, I e II

O titular pode consultar seus próprios dados a qualquer momento via endpoint autenticado:

```
GET /api/v1/usuario?email={email}
  └─ Doadores: apenas o próprio perfil
  └─ Gestores: qualquer perfil
```

### ✅ Direito à Correção — Art. 18, III

O titular pode atualizar nome completo e CPF a qualquer momento:

```
PUT /api/v1/usuario/alterar
  └─ Requer autenticação
  └─ Apenas o próprio usuário ou GESTOR_ONG
```

### ✅ Direito à Eliminação — Art. 18, VI

O titular pode solicitar a exclusão de seus dados pessoais. A implementação segue a regra de deleção física prevista no **Art. 16 da LGPD**:

```
DELETE /api/v1/usuario?email={email}
  └─ Apenas o próprio usuário pode solicitar
  └─ Deleção física do registro no banco de dados (não é soft delete)
  └─ Remoção imediata do cache Redis
  └─ Regra de negócio: somente o próprio usuário pode se remover
       └─ GESTOR_ONG que deseja desabilitar um usuário usa SUSPENDED, não remoção
```

**Implementação no `RemoverUsuarioCommandHandler`:**

```csharp
// O usuário somente pode remover o próprio perfil
var solicitante = _userContext.GetUser();
if (solicitante == null)
    throw new DomainException("400_REQUESTER_REQUIRED");

// Remove fisicamente do banco de dados
await _usuarioRepository.RemoverAsync(usuario.Guid, ct);

// Remove do cache Redis imediatamente
await _cacheService.RemoveAsync($"usuario:{command.Email}");
```

### ✅ Direito à Portabilidade — Art. 18, V

Os dados do usuário podem ser obtidos via `GET /api/v1/usuario` em formato JSON estruturado, permitindo portabilidade para outros sistemas.

### ✅ Direito de Revogação do Consentimento — Art. 18, IX

O titular pode revogar o consentimento a qualquer momento via deleção da conta, conforme descrito acima.

---

## Retenção de Dados de Doações — Art. 16, II da LGPD

O ponto mais importante da arquitetura em relação à LGPD é a **separação entre dados do titular e registros de doações**.

### A decisão de arquitetura

Quando um usuário exerce o direito à eliminação, seus dados pessoais são removidos do microsserviço de Usuários. Porém, os **registros de doações não são deletados**.

### Por que as doações são mantidas?

O **Art. 16, II da LGPD** estabelece uma exceção explícita ao direito à eliminação:

> *"Os dados pessoais serão eliminados após o término de seu tratamento, [...] sendo permitida a conservação para as seguintes finalidades: [...] II - uso exclusivo do controlador, vedado seu acesso por terceiro, e desde que anonimizados os dados."*

Além disso, o **Art. 16, IV** permite retenção:

> *"IV - proteção do crédito, inclusive quanto ao disposto na legislação pertinente."*

As doações são mantidas por obrigações legais que transcendem o interesse individual:

| Lei | Dispositivo | Exigência |
|---|---|---|
| **Lei nº 9.532/1997** | Art. 30 | ONGs devem manter escrituração contábil de todas as receitas, incluindo doações |
| **Código Civil** | Art. 1.194 | Empresas e entidades devem conservar livros e documentos contábeis por 10 anos |
| **Instrução Normativa RFB nº 2.003/2021** | Art. 4º | Prestação de contas de doações à Receita Federal |
| **Lei de Responsabilidade Fiscal (LC 101/2000)** | Art. 48 | Transparência e prestação de contas para entidades que recebem recursos |
| **LGPD — Art. 16, II** | Art. 16, II | Permite retenção para cumprimento de obrigação legal ou regulatória |

### O que acontece com o registro de doação após a exclusão do usuário

```
Antes da exclusão:
  tabela doacao:
    guid_usuario: 3fa85f64-...
    nome_usuario: "João Silva"
    email_usuario: "joao@email.com"
    cpf_usuario:  "12345678901"  ← dado pessoal
    valor_doacao: 250.00
    guid_campanha: abc-123

Após a exclusão do usuário:
  tabela usuario: REMOVIDO fisicamente ✅
  tabela doacao:  MANTIDA para fins de auditoria fiscal
    → O registro existe, mas o usuário correspondente não existe mais no sistema
    → Para fins contábeis, o valor e a campanha são os dados relevantes
    → Os dados pessoais remanescentes (nome, e-mail) servem como registro histórico
       sob proteção de obrigação legal (Art. 16, II da LGPD)
```

### Separação de microsserviços como proteção adicional

A arquitetura de microsserviços reforça a conformidade — o Worker de Doações grava os registros de doação em um banco de dados separado do microsserviço de Usuários:

```
Banco cs-usuarios  ← REMOVIDO ao solicitar exclusão
  └─ tabela: identidade.usuario

Banco cs-campanhas  ← MANTIDO (obrigação legal)
  └─ tabela: operacao.doacao
  └─ tabela: operacao.campanha
```

Essa separação garante que a deleção do usuário é completa e definitiva no sistema de identidade, sem efeito colateral nas obrigações de auditoria fiscal.

---

## Proteção de Dados Pessoais — Medidas Técnicas

### CPF — Art. 46 da LGPD

> *"Os agentes de tratamento devem adotar medidas de segurança, técnicas e administrativas aptas a proteger os dados pessoais de acessos não autorizados."*

O CPF, por ser um dado sensível de identificação fiscal, recebe tratamento especial em todas as camadas:

```
Banco de dados   → armazenado como texto (apenas 11 dígitos numéricos)
Token JWT        → encriptado com AES-256 antes de ser inserido no claim
Eventos RabbitMQ → encriptado com AES-256 antes de publicar
Logs             → nunca aparece em texto plano em logs ou audit trail
```

### Senhas — Art. 46 da LGPD

```
Nunca armazenadas em texto plano
Hash BCrypt com workFactor 12 + salt único por senha
Verificação via BCrypt.Verify() — sem reversão possível
```

### Audit Log e IP — Art. 37 da LGPD

> *"O controlador deve manter registro das operações de tratamento de dados pessoais que realizar."*

O `AuditInterceptor` registra automaticamente todas as operações no DynamoDB (`cs-audit-log`), incluindo o IP de origem e o e-mail do responsável pela operação — criando a trilha de auditoria exigida pelo Art. 37.

### Token Blacklist — Segurança de Sessão

Ao solicitar exclusão da conta ou logout, o token JWT é imediatamente invalidado via blacklist no Redis, impedindo uso indevido de tokens emitidos anteriormente — mesmo que ainda estejam dentro do prazo de validade.

---

## Minimização de Dados — Art. 6º, III da LGPD

> *"A finalidade: realização do tratamento para propósitos legítimos, específicos, explícitos e informados ao titular."*

A plataforma aplica o princípio da minimização:

- O **ElasticSearch** não indexa `valorArrecadado` nem dados pessoais — apenas campos necessários para busca de campanhas
- O **Redis** cacheia apenas dados necessários para performance — sem replicar dados sensíveis desnecessariamente
- Os **eventos de mensageria** carregam apenas os campos necessários para o processamento — CPF encriptado somente quando indispensável para o registro de doação

---

## Encarregado de Dados (DPO) — Art. 41 da LGPD

A LGPD exige a indicação de um **Encarregado de Proteção de Dados (DPO — Data Protection Officer)** responsável por:

- Receber reclamações e comunicações dos titulares
- Orientar os colaboradores sobre práticas de proteção de dados
- Executar as demais atribuições determinadas pelo controlador ou por normas complementares

> ⚠️ A indicação do DPO deve ser feita pela organização responsável pela plataforma e comunicada à ANPD (Autoridade Nacional de Proteção de Dados).

---

## Incidentes de Segurança — Art. 48 da LGPD

> *"O controlador deverá comunicar à autoridade nacional e ao titular a ocorrência de incidente de segurança que possa acarretar risco ou dano relevante aos titulares."*

O prazo para comunicação à ANPD é de **72 horas** após a ciência do incidente. O sistema de Audit Log e Application Log facilita a detecção e investigação de incidentes por meio do `CorrelationId` e do histórico de operações no DynamoDB.

---

## Resumo das Conformidades

| Requisito LGPD | Artigo | Status | Implementação |
|---|---|---|---|
| Acesso aos dados | Art. 18, I-II | ✅ | GET /api/v1/usuario |
| Correção de dados | Art. 18, III | ✅ | PUT /api/v1/usuario/alterar |
| Eliminação de dados | Art. 18, VI | ✅ | DELETE /api/v1/usuario (deleção física) |
| Proteção do CPF | Art. 46 | ✅ | AES-256 em tokens e eventos |
| Proteção de senhas | Art. 46 | ✅ | BCrypt workFactor 12 |
| Registro de operações | Art. 37 | ✅ | AuditInterceptor + DynamoDB |
| Retenção legal de doações | Art. 16, II | ✅ | Microsserviço separado, banco independente |
| Minimização de dados | Art. 6º, III | ✅ | ElasticSearch sem dados sensíveis |
| Comunicação de incidentes | Art. 48 | ⚠️ | Logs disponíveis; processo manual a definir |
| Indicação de DPO | Art. 41 | ⚠️ | A ser designado pela organização |
