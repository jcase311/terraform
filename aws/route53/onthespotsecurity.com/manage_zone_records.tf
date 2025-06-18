#this is where you will add additional dns entries 
#records of A,CNAME,MX etc..

resource "aws_route53_record" "web" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.onthespotsecurity.com"
  type    = "CNAME"
  ttl     = 300
  records = ["web-alb-1999023055.us-east-2.elb.amazonaws.com"]

}
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.onthespotsecurity.com"
  type    = "CNAME"
  ttl     = 300
  records = ["internal-app-alb-293253736.us-east-2.elb.amazonaws.com"]

}
