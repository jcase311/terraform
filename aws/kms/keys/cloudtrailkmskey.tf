resource "aws_kms_key" "cloudtrail-s3-key" {
  description         = "KMS key for cloudtrail to S3"
  deletion_window_in_days = 10
  enable_key_rotation = true
}

output "kms_key_arn" {
  description = "The ARN of the KMS key"
  value       = aws_kms_key.cloudtrail-s3-key.arn
}

resource "aws_kms_alias" "cloudtrail-s3-alias" {
  name          = "alias/cloudtrail-s3"
  target_key_id = aws_kms_key.cloudtrail-s3-key.key_id
}
