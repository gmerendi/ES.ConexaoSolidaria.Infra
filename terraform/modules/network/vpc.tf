###############################################################################
# Módulo VPC - Geral
###############################################################################
locals {
  name_prefix      = "${var.project_prefix}"
  region           = "${var.region}"
}





###############################################################################
# VPC
###############################################################################
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${local.name_prefix}-vpc" }
}





############################################################################
# Subnets publicas - 2 regioes
############################################################################
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${local.region}a"
  map_public_ip_on_launch = true

  tags = { Name = "${local.name_prefix}-subnet-public-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${local.region}b"
  map_public_ip_on_launch = true

  tags = { Name = "${local.name_prefix}-subnet-public-b" }
}





############################################################################
# Subnets privadas - 2 regioes
############################################################################
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "${local.region}a"
  map_public_ip_on_launch = false

  tags = { Name = "${local.name_prefix}-subnet-private-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "${local.region}b"
  map_public_ip_on_launch = false

  tags = { Name = "${local.name_prefix}-subnet-private-b" }
}





############################################################################
# Internet Gateway - Conecta VPC com a internet
############################################################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags   = { Name = "${local.name_prefix}-igw" }
}





############################################################################
# NAT Gateway - Conecta rede privada com a internet
############################################################################
# O NAT Gateway precisa de um IP estatico publico.
resource "aws_eip" "nat_eip" {
  depends_on = [aws_internet_gateway.igw]

  tags = { Name = "${local.name_prefix}-nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_a.id # Colocado na 1a apenas por custo.

  tags = { Name = "${local.name_prefix}-nat-gateway" }

  # Aguarda o IGW estar pronto
  depends_on = [aws_internet_gateway.igw]
}





############################################################################
# Tabela de Rotas publicas (Direciona 0.0.0.0/0 para o IGW)
############################################################################
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${local.name_prefix}-rt-public" }
}

# Associacoes da Tabela Publica
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_1b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}





############################################################################
# Tabela de Rotas privadas (Apenas trafego local)
############################################################################
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = { Name = "${local.name_prefix}-rt-private" }
}

# Associa  es da Tabela Privada
resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_1b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
}




############################################################################
# Tabela de Rotas privadas para internet - NAT Gateway
############################################################################
resource "aws_route" "private_internet_access" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}





###############################################################################
# VPC Endpoint para DynamoDB 
###############################################################################
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${var.region}.dynamodb"
  
  # Aqui você usa a rota privada que já existe neste módulo
  route_table_ids = [aws_route_table.private_rt.id]

  tags = {
    Name = "${var.project_prefix}-dynamodb-endpoint"
  }
}

