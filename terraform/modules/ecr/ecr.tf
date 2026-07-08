###############################################################################
# Módulo ECR - Geral
###############################################################################
locals {
  name_prefix      = "${var.project_prefix}"
  version_qty      = "${var.image_version_qty}"
}





############################################################################
# Usuarios API
############################################################################
resource "aws_ecr_repository" "usuarios_api" {
  name                 = "${local.name_prefix}-usuarios-api"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration { scan_on_push = true }
}



resource "aws_ecr_lifecycle_policy" "usuarios_api" {
  repository = aws_ecr_repository.usuarios_api.name
  policy = jsonencode({
    rules = [{ rulePriority = 1, description = "Manter ultimas ${local.version_qty} imagens",
      selection = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = local.version_qty },
      action = { type = "expire" } }]
  })
}





############################################################################
# Campanhas API
############################################################################
resource "aws_ecr_repository" "campanhas_api" {
  name                 = "${local.name_prefix}-campanhas-api"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration { scan_on_push = true }
}



resource "aws_ecr_lifecycle_policy" "campanhas_api" {
  repository = aws_ecr_repository.campanhas_api.name
  policy = jsonencode({
    rules = [{ rulePriority = 1, description = "Manter ultimas ${local.version_qty} imagens",
      selection = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = local.version_qty },
      action = { type = "expire" } }]
  })
}





############################################################################
# DonationWorker
############################################################################
resource "aws_ecr_repository" "donationworker_api" {
  name                 = "${local.name_prefix}-donationworker-api"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration { scan_on_push = true }
}



resource "aws_ecr_lifecycle_policy" "donationworker_api" {
  repository = aws_ecr_repository.donationworker_api.name
  policy = jsonencode({
    rules = [{ rulePriority = 1, description = "Manter ultimas ${local.version_qty} imagens",
      selection = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = local.version_qty },
      action = { type = "expire" } }]
  })
}




############################################################################
# Frontend
############################################################################
resource "aws_ecr_repository" "frontend" {
  name                 = "${local.name_prefix}-frontend"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration { scan_on_push = true }
}



resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = aws_ecr_repository.frontend.name
  policy = jsonencode({
    rules = [{ rulePriority = 1, description = "Manter ultimas ${local.version_qty} imagens",
      selection = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = local.version_qty },
      action = { type = "expire" } }]
  })
}




############################################################################
# Dynamo Proxy
############################################################################
resource "aws_ecr_repository" "dynamo_pg_proxy" {
  name                 = "${local.name_prefix}-dynamo-pg-proxy"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration { scan_on_push = true }
}



resource "aws_ecr_lifecycle_policy" "dynamo_pg_proxy" {
  repository = aws_ecr_repository.dynamo_pg_proxy.name
  policy = jsonencode({
    rules = [{ rulePriority = 1, description = "Manter ultimas ${local.version_qty} imagens",
      selection = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = local.version_qty },
      action = { type = "expire" } }]
  })
}
