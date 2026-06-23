###############################################################################
# Módulo EKS - Geral
###############################################################################
locals {
  name_prefix      = "${var.project_prefix}"
  region           = "${var.region}"
}





############################################################################
# Role and Security Groups
############################################################################
# data "aws_iam_role" "role" {
#   name = var.role
# }




resource "aws_security_group" "eks_sg" {
  name        = "${local.name_prefix}-eks-sg"
  description = "Security group EKS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${local.name_prefix}-eks-sg" }
}





############################################################################
# Cluster EKS
############################################################################
resource "aws_eks_cluster" "eks" {
  name     = "${local.name_prefix}-cluster"
  role_arn = var.role_arn
  version  = "1.31"

  vpc_config {
    subnet_ids             = var.subnet_ids
    security_group_ids     = [aws_security_group.eks_sg.id]
    endpoint_public_access = true
  }

  tags = { Project = var.project_name }
}





############################################################################
# Node Group
############################################################################
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${local.name_prefix}-nodes"
  node_role_arn   = var.role_arn
  subnet_ids      = var.subnet_ids
  instance_types  = [var.node_instance]
  disk_size       = 20

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 1
  }

  update_config { max_unavailable = 1 }

  tags = { Project = var.project_name }
}
