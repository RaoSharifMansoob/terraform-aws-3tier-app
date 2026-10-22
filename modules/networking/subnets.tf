
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name        = "terraform-3tier-${var.environment}-public-${count.index + 1}"
    Tier        = "public"
    Project     = "terraform-aws-3tier-app"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "app" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.app_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name        = "terraform-3tier-${var.environment}-app-${count.index + 1}"
    Tier        = "application"
    Project     = "terraform-aws-3tier-app"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "db" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.db_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name        = "terraform-3tier-${var.environment}-db-${count.index + 1}"
    Tier        = "database"
    Project     = "terraform-aws-3tier-app"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
