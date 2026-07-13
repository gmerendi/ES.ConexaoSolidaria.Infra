# Glossário de Domínio — Conexão Solidária

> **Ubiquitous Language** — Domain Driven Design
> Este glossário define os termos do domínio com precisão. Todos os membros do time, código, documentação e comunicação devem usar estes termos consistentemente.

---

## Entidades e Agregados

### Usuário
Pessoa física cadastrada na plataforma. Possui uma identidade única (email) e um perfil de acesso (role). Pode ser um `Doador` ou um `GestorONG`. 
Um usuário não pode ter múltiplos perfis simultaneamente e será identificado por seu e-mail.

### Doador
Usuário com role `Doador`. Pode visualizar campanhas ativas, realizar doações e consultar seu histórico. Não tem acesso a funcionalidades de gestão.

### Gestor da ONG
Usuário com role `GestorONG`. Responsável pela criação e gestão de campanhas, visualização de relatórios e administração de usuários. 
O primeiro GestorONG é criado via migration.

### Campanha
Iniciativa de arrecadação financeira criada pela ONG com objetivo específico, prazo definido e meta financeira. 
Uma campanha possui um ciclo de vida: `Ativa` → `Concluída` ou `Cancelada`.

### Doação
Contribuição financeira realizada por um `Doador` para uma `Campanha` ativa. 
A doação possui dois momentos: a **intenção** (quando o Doador submete) e a **efetivação** (quando o Worker processa e atualiza o total da Campanha).

### Notificação
Comunicação eletrônica (email) enviada a um usuário em resposta a eventos do sistema.

---

## Value Objects

### Email
O endereço de e-mail do usuário que o identificano sistema - será o login do usuário.

### Cpf
O número do cadastro de pessoa física do governo brasileiro.

### Password
A senha alfanumerica que possibilita a autenticação do usuário.

### Meta Financeira
Valor decimal positivo que representa o objetivo de arrecadação de uma campanha. Deve ser maior que zero. Não representa um compromisso de alcance.

### Valor Arrecadado
Soma acumulada de todas as doações efetivadas para uma campanha específica. 
Atualizado exclusivamente pelo Worker após processamento assíncrono. Nunca atualizado diretamente pela API de Doações.

### Percentual Atingido (`PercentageReached`)
Valor calculado: `(ValorArrecadado / MetaFinanceira) × 100`. Campo derivado, não persistido — calculado em tempo de resposta.

### Token JWT (`AccessToken`)
Token de acesso de curta duração contendo claims. Assinado com chave privada RS256.

---

## Status e Enumerações

### Status de Campanha
| Valor | Descrição |
|---|---|
| `Active` (Ativa) | Campanha em andamento, aberta para doações |
| `Completed` (Concluída) | Campanha encerrada (por prazo ou manualmente pelo gestor) |
| `Cancelled` (Cancelada) | Campanha interrompida antes do prazo pelo gestor |

### Status de Usuário
| Valor | Descrição |
|---|---|
| `Active` (Ativo) | Usuário com acesso normal ao sistema |
| `Suspended` (Suspenso) | Acesso bloqueado por decisão do GestorONG |
| `Removed` (Removido) | Dados anonimizados a pedido do usuário (LGPD) |

### Role de Usuário
| Valor | Descrição |
|---|---|
| `Doador` | Perfil de doador — acesso a doações e histórico próprio |
| `GestorONG` | Perfil administrativo — acesso completo |

---

## Eventos de Domínio

### `UserCreatedEvent`
Publicado pelo serviço de Usuários quando um novo usuário é criado (via cadastro público ou por um Gestor). Consumido pelo serviço de Notificações para envio do email de boas-vindas.

### `DonationCreatedEvent`
Publicado pelo serviço de Doações quando uma intenção de doação é registrada. Consumido pelo Worker para processamento assíncrono e atualização do ValorArrecadado.

### `DoacaoProcessedEvent`
Publicado pelo serviço de Doações simultaneamente ao `DoacaoRecebidaEvent`. Consumido pelo serviço de Notificações para envio do email de agradecimento ao Doador.

---

## Conceitos Técnicos do Domínio

### Intenção de Doação
O ato do Doador submeter uma doação. Neste momento, um evento é publicado, para ser consumido por um worker. O ValorArrecadado da campanha ainda NÃO foi atualizado.

### Processamento de Doação
Etapa executada pelo Worker que efetiva a Intenção de Doação: atualiza atomicamente o ValorArrecadado e muda o status da doação para `Processada`.

### Painel de Transparência
Interface pública (sem autenticação) que exibe campanhas ativas com seus valores arrecadados. Dados atualizados a cada 1 minuto via invalidação de cache.

### Auditoria (`Audit Trail`)
Registro imutável no DynamoDB de todas as ações realizadas no sistema. Contém: quem fez, o quê, quando, antes e depois. Usado para rastreabilidade, compliance e investigação de fraudes.

### Dead Letter Queue (DLQ)
Fila especial no RabbitMQ que recebe mensagens que falharam o número máximo de tentativas de processamento. Permite investigação e reprocessamento manual.

---
