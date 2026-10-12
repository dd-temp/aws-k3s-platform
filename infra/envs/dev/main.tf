provider "aws" {
  region = "us-east-1"
}

module "network" {
  source                = "../../modules/network"
  aws_vpc_cidr          = "10.0.0.0/16"
  aws_subnet_cidr       = "10.0.1.0/24"
  aws_availability_zone = "us-east-1a"
}

module "ec2" {
  source        = "../../modules/ec2"
  instance_type = "c7i-flex.large"
  vpc_id        = module.network.vpc_id
  subnet_id     = module.network.subnet_id
}