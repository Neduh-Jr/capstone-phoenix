variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)

  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "aws_availability_zones" {
  type = list(string)

  default = [
    "eu-north-1a",
    "eu-north-1b"
  ]
}

variable "private_subnet_cidrs" {
  type = list(string)

  default = [
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]
}
