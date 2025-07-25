provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "useast2"
  region = "us-east-2"
}


data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "config_bucket" {
  bucket        = var.config_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "config_versioning" {
  bucket = aws_s3_bucket.config_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config_encryption" {
  bucket = aws_s3_bucket.config_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = aws_s3_bucket.config_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSConfigBucketPermissionsCheck",
        Effect    = "Allow",
        Principal = { Service = "config.amazonaws.com" },
        Action    = "s3:GetBucketAcl",
        Resource  = "arn:aws:s3:::${aws_s3_bucket.config_bucket.bucket}"
      },
      {
        Sid       = "AWSConfigBucketDelivery",
        Effect    = "Allow",
        Principal = { Service = "config.amazonaws.com" },
        Action    = "s3:PutObject",
        Resource  = "arn:aws:s3:::${aws_s3_bucket.config_bucket.bucket}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_s3_object" "pci_template" {
  bucket = aws_s3_bucket.config_bucket.bucket
  key    = "templates/pci.yaml"
  source = "${path.module}/templates/pci.yaml"
  etag   = filemd5("${path.module}/templates/pci.yaml")
}

resource "aws_iam_role" "config_role" {
  name = "aws-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "config.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config_role_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

resource "aws_config_configuration_recorder" "recorder" {
  name     = "org-config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "delivery_channel" {
  name           = "default"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
  depends_on     = [aws_config_configuration_recorder.recorder]
}

resource "aws_config_configuration_recorder_status" "recorder_status" {
  name       = aws_config_configuration_recorder.recorder.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.delivery_channel]
}

resource "aws_config_configuration_aggregator" "org_aggregator" {
  name = "org-aggregator"

  organization_aggregation_source {
    role_arn    = aws_iam_role.config_role.arn
    all_regions = true 
 }
}


resource "aws_config_configuration_recorder" "recorder_useast2" {
  provider = aws.useast2
  name     = "org-config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "delivery_channel_useast2" {
  provider       = aws.useast2
  name           = "default"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
  depends_on     = [aws_config_configuration_recorder.recorder_useast2]
}

resource "aws_config_configuration_recorder_status" "recorder_status_useast2" {
  provider   = aws.useast2
  name       = aws_config_configuration_recorder.recorder_useast2.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.delivery_channel_useast2]
}


resource "aws_config_conformance_pack" "pci_pack" {
  name                = "PCI-DSS"
  delivery_s3_bucket  = aws_s3_bucket.config_bucket.bucket
  template_s3_uri     = "s3://${aws_s3_bucket.config_bucket.bucket}/templates/pci.yaml"
}

resource "aws_config_conformance_pack" "pci_pack_useast2" {
  provider            = aws.useast2
  name                = "PCI-DSS-USEAST2"
  delivery_s3_bucket  = aws_s3_bucket.config_bucket.bucket
  template_s3_uri     = "s3://${aws_s3_bucket.config_bucket.bucket}/templates/pci.yaml"
}
