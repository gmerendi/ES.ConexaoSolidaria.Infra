output "api_endpoint" {
  description = "URL base do API Gateway"
  value       = aws_apigatewayv2_stage.this.invoke_url
}

output "api_id" {
  description = "ID do API Gateway"
  value       = aws_apigatewayv2_api.this.id
}

output "vpc_link_id" {
  description = "ID do VPC Link"
  value       = aws_apigatewayv2_vpc_link.this.id
}