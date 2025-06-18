module "secure_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "aws-secure-vpc"
  cidr = "10.0.0.0/16"
  azs  = ["us-east-2a", "us-east-2b"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]     # Web Tier
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]   # App Tier
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24"]  # DB Tier

  enable_nat_gateway     = true
  single_nat_gateway     = true
  enable_dns_hostnames   = true
  enable_dns_support     = true

  create_database_subnet_group = true
  create_database_subnet_route_table = true

  public_subnet_tags = {
    Tier = "web tier"
  }

  private_subnet_tags = {
    Tier = "app tier"
  }

  database_subnet_tags = {
    Tier = "db"
  }

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}



#start network ACLs

resource "aws_network_acl" "app_tier" {
  vpc_id = module.secure_vpc.vpc_id
  subnet_ids = module.secure_vpc.private_subnets

  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "10.0.0.0/8"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "10.0.1.0/24"  # Only from web tier
    from_port  = 80
    to_port    = 80
  }

  ingress {
    rule_no    = 1
    protocol   = "-1"
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Tier = "app"
  }
}

resource "aws_network_acl" "db_tier" {
  vpc_id = module.secure_vpc.vpc_id
  subnet_ids = module.secure_vpc.database_subnets

  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "10.0.0.0/8"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "10.0.11.0/24" # Only from app tier
    from_port  = 3306
    to_port    = 3306
  }

  ingress {
    rule_no    = 1
    protocol   = "-1"
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Tier = "db"
  }
}


#start security groups

resource "aws_security_group" "web_sg" {
  name        = "web-tier-sg"
  description = "Allow inbound HTTP/HTTPS"
  vpc_id      = module.secure_vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/8"]
  }

  tags = {
    Tier = "web"
  }
}

resource "aws_security_group" "app_sg" {
  name        = "app-tier-sg"
  description = "Allow HTTPS from Web Tier"
  vpc_id      = module.secure_vpc.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }

  tags = {
    Tier = "app"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "db-tier-sg"
  description = "Allow MySQL from App Tier"
  vpc_id      = module.secure_vpc.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }

  tags = {
    Tier = "db"
  }
}


#start vpc flow logs 
resource "aws_iam_role" "flow_logs_role" {
  name = "vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "flow_logs_policy" {
  name = "vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "vpc_flow_logs" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = module.secure_vpc.vpc_id
  iam_role_arn         = aws_iam_role.flow_logs_role.arn
  depends_on           = [aws_iam_role_policy.flow_logs_policy]
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs"
  retention_in_days = 180
  skip_destroy = false
}

#start guardduty 

resource "aws_guardduty_detector" "main" {
  enable = true
}


#start vpc endpoints

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.secure_vpc.vpc_id
  service_name      = "com.amazonaws.us-east-2.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.secure_vpc.private_route_table_ids

  tags = {
    Name = "vpc-endpoint-s3"
  }
}
