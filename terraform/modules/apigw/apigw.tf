###############################################################################
# Módulo Dynamo DB - Geral
###############################################################################
locals {
  name_prefix = "${var.project_prefix}"
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
# cors_configuration só funciona quando OPTIONS não tem rota ANY cobrindo
# o path — por isso as rotas abaixo usam métodos específicos (GET/POST/PUT/DELETE)
# e o OPTIONS fica sem rota, sendo interceptado automaticamente pelo API GW.
###############################################################################
resource "aws_apigatewayv2_api" "this" {
  name          = "${var.project_prefix}-apigw"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins     = [var.frontend_url]
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers     = ["Content-Type", "Authorization", "Accept"]
    expose_headers    = ["*"]
    allow_credentials = true
    max_age           = 300
  }

  tags = {
    Environment = var.environment
  }
}

###############################################################################
# Deployment explícito — garante que mudanças no CORS sejam propagadas
###############################################################################
resource "aws_apigatewayv2_deployment" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  description = "Deploy com CORS configurado"

  triggers = {
    redeployment = sha1(jsonencode([
      aws_apigatewayv2_api.this.cors_configuration,
      aws_apigatewayv2_route.usuarios_auth_get.id,
      aws_apigatewayv2_route.usuarios_auth_post.id,
      aws_apigatewayv2_route.usuarios_auth_put.id,
      aws_apigatewayv2_route.usuarios_auth_delete.id,
      aws_apigatewayv2_route.usuarios_root_get.id,
      aws_apigatewayv2_route.usuarios_root_post.id,
      aws_apigatewayv2_route.usuarios_root_put.id,
      aws_apigatewayv2_route.usuarios_root_delete.id,
      aws_apigatewayv2_route.usuarios_api_get.id,
      aws_apigatewayv2_route.usuarios_api_post.id,
      aws_apigatewayv2_route.usuarios_api_put.id,
      aws_apigatewayv2_route.usuarios_api_delete.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_apigatewayv2_integration.usuarios,
    aws_apigatewayv2_integration.campanhas,
  ]
}

###############################################################################
# Stage
###############################################################################
resource "aws_apigatewayv2_stage" "this" {
  api_id        = aws_apigatewayv2_api.this.id
  name          = var.environment
  deployment_id = aws_apigatewayv2_deployment.this.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      responseLength   = "$context.responseLength"
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
  integration_uri    = data.aws_lb_listener.usuarios.arn
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
  integration_uri    = data.aws_lb_listener.campanhas.arn
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.this.id

  request_parameters = {
    "overwrite:path" = "$request.path"
  }
}

###############################################################################
# Rotas — Auth (Usuarios API)
# OPTIONS não tem rota → interceptado pelo cors_configuration automaticamente
###############################################################################
resource "aws_apigatewayv2_route" "usuarios_auth_get" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /api/v1/auth/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.usuarios.id}"
}

resource "aws_apigatewayv2_route" "usuarios_auth_post" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /api/v1/auth/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.usuarios.id}"
}

resource "aws_apigatewayv2_route" "usuarios_auth_put" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "PUT /api/v1/auth/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.usuarios.id}"
}

resource "aws_apigatewayv2_route" "usuarios_auth_delete" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "DELETE /api/v1/auth/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.usuarios.id}"
}

###############################################################################
# Rotas — /api/v1/usuario (raiz)
###############################################################################
resource "aws_apigatewayv2_route" "usuarios_root_get" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /api/v1/usuario"
  target    = "integrations/${aws_apigatewayv2_integration.usuarios.id}"
}

resource "aws_apigatewayv2_route" "usuarios_root_post" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /api/v1/usuario"
  target    = "integrations/${aws_apigatewayv2_integration.usuarios.id}"
}

resource "aws_apigatewayv2_route" "usuarios_root_put" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "PUT /api/v1/usuario"
  target    = "integrations/${aws_apigatewayv2_integration.usuarios.id}"
}

resource "aws_apigatewayv2_route" "usuarios_root_delete" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "DELETE /api/v1/usuario"
  target    = "integrations/${aws_apigatewayv2_integration.usuarios.id}"
}

###############################################################################
# Rotas — /api/v1/usuario/{proxy+}
###############################################################################
resource "aws_apigatewayv2_route" "usuarios_api_get" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /api/v1/usuario/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.usuarios.id}"
}

resource "aws_apigatewayv2_route" "usuarios_api_post" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /api/v1/usuario/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.usuarios.id}"
}

resource "aws_apigatewayv2_route" "usuarios_api_put" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "PUT /api/v1/usuario/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.usuarios.id}"
}

resource "aws_apigatewayv2_route" "usuarios_api_delete" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "DELETE /api/v1/usuario/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.usuarios.id}"
}

###############################################################################
# Rotas — /api/v1/Campanhas (raiz)
###############################################################################
resource "aws_apigatewayv2_route" "campanhas_root_get" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /api/v1/Campanhas"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}

resource "aws_apigatewayv2_route" "campanhas_root_post" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /api/v1/Campanhas"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}

resource "aws_apigatewayv2_route" "campanhas_root_put" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "PUT /api/v1/Campanhas"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}

resource "aws_apigatewayv2_route" "campanhas_root_delete" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "DELETE /api/v1/Campanhas"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}

###############################################################################
# Rotas — /api/v1/Campanhas/{proxy+}
###############################################################################
resource "aws_apigatewayv2_route" "campanhas_api_get" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /api/v1/Campanhas/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}

resource "aws_apigatewayv2_route" "campanhas_api_post" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /api/v1/Campanhas/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}

resource "aws_apigatewayv2_route" "campanhas_api_put" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "PUT /api/v1/Campanhas/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}

resource "aws_apigatewayv2_route" "campanhas_api_delete" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "DELETE /api/v1/Campanhas/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}

###############################################################################
# Rotas — /api/v1/Doacoes (raiz)
###############################################################################
resource "aws_apigatewayv2_route" "doacoes_root_get" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /api/v1/Doacoes"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}

resource "aws_apigatewayv2_route" "doacoes_root_post" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /api/v1/Doacoes"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}

resource "aws_apigatewayv2_route" "doacoes_root_put" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "PUT /api/v1/Doacoes"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}

resource "aws_apigatewayv2_route" "doacoes_root_delete" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "DELETE /api/v1/Doacoes"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}

###############################################################################
# Rotas — /api/v1/Doacoes/{proxy+}
###############################################################################
resource "aws_apigatewayv2_route" "doacoes_api_get" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /api/v1/Doacoes/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}

resource "aws_apigatewayv2_route" "doacoes_api_post" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /api/v1/Doacoes/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}

resource "aws_apigatewayv2_route" "doacoes_api_put" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "PUT /api/v1/Doacoes/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}

resource "aws_apigatewayv2_route" "doacoes_api_delete" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "DELETE /api/v1/Doacoes/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.campanhas.id}"
}
