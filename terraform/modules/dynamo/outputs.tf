output "dynamodb_audit_table_name" {
  description = "Nome da tabela de audit log para configurar na API"
  value       = aws_dynamodb_table.audit_log.name
}

output "dynamodb_audit_table_arn" {
  description = "ARN da tabela de audit log para as permissoes de IAM"
  value       = aws_dynamodb_table.audit_log.arn
}

output "dynamodb_applog_table_name" {
  description = "Nome da tabela de application log para configurar na API"
  value       = aws_dynamodb_table.app_log.name
}

output "dynamodb_applog_table_arn" {
  description = "ARN da tabela de application log para as permissoes de IAM"
  value       = aws_dynamodb_table.app_log.arn
}