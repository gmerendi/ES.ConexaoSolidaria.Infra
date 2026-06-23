###############################################################################
# Módulo RDS - Geral
###############################################################################
locals {
  name_prefix      = "${var.project_prefix}"
}





############################################################################
# Subnet Group para o RDS - Onde o banco reside (Rede Privada)
############################################################################
resource "aws_db_subnet_group" "rds_private_group" {
  name       = "${local.name_prefix}-rds_private_group"
  subnet_ids = var.subnet_ids
  tags = {
    Name = "${local.name_prefix}-rds-subnet-group"
  }
}





############################################################################
# Security Group (Porta 5432)
############################################################################
resource "aws_security_group" "rds_sg" {
  name   = "${local.name_prefix}-rds-sg"
  description = "Acesso ao Postgres apenas de dentro da VPC"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
    # Segurança: Permite apenas o tráfego interno da VPC
    #cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}





############################################################################
# Instância do RDS
############################################################################
resource "aws_db_instance" "postgres" {
  identifier           = "${local.name_prefix}-postgres-db"
  engine               = "postgres"
  engine_version       = "16"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  
  # Credenciais (Vindas de secret)
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password

  # Configuração de Rede
  db_subnet_group_name   = aws_db_subnet_group.rds_private_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  
  skip_final_snapshot    = true
  publicly_accessible    = var.public

  multi_az               = false

  tags = {
    Name = "${local.name_prefix}-rds"
  }
}