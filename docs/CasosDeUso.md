# 📋 Casos de Uso — Conexão Solidária

Documento que descreve os casos de uso da plataforma Conexão Solidária, com pré-condições, pós-condições, fluxo principal, fluxos alternativos, regras de negócio e dados de entrada/saída.

---

## UC-01 — Cadastrar Novo Usuário

**Ator:** Visitante (não autenticado)

### Pré-condições
- O sistema está disponível
- O visitante não possui cadastro prévio com o e-mail informado
- O CPF informado não está cadastrado por outro usuário

### Pós-condições
- Um novo usuário é criado com perfil **DOADOR** e status **ACTIVE**
- O evento `UserCreatedEvent` é publicado no broker de mensagens
- O Worker de Notificações envia e-mail de boas-vindas ao usuário

### Fluxo Principal
1. O visitante preenche nome completo, e-mail, CPF e senha
2. O sistema valida o formato do e-mail
3. O sistema valida o CPF (formato e dígitos verificadores)
4. O sistema valida a força da senha
5. O sistema verifica unicidade do e-mail no banco de dados
6. O sistema verifica unicidade do CPF no banco de dados
7. O sistema gera hash BCrypt da senha (workFactor: 12)
8. O sistema persiste o usuário com perfil DOADOR e status ACTIVE
9. O sistema publica `UserCreatedEvent` no broker
10. O sistema retorna os dados do usuário criado

### Fluxos Alternativos
- **FA01 — E-mail já cadastrado:** o sistema lança `422_USER_DUPLICATED` e interrompe o fluxo
- **FA02 — CPF já cadastrado:** o sistema lança `422_CPF_DUPLICATED` e interrompe o fluxo
- **FA03 — CPF inválido:** o sistema lança `422_CPF_INVALID` antes de verificar unicidade
- **FA04 — Senha fraca:** o sistema lança erro de validação antes de persistir

### Regras de Negócio
- Todo novo usuário é criado com perfil **DOADOR** — nunca como GESTOR_ONG
- O perfil só pode ser alterado posteriormente por um GESTOR_ONG (UC-09)
- CPF é armazenado apenas com dígitos numéricos (sem máscara)
- A senha nunca é armazenada em texto plano — apenas o hash BCrypt

### Dados de Entrada
| Campo | Tipo | Obrigatório | Validação |
|---|---|---|---|
| `nomeCompleto` | string | ✅ | 5–100 caracteres |
| `email` | string | ✅ | Formato válido, único no sistema |
| `cpf` | string | ✅ | 11 dígitos, válido matematicamente, único |
| `password` | string | ✅ | Mínimo 8 chars, maiúscula, minúscula, número e especial |

### Dados de Saída
| Campo | Tipo | Descrição |
|---|---|---|
| `guid` | UUID | Identificador único do usuário |
| `nomeCompleto` | string | Nome completo |
| `cpf` | string | CPF (apenas dígitos) |
| `email` | string | E-mail cadastrado |
| `perfil` | string | Sempre `DOADOR` |
| `status` | string | Sempre `ACTIVE` |

---

## UC-02 — Realizar Login

**Ator:** Usuário cadastrado

### Pré-condições
- O usuário possui cadastro com e-mail e senha válidos
- O usuário não está com status SUSPENDED ou REMOVED

### Pós-condições
- Um token JWT é gerado com validade configurável
- Os dados do usuário são cacheados no Redis por 30 minutos
- A métrica `usuarios_login_total` é incrementada

### Fluxo Principal
1. O usuário informa e-mail e senha
2. O sistema busca o usuário pelo e-mail no banco de dados
3. O sistema verifica o status do usuário
4. O sistema verifica a senha via BCrypt (`Verify(senha, hash)`)
5. O sistema gera o token JWT com claims (GUID, nome, e-mail, perfil, CPF encriptado)
6. O sistema cacheia os dados do usuário no Redis por 30 minutos
7. O sistema retorna o token, data de expiração, GUID, e-mail e status

### Fluxos Alternativos
- **FA01 — Usuário não encontrado:** lança `400_USER_NOT_FOUND`
- **FA02 — Usuário suspenso:** lança `403_USER_SUSPENDED`
- **FA03 — Usuário removido:** lança `403_USER_REMOVED`
- **FA04 — Senha incorreta:** lança `401_INVALID_CREDENTIALS`

### Regras de Negócio
- A verificação de senha usa `BCrypt.Verify()` — nunca compara texto plano
- O CPF é encriptado com AES-256 antes de ser inserido no claim JWT
- O token JWT inclui `ClockSkew = Zero` — sem tolerância de 5 minutos padrão do .NET
- Usuários REMOVED não conseguem logar mesmo que o e-mail exista

### Dados de Entrada
| Campo | Tipo | Obrigatório |
|---|---|---|
| `email` | string | ✅ |
| `password` | string | ✅ |

### Dados de Saída
| Campo | Tipo | Descrição |
|---|---|---|
| `token` | string | JWT assinado com HMAC SHA256 |
| `dataExpiracao` | datetime | Data/hora de expiração do token |
| `usuarioId` | UUID | GUID do usuário |
| `email` | string | E-mail do usuário |
| `status` | string | Status atual (`ACTIVE`) |

---

## UC-03 — Realizar Logout

**Ator:** Usuário autenticado (DOADOR ou GESTOR_ONG)

### Pré-condições
- O usuário está autenticado com token JWT válido

### Pós-condições
- O token JWT é adicionado à blacklist no Redis com TTL igual ao tempo restante de vida
- Os dados do usuário são removidos do cache Redis
- A métrica `usuarios_logout_total` é incrementada
- O token deixa de ser aceito imediatamente em qualquer requisição subsequente

### Fluxo Principal
1. O usuário envia requisição com token JWT no header Authorization
2. O sistema calcula o tempo restante de vida do token (`GetTokenTimeToExpire`)
3. O sistema insere o token na blacklist Redis com o TTL calculado
4. O sistema remove os dados do usuário do cache (`usuario:{email}`)
5. O sistema retorna `true`

### Fluxos Alternativos
- **FA01 — Token inválido/expirado:** o JWT middleware rejeita antes de chegar ao handler

### Regras de Negócio
- O TTL da blacklist é exatamente igual ao tempo restante do token — ele expira do Redis no mesmo instante em que expiraria naturalmente, sem acúmulo de dados
- Após o logout, qualquer requisição com o mesmo token é bloqueada pelo `TokenBlacklistMiddleware` antes da validação JWT

### Dados de Entrada
| Campo | Tipo | Obrigatório |
|---|---|---|
| `Authorization` | header | ✅ (Bearer token) |

### Dados de Saída
| Campo | Tipo | Descrição |
|---|---|---|
| — | boolean | `true` em caso de sucesso |

---

## UC-04 — Visualizar Dados de Usuário

**Ator:** DOADOR (próprio perfil) ou GESTOR_ONG (qualquer perfil)

### Pré-condições
- O solicitante está autenticado
- O usuário consultado existe no sistema

### Pós-condições
- Os dados do usuário são retornados
- Se não estavam em cache, são cacheados no Redis por 30 minutos

### Fluxo Principal
1. O solicitante informa o e-mail do usuário a ser consultado
2. O sistema verifica o perfil do solicitante
3. O sistema tenta obter os dados do cache Redis (`usuario:{email}`)
4. **Cache hit:** retorna os dados diretamente do cache
5. **Cache miss:** busca no banco de dados, cacheia e retorna

### Fluxos Alternativos
- **FA01 — DOADOR tentando consultar outro usuário:** lança `403_USER_NOT_ALLOWED`
- **FA02 — Usuário não encontrado no banco:** lança `400_USER_NOT_FOUND`

### Regras de Negócio
- DOADOR só pode consultar o próprio perfil
- GESTOR_ONG pode consultar qualquer perfil
- Cache com TTL de 30 minutos — dado eventualmente consistente

### Dados de Entrada
| Campo | Tipo | Obrigatório |
|---|---|---|
| `email` | string (query) | ✅ |

### Dados de Saída
| Campo | Tipo |
|---|---|
| `guid` | UUID |
| `nomeCompleto` | string |
| `cpf` | string |
| `email` | string |
| `perfil` | string |
| `status` | string |

---

## UC-05 — Remover Usuário (LGPD)

**Ator:** Usuário autenticado (própria conta)

### Pré-condições
- O solicitante está autenticado
- O usuário a ser removido existe no sistema
- O e-mail informado pertence ao próprio solicitante

### Pós-condições
- O usuário é removido fisicamente do banco de dados PostgreSQL
- Os dados do usuário são removidos do cache Redis
- As doações realizadas pelo usuário **permanecem** no banco para fins de auditoria fiscal
- A métrica `usuarios_removidos_total` é incrementada

### Fluxo Principal
1. O usuário solicita a exclusão informando o próprio e-mail
2. O sistema identifica o solicitante via claims do JWT
3. O sistema busca o usuário no banco de dados
4. O sistema remove fisicamente o registro (`DELETE` físico, não soft delete)
5. O sistema remove os dados do cache Redis
6. O sistema retorna `true`

### Fluxos Alternativos
- **FA01 — Usuário não encontrado:** lança `400_USER_NOT_FOUND`
- **FA02 — Solicitante não identificado:** lança `400_REQUESTER_REQUIRED`

### Regras de Negócio
- Apenas o próprio usuário pode solicitar a exclusão — GESTOR_ONG **não** pode remover outro usuário; deve usar SUSPENDED (UC-07)
- A deleção é física (hard delete) conforme Art. 18, VI da LGPD
- Doações permanecem no banco conforme Art. 16, II da LGPD e Lei nº 9.532/1997 (obrigação fiscal)

### Dados de Entrada
| Campo | Tipo | Obrigatório |
|---|---|---|
| `email` | string (query) | ✅ |

### Dados de Saída
| Campo | Tipo |
|---|---|
| — | boolean (`true`) |

---

## UC-06 — Resetar Senha

**Ator:** Usuário autenticado (DOADOR ou GESTOR_ONG)

### Pré-condições
- O usuário está autenticado com token JWT válido
- O usuário está com status ACTIVE

### Pós-condições
- A senha é atualizada no banco com novo hash BCrypt
- O token atual é invalidado (adicionado à blacklist no Redis)
- Um novo token JWT é gerado e retornado
- O registro de auditoria é gerado pelo `AuditInterceptor`

### Fluxo Principal
1. O usuário informa a senha atual e a nova senha
2. O sistema identifica o usuário pelo e-mail do token JWT
3. O sistema verifica o status do usuário (deve ser ACTIVE)
4. O sistema verifica a senha atual via BCrypt
5. O sistema gera novo hash BCrypt para a nova senha
6. O sistema atualiza a senha no banco de dados
7. O sistema invalida o token atual (blacklist Redis)
8. O sistema gera e retorna um novo token JWT

### Fluxos Alternativos
- **FA01 — Nova senha vazia:** lança `400_PASSWORD_REQUIRED` imediatamente
- **FA02 — Usuário suspenso:** lança `403_USER_SUSPENDED`
- **FA03 — Senha atual incorreta:** lança `403_PASSWORD_INCORRECT`
- **FA04 — Usuário não encontrado:** lança `400_USER_NOT_FOUND`

### Regras de Negócio
- A senha atual é verificada mesmo com o usuário já autenticado — dupla confirmação de identidade que previne ataques com token roubado
- O token anterior é invalidado imediatamente após a troca — sessão anterior deixa de ser válida
- Apenas o próprio usuário altera a própria senha — não é possível alterar a senha de outro usuário

### Dados de Entrada
| Campo | Tipo | Obrigatório | Validação |
|---|---|---|---|
| `passwordAtual` | string | ✅ | Deve bater com o hash atual |
| `passwordNovo` | string | ✅ | Mínimo 8 chars, maiúscula, minúscula, número, especial |

### Dados de Saída
| Campo | Tipo | Descrição |
|---|---|---|
| — | string | Novo token JWT |

---

## UC-07 — Suspender Usuário

**Ator:** GESTOR_ONG

### Pré-condições
- O solicitante está autenticado com perfil GESTOR_ONG
- O usuário alvo existe no sistema
- O solicitante não está tentando suspender o próprio perfil

### Pós-condições
- O status do usuário é atualizado para **SUSPENDED**
- Os dados do usuário são removidos do cache Redis
- O usuário não consegue mais fazer login

### Fluxo Principal
1. O gestor informa o e-mail do usuário a ser suspenso
2. O sistema verifica se o solicitante é GESTOR_ONG
3. O sistema verifica a regra de domínio (`PodeAlterarPerfilEStatus`)
4. O sistema atualiza o status para SUSPENDED
5. O sistema remove o usuário do cache Redis
6. O sistema retorna `true`

### Fluxos Alternativos
- **FA01 — Usuário não encontrado:** lança `400_USER_NOT_FOUND`
- **FA02 — Gestor tentando suspender o próprio perfil:** `PodeAlterarPerfilEStatus` lança exceção

### Regras de Negócio
- GESTOR_ONG não pode suspender o próprio perfil
- Usuário SUSPENDED não consegue fazer login (bloqueado no UC-02)
- Para reativar, utilizar UC-08

### Dados de Entrada
| Campo | Tipo | Obrigatório |
|---|---|---|
| `email` | string (query) | ✅ |

### Dados de Saída
| Campo | Tipo |
|---|---|
| — | boolean (`true`) |

---

## UC-08 — Ativar Usuário

**Ator:** GESTOR_ONG

### Pré-condições
- O solicitante está autenticado com perfil GESTOR_ONG
- O usuário alvo existe no sistema
- O solicitante não está tentando ativar o próprio perfil

### Pós-condições
- O status do usuário é atualizado para **ACTIVE**
- Os dados do usuário são removidos do cache Redis
- O usuário volta a conseguir fazer login

### Fluxo Principal
1. O gestor informa o e-mail do usuário a ser ativado
2. O sistema verifica se o solicitante é GESTOR_ONG
3. O sistema verifica a regra de domínio (`PodeAlterarPerfilEStatus`)
4. O sistema atualiza o status para ACTIVE
5. O sistema remove o usuário do cache Redis
6. O sistema retorna `true`

### Fluxos Alternativos
- **FA01 — Usuário não encontrado:** lança `400_USER_NOT_FOUND`
- **FA02 — Gestor tentando ativar o próprio perfil:** `PodeAlterarPerfilEStatus` lança exceção

### Regras de Negócio
- GESTOR_ONG não pode ativar o próprio perfil
- Geralmente usado para reverter uma suspensão (UC-07)

### Dados de Entrada
| Campo | Tipo | Obrigatório |
|---|---|---|
| `email` | string (query) | ✅ |

### Dados de Saída
| Campo | Tipo |
|---|---|
| — | boolean (`true`) |

---

## UC-09 — Alterar Perfil para GESTOR_ONG

**Ator:** GESTOR_ONG

### Pré-condições
- O solicitante está autenticado com perfil GESTOR_ONG
- O usuário alvo existe no sistema
- O solicitante não está tentando alterar o próprio perfil

### Pós-condições
- O perfil do usuário alvo é atualizado para **GESTOR_ONG**
- Os dados do usuário são removidos do cache Redis

### Fluxo Principal
1. O gestor informa o e-mail do usuário a ter o perfil elevado
2. O sistema verifica se o solicitante é GESTOR_ONG
3. O sistema verifica a regra de domínio (`PodeAlterarPerfilEStatus`)
4. O sistema atualiza o perfil para GESTOR_ONG
5. O sistema remove o usuário do cache Redis
6. O sistema retorna `true`

### Fluxos Alternativos
- **FA01 — Usuário não encontrado:** lança `400_USER_NOT_FOUND`
- **FA02 — Gestor tentando alterar o próprio perfil:** lança exceção de domínio

### Regras de Negócio
- GESTOR_ONG não pode alterar o próprio perfil
- O usuário precisa fazer um novo login para que o novo perfil seja refletido no token

### Dados de Entrada
| Campo | Tipo | Obrigatório |
|---|---|---|
| `email` | string (query) | ✅ |

### Dados de Saída
| Campo | Tipo |
|---|---|
| — | boolean (`true`) |

---

## UC-10 — Alterar Perfil para DOADOR

**Ator:** GESTOR_ONG

### Pré-condições
- O solicitante está autenticado com perfil GESTOR_ONG
- O usuário alvo existe no sistema
- O solicitante não está tentando alterar o próprio perfil

### Pós-condições
- O perfil do usuário alvo é rebaixado para **DOADOR**
- Os dados do usuário são removidos do cache Redis

### Fluxo Principal
1. O gestor informa o e-mail do usuário a ter o perfil rebaixado
2. O sistema verifica se o solicitante é GESTOR_ONG
3. O sistema verifica a regra de domínio (`PodeAlterarPerfilEStatus`)
4. O sistema atualiza o perfil para DOADOR
5. O sistema remove o usuário do cache Redis
6. O sistema retorna `true`

### Fluxos Alternativos
- **FA01 — Usuário não encontrado:** lança `400_USER_NOT_FOUND`
- **FA02 — Gestor tentando alterar o próprio perfil:** lança exceção de domínio

### Regras de Negócio
- GESTOR_ONG não pode alterar o próprio perfil
- O usuário precisa fazer um novo login para que o novo perfil seja refletido no token

### Dados de Entrada
| Campo | Tipo | Obrigatório |
|---|---|---|
| `email` | string (query) | ✅ |

### Dados de Saída
| Campo | Tipo |
|---|---|
| — | boolean (`true`) |

---

## UC-11 — Alterar Dados do Usuário

**Ator:** Usuário autenticado (DOADOR ou GESTOR_ONG)

### Pré-condições
- O usuário está autenticado
- O usuário existe no sistema

### Pós-condições
- Nome completo e CPF do usuário são atualizados no banco
- Os dados do usuário são removidos do cache Redis
- O registro de auditoria é gerado pelo `AuditInterceptor`

### Fluxo Principal
1. O usuário informa o novo nome completo e CPF
2. O sistema identifica o solicitante via claims do JWT
3. O sistema verifica a regra de domínio (`PodeAlterarUsuario`)
4. O sistema atualiza nome e CPF
5. O sistema remove os dados do cache Redis
6. O sistema retorna os dados atualizados

### Fluxos Alternativos
- **FA01 — Usuário não encontrado:** lança `400_USER_NOT_FOUND`
- **FA02 — Solicitante não identificado:** lança `400_REQUESTER_REQUIRED`

### Regras de Negócio
- Apenas o próprio usuário pode alterar os seus dados
- O e-mail não pode ser alterado — é o identificador imutável do usuário no sistema

### Dados de Entrada
| Campo | Tipo | Obrigatório | Validação |
|---|---|---|---|
| `nomeCompleto` | string (query) | ✅ | 5–100 caracteres |
| `cpf` | string (query) | ✅ | 11 dígitos, válido matematicamente |

### Dados de Saída
| Campo | Tipo |
|---|---|
| `guid` | UUID |
| `nomeCompleto` | string |
| `cpf` | string |
| `email` | string |
| `perfil` | string |
| `status` | string |

---

## UC-12 — Criar Nova Campanha

**Ator:** GESTOR_ONG

### Pré-condições
- O solicitante está autenticado com perfil GESTOR_ONG
- Não existe campanha com o mesmo título no sistema

### Pós-condições
- A campanha é criada com status **ATIVA**
- A campanha é indexada no Elasticsearch
- O cache de listas de campanhas ativas é invalidado
- O evento `CampaignCreatedEvent` é publicado no broker
- A métrica `campanhas_criadas_total` é incrementada

### Fluxo Principal
1. O gestor preenche título, descrição, meta financeira, data de início e data de fim
2. O sistema valida os dados de entrada
3. O sistema verifica se o solicitante é GESTOR_ONG
4. O sistema verifica unicidade do título
5. O sistema cria a entidade `Campanha` via value objects
6. O sistema persiste a campanha no banco de dados
7. O sistema indexa a campanha no Elasticsearch
8. O sistema invalida o cache de listagem de campanhas ativas
9. O sistema publica `CampaignCreatedEvent`
10. O sistema retorna os dados da campanha criada

### Fluxos Alternativos
- **FA01 — Título duplicado:** lança `422_CAMPAIGN_DUPLICATED`
- **FA02 — Solicitante não é GESTOR_ONG:** lança `403_USER_NOT_ALLOWED`
- **FA03 — Data de fim anterior à data de início:** lança `422_DATES_MISMATCHING`

### Regras de Negócio
- Apenas GESTOR_ONG pode criar campanhas
- O título deve ser único no sistema
- A data de fim deve ser posterior à data de início
- A meta financeira deve ser maior que zero
- Status inicial é sempre ATIVA

### Dados de Entrada
| Campo | Tipo | Obrigatório | Validação |
|---|---|---|---|
| `titulo` | string | ✅ | 5–200 caracteres, único |
| `descricao` | string | ✅ | Máximo 2000 caracteres |
| `metaFinanceira` | decimal | ✅ | Maior que 0 |
| `dataInicio` | datetime | ✅ | |
| `dataFim` | datetime | ✅ | Posterior à data de início |

### Dados de Saída
| Campo | Tipo |
|---|---|
| `guid` | UUID |
| `titulo` | string |
| `descricao` | string |
| `metaFinanceira` | decimal |
| `valorArrecadado` | decimal |
| `dataInicio` | string |
| `dataFim` | string |
| `statusCampanha` | string |

---

## UC-13 — Visualizar Dados de uma Campanha

**Ator:** DOADOR ou GESTOR_ONG

### Pré-condições
- O solicitante está autenticado
- A campanha existe no sistema (qualquer status)

### Pós-condições
- Os dados da campanha são retornados
- Se não estavam em cache, são cacheados com TTL estratificado por status

### Fluxo Principal
1. O solicitante informa o GUID da campanha
2. O sistema tenta obter a campanha do cache Redis
3. **Cache hit:** retorna os dados diretamente
4. **Cache miss:** busca no banco, aplica TTL conforme status e cacheia

### Fluxos Alternativos
- **FA01 — Campanha não encontrada:** lança `400_CAMPAIGN_NOT_FOUND`

### Regras de Negócio
- Campanhas ATIVAS são cacheadas com TTL de 60s (configurável)
- Campanhas não ATIVAS (CONCLUÍDA, CANCELADA) são cacheadas com TTL de 86.400s (1 dia)
- Retorna campanhas de qualquer status — inclusive CANCELADA e CONCLUÍDA

### Dados de Entrada
| Campo | Tipo | Obrigatório |
|---|---|---|
| `guid` | UUID (query) | ✅ |

### Dados de Saída
| Campo | Tipo |
|---|---|
| `guid` | UUID |
| `titulo` | string |
| `descricao` | string |
| `metaFinanceira` | decimal |
| `valorArrecadado` | decimal |
| `dataInicio` | string |
| `dataFim` | string |
| `statusCampanha` | string |

---

## UC-14 — Listar Todas as Campanhas Ativas (Painel de Transparência)

**Ator:** Qualquer pessoa (público)

### Pré-condições
- O sistema está disponível

### Pós-condições
- A lista de campanhas ativas é retornada com paginação

### Fluxo Principal
1. O sistema recebe a requisição (sem necessidade de autenticação)
2. O sistema aplica os parâmetros de paginação
3. O sistema busca campanhas com status ATIVA no banco de dados
4. O sistema retorna a lista paginada

### Fluxos Alternativos
- **FA01 — Sem parâmetros:** usa padrão (página 1, tamanho 9999 — retorna todas)

### Regras de Negócio
- Endpoint público — não requer autenticação
- Retorna exclusivamente campanhas com status **ATIVA**
- Usado na landing page pública da plataforma

### Dados de Entrada
| Campo | Tipo | Obrigatório | Padrão |
|---|---|---|---|
| `pagina` | int (query) | ❌ | 1 |
| `tamanhoPagina` | int (query) | ❌ | 9999 |

### Dados de Saída
| Campo | Tipo |
|---|---|
| `campanhas` | lista de CampanhaDTO |
| `totalRegistros` | int |
| `pagina` | int |
| `tamanhoPagina` | int |

---

## UC-15 — Cancelar Campanha

**Ator:** GESTOR_ONG

### Pré-condições
- O solicitante está autenticado com perfil GESTOR_ONG
- A campanha existe e está com status **ATIVA**

### Pós-condições
- O status da campanha é alterado para **CANCELADA**
- O cache da campanha é invalidado
- O documento no Elasticsearch é atualizado
- A métrica `campanhas_canceladas_total` é incrementada

### Fluxo Principal
1. O gestor informa o GUID da campanha
2. O sistema verifica se o solicitante é GESTOR_ONG
3. O sistema busca a campanha no banco
4. O sistema chama `campanha.CancelarCampanha(email)` na entidade
5. O sistema persiste a alteração
6. O sistema invalida o cache e atualiza o Elasticsearch
7. O sistema retorna confirmação de cancelamento

### Fluxos Alternativos
- **FA01 — Campanha não encontrada:** lança `400_CAMPAIGN_NOT_FOUND`
- **FA02 — Campanha já cancelada:** entidade lança `422_CAMPAIGN_ALREADY_CANCELLED`
- **FA03 — Campanha concluída:** entidade lança `422_CAMPAIGN_FINISHED_CANNOT_CANCEL`

### Regras de Negócio
- Apenas campanhas ATIVAS podem ser canceladas
- Campanhas CONCLUÍDAS **não** podem ser canceladas
- Doações já realizadas na campanha permanecem no sistema

### Dados de Entrada
| Campo | Tipo | Obrigatório |
|---|---|---|
| `guid` | UUID (query) | ✅ |

### Dados de Saída
| Campo | Tipo |
|---|---|
| — | boolean (`true`) |

---

## UC-16 — Concluir Campanha

**Ator:** GESTOR_ONG

### Pré-condições
- O solicitante está autenticado com perfil GESTOR_ONG
- A campanha existe e está com status **ATIVA**

### Pós-condições
- O status da campanha é alterado para **CONCLUÍDA**
- O cache da campanha é invalidado e recriado com TTL de 1 dia
- O documento no Elasticsearch é atualizado
- A métrica `campahas_concluidas_total` é incrementada

### Fluxo Principal
1. O gestor informa o GUID da campanha
2. O sistema verifica se o solicitante é GESTOR_ONG
3. O sistema busca a campanha no banco
4. O sistema chama `campanha.ConcluirCampanha(email)` na entidade
5. O sistema persiste a alteração
6. O sistema invalida o cache e atualiza o Elasticsearch
7. O sistema retorna confirmação de conclusão

### Fluxos Alternativos
- **FA01 — Campanha não encontrada:** lança `400_CAMPAIGN_NOT_FOUND`
- **FA02 — Campanha não está ativa:** entidade lança `422_CAMPAIGN_ACTIVE_CAN_BE_FINISHED`

### Regras de Negócio
- Apenas campanhas ATIVAS podem ser concluídas
- Campanhas CONCLUÍDAS continuam recebendo doações já pagas (processamento assíncrono)
- Campanha CONCLUÍDA não pode ser cancelada posteriormente

### Dados de Entrada
| Campo | Tipo | Obrigatório |
|---|---|---|
| `guid` | UUID (query) | ✅ |

### Dados de Saída
| Campo | Tipo |
|---|---|
| — | boolean (`true`) |

---

## UC-17 — Alterar Campanha

**Ator:** GESTOR_ONG

### Pré-condições
- O solicitante está autenticado com perfil GESTOR_ONG
- A campanha existe e está com status **ATIVA**

### Pós-condições
- Os dados da campanha são atualizados no banco
- O cache da campanha é invalidado
- O documento no Elasticsearch é atualizado com os novos dados

### Fluxo Principal
1. O gestor informa o GUID e os novos dados da campanha
2. O sistema verifica se o solicitante é GESTOR_ONG
3. O sistema busca a campanha no banco
4. O sistema chama `campanha.AlterarCampanha(...)` na entidade
5. O sistema persiste a alteração
6. O sistema invalida o cache e atualiza o Elasticsearch
7. O sistema retorna os dados atualizados

### Fluxos Alternativos
- **FA01 — Campanha não encontrada:** lança `400_CAMPAIGN_DOES_NOT_EXIST`
- **FA02 — Solicitante não é GESTOR_ONG:** lança `403_CAMPAIGN_CAN_BE_CHANGED_BY_MANAGER`
- **FA03 — Campanha cancelada ou concluída:** entidade lança `422_CAMPAIGN_ACTIVE_CAN_BE_EDITED`

### Regras de Negócio
- Apenas campanhas ATIVAS podem ser editadas
- Apenas GESTOR_ONG pode editar campanhas
- A validação das datas e valores é realizada pela entidade de domínio

### Dados de Entrada
| Campo | Tipo | Obrigatório | Validação |
|---|---|---|---|
| `guid` | UUID | ✅ | |
| `titulo` | string | ✅ | 5–200 caracteres |
| `descricao` | string | ✅ | Máximo 2000 caracteres |
| `metaFinanceira` | decimal | ✅ | Maior que 0 |
| `dataInicio` | datetime | ✅ | |
| `dataFim` | datetime | ✅ | Posterior à data de início |

### Dados de Saída
| Campo | Tipo |
|---|---|
| `guid` | UUID |
| `titulo` | string |
| `descricao` | string |
| `metaFinanceira` | decimal |
| `valorArrecadado` | decimal |
| `dataInicio` | string |
| `dataFim` | string |
| `statusCampanha` | string |

---

## UC-18 — Busca Avançada de Campanhas

**Ator:** DOADOR ou GESTOR_ONG

### Pré-condições
- O solicitante está autenticado
- O Elasticsearch está disponível

### Pós-condições
- A lista de campanhas correspondentes ao termo é retornada ordenada por relevância

### Fluxo Principal
1. O solicitante informa o termo de busca
2. O sistema verifica se o solicitante está autenticado
3. O sistema executa query no Elasticsearch com dual strategy:
   - **BestFields + Fuzziness AUTO:** tolerância a erros de digitação
   - **BoolPrefix:** busca por prefixo em tempo real
4. O sistema aplica boost 3x no campo `titulo`
5. O sistema retorna os resultados ordenados por relevância

### Fluxos Alternativos
- **FA01 — Elasticsearch indisponível:** lança `ApplicationException`
- **FA02 — Nenhum resultado:** retorna lista vazia

### Regras de Negócio
- A busca ocorre nos campos: `titulo` (peso 3x), `descricao`, `statusCampanha`, `dataInicio`, `dataFim`
- `valorArrecadado` **não** é indexado no Elasticsearch
- Fuzziness AUTO: 0 erros (1-2 chars), 1 erro (3-5 chars), 2 erros (6+ chars)

### Dados de Entrada
| Campo | Tipo | Obrigatório |
|---|---|---|
| `termo` | string (query) | ✅ |

### Dados de Saída
| Campo | Tipo |
|---|---|
| `campanhas` | lista de CampanhaSemArrecadacaoDTO |

---

## UC-19 — Realizar Doação

**Ator:** DOADOR ou GESTOR_ONG

### Pré-condições
- O solicitante está autenticado
- A campanha existe e está com status **ATIVA**
- O valor da doação é maior que zero

### Pós-condições
- Uma intenção de doação é registrada
- O evento `DonationCreatedEvent` é publicado no broker
- O Worker de Doações processa a persistência de forma assíncrona
- A métrica `campanha_intencoes_total` é incrementada

### Fluxo Principal
1. O solicitante informa o GUID da campanha e o valor
2. O sistema verifica se o solicitante está autenticado
3. O sistema busca a campanha no banco de dados
4. O sistema valida que a campanha está ATIVA
5. O sistema publica `DonationCreatedEvent` com dados do doador e da campanha
6. O sistema retorna confirmação da intenção de doação

### Fluxos Alternativos
- **FA01 — Campanha não encontrada:** lança `400_CAMPAIGN_DOES_NOT_EXIST`
- **FA02 — Campanha não está ATIVA:** lança `403_CAMPAIGN_DOES_NOT_ACCEPT_DONATION`
- **FA03 — Valor inválido:** lança `400_VALOR_INVALIDO`

### Regras de Negócio
- Apenas campanhas com status ATIVA aceitam novas intenções de doação
- Se a campanha for concluída ou cancelada **durante** o processamento assíncrono, a doação ainda é persistida (já foi paga — obrigação fiscal)
- O CPF do doador é encriptado com AES-256 antes de ser publicado no evento
- O processamento efetivo (persistência + atualização do valor arrecadado) ocorre de forma assíncrona no Worker de Doações

### Dados de Entrada
| Campo | Tipo | Obrigatório | Validação |
|---|---|---|---|
| `guid` | UUID (GuidCampanha) | ✅ | Campanha deve existir e estar ATIVA |
| `valor` | decimal | ✅ | Maior que 0 |

### Dados de Saída
| Campo | Tipo |
|---|---|
| `guidCampanha` | UUID |
| `tituloCampanha` | string |
| `valor` | decimal |
| `nomeUsuario` | string |
| `emailUsuario` | string |

---

## UC-20 — Obter Doações por Campanha

**Ator:** GESTOR_ONG

### Pré-condições
- O solicitante está autenticado com perfil GESTOR_ONG
- O GUID da campanha é válido

### Pós-condições
- A lista de doações da campanha é retornada

### Fluxo Principal
1. O gestor informa o GUID da campanha
2. O sistema verifica se o solicitante é GESTOR_ONG
3. O sistema busca todas as doações da campanha no banco de dados
4. O sistema retorna a lista

### Fluxos Alternativos
- **FA01 — Nenhuma doação encontrada:** retorna lista vazia

### Regras de Negócio
- Exclusivo para GESTOR_ONG — relatório administrativo
- Retorna todas as doações independente do status da campanha

### Dados de Entrada
| Campo | Tipo | Obrigatório |
|---|---|---|
| `guidCampanha` | UUID (query) | ✅ |

### Dados de Saída
| Campo | Tipo |
|---|---|
| `doacoes` | lista de DoacaoDTO |

---

## UC-21 — Obter Doações por Usuário

**Ator:** GESTOR_ONG

### Pré-condições
- O solicitante está autenticado com perfil GESTOR_ONG
- O e-mail informado é válido

### Pós-condições
- A lista de doações do usuário é retornada

### Fluxo Principal
1. O gestor informa o e-mail do usuário
2. O sistema verifica se o solicitante é GESTOR_ONG
3. O sistema busca todas as doações do usuário no banco de dados
4. O sistema retorna a lista

### Fluxos Alternativos
- **FA01 — Nenhuma doação encontrada:** retorna lista vazia
- **FA02 — Usuário removido (LGPD):** as doações permanecem e são retornadas — usuário pode não existir mais, mas as doações são preservadas

### Regras de Negócio
- Exclusivo para GESTOR_ONG — relatório administrativo
- Doações de usuários já removidos (LGPD) continuam acessíveis para fins de auditoria fiscal

### Dados de Entrada
| Campo | Tipo | Obrigatório |
|---|---|---|
| `email` | string (query) | ✅ |

### Dados de Saída
| Campo | Tipo |
|---|---|
| `doacoes` | lista de DoacaoDTO |

---

## UC-22 — Obter Próprias Doações

**Ator:** DOADOR ou GESTOR_ONG

### Pré-condições
- O solicitante está autenticado

### Pós-condições
- A lista de doações do usuário logado é retornada

### Fluxo Principal
1. O sistema identifica o e-mail do solicitante via claims do JWT
2. O sistema busca todas as doações do usuário logado no banco de dados
3. O sistema retorna a lista

### Fluxos Alternativos
- **FA01 — Nenhuma doação encontrada:** retorna lista vazia
- **FA02 — Claims inválidos no token:** lança `UnauthorizedAccessException`

### Regras de Negócio
- Não é necessário informar o e-mail — é extraído automaticamente das claims do JWT
- O usuário só visualiza as próprias doações — sem acesso às de outros usuários

### Dados de Entrada
| Campo | Tipo | Obrigatório |
|---|---|---|
| — | — | Apenas o token JWT no header |

### Dados de Saída
| Campo | Tipo |
|---|---|
| `doacoes` | lista de DoacaoDTO |
