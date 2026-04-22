variable "aws_region" {
  description = "AWS region where Arcadia will run"
  type        = string
}

variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Existing public subnet ID"
  type        = string
}

variable "ssh_public_key" {
  description = "Public SSH key used to create the AWS key pair"
  type        = string
  sensitive   = true
}

variable "instance_name" {
  description = "Name prefix for the Arcadia EC2 instance"
  type        = string
  default     = "arcadia"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.large"
}

variable "ami_ssm_parameter" {
  description = "SSM parameter with the latest Amazon Linux AMI"
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

variable "volume_size" {
  description = "EC2 root volume size in GiB"
  type        = number
  default     = 30
}

variable "allowed_ingress_cidrs" {
  description = "CIDRs allowed to reach the instance over HTTP and SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_pair_name" {
  description = "AWS key pair name"
  type        = string
  default     = "arcadia-lab-key"
}

variable "arcadia_repo_url" {
  description = "Arcadia source repository URL"
  type        = string
  default     = "https://github.com/pupapaik/f5-arcadia.git"
}

variable "arcadia_repo_ref" {
  description = "Arcadia source repository git ref"
  type        = string
  default     = "master"
}
