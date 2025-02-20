module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  public_subnets  = [for k, v in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, k)]
  private_subnets = [for k, v in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, k + 3)]

  enable_nat_gateway     = true
  single_nat_gateway     = true  # Add this for cost savings in dev
  enable_dns_hostnames   = true
  enable_dns_support     = true

  # Enable auto-assign public IP on public subnets
  map_public_ip_on_launch = true

  # Make sure NAT Gateway is in public subnet
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
    "Tier"                                      = "Public"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
    "Tier"                                      = "Private"
  }

  tags = {
    Environment = "dev"
  }
} 