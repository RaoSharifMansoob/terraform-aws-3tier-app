module "networking" {
  source = "../../modules/networking"

  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  app_subnet_cidrs    = var.app_subnet_cidrs
  db_subnet_cidrs     = var.db_subnet_cidrs
}

module "security" {
  source = "../../modules/security"

  environment = var.environment
  vpc_id      = module.networking.vpc_id
}

module "load_balancer" {
  source = "../../modules/load_balancer"

  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
}

module "compute" {
  source = "../../modules/compute"

  environment           = var.environment
  app_subnet_ids        = module.networking.app_subnet_ids
  app_security_group_id = module.security.app_security_group_id
  target_group_arn      = module.load_balancer.target_group_arn

  instance_type    = var.instance_type
  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size
}

module "database" {
  source = "../../modules/database"

  environment          = var.environment
  db_subnet_ids        = module.networking.db_subnet_ids
  db_security_group_id = module.security.db_security_group_id

  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  db_instance_class       = var.db_instance_class
  db_allocated_storage    = var.db_allocated_storage
  backup_retention_period = var.backup_retention_period
}
