output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_web_subnet_ids" {
  value = slice(aws_subnet.private[*].id, 0, 2)
}

output "private_app_subnet_ids" {
  value = slice(aws_subnet.private[*].id, 2, 4)
}

output "private_db_subnet_ids" {
  value = slice(aws_subnet.private[*].id, 4, 6)
}

# modules/vpc/outputs.tf

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# output "public_route_table_id" {
#   value = aws_route_table.public.id
# }

# output "private_route_table_nat_id" {
#   value = aws_route_table.private-nat.id
# }

# output "private_route_table_id" {
#   value = aws_route_table.private.id
# }

