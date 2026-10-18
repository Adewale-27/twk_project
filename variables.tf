variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "az" {
  type    = string
  default = "eu-west-1a"
}

variable "env_prefix" {
  type    = string
  default = "twk"
}

variable "vpc_cidr" {
  type    = string
  default = "10.60.0.0/16"
}

variable "dev_subnet_cidr" {
  type    = string
  default = "10.60.2.0/24"
}

variable "instance_name" {
  type    = string
  default = "twk-dev"
}

variable "instance_type" {
  description = "t3.xlarge = 4 vCPU / 16 GB. Use m5.xlarge (4 vCPU / 16 GB) or t3.large (2 vCPU / 8 GB) as alternatives."
  type        = string
  default     = "t3.xlarge"
}

variable "ami_name_filter" {
  type    = string
  default = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "system_disk_size" {
  type    = number
  default = 40
}

variable "data_disk_size" {
  type    = number
  default = 100
}

variable "ssh_cidr" {
  description = "Your public IP in CIDR form, e.g. 203.0.113.10/32. Only this address may use SSH."
  type        = string
}

variable "ssh_key_name" {
  type    = string
  default = "twk-dev-key"
}

variable "ssh_public_key" {
  description = "The PUBLIC half of your SSH key. Safe to store; never the private key."
  type        = string
}

variable "s3_bucket_name" {
  description = "Bucket names are global across all AWS accounts. Make yours unique."
  type        = string
}

variable "tags" {
  type = map(string)
  default = {
    project    = "twk"
    env        = "dev"
    managed-by = "terraform"
  }
}
