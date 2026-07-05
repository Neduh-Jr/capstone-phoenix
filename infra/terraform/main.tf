data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "./modules/vpc"

  project_name           = var.project_name
  environment            = var.environment
  vpc_cidr               = var.vpc_cidr
  aws_availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "security" {
  source = "./modules/security"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
}

module "compute" {
  source = "./modules/compute"

  project_name = var.project_name
  environment  = var.environment

  public_subnet_ids = module.vpc.public_subnet_ids

  security_group_id = module.security.k3s_security_group_id

  instance_type = var.instance_type

  key_name = var.key_name
}