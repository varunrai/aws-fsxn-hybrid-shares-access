terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.66.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.2.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region = var.aws_location
  default_tags {
    tags = {
      "creator" = var.creator_tag
    }
  }
}

module "ec2-ad" {
  source = "git::https://github.com/varunrai/terraform-aws-ec2activedirectory.git"

  ad_domain               = "ad.fsxn.com"
  ad_service_account      = "fsxnadmin"
  ad_service_account_pwd  = var.default_password
  ad_administrators_group = "FSXN ADMINISTRATORS"
  ec2_keypair             = var.ec2_instance_keypair
  ec2_subnet_id           = aws_subnet.public_subnet[0].id
  ec2_instance_name       = "FSxN"
  ec2_instance_type       = "t3.xlarge"
  ec2_iam_role            = var.ec2_iam_role
  creator_tag             = var.creator_tag
  security_groups_ids     = [aws_security_group.sg-default.id, aws_security_group.sg-ec2-fsx.id]
}

module "vpn" {
  source = "git::https://github.com/varunrai/terraform-aws-clientvpn.git"

  vpc_id           = aws_vpc.vpc.id
  vpn_cidr         = "10.100.0.0/22"
  public_subnet_id = aws_subnet.public_subnet[0].id

  depends_on = [module.ec2-ad, module.fsxontap-fs1]
}

module "fsxontap-fs1" {
  source = "git::https://github.com/varunrai/terraform-aws-fsxn.git"

  creator_tag         = var.creator_tag
  filesystem_password = var.default_password
  filesystem = {
    name                    = "${var.creator_tag}-FSxN-Demo-1"
    storage_capacity_in_gb  = var.fsxn.size_in_megabytes
    throughput_capacity     = var.fsxn.throughput_capacity
    subnet_ids              = [aws_subnet.private_subnet[0].id]
    preferred_subnet_id     = aws_subnet.public_subnet[0].id
    volume_security_style   = var.fsxn.volume_security_style
    security_group_ids      = [aws_security_group.sg-fsx.id]
    deployment_type_multiaz = false

    svm = [
      {
        enable_smb                 = true
        name                       = "svm01"
        root_volume_security_style = "NTFS"
        svm_admin_password         = var.default_password

        ad = {
          svm_netbiosname          = "FSxN_SVM01"
          domain_name              = "AD.FSXN.COM"
          administrators_group     = "FSXN Administrators"
          ou                       = "OU=FSXN,DC=AD,DC=FSXN,DC=com"
          service_account          = "fsxnadmin"
          service_account_password = var.default_password
          dns_ips                  = [module.ec2-ad.instance.private_ip]
        }

        volumes = [{
          name                       = "vol1"
          junction_path              = "/vol1"
          security_style             = "NTFS"
          size_in_megabytes          = 1024000
          skip_final_backup          = true
          storage_efficiency_enabled = true
          tiering_policy             = "AUTO"
          cooling_period             = 7
          },
          {
            name                       = "vol2"
            junction_path              = "/vol2"
            security_style             = "NTFS"
            size_in_megabytes          = 1024000
            skip_final_backup          = true
            storage_efficiency_enabled = true
            tiering_policy             = "NONE"
            cooling_period             = null
          },
          {
            name                       = "vol3"
            junction_path              = "/vol3"
            security_style             = "NTFS"
            size_in_megabytes          = 1024000
            skip_final_backup          = true
            storage_efficiency_enabled = true
            tiering_policy             = "ALL"
            cooling_period             = null
        }]
      }
    ]
  }
}
