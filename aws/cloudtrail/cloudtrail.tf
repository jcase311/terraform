module "cloudtrail" {
  source = "cloudposse/cloudtrail/aws"
  # Cloud Posse recommends pinning every module to a specific version
  # version     = "x.x.x"
  namespace                     = "eg"
  stage                         = "dev"
  name                          = "onthespotsecurity-cloudtrail"
  enable_log_file_validation    = true
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = true 
  enable_logging                = true
  s3_bucket_name                = module.cloudtrail_s3_bucket.bucket_id
}

module "cloudtrail_s3_bucket" {
  source = "cloudposse/cloudtrail-s3-bucket/aws"
  # Cloud Posse recommends pinning every module to a specific version
  # version     = "x.x.x"
  namespace = "eg"
  stage     = "dev"
  name      = "onthespotsecurity-cloudtrail-logging"
}
