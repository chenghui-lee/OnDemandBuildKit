module "build_cache_bucket" {
  source            = "../modules/s3_bucket"
  bucket_name       = "buildkit-cache-bucket"
  ec2_instance_role = var.ec2_instance_role
}
