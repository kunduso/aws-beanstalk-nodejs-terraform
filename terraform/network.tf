module "vpc" {
  source                  = "github.com/kunduso/terraform-aws-vpc?ref=0a9311595ae226011d90770148dcafd091c06280"
  region                  = var.region
  enable_internet_gateway = true
  enable_nat_gateway      = true
  enable_dns_support      = true
  enable_dns_hostnames    = true
  vpc_cidr                = "10.20.30.0/24"
  subnet_cidr_public      = ["10.20.30.0/26", "10.20.30.64/26"]
  subnet_cidr_private     = ["10.20.30.128/26", "10.20.30.192/26"]
  #CKV_TF_1: Ensure Terraform module sources use a commit hash
  #checkov:skip=CKV_TF_1: This is a self hosted module where the version number is tagged rather than the commit hash.
}