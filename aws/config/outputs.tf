output "config_bucket_name" {
  value = aws_s3_bucket.config_bucket.bucket
}

output "aggregator_arn" {
  value = aws_config_configuration_aggregator.org_aggregator.arn
}
