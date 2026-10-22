
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "terraform-3tier-${var.environment}-public-rt"
    Project     = "terraform-aws-3tier-app"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table" "app" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "terraform-3tier-${var.environment}-app-rt"
    Project     = "terraform-aws-3tier-app"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "terraform-3tier-${var.environment}-db-rt"
    Project     = "terraform-aws-3tier-app"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "app" {
  count = 2

  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app.id
}

resource "aws_route_table_association" "db" {
  count = 2

  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}
