provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"
}

module "iam" {
  source = "./modules/iam"
}

module "s3" {
  source            = "./modules/s3"
  bucket_name       = var.bucket_name
  ec2_instance_role = module.iam.iam_role_name
  vpc_id            = module.vpc.vpc_id
}

module "ec2-sg" {
  source = "./modules/ec2-sg"
  vpc_id = module.vpc.vpc_id
}

module "ec2" {
  source                   = "./modules/ec2"
  iam_instance_profile     = module.iam.iam_instance_profile
  subnet_ids               = module.vpc.subnet_ids
  tailscale_auth_key_x86   = var.tailscale_auth_key_x86
  tailscale_auth_key_arm64 = var.tailscale_auth_key_arm64
  security_group_id        = module.ec2-sg.security_group_id
}
