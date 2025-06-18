
provider "aws" {
  alias  = "use2"
  region = "us-east-2"
}

data "aws_route53_zone" "primary_use2" {
  name         = "onthespotsecurity.com."
  private_zone = false
}

resource "aws_acm_certificate" "wildcard_cert_use2" {
  provider          = aws.use2
  domain_name       = "*.onthespotsecurity.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "wildcard.onthespotsecurity.com"
  }
}

resource "aws_acm_certificate_validation" "validate_cert_use2" {
  provider        = aws.use2
  certificate_arn = aws_acm_certificate.wildcard_cert_use2.arn
  validation_record_fqdns = [
    for dvo in aws_acm_certificate.wildcard_cert_use2.domain_validation_options : dvo.resource_record_name
  ]
}
