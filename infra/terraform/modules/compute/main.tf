data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  nodes = {
    k3s-server = {
      subnet = 0
      role   = "server"
    }

    k3s-worker-1 = {
      subnet = 1
      role   = "worker"
    }

    k3s-worker-2 = {
      subnet = 0
      role   = "worker"
    }
  }
}

resource "aws_instance" "node" {
  for_each = local.nodes

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id = var.public_subnet_ids[each.value.subnet]

  vpc_security_group_ids = [
    var.security_group_id
  ]

  associate_public_ip_address = true

  root_block_device {
    volume_size           = 15
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = each.key
    Project     = var.project_name
    Environment = var.environment
    Role        = each.value.role
    ManagedBy   = "Terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}