
data "aws_caller_identity" "current" {}


resource "aws_route53_record" "spf" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "onthespotsecurity.com"
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 include:amazonses.com ~all"]
}

resource "aws_route53_record" "dmarc" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "_dmarc.onthespotsecurity.com"
  type    = "TXT"
  ttl     = 300
  records = ["v=DMARC1; p=reject; rua=mailto:dmarc@onthespotsecurity.com"]
}
