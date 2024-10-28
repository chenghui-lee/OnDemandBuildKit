resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "buildkit-vpc"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "buildkit-private-rt"
  }
  # Route to the internet gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.buildkit-igw.id
  }
}

resource "aws_internet_gateway" "buildkit-igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "buildkit-igw"
  }
}

resource "aws_subnet" "private" {
  for_each = {
    "a" = "10.0.1.0/24"
    "b" = "10.0.2.0/24"
    "c" = "10.0.3.0/24"
    "d" = "10.0.4.0/24"
    "e" = "10.0.5.0/24"
    "f" = "10.0.6.0/24"
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = "${data.aws_region.current.name}${each.key}"

  tags = {
    Name = "buildkit-private-subnet-${each.key}"
  }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# VPC Endpoint for S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
}

# Get current region
data "aws_region" "current" {}
