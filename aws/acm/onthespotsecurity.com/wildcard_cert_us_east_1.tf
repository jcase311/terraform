
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

data "aws_route53_zone" "primary" {
  name         = "onthespotsecurity.com."
  private_zone = false
}

resource "aws_acm_certificate" "wildcard_cert" {
  provider          = aws.use1
  domain_name       = "*.onthespotsecurity.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "wildcard.onthespotsecurity.com"
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.wildcard_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.primary.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "validate_cert" {
  provider                = aws.use1
  certificate_arn         = aws_acm_certificate.wildcard_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
