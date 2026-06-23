variable "role"					{ default = "" }
variable "region"				{ default = "" }
variable "vpc_id"				{ default = "" }
variable "subnet_ids"			{ type = list(string) }
variable "role_arn"				{ default = "" }
variable "node_instance"		{ default = "" }
variable "project_name"			{ default = "" }
variable "project_prefix"		{ default = "" }
