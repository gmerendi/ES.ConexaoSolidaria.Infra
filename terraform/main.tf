data "aws_caller_identity" "current" {}
############################################################################
# Secret Manager - Deve ser apagado na entrega.
############################################################################
resource "aws_secretsmanager_secret" "rds_secret" {
  name              = "${var.project_prefix}-rds-secret-${var.account_id}" # Com ID para evitar erro de nome já usado no Lab
  description       = "Credenciais do banco de dados RDS"
  
  # Importante para o Lab: permite deletar e recriar sem esperar 7 dias
  recovery_window_in_days = 0 
}

resource "aws_secretsmanager_secret_version" "rds_secret_val" {
  secret_id         = aws_secretsmanager_secret.rds_secret.id
  secret_string     = jsonencode({
                                    username = "Fiap"
                                    password = "F1apPa55w0rd"
                                 })
}





############################################################################
# Network
############################################################################
module "network" {
  source            = "./modules/network" 

  vpc_cidr          = "10.0.0.0/16"
  region            = var.region
  project_prefix    = var.project_prefix
}
# Saidas:
#           vpc_id
#           subnet_ids (public e private)
#		    private_subnet_ids    
#		    dynamodb_vpc_endpoint_id





############################################################################
# Elastic Container Registry (ECR)
############################################################################
module "ecr" {
  source            = "./modules/ecr" 

  project_prefix    = var.project_prefix
  image_version_qty = var.image_version_qty
}
# Saidas:
#		    usuarios_api_url
#           campanhas_api_url
#           donationworker_api_url





############################################################################
# Base de Dados RDS - Postgres
############################################################################
module "rds" {
  source            = "./modules/rds" 

  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.private_subnet_ids

  # Passando as credenciais do Secrets Manager
  db_username       = jsondecode(aws_secretsmanager_secret_version.rds_secret_val.secret_string)["username"]
  db_password       = jsondecode(aws_secretsmanager_secret_version.rds_secret_val.secret_string)["password"]
  db_name	        = var.project_prefix

  project_prefix    = var.project_prefix
  public            = var.services_public_accessible
}
# Saidas:
#           db_endpoint





############################################################################
# Base de Dados Dynamo DB - Logs
############################################################################
module "dynamo" {
  source            = "./modules/dynamo" 

  project_prefix    = var.project_prefix
  project_name      = var.project_name
  environment       = var.environment
}
# Saidas:
#           dynamodb_table_name
#           dynamodb_table_arn





############################################################################
# Redis - Elastic Cache
############################################################################
module "redis" {
  source            = "./modules/redis" 

  project_prefix    = var.project_prefix
  #project_name      = var.project_name
  #environment       = var.environment

  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.private_subnet_ids
}
# Saidas:
#		   redis_endpoint





############################################################################
# Elastic Kubernetes Service (EKS)
############################################################################
module "eks" {
  source            = "./modules/eks" 

  project_prefix    = var.project_prefix
  project_name      = var.project_name
  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.subnet_ids
  region            = var.region
  role_arn			= var.role_arn
  node_instance     = "t3.medium"
}
# Saidas:
#		   cluster_name
#          cluster_endpoint






############################################################################
# Messaging (SQS + Lambda Email + Lambda Processamento pagamento)
############################################################################
module "messaging" {
  source = "./modules/sqs"

  # Variáveis necessárias para a Lambda
  environment       = var.environment
  sender_email      = "notificacao@fiapcloudgames.com.br" 
  region            = var.region
  project_name	    = var.project_name
  project_prefix    = var.project_prefix

  # Variáveis do Mailtrap
  mailtrap_api_token = var.mailtrap_api_token
  mailtrap_inbox_id  = var.mailtrap_inbox_id
  admin_email        = var.admin_email
}
# Saidas:
#           user_created_queue_url
#           donation_cre_queue_url
#           order_created_queue_url
#           payment_request_queue_url
#           payment_processed_queue_url
#           ame_to_library_queue_url





