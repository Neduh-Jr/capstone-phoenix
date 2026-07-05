output "public_ips" {
  value = module.compute.public_ips
}

output "private_ips" {
  value = module.compute.private_ips
}

output "instance_ids" {
  value = module.compute.instance_ids
}

output "vpc_id" {
  value = module.vpc.vpc_id
}