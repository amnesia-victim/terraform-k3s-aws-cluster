provider "aws" {
  region  = var.k3s_region
  profile = var.aws_profile
}

provider "aws" {
  alias   = "r53"
  region  = var.k3s_region
  profile = var.aws_profile
}

# Get availability zones for the region specified in var.region
data "aws_availability_zones" "all" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.17.0"

  name = "k3s"
  cidr = "10.105.0.0/16"

  azs             = var.aws_azs
  public_subnets  = ["10.105.1.0/24", "10.105.2.0/24", "10.105.3.0/24"]
  private_subnets = ["10.105.4.0/24", "10.105.5.0/24", "10.105.6.0/24"]

  create_database_subnet_group = false

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true

  tags = {
    "Name" = "example"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu-minimal/images/*/ubuntu-bionic-18.04-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "bastion" {
  name   = "example-bastion"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group_rule" "bastion_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "bastion_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}

resource "aws_instance" "bastion" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  subnet_id     = element(module.vpc.public_subnets, 0)
  user_data     = templatefile("${path.module}/bastion.tmpl", { ssh_keys = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCvXfGGHHEc4qI1iOxxEME3G4ONzBN/0YFpCMZD5+cqPaMd4usSu6ChT0ZGeLCR/jpAKY0dTboU5fV6Afv2phnX6ggB1rWRi86CZBO/HKdLWP8sveK3u2jRGgYAKj+sQcUoYZjA12Zfnxw3O+s3hW4ZYfHfzsMWuLUo9yGiA+i1CiX7OPtaLoYLkaJpWc+rS5bA087m9vVaGhnQCHGrFutQdklMEa8dKqQumWIaKGau3DvhLaCfKorHKMeARudijwprjF8imeE0izttAO2SSX/Ftet5LHyJTZGKojtEEpkZeqB7inMocGQcgcNH5musGnQEvez/OEU3ClLEu9kAbbGf amnesiax@Dmitrys-MacBook-Pro.local"] })

  vpc_security_group_ids = [aws_security_group.bastion.id, module.vpc.default_security_group_id]

  tags = {
    Name = "example-bastion"
  }
}

provider "rancher2" {
  api_url   = "https://${var.name}.${var.domain}"
  token_key = "token-4hdgv:zsgmrtqhzf4rf5l7tp6vv6fpxv8jwdxntwsk2bq7mwgmbv8kcg5lsf"
}

resource "rancher2_cluster" "k3s" {
  name = "example-imported"
}

module "k3s_rancher" {
  source                       = "../../"
  vpc_id                       = module.vpc.vpc_id
  aws_region                   = var.k3s_region
  aws_profile                  = var.aws_profile
  private_subnets              = module.vpc.private_subnets
  public_subnets               = module.vpc.public_subnets
  ssh_keys                     = var.ssh_keys
  name                         = var.name
  domain                       = var.domain
  k3s_cluster_secret           = "secretvaluechangeme"
  aws_azs                      = var.aws_azs
  k3s_storage_endpoint         = "postgres"
  db_user                      = "exampleuser"
  db_pass                      = "mD,50cbf5597fd320b6a732ce778082a0359"
  extra_server_security_groups = [module.vpc.default_security_group_id]
  extra_agent_security_groups  = [module.vpc.default_security_group_id]
  private_subnets_cidr_blocks  = module.vpc.private_subnets_cidr_blocks
  registration_command         = rancher2_cluster.k3s.cluster_registration_token[0].command
  providers = {
    aws     = "aws"
    aws.r53 = "aws.r53"
  }
}
