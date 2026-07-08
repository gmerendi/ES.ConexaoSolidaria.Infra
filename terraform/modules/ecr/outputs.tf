output "usuarios_api_url"   { value = aws_ecr_repository.usuarios_api.repository_url }
output "campanhas_api_url" { value = aws_ecr_repository.campanhas_api.repository_url }
output "donationworker_api_url" { value = aws_ecr_repository.donationworker_api.repository_url }
output "frontend_url" { value = aws_ecr_repository.frontend.repository_url }
output "dynamo_pg_proxy" { value = aws_ecr_repository.dynamo_pg_proxy.repository_url }
