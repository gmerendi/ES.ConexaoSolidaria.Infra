############################################################################
# Project
############################################################################
variable "project_name" {
  description = "Conexao-Solidaria"
  type        = string
  default     = ""
}

variable "project_prefix" {
  description = "Prefixo de projeto a ser utilizado nos nomes dos artefatos"
  type        = string
  default     = "cs"
}


variable "environment" {
  description = "Environment name"
  type        = string
  default     = "Production"
}


variable "image_version_qty" {
  description = "Numero maximo de versoes de imagens a serem mantidas"
  type        = number
  default     = 1
}






############################################################################
# AWS - Configure no tfvars
############################################################################
variable "region" {
  description = "AWS Region"
  type        = string
  default     = ""
}

variable "account_id" {
  description = "Account ID"
  type        = string
  default     = ""
}

variable "services_public_accessible" {
  description = "Define se servicos, como bases de dados sao acessiveis publicamente"
  type        = bool
  default     = false
}

variable "role_arn" {
  description = "ARN do role a ser usado no EKS"
  type        = string
  default     = ""
}

# Mailtrap
variable "mailtrap_api_token" {
  description = "Mailtrap API Token"
  type        = string
  default     = ""
}

variable "mailtrap_inbox_id" {
  description = "Mailtrap Inbox ID"
  type        = string
  default	 = ""
}

variable "admin_email" {
  description = "admin_email"
  type        = string
  default     = ""
}