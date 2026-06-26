###############################################################################
# Módulo Dynamo DB - Geral
###############################################################################
locals {
  name_prefix      = "${var.project_prefix}"
}


###############################################################################
# API Gateway v2 (HTTP API) + VPC Link → NLB privado no EKS
###############################################################################

###############################################################################
# VPC Link — conecta o API Gateway à VPC privada
###############################################################################
resource "aws_apigatewayv2_vpc_link" "this" {
  name               = "${var.project_prefix}-vpc-link"
  security_group_ids = [var.vpc_link_sg_id]
  subnet_ids         = var.private_subnet_ids

  tags = {
    Environment = var.environment
  }
}

###############################################################################
# HTTP API
###############################################################################
resource "aws_apigatewayv2_api" "this" {
  name          = "${var.project_prefix}-apigw"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 300
  }

  tags = {
    Environment = var.environment
  }
}

###############################################################################
# Stage
###############################################################################
resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
  destination_arn = aws_cloudwatch_log_group.apigw.arn
  format = jsonencode({
    requestId      = "$context.requestId"
    ip             = "$context.identity.sourceIp"
    requestTime    = "$context.requestTime"
    httpMethod     = "$context.httpMethod"
    routeKey       = "$context.routeKey"
    status         = "$context.status"
    responseLength = "$context.responseLength"
    integrationError = "$context.integrationErrorMessage"
  })
  }

  default_route_settings {
    throttling_rate_limit  = var.rate_limit_rate
    throttling_burst_limit = var.rate_limit_burst
    logging_level          = "INFO"
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

###############################################################################
# CloudWatch Log Group
###############################################################################
resource "aws_cloudwatch_log_group" "apigw" {
  name              = "/aws/apigateway/${var.project_prefix}-apigw"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}


###############################################################################
# Data Sources — busca ARN dos listeners pelo DNS do NLB
###############################################################################
data "aws_lb" "usuarios" {
  name = split("-", split(".", var.usuarios_api_elb)[0])[0]
}

data "aws_lb_listener" "usuarios" {
  load_balancer_arn = data.aws_lb.usuarios.arn
  port              = 5001
}

data "aws_lb" "campanhas" {
  name = split("-", split(".", var.campanhas_api_elb)[0])[0]
}

data "aws_lb_listener" "campanhas" {
  load_balancer_arn = data.aws_lb.campanhas.arn
  port              = 5002
}



###############################################################################
# Integração — Usuarios API
###############################################################################
resource "aws_apigatewayv2_integration" "usuarios" {
  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = data.aws_lb_listener.usuarios.arn  # ← era o DNS
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.this.id

  request_parameters = {
    "overwrite:path" = "$request.path"
  }
}

###############################################################################
# Integração — Campanhas API
###############################################################################
resource "aws_apigatewayv2_integration" "campanhas" {
  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = data.aws_lb_listener.campanhas.arn  # ← era o DNS
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.this.id

  request_parameters = {
    "overwrite:path" = "$request.path"
  }
}

###############################################################################
# Rotas — Usuarios API
###############################################################################
resource "aws_apigatewayv2_route" "usuarios_auth" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /api/v1/auth/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.usuarios.id}"
}

resource "aws_apigatewayv2_route" "usuarios_api" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /api/v1/usuario/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.usuarios.id}"
}

resource "aws_apigatewayv2_route" "usuarios_root" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /api/v1/usuario"
  target    = "integrations/${aws_apigatewayv2_integration.usuarios.id}"
}

###############################################################################
# Rotas — Campanhas API
###############################################################################
resource "aws_apigatewayv2_route" "campanhas_api" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /api/v1/Campanhas/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}

resource "aws_apigatewayv2_route" "doacoes_api" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /api/v1/Doacoes/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}

resource "aws_apigatewayv2_route" "campanhas_root" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /api/v1/Campanhas"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}

resource "aws_apigatewayv2_route" "doacoes_root" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /api/v1/Doacoes"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}
