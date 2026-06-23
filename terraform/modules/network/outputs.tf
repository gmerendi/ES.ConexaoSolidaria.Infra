output "vpc_id"     { value = aws_vpc.vpc.id }
output "subnet_ids" { value = [aws_subnet.public_a.id, aws_subnet.public_b.id, aws_subnet.private_a.id, aws_subnet.private_b.id] }
output "private_subnet_ids" { value = [aws_subnet.private_a.id, aws_subnet.private_b.id] }
output "dynamodb_vpc_endpoint_id" { value = aws_vpc_endpoint.dynamodb.id }