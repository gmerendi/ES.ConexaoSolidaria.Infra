###############################################################################
# Módulo Dynamo DB - Geral
###############################################################################
locals {
  name_prefix      = "${var.project_prefix}"
}





###############################################################################
# Base de dados Audit Log
###############################################################################
resource "aws_dynamodb_table" "audit_log" {
  name           = "${var.project_prefix}-audit-log"
  billing_mode   = "PAY_PER_REQUEST" # Escala automaticamente conforme o uso da API

  # PK: Identifica o domínio (ex: USERS, CATALOG, PAYMENTS)
  hash_key       = "PK"
  range_key      = "SK"      

  # Definição dos atributos que compõem as chaves
  attribute {
    name = "PK"
    type = "S" 
  }

  attribute {
    name = "SK"
    type = "S" 
  }


  # Índice Global Secundário (GSI) 
  # Permite buscar todos os logs de um GUID específico, independente do serviço.
  global_secondary_index {
    name               = "ResourceIdIndex"
    hash_key           = "ResourceId"
    range_key          = "SK"
    projection_type    = "ALL"
  }

  attribute {
    name = "ResourceId"
    type = "S" 
  }

  # Útil para deletar logs automaticamente após X tempo e economizar custo
  ttl {
    attribute_name = "TTL"
    enabled        = true
  }


  tags = {
    Name        = "${var.project_prefix}-audit-log"
    Environment = var.environment
    Project     = var.project_name
  }
}





###############################################################################
# Base de dados Application Log
###############################################################################
resource "aws_dynamodb_table" "app_log" {
  name         = "${var.project_prefix}-app-log"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "CorrelationId"
  range_key = "Timestamp"

  attribute {
    name = "CorrelationId"
    type = "S"
  }

  attribute {
    name = "Timestamp"
    type = "S"
  }

  # GSI para Event Sourcing
  # Permite filtrar por tipo (Log=0, Evento=1) e ordenar por data
  attribute {
    name = "Type"
    type = "N"  # número — 0 = LOG, 1 = EVENT
  }

  global_secondary_index {
    name            = "GSI_EventSourcing"
    hash_key        = "Type"
    range_key       = "Timestamp"
    projection_type = "ALL"
  }

  # TTL — deleta logs antigos automaticamente, economiza custo
  ttl {
    attribute_name = "TTL"
    enabled        = true
  }

  tags = {
    Name        = "${var.project_prefix}-app-log"
    Environment = var.environment
    Project     = var.project_name
  }
}