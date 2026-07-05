output "public_ips" {
  value = {
    for k, v in aws_instance.node :
    k => v.public_ip
  }
}

output "private_ips" {
  value = {
    for k, v in aws_instance.node :
    k => v.private_ip
  }
}

output "instance_ids" {
  value = {
    for k, v in aws_instance.node :
    k => v.id
  }
}