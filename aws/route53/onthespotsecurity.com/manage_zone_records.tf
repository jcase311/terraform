#this is where you will add additional dns entries 
#records of A,CNAME,MX etc..


resource "aws_route53_record" "app_ip" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.onthespotsecurity.com"
  type    = "CNAME"
  ttl     = 300
  records = ["cis-alb-1800985296.us-east-2.elb.amazonaws.com"]  # replace with your actual public IP
}
