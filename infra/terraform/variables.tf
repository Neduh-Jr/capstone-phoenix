variable "project_name" {
  description = "The name of the project in which to create the resources."
  type        = string
  default     = "taskapp-phoenix"
}

variable "environment" {
  description = "The environment in which to create the resources."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "The AWS region in which to create the resources."
  type        = string
  default     = "eu-north-1"
}

# Network variables
variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

}

#EC2 variables
variable "instance_type" {
  description = "The type of EC2 instance to create."
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "The name of the SSH key pair to use for the EC2 instance. It should be created in the AWS region specified by aws_region."
  type        = string
}

variable "aws_availability_zones" {
  description = "Availability Zones for the VPC"
  type        = list(string)

  default = [
    "eu-north-1a",
    "eu-north-1b"
  ]
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into cluster nodes"
  type        = list(string)
}
