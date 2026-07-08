variable "project_prefix"   { default = "" }
variable "project_name"   { default = "" }
variable "environment" {
  description = "Nome do ambiente (ex: lab, prod)"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs das subnets privadas para o VPC Link"
  type        = list(string)
}

variable "vpc_link_sg_id" {
  description = "Security Group ID para o VPC Link"
  type        = string
}

variable "usuarios_api_elb" {
  description = "DNS do NLB interno da Usuarios API"
  type        = string
}

variable "campanhas_api_elb" {
  description = "DNS do NLB interno da Campanhas API"
  type        = string
}

variable "frontend_url" {
  description = "DNS do Frontend"
  type        = string
}

variable "rate_limit_rate" {
  description = "Requisições por segundo"
  type        = number
  default     = 100
}

variable "rate_limit_burst" {
  description = "Requisições em burst"
  type        = number
  default     = 200
}