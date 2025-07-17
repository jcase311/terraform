resource "aws_route53_zone" "main" {
  name = "onthespotsecurity.com"
  
  lifecycle {
    prevent_destroy = true
  }
}
