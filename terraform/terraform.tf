data "aws_ami" "ubuntu_jammy" {
  
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

provider "aws" {
    region = "us-east-2"
    profile = "backup-production"
}


resource "aws_key_pair" "ec2_kafka" {
    key_name = "ec2_kafka"
    public_key = file("~/.ssh/ec2_kafka.pub")
  
}

variable "server_name" {
  type = list(string)
  default = ["kafka-1a-backup-production", "kafka-2b-backup-production", "kafka-3c-backup-production"]
}

variable "az" {
  type = list(string)
  default = ["a", "b", "c"]
  
}

variable "environment" {
  type = string
  default = "backup-production"
}

variable "region" {
  type = string
  default = "us-east-2"
}

module "network" {
  source            = "./modules/network"
  vpc_begin_range   =  "10.203"
  env               =  "backup-production"
  azs               =  ["us-east-2a", "us-east-2b", "us-east-2c"]
  az_codes          =  ["a", "b", "c"]
  vpn_connections   =  []
  vpn_connection_routes =  []
  external_routes   =  []
  region            =  "us-east-2"
}


locals {
  subnet_options = {
  
    app-private-a = lookup(module.network.subnets-app-private, "a", "")
  
    app-private-b = lookup(module.network.subnets-app-private, "b", "")
  
    app-private-c = lookup(module.network.subnets-app-private, "c", "")
  
  
    db-private-a = lookup(module.network.subnets-db-private, "a", "")
  
    db-private-b = lookup(module.network.subnets-db-private, "b", "")
  
    db-private-c = lookup(module.network.subnets-db-private, "c", "")
  
  
    public-a = lookup(module.network.subnets-public, "a", "")
  
    public-b = lookup(module.network.subnets-public, "b", "")
  
    public-c = lookup(module.network.subnets-public, "c", "")
  
  }
    security_group_options = {
    "public" = [module.network.proxy-sg, module.network.ssh-sg, module.network.vpn-connections-sg]
    "app-private" = [module.network.app-private-sg, module.network.ssh-sg, module.network.vpn-connections-sg]
    "db-private" = [module.network.db-private-sg, module.network.ssh-sg, module.network.vpn-connections-sg]
  }
}


module "server_iam_role" {
  source = "./modules/server/iam"
  environment = var.environment
  account_id = "213307118311"
  region_name = var.region
  account_alias =  "backup-production"
  s3_blob_db_s3_bucket = ""
}

module "server__kafka_backup-production" {
  count = length(var.server_name)
  
  source = "./modules/server"

  server_name = var.server_name[count.index]
  server_instance_type = "t3a.nano"
  network_tier = "db-private"
  az = var.az[count.index]
  volume_size = 10
  volume_type = "gp3"
  volume_encrypted = true
  secondary_volume_size = 0
  secondary_volume_type = ""
  secondary_volume_encrypted = false
  secondary_volume_enable_cross_region_backup = false
  server_auto_recovery = false
  iam_instance_profile = module.server_iam_role.commcare_server_instance_profile
  metadata_tokens = "required"
  enable_cross_region_backup = false


  server_image = data.aws_ami.ubuntu_jammy.id

  environment = var.environment
  vpc_id = module.network.vpc-id
  subnet_options = local.subnet_options
  security_group_options = local.security_group_options
  key_name = aws_key_pair.ec2_kafka.key_name
  group_tag= "kafka"
}

module "server__control4-backup-production" {
  source = "./modules/server"

  server_name = "control4-backup-production"
  server_instance_type = "t3a.micro"
  network_tier = "app-private"
  az = "a"
  volume_size = 60
  volume_type = "gp3"
  volume_encrypted = true
  secondary_volume_size = 0
  secondary_volume_type = ""
  secondary_volume_encrypted = false
  secondary_volume_enable_cross_region_backup = false
  server_auto_recovery = false
  iam_instance_profile = module.server_iam_role.commcare_server_instance_profile
  metadata_tokens = "required"
  enable_cross_region_backup = false


  server_image = data.aws_ami.ubuntu_jammy.id

  environment = var.environment
  vpc_id = module.network.vpc-id
  subnet_options = local.subnet_options
  security_group_options = local.security_group_options
  key_name = aws_key_pair.ec2_kafka.key_name
  group_tag= "control"
}