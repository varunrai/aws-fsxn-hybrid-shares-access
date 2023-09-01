variable "aws_location" {
  type = string
}
variable "creator_tag" {
  type = string
}
variable "environment" {
  type    = string
  default = "Demo"
}
variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "default CIDR range of the VPC"
}
variable "vpc_private_subnets" {
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "default CIDR range of the VPC"
}
variable "vpc_public_subnets" {
  default     = ["10.0.4.0/24", "10.0.5.0/24"]
  description = "default CIDR range of the VPC"
}

variable "default_password" {
  type      = string
  sensitive = true
}
variable "ec2_instance_keypair" {
  type = string
}
variable "ec2_iam_role" {
  description = "Value of the EC2 IAM Role"
  type        = string
}

variable "ec2_security_group_config" {
  default = [
    {
      description      = "RDP Port"
      port             = 3389
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    },
    {
      description      = "Within VPC Traffic/Ports"
      port             = 0
      protocol         = "-1"
      cidr_blocks      = ["10.0.0.0/16"]
      ipv6_cidr_blocks = ["::/0"]
    },
    {
      description      = "SSH Port"
      port             = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  ]
}
variable "fsxn" {
  type = object({
    volume_security_style = string
    size_in_megabytes     = number
    throughput_capacity   = number
  })
}
