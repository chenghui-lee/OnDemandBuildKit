output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = values(aws_subnet.private)[*].id
}

output "s3_gateway_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}