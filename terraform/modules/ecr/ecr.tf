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
