
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.secure_vpc.vpc_id
}

output "public_subnets" {
  description = "The public subnets"
  value       = module.secure_vpc.public_subnets
}

output "private_subnets" {
  description = "The private subnets"
  value       = module.secure_vpc.private_subnets
}

output "database_subnets" {
  description = "The database subnets"
  value       = module.secure_vpc.database_subnets
}
