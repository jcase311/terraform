
variable "vpc_id" {
  description = "The VPC ID to launch EC2 instances in"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to spread EC2s across AZs"
  type        = list(string)
}

variable "domain_name" {
  description = "The domain name for the TLS certificate"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate to use for HTTPS listener"
  type        = string
  default     = "arn:aws:acm:us-east-2:717279727434:certificate/6577a49e-4139-4352-b046-971a93494ffb"
}

variable "key_name" {
  description = "Name of the EC2 key pair"
  type        = string
}

#variable "waf_web_acl_arn" {
#  description = "ARN of the WAF Web ACL to associate with the ALB"
#  type        = string
#}
