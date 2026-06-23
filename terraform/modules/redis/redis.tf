###############################################################################
# Módulo Redis - Geral
###############################################################################
locals {
  name_prefix      = "${var.project_prefix}"
}



###############################################################################
# Security Group para o Redis
###############################################################################
resource "aws_security_group" "redis_sg" {
  name          = "${local.name_prefix}-redis-sg"
  description   = "Permitir acesso ao Redis"
  vpc_id	    = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name          = "${local.name_prefix}-redis-subnet-group"
  subnet_ids    = var.subnet_ids
}



###############################################################################
# Cluster ElastiCache (Redis)
###############################################################################
resource "aws_elasticache_cluster" "redis_cluster" {
  cluster_id           = "${local.name_prefix}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro" 
  num_cache_nodes      = 1                
  parameter_group_name = "default.redis7" 
  port                 = 6379
  security_group_ids   = [aws_security_group.redis_sg.id]
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
}