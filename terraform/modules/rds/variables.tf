variable "vpc_id" {}
variable "subnet_ids" { type = list(string) }
variable "db_username" { default = "" }
variable "db_password" { sensitive = true }
variable "db_name" { default = "" }
variable "project_prefix"   { default = "" }
variable "public"   { default = "" }